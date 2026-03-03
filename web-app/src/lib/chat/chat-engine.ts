/**
 * ChatEngine — production-grade WebSocket chat client.
 *
 * State machine:
 *   disconnected ──connect()──▷ connecting
 *   connecting ──auth_success──▷ connected
 *   connected ──ws.close(4000)──▷ reconnecting (immediate)
 *   connected ──ws.close(4001)──▷ session_expired (terminal)
 *   connected ──ws.close(other)──▷ reconnecting
 *   reconnecting ──backoff──▷ connecting
 *
 * Portable: no DOM dependencies beyond WebSocket, localStorage, crypto.
 * Runs in main thread or SharedWorker.
 */

import { ConnectionQualityMonitor } from './connection-quality'
import type {
  ChatEngineEvents,
  ConnectionQuality,
  ConnectionState,
  InboundMessage,
  InboundNewMessage,
  InboundReplayMessage,
  OutboundMessage,
  QueuedMessage,
} from './types'

// Strip trailing /api suffix — the WS endpoint is mounted at /social/ws on the
// root app, not under the /api prefix used by REST routes.
const BASE_URL = (process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000').replace(/\/api\/?$/, '')
const QUEUE_STORAGE_KEY = 'blakjaks_chat_queue'
const MAX_QUEUE_SIZE = 20
const QUEUE_TTL_MS = 5 * 60 * 1000 // 5 minutes
const QUEUE_FLUSH_DELAY_MS = 100
const ZOMBIE_TIMEOUT_MS = 35_000 // no server ping in 35s → zombie
const DEDUP_MAX_SIZE = 1000
const MAX_RECONNECT_DELAY_MS = 10_000
const RECONNECT_JITTER_MS = 500
const MAX_RECONNECT_ATTEMPTS = 10 // stop retrying after 10 consecutive failures
const RAPID_CLOSE_MS = 2_000 // if WS closes within 2s of opening, it's likely an auth rejection

type EventKey = keyof ChatEngineEvents
type Handler<K extends EventKey> = ChatEngineEvents[K]

export class ChatEngine {
  // ── Connection state ──
  private _state: ConnectionState = 'disconnected'
  private _ws: WebSocket | null = null
  private _sessionId: string | null = null
  private _userId: string | null = null
  private _getToken: (() => string | null) | null = null
  private _reconnectAttempts = 0
  private _rapidCloseCount = 0 // consecutive connections that closed within RAPID_CLOSE_MS
  private _connectTime = 0 // timestamp when current WS opened
  private _reconnectTimer: ReturnType<typeof setTimeout> | null = null
  private _zombieTimer: ReturnType<typeof setTimeout> | null = null
  private _visibilityDelay: ReturnType<typeof setTimeout> | null = null

  // ── Per-channel sequence tracking ──
  private _lastSequence = new Map<string, number>()

  // ── Outbound queue (persisted to localStorage) ──
  private _outboundQueue = new Map<string, QueuedMessage>()

  // ── Replay buffer ──
  private _replayBuffer = new Map<string, InboundReplayMessage[]>()
  private _replayFullResync = new Map<string, boolean>()
  private _catchingUp = new Set<string>()

  // ── Dedup ──
  private _seenIds: string[] = []

  // ── Connection quality ──
  private _qualityMonitor = new ConnectionQualityMonitor()
  private _pingTimestamp: number | null = null
  private _rttInterval: ReturnType<typeof setInterval> | null = null

  // ── Event handlers ──
  private _handlers = new Map<EventKey, Set<Function>>()

  // ── Joined channels ──
  private _joinedChannels = new Set<string>()

  // ── Confirmation timeouts ──
  private _confirmationTimeouts = new Map<string, ReturnType<typeof setTimeout>>()

  // ── Visibility (inline mode only, not SharedWorker) ──
  private _visibilityHandler: (() => void) | null = null

  constructor() {
    this._restoreQueue()
    this._qualityMonitor.onChange = (q: ConnectionQuality) => {
      this._emit('qualityChange', q)
      // Restart the RTT interval at the new rate
      this._startRttInterval()
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  connect(getToken: () => string | null): void {
    this._getToken = getToken
    this._doConnect()
    this._bindVisibility()
  }

  disconnect(): void {
    this._unbindVisibility()
    this._clearReconnect()
    this._clearZombieTimer()
    this._stopRttInterval()
    if (this._ws) {
      this._ws.onclose = null // prevent reconnect
      this._ws.close(1000)
      this._ws = null
    }
    this._setState('disconnected')
  }

  joinChannel(channelId: string): void {
    this._joinedChannels.add(channelId)
    this._send({ type: 'join_channel', channel_id: channelId })
  }

  leaveChannel(channelId: string): void {
    this._joinedChannels.delete(channelId)
    this._send({ type: 'leave_channel', channel_id: channelId })
  }

  resumeChannel(channelId: string): void {
    const lastSeq = this._lastSequence.get(channelId) ?? 0
    this._joinedChannels.add(channelId)
    this._send({ type: 'resume', channel_id: channelId, last_sequence: lastSeq })
  }

  sendMessage(channelId: string, content: string, replyToId?: string, existingIdempotencyKey?: string): QueuedMessage {
    const idempotencyKey = existingIdempotencyKey ?? crypto.randomUUID()
    const queued: QueuedMessage = {
      idempotencyKey,
      channelId,
      content,
      replyToId,
      status: 'sending',
      queuedAt: Date.now(),
    }

    this._outboundQueue.set(idempotencyKey, queued)
    this._persistQueue()
    this._emit('messageQueued', queued)

    // Set 10s confirmation timeout
    const timeout = setTimeout(() => {
      const q = this._outboundQueue.get(idempotencyKey)
      if (q && q.status === 'sending') {
        q.status = 'failed'
        this._persistQueue()
        this._emit('messageFailed', idempotencyKey)
      }
      this._confirmationTimeouts.delete(idempotencyKey)
    }, 10_000)
    this._confirmationTimeouts.set(idempotencyKey, timeout)

    // Try to send immediately if connected
    if (this._ws?.readyState === WebSocket.OPEN) {
      this._send({
        type: 'send_message',
        channel_id: channelId,
        content,
        reply_to_id: replyToId,
        idempotency_key: idempotencyKey,
      })
    }

    return queued
  }

  addReaction(messageId: string, emoji: string, channelId: string): void {
    this._send({ type: 'add_reaction', message_id: messageId, emoji, channel_id: channelId })
  }

  removeReaction(messageId: string, emoji: string, channelId: string): void {
    this._send({ type: 'remove_reaction', message_id: messageId, emoji, channel_id: channelId })
  }

  sendTyping(channelId: string): void {
    // Don't send typing indicators when connection quality is degraded or poor
    if (this._qualityMonitor.quality !== 'good') return
    this._send({ type: 'typing', channel_id: channelId })
  }

  deleteMessage(messageId: string, channelId: string): void {
    this._send({ type: 'delete_message', message_id: messageId, channel_id: channelId })
  }

  getState(): ConnectionState {
    return this._state
  }

  getQuality(): ConnectionQuality {
    return this._qualityMonitor.quality
  }

  getPresence(): Map<string, Set<string>> {
    // Presence is tracked in the hook layer, not here
    return new Map()
  }

  getLastSequence(channelId: string): number {
    return this._lastSequence.get(channelId) ?? 0
  }

  getSessionId(): string | null {
    return this._sessionId
  }

  getUserId(): string | null {
    return this._userId
  }

  on<K extends EventKey>(event: K, handler: Handler<K>): () => void {
    if (!this._handlers.has(event)) {
      this._handlers.set(event, new Set())
    }
    this._handlers.get(event)!.add(handler)
    return () => {
      this._handlers.get(event)?.delete(handler)
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection
  // ═══════════════════════════════════════════════════════════════════════════

  private _doConnect(): void {
    if (this._ws?.readyState === WebSocket.CONNECTING || this._ws?.readyState === WebSocket.OPEN) {
      return
    }

    const token = this._getToken?.()
    if (!token) {
      this._setState('disconnected')
      return
    }

    this._setState(this._reconnectAttempts > 0 ? 'reconnecting' : 'connecting')

    const wsUrl = BASE_URL.replace(/^http/, 'ws') + `/social/ws?token=${token}`
    const ws = new WebSocket(wsUrl)
    this._ws = ws
    this._connectTime = Date.now()

    ws.onopen = () => {
      // Connection opened — waiting for auth_success
    }

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data) as InboundMessage
        this._handleMessage(data)
      } catch {
        // Ignore malformed messages
      }
    }

    ws.onclose = (event) => {
      this._ws = null
      this._clearZombieTimer()
      this._stopRttInterval()

      if (event.code === 4001) {
        // Auth failure — terminal, do not reconnect
        this._setState('session_expired')
        return
      }

      if (this._state === 'disconnected') {
        // Intentional disconnect via disconnect()
        return
      }

      // Detect rapid close — if the WS closes within 2s of opening without
      // ever reaching auth_success, it's likely a server-side auth rejection
      // that doesn't use close code 4001 (e.g. HTTP-level 401 before upgrade).
      const wasRapidClose = Date.now() - this._connectTime < RAPID_CLOSE_MS
      if (wasRapidClose && this._state !== 'connected') {
        this._rapidCloseCount++
      } else {
        this._rapidCloseCount = 0
      }

      // Stop retrying if we've hit max attempts or keep getting rapid-closed
      if (this._reconnectAttempts >= MAX_RECONNECT_ATTEMPTS || this._rapidCloseCount >= 3) {
        this._setState('session_expired')
        return
      }

      // Schedule reconnect
      if (event.code === 4000) {
        // Resumable — immediate retry
        this._scheduleReconnect(0)
      } else {
        this._scheduleReconnect()
      }
    }

    ws.onerror = () => {
      // onerror is always followed by onclose — handle there
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Message handling
  // ═══════════════════════════════════════════════════════════════════════════

  private _handleMessage(data: InboundMessage): void {
    switch (data.type) {
      case 'auth_success':
        this._sessionId = data.session_id
        this._userId = data.user_id
        this._reconnectAttempts = 0
        this._rapidCloseCount = 0
        this._setState('connected')
        this._resetZombieTimer()
        this._onConnected()
        break

      case 'new_message':
        this._handleNewMessage(data)
        break

      case 'message_deleted':
        this._emit('messageDeleted', data)
        break

      case 'reaction_update':
        this._emit('reactionUpdate', data)
        break

      case 'typing':
        this._emit('typing', data)
        break

      case 'presence_update':
        this._emit('presenceUpdate', data)
        break

      case 'stream_ended':
        this._emit('streamEnded', data)
        break

      case 'replay_start':
        this._catchingUp.add(data.channel_id)
        this._replayBuffer.set(data.channel_id, [])
        this._replayFullResync.set(data.channel_id, data.full_resync)
        this._emit('catchingUp', true)
        this._emit('replayStart', data)
        break

      case 'replay_message':
        this._trackSequence(data.channel_id, data.sequence)
        this._ack(data.channel_id, data.sequence)
        {
          const buf = this._replayBuffer.get(data.channel_id)
          if (buf) buf.push(data)
        }
        this._emit('replayMessage', data)
        break

      case 'replay_end':
        this._emit('replayEnd', data)
        this._catchingUp.delete(data.channel_id)
        if (this._catchingUp.size === 0) {
          this._emit('catchingUp', false)
        }
        this._replayBuffer.delete(data.channel_id)
        this._replayFullResync.delete(data.channel_id)
        // Flush outbound queue after replay completes
        this._flushQueue()
        break

      case 'ping':
        // Server ping — respond with pong, reset zombie timer
        this._send({ type: 'pong' })
        this._resetZombieTimer()
        break

      case 'pong':
        // Response to our client-initiated ping — measure RTT
        if (this._pingTimestamp !== null) {
          const rtt = Date.now() - this._pingTimestamp
          this._qualityMonitor.recordRtt(rtt)
          this._pingTimestamp = null
        }
        break

      case 'error':
        this._emit('error', data)
        break

      case 'session_expired':
        this._setState('session_expired')
        if (this._ws) {
          this._ws.onclose = null
          this._ws.close()
          this._ws = null
        }
        break
    }
  }

  private _handleNewMessage(msg: InboundNewMessage): void {
    // Track sequence
    this._trackSequence(msg.channel_id, msg.sequence)

    // ACK delivery
    this._ack(msg.channel_id, msg.sequence)

    // Check if this confirms an optimistic message — do this BEFORE dedup
    // so that a broadcast from another tab's send can still clear our queue
    if (msg.idempotency_key) {
      const queued = this._outboundQueue.get(msg.idempotency_key)
      if (queued) {
        // Clear confirmation timeout
        const timeout = this._confirmationTimeouts.get(msg.idempotency_key)
        if (timeout) {
          clearTimeout(timeout)
          this._confirmationTimeouts.delete(msg.idempotency_key)
        }
        this._outboundQueue.delete(msg.idempotency_key)
        this._persistQueue()
        // Only emit if not already seen (avoids double-render)
        if (!this._hasSeen(msg.id)) {
          this._markSeen(msg.id)
          this._emit('messageConfirmed', msg.idempotency_key, msg)
        }
        return
      }
    }

    // Dedup — skip if already processed
    if (this._hasSeen(msg.id)) return
    this._markSeen(msg.id)

    this._emit('message', msg)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reconnect + queue flush
  // ═══════════════════════════════════════════════════════════════════════════

  private _onConnected(): void {
    // Resume all previously joined channels
    for (const channelId of this._joinedChannels) {
      this.resumeChannel(channelId)
    }

    // Measure RTT immediately, then start periodic interval
    this._measureRtt()
    this._startRttInterval()
  }

  private _flushQueue(): void {
    const now = Date.now()
    const toSend: QueuedMessage[] = []
    const toDiscard: string[] = []

    for (const [key, msg] of this._outboundQueue) {
      if (now - msg.queuedAt > QUEUE_TTL_MS) {
        toDiscard.push(key)
      } else if (msg.status === 'sending') {
        toSend.push(msg)
      }
    }

    // Discard expired
    for (const key of toDiscard) {
      const timeout = this._confirmationTimeouts.get(key)
      if (timeout) {
        clearTimeout(timeout)
        this._confirmationTimeouts.delete(key)
      }
      this._outboundQueue.delete(key)
      this._emit('messageFailed', key)
    }

    if (toSend.length > 0) {
      this._flushWithDelay(toSend, 0)
    }

    this._persistQueue()
  }

  private _flushWithDelay(messages: QueuedMessage[], index: number): void {
    if (index >= messages.length) return
    if (this._ws?.readyState !== WebSocket.OPEN) return

    const msg = messages[index]
    this._send({
      type: 'send_message',
      channel_id: msg.channelId,
      content: msg.content,
      reply_to_id: msg.replyToId,
      idempotency_key: msg.idempotencyKey,
    })

    if (index + 1 < messages.length) {
      setTimeout(() => this._flushWithDelay(messages, index + 1), QUEUE_FLUSH_DELAY_MS)
    }
  }

  private _scheduleReconnect(delayMs?: number): void {
    this._clearReconnect()
    this._setState('reconnecting')

    const delay = delayMs ?? this._backoffDelay()
    this._reconnectAttempts++

    this._reconnectTimer = setTimeout(() => {
      this._reconnectTimer = null
      this._doConnect()
    }, delay)
  }

  private _backoffDelay(): number {
    const base = Math.min(1000 * Math.pow(2, this._reconnectAttempts), MAX_RECONNECT_DELAY_MS)
    const jitter = (Math.random() * 2 - 1) * RECONNECT_JITTER_MS
    return Math.max(0, base + jitter)
  }

  private _clearReconnect(): void {
    if (this._reconnectTimer) {
      clearTimeout(this._reconnectTimer)
      this._reconnectTimer = null
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Zombie detection (server ping timeout)
  // ═══════════════════════════════════════════════════════════════════════════

  private _resetZombieTimer(): void {
    this._clearZombieTimer()
    this._zombieTimer = setTimeout(() => {
      // No server ping received in 35s — zombie connection
      if (this._ws && this._ws.readyState === WebSocket.OPEN) {
        this._ws.close(4000, 'zombie')
      }
    }, ZOMBIE_TIMEOUT_MS)
  }

  private _clearZombieTimer(): void {
    if (this._zombieTimer) {
      clearTimeout(this._zombieTimer)
      this._zombieTimer = null
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RTT measurement via client-initiated ping
  // ═══════════════════════════════════════════════════════════════════════════

  private _measureRtt(): void {
    if (this._ws?.readyState !== WebSocket.OPEN) return
    this._pingTimestamp = Date.now()
    this._send({ type: 'ping' })
  }

  private _startRttInterval(): void {
    this._stopRttInterval()
    // Poor = 10s, good/degraded = 25s
    const intervalMs = this._qualityMonitor.quality === 'poor' ? 10_000 : 25_000
    this._rttInterval = setInterval(() => this._measureRtt(), intervalMs)
  }

  private _stopRttInterval(): void {
    if (this._rttInterval) {
      clearInterval(this._rttInterval)
      this._rttInterval = null
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sequence tracking & ACK
  // ═══════════════════════════════════════════════════════════════════════════

  private _trackSequence(channelId: string, sequence: number): void {
    const current = this._lastSequence.get(channelId) ?? 0
    if (sequence > current) {
      this._lastSequence.set(channelId, sequence)
    }
  }

  private _ack(channelId: string, sequence: number): void {
    this._send({ type: 'ack', sequence, channel_id: channelId })
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dedup
  // ═══════════════════════════════════════════════════════════════════════════

  private _hasSeen(id: string): boolean {
    return this._seenIds.includes(id)
  }

  private _markSeen(id: string): void {
    this._seenIds.push(id)
    if (this._seenIds.length > DEDUP_MAX_SIZE) {
      this._seenIds = this._seenIds.slice(-DEDUP_MAX_SIZE)
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Queue persistence (localStorage)
  // ═══════════════════════════════════════════════════════════════════════════

  private _persistQueue(): void {
    try {
      const entries = Array.from(this._outboundQueue.values())
        .filter((m) => m.status === 'sending')
        .slice(-MAX_QUEUE_SIZE)
      localStorage.setItem(QUEUE_STORAGE_KEY, JSON.stringify(entries))
    } catch {
      // localStorage unavailable (SSR, quota exceeded)
    }
  }

  private _restoreQueue(): void {
    try {
      const raw = localStorage.getItem(QUEUE_STORAGE_KEY)
      if (!raw) return
      const entries = JSON.parse(raw) as QueuedMessage[]
      const now = Date.now()
      for (const entry of entries) {
        if (now - entry.queuedAt < QUEUE_TTL_MS && entry.status === 'sending') {
          this._outboundQueue.set(entry.idempotencyKey, entry)
        }
      }
    } catch {
      // localStorage unavailable or corrupted
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Visibility handling (inline mode — not used in SharedWorker)
  // ═══════════════════════════════════════════════════════════════════════════

  private _bindVisibility(): void {
    if (typeof document === 'undefined') return
    this._visibilityHandler = () => {
      if (document.visibilityState === 'visible') {
        if (this._visibilityDelay) {
          clearTimeout(this._visibilityDelay)
          this._visibilityDelay = null
        }
        if (this._state !== 'connected' && this._state !== 'connecting' && this._state !== 'session_expired') {
          this._reconnectAttempts = 0
          this._scheduleReconnect(0)
        }
        // Measure RTT on tab foreground
        if (this._state === 'connected') {
          this._measureRtt()
        }
      } else {
        // Tab hidden — delay reconnect attempts by 30s
        if (this._state === 'reconnecting') {
          this._clearReconnect()
          this._visibilityDelay = setTimeout(() => {
            this._visibilityDelay = null
            if (this._state !== 'connected' && this._state !== 'session_expired') {
              this._scheduleReconnect()
            }
          }, 30_000)
        }
      }
    }
    document.addEventListener('visibilitychange', this._visibilityHandler)
  }

  private _unbindVisibility(): void {
    if (this._visibilityHandler && typeof document !== 'undefined') {
      document.removeEventListener('visibilitychange', this._visibilityHandler)
      this._visibilityHandler = null
    }
    if (this._visibilityDelay) {
      clearTimeout(this._visibilityDelay)
      this._visibilityDelay = null
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Send helper
  // ═══════════════════════════════════════════════════════════════════════════

  private _send(msg: OutboundMessage): void {
    if (this._ws?.readyState === WebSocket.OPEN) {
      this._ws.send(JSON.stringify(msg))
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // State management
  // ═══════════════════════════════════════════════════════════════════════════

  private _setState(state: ConnectionState): void {
    if (this._state === state) return
    this._state = state
    this._emit('stateChange', state)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Event emitter
  // ═══════════════════════════════════════════════════════════════════════════

  private _emit<K extends EventKey>(event: K, ...args: Parameters<Handler<K>>): void {
    const handlers = this._handlers.get(event)
    if (!handlers) return
    for (const handler of handlers) {
      try {
        ;(handler as Function)(...args)
      } catch {
        // Don't let handler errors crash the engine
      }
    }
  }
}
