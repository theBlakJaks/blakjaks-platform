/**
 * WebSocket client for real-time chat messaging.
 *
 * Connects to the backend at /social/ws, handles authentication,
 * channel join/leave, and incoming message events.  Reconnects
 * automatically with exponential backoff on disconnect.
 */

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

export type ConnectionState = 'disconnected' | 'connecting' | 'connected' | 'reconnecting'

export interface ChatMessage {
  id: string
  channel_id: string
  user_id: string
  username: string
  avatar_url: string | null
  content: string
  reply_to_id: string | null
  is_pinned: boolean
  is_system: boolean
  created_at: string
}

export interface TypingEvent {
  channel_id: string
  user_id: string
  username: string
}

export interface ReactionUpdate {
  message_id: string
  emoji: string
  user_id: string
  action: 'add' | 'remove'
}

type MessageHandler = (msg: ChatMessage) => void
type TypingHandler = (evt: TypingEvent) => void
type ReactionHandler = (evt: ReactionUpdate) => void
type StateHandler = (state: ConnectionState) => void

class ChatSocket {
  private ws: WebSocket | null = null
  private state: ConnectionState = 'disconnected'
  private reconnectAttempts = 0
  private maxReconnectDelay = 30_000
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null
  private activeChannel: string | null = null

  // Event handlers
  private onMessageHandlers: MessageHandler[] = []
  private onTypingHandlers: TypingHandler[] = []
  private onReactionHandlers: ReactionHandler[] = []
  private onStateHandlers: StateHandler[] = []

  // ── Public API ──────────────────────────────────────────────────

  connect() {
    if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
      return
    }

    const token = typeof window !== 'undefined' ? localStorage.getItem('blakjaks_token') : null
    if (!token) {
      console.warn('[ChatSocket] No auth token — skipping connect')
      return
    }

    this.setState(this.reconnectAttempts > 0 ? 'reconnecting' : 'connecting')

    // Build WebSocket URL: http→ws, https→wss
    const wsBase = BASE_URL.replace(/^http/, 'ws')
    this.ws = new WebSocket(`${wsBase}/social/ws?token=${encodeURIComponent(token)}`)

    this.ws.onopen = () => {
      // Auth happens automatically via query param; we wait for auth_success
    }

    this.ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        this.handleMessage(data)
      } catch {
        console.error('[ChatSocket] Failed to parse message', event.data)
      }
    }

    this.ws.onclose = (event) => {
      console.info(`[ChatSocket] Disconnected (code=${event.code})`)
      this.ws = null

      if (event.code === 4001) {
        // Auth failed — don't reconnect
        this.setState('disconnected')
        return
      }

      this.scheduleReconnect()
    }

    this.ws.onerror = () => {
      // onclose will fire after this; we handle reconnection there
    }
  }

  disconnect() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = null
    }
    this.reconnectAttempts = 0
    this.activeChannel = null
    if (this.ws) {
      this.ws.close(1000, 'Client disconnect')
      this.ws = null
    }
    this.setState('disconnected')
  }

  joinChannel(channelId: string) {
    // Leave previous channel first
    if (this.activeChannel && this.activeChannel !== channelId) {
      this.send({ type: 'leave_channel', channel_id: this.activeChannel })
    }
    this.activeChannel = channelId
    this.send({ type: 'join_channel', channel_id: channelId })
  }

  leaveChannel(channelId: string) {
    if (this.activeChannel === channelId) {
      this.activeChannel = null
    }
    this.send({ type: 'leave_channel', channel_id: channelId })
  }

  sendMessage(channelId: string, content: string, replyToId?: string) {
    this.send({
      type: 'send_message',
      channel_id: channelId,
      content,
      reply_to_id: replyToId ?? null,
    })
  }

  sendTyping(channelId: string) {
    this.send({ type: 'typing', channel_id: channelId })
  }

  addReaction(messageId: string, emoji: string, channelId: string) {
    this.send({ type: 'add_reaction', message_id: messageId, emoji, channel_id: channelId })
  }

  removeReaction(messageId: string, emoji: string, channelId: string) {
    this.send({ type: 'remove_reaction', message_id: messageId, emoji, channel_id: channelId })
  }

  getState(): ConnectionState {
    return this.state
  }

  // ── Event subscriptions ─────────────────────────────────────────

  onMessage(handler: MessageHandler): () => void {
    this.onMessageHandlers.push(handler)
    return () => { this.onMessageHandlers = this.onMessageHandlers.filter(h => h !== handler) }
  }

  onTyping(handler: TypingHandler): () => void {
    this.onTypingHandlers.push(handler)
    return () => { this.onTypingHandlers = this.onTypingHandlers.filter(h => h !== handler) }
  }

  onReaction(handler: ReactionHandler): () => void {
    this.onReactionHandlers.push(handler)
    return () => { this.onReactionHandlers = this.onReactionHandlers.filter(h => h !== handler) }
  }

  onStateChange(handler: StateHandler): () => void {
    this.onStateHandlers.push(handler)
    return () => { this.onStateHandlers = this.onStateHandlers.filter(h => h !== handler) }
  }

  // ── Internal ────────────────────────────────────────────────────

  private send(data: Record<string, unknown>) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data))
    }
  }

  private setState(state: ConnectionState) {
    this.state = state
    this.onStateHandlers.forEach(h => h(state))
  }

  private handleMessage(data: Record<string, unknown>) {
    switch (data.type) {
      case 'auth_success':
        this.setState('connected')
        this.reconnectAttempts = 0
        // Rejoin active channel after reconnect
        if (this.activeChannel) {
          this.send({ type: 'join_channel', channel_id: this.activeChannel })
        }
        break

      case 'new_message':
        this.onMessageHandlers.forEach(h => h(data as unknown as ChatMessage))
        break

      case 'typing':
        this.onTypingHandlers.forEach(h => h(data as unknown as TypingEvent))
        break

      case 'reaction_update':
        this.onReactionHandlers.forEach(h => h(data as unknown as ReactionUpdate))
        break

      case 'error':
        console.warn('[ChatSocket] Server error:', data.message)
        break

      case 'joined':
      case 'left':
        // Acknowledgements — no action needed
        break

      default:
        console.debug('[ChatSocket] Unknown message type:', data.type)
    }
  }

  private scheduleReconnect() {
    this.setState('reconnecting')
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s max
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), this.maxReconnectDelay)
    this.reconnectAttempts++
    console.info(`[ChatSocket] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`)
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null
      this.connect()
    }, delay)
  }
}

// Singleton instance
export const chatSocket = new ChatSocket()
