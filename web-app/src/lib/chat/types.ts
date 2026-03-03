/**
 * WebSocket message types for the BlakJaks chat system.
 *
 * All client↔server messages are discriminated unions on the `type` field.
 */

// ---------------------------------------------------------------------------
// Connection & delivery state
// ---------------------------------------------------------------------------

export type ConnectionState =
  | 'disconnected'
  | 'connecting'
  | 'connected'
  | 'reconnecting'
  | 'session_expired'

export type ConnectionQuality = 'good' | 'degraded' | 'poor'

export type MessageDeliveryStatus = 'sending' | 'sent' | 'failed'

// ---------------------------------------------------------------------------
// Outbound queue
// ---------------------------------------------------------------------------

export interface QueuedMessage {
  idempotencyKey: string
  channelId: string
  content: string
  replyToId?: string
  status: MessageDeliveryStatus
  queuedAt: number // Date.now()
}

// ---------------------------------------------------------------------------
// Client → Server messages
// ---------------------------------------------------------------------------

export interface OutboundJoinChannel {
  type: 'join_channel'
  channel_id: string
}

export interface OutboundLeaveChannel {
  type: 'leave_channel'
  channel_id: string
}

export interface OutboundResume {
  type: 'resume'
  channel_id: string
  last_sequence: number
}

export interface OutboundSendMessage {
  type: 'send_message'
  channel_id: string
  content: string
  reply_to_id?: string
  idempotency_key: string
}

export interface OutboundTyping {
  type: 'typing'
  channel_id: string
}

export interface OutboundAddReaction {
  type: 'add_reaction'
  message_id: string
  emoji: string
  channel_id: string
}

export interface OutboundRemoveReaction {
  type: 'remove_reaction'
  message_id: string
  emoji: string
  channel_id: string
}

export interface OutboundPing {
  type: 'ping'
}

export interface OutboundPong {
  type: 'pong'
}

export interface OutboundAck {
  type: 'ack'
  sequence: number
  channel_id: string
}

export interface OutboundDeleteMessage {
  type: 'delete_message'
  message_id: string
  channel_id: string
}

export type OutboundMessage =
  | OutboundJoinChannel
  | OutboundLeaveChannel
  | OutboundResume
  | OutboundSendMessage
  | OutboundTyping
  | OutboundAddReaction
  | OutboundRemoveReaction
  | OutboundPing
  | OutboundPong
  | OutboundAck
  | OutboundDeleteMessage

// ---------------------------------------------------------------------------
// Server → Client messages
// ---------------------------------------------------------------------------

export interface InboundAuthSuccess {
  type: 'auth_success'
  session_id: string
  user_id: string
}

export interface InboundNewMessage {
  type: 'new_message'
  id: string
  channel_id: string
  user_id: string
  username: string
  avatar_url: string | null
  content: string
  sequence: number
  timestamp: string
  reply_to_id: string | null
  reply_to_content: string | null
  reply_to_username: string | null
  is_system: boolean
  idempotency_key: string | null
  status: string
}

export interface InboundMessageDeleted {
  type: 'message_deleted'
  message_id: string
  channel_id: string
  deleted_by: string
}

export interface InboundReactionUpdate {
  type: 'reaction_update'
  message_id: string
  channel_id: string
  emoji: string
  action: 'add' | 'remove'
  user_id: string
}

export interface InboundTyping {
  type: 'typing'
  channel_id: string
  username: string
  user_id: string
}

export interface InboundPresenceUpdate {
  type: 'presence_update'
  channel_id: string
  user_id: string
  username: string
  status: 'online' | 'offline'
}

export interface InboundStreamEnded {
  type: 'stream_ended'
  stream_id: string
}

export interface InboundReplayStart {
  type: 'replay_start'
  channel_id: string
  from_sequence: number
  to_sequence: number
  full_resync: boolean
  message_count: number
}

export interface InboundReplayMessage {
  type: 'replay_message'
  id: string
  channel_id: string
  user_id: string
  username: string
  avatar_url: string | null
  content: string
  sequence: number
  timestamp: string
  reply_to_id: string | null
  reply_to_content: string | null
  reply_to_username: string | null
  is_system: boolean
  idempotency_key: string | null
  status: string
}

export interface InboundReplayEnd {
  type: 'replay_end'
  channel_id: string
  to_sequence: number
}

export interface InboundPing {
  type: 'ping'
}

export interface InboundPong {
  type: 'pong'
}

export interface InboundError {
  type: 'error'
  code: string
  message: string
}

export interface InboundSessionExpired {
  type: 'session_expired'
}

export type InboundMessage =
  | InboundAuthSuccess
  | InboundNewMessage
  | InboundMessageDeleted
  | InboundReactionUpdate
  | InboundTyping
  | InboundPresenceUpdate
  | InboundStreamEnded
  | InboundReplayStart
  | InboundReplayMessage
  | InboundReplayEnd
  | InboundPing
  | InboundPong
  | InboundError
  | InboundSessionExpired

// ---------------------------------------------------------------------------
// ChatEngine event map
// ---------------------------------------------------------------------------

export interface ChatEngineEvents {
  stateChange: (state: ConnectionState) => void
  message: (msg: InboundNewMessage) => void
  messageDeleted: (msg: InboundMessageDeleted) => void
  reactionUpdate: (msg: InboundReactionUpdate) => void
  typing: (msg: InboundTyping) => void
  presenceUpdate: (msg: InboundPresenceUpdate) => void
  streamEnded: (msg: InboundStreamEnded) => void
  replayStart: (msg: InboundReplayStart) => void
  replayMessage: (msg: InboundReplayMessage) => void
  replayEnd: (msg: InboundReplayEnd) => void
  messageQueued: (msg: QueuedMessage) => void
  messageConfirmed: (idempotencyKey: string, serverMsg: InboundNewMessage) => void
  messageFailed: (idempotencyKey: string) => void
  qualityChange: (quality: ConnectionQuality) => void
  error: (msg: InboundError) => void
  catchingUp: (catching: boolean) => void
}
