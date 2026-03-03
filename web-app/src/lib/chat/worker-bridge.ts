/**
 * WorkerBridge — adapter that exposes the same public API as ChatEngine
 * but routes all calls through a SharedWorker MessagePort.
 *
 * The tab sends commands via port.postMessage() and receives engine events
 * back via port.onmessage. From the hook/UI perspective, this is
 * indistinguishable from an inline ChatEngine.
 */

import type {
  ChatEngineEvents,
  ConnectionQuality,
  ConnectionState,
  QueuedMessage,
} from './types'
import type { TabToWorkerMessage, WorkerToTabMessage } from './worker-protocol'

const QUEUE_STORAGE_KEY = 'blakjaks_chat_queue'
const QUEUE_TTL_MS = 5 * 60 * 1000

type EventKey = keyof ChatEngineEvents
type Handler<K extends EventKey> = ChatEngineEvents[K]

export class WorkerBridge {
  private _worker: SharedWorker
  private _port: MessagePort
  private _state: ConnectionState = 'disconnected'
  private _quality: ConnectionQuality = 'good'
  private _userId: string | null = null
  private _handlers = new Map<EventKey, Set<Function>>()
  private _pendingRequests = new Map<string, (value: unknown) => void>()
  private _visibilityHandler: (() => void) | null = null

  constructor() {
    this._worker = new SharedWorker('/chat-worker.js', { name: 'blakjaks-chat' })
    this._port = this._worker.port

    this._port.onmessage = (event) => {
      this._handleWorkerMessage(event.data as WorkerToTabMessage)
    }

    this._port.onmessageerror = () => {
      // Worker died — set disconnected
      this._state = 'disconnected'
      this._emit('stateChange', 'disconnected')
    }

    this._port.start()

    // Restore and forward persisted queue to worker
    this._restoreAndForwardQueue()
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API (matches ChatEngine)
  // ═══════════════════════════════════════════════════════════════════════════

  connect(getToken: () => string | null): void {
    const token = getToken()
    if (!token) return
    this._post({ type: 'CONNECT', token })
    this._bindVisibility()
  }

  disconnect(): void {
    this._unbindVisibility()
    this._post({ type: 'DISCONNECT' })
  }

  joinChannel(channelId: string): void {
    this._post({ type: 'JOIN_CHANNEL', channelId })
  }

  leaveChannel(channelId: string): void {
    this._post({ type: 'LEAVE_CHANNEL', channelId })
  }

  resumeChannel(channelId: string): void {
    this._post({ type: 'RESUME_CHANNEL', channelId })
  }

  sendMessage(channelId: string, content: string, replyToId?: string): QueuedMessage {
    // Generate a local placeholder — the real QueuedMessage comes back via MESSAGE_QUEUED
    const placeholder: QueuedMessage = {
      idempotencyKey: crypto.randomUUID(),
      channelId,
      content,
      replyToId,
      status: 'sending',
      queuedAt: Date.now(),
    }
    this._post({ type: 'SEND_MESSAGE', channelId, content, replyToId })
    return placeholder
  }

  addReaction(messageId: string, emoji: string, channelId: string): void {
    this._post({ type: 'ADD_REACTION', messageId, emoji, channelId })
  }

  removeReaction(messageId: string, emoji: string, channelId: string): void {
    this._post({ type: 'REMOVE_REACTION', messageId, emoji, channelId })
  }

  sendTyping(channelId: string): void {
    this._post({ type: 'SEND_TYPING', channelId })
  }

  deleteMessage(messageId: string, channelId: string): void {
    this._post({ type: 'DELETE_MESSAGE', messageId, channelId })
  }

  getState(): ConnectionState {
    return this._state
  }

  getQuality(): ConnectionQuality {
    return this._quality
  }

  getPresence(): Map<string, Set<string>> {
    // Presence is tracked in the hook layer
    return new Map()
  }

  getLastSequence(channelId: string): number {
    // Synchronous access not possible across worker boundary — return 0.
    // For async access, use getLastSequenceAsync().
    return 0
  }

  async getLastSequenceAsync(channelId: string): Promise<number> {
    const requestId = crypto.randomUUID()
    return new Promise<number>((resolve) => {
      this._pendingRequests.set(requestId, resolve as (value: unknown) => void)
      this._post({ type: 'GET_LAST_SEQUENCE', channelId, requestId })
      // Timeout after 5s
      setTimeout(() => {
        if (this._pendingRequests.has(requestId)) {
          this._pendingRequests.delete(requestId)
          resolve(0)
        }
      }, 5000)
    })
  }

  getSessionId(): string | null {
    return null // Not available synchronously across worker boundary
  }

  getUserId(): string | null {
    return this._userId
  }

  async getUserIdAsync(): Promise<string | null> {
    const requestId = crypto.randomUUID()
    return new Promise<string | null>((resolve) => {
      this._pendingRequests.set(requestId, resolve as (value: unknown) => void)
      this._post({ type: 'GET_USER_ID', requestId })
      setTimeout(() => {
        if (this._pendingRequests.has(requestId)) {
          this._pendingRequests.delete(requestId)
          resolve(null)
        }
      }, 5000)
    })
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

  /**
   * Forward a token update to the worker (call this when the auth token refreshes).
   */
  updateToken(token: string): void {
    this._post({ type: 'UPDATE_TOKEN', token })
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Worker message handling
  // ═══════════════════════════════════════════════════════════════════════════

  private _handleWorkerMessage(msg: WorkerToTabMessage): void {
    switch (msg.type) {
      case 'STATE_UPDATE':
        if (this._state !== msg.state) {
          this._state = msg.state
          this._emit('stateChange', msg.state)
        }
        break

      case 'CONNECTION_QUALITY':
        if (this._quality !== msg.quality) {
          this._quality = msg.quality
          this._emit('qualityChange', msg.quality)
        }
        break

      case 'CATCHING_UP':
        this._emit('catchingUp', msg.catching)
        break

      case 'MESSAGE':
        this._emit('message', msg.data)
        break

      case 'MESSAGE_CONFIRMED':
        this._emit('messageConfirmed', msg.idempotencyKey, msg.serverMsg)
        break

      case 'MESSAGE_FAILED':
        this._emit('messageFailed', msg.idempotencyKey)
        break

      case 'MESSAGE_QUEUED':
        this._emit('messageQueued', msg.data)
        break

      case 'MESSAGE_DELETED':
        this._emit('messageDeleted', msg.data)
        break

      case 'REACTION_UPDATE':
        this._emit('reactionUpdate', msg.data)
        break

      case 'TYPING':
        this._emit('typing', msg.data)
        break

      case 'PRESENCE_UPDATE':
        this._emit('presenceUpdate', msg.data)
        break

      case 'STREAM_ENDED':
        this._emit('streamEnded', msg.data)
        break

      case 'REPLAY_START':
        this._emit('replayStart', msg.data)
        break

      case 'REPLAY_MESSAGE':
        this._emit('replayMessage', msg.data)
        break

      case 'REPLAY_END':
        this._emit('replayEnd', msg.data)
        break

      case 'ERROR':
        this._emit('error', msg.data)
        break

      case 'SESSION_EXPIRED':
        this._state = 'session_expired'
        this._emit('stateChange', 'session_expired')
        break

      case 'CURRENT_STATE': {
        const stateChanged = this._state !== msg.state
        const qualityChanged = this._quality !== msg.quality
        this._state = msg.state
        this._quality = msg.quality
        this._userId = msg.userId
        if (stateChanged) this._emit('stateChange', msg.state)
        if (qualityChanged) this._emit('qualityChange', msg.quality)
        break
      }

      case 'CACHE_SYNC':
        // Handled by consumer via on('cacheSync') — not currently in ChatEngineEvents
        // but available for future use
        break

      case 'LAST_SEQUENCE_RESPONSE': {
        const resolve = this._pendingRequests.get(msg.requestId)
        if (resolve) {
          this._pendingRequests.delete(msg.requestId)
          resolve(msg.sequence)
        }
        break
      }

      case 'USER_ID_RESPONSE': {
        const resolve = this._pendingRequests.get(msg.requestId)
        if (resolve) {
          this._pendingRequests.delete(msg.requestId)
          resolve(msg.userId)
        }
        this._userId = msg.userId
        break
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Visibility handling
  // ═══════════════════════════════════════════════════════════════════════════

  private _bindVisibility(): void {
    if (typeof document === 'undefined') return
    this._visibilityHandler = () => {
      if (document.visibilityState === 'visible') {
        this._post({ type: 'TAB_VISIBLE' })
      } else {
        this._post({ type: 'TAB_HIDDEN' })
      }
    }
    document.addEventListener('visibilitychange', this._visibilityHandler)
  }

  private _unbindVisibility(): void {
    if (this._visibilityHandler && typeof document !== 'undefined') {
      document.removeEventListener('visibilitychange', this._visibilityHandler)
      this._visibilityHandler = null
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Queue restoration
  // ═══════════════════════════════════════════════════════════════════════════

  private _restoreAndForwardQueue(): void {
    try {
      const raw = localStorage.getItem(QUEUE_STORAGE_KEY)
      if (!raw) return
      const entries = JSON.parse(raw) as QueuedMessage[]
      const now = Date.now()
      const valid = entries.filter(
        (e) => e.status === 'sending' && now - e.queuedAt < QUEUE_TTL_MS,
      )
      if (valid.length > 0) {
        this._post({ type: 'RESTORE_QUEUE', entries: valid })
        // Clear localStorage since the worker now owns the queue
        localStorage.removeItem(QUEUE_STORAGE_KEY)
      }
    } catch {
      // localStorage unavailable or corrupted
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  private _post(msg: TabToWorkerMessage): void {
    try {
      this._port.postMessage(msg)
    } catch {
      // Port closed — worker died
    }
  }

  private _emit<K extends EventKey>(event: K, ...args: Parameters<Handler<K>>): void {
    const handlers = this._handlers.get(event)
    if (!handlers) return
    for (const handler of handlers) {
      try {
        ;(handler as Function)(...args)
      } catch {
        // Don't let handler errors crash the bridge
      }
    }
  }
}
