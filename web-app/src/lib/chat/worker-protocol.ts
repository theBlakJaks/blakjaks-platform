/**
 * Worker protocol — discriminated union types for tab ↔ SharedWorker messages.
 *
 * Tab → Worker: commands routed to the single ChatEngine instance.
 * Worker → Tab: engine events broadcast to all connected ports.
 */

import type {
  ConnectionQuality,
  ConnectionState,
  InboundError,
  InboundMessageDeleted,
  InboundNewMessage,
  InboundPresenceUpdate,
  InboundReactionUpdate,
  InboundReplayEnd,
  InboundReplayMessage,
  InboundReplayStart,
  InboundStreamEnded,
  InboundTyping,
  QueuedMessage,
} from './types'

// ═══════════════════════════════════════════════════════════════════════════════
// Tab → Worker messages
// ═══════════════════════════════════════════════════════════════════════════════

export interface TabConnect {
  type: 'CONNECT'
  token: string
}

export interface TabDisconnect {
  type: 'DISCONNECT'
}

export interface TabJoinChannel {
  type: 'JOIN_CHANNEL'
  channelId: string
}

export interface TabLeaveChannel {
  type: 'LEAVE_CHANNEL'
  channelId: string
}

export interface TabResumeChannel {
  type: 'RESUME_CHANNEL'
  channelId: string
}

export interface TabSendMessage {
  type: 'SEND_MESSAGE'
  channelId: string
  content: string
  replyToId?: string
}

export interface TabAddReaction {
  type: 'ADD_REACTION'
  messageId: string
  emoji: string
  channelId: string
}

export interface TabRemoveReaction {
  type: 'REMOVE_REACTION'
  messageId: string
  emoji: string
  channelId: string
}

export interface TabSendTyping {
  type: 'SEND_TYPING'
  channelId: string
}

export interface TabDeleteMessage {
  type: 'DELETE_MESSAGE'
  messageId: string
  channelId: string
}

export interface TabGetState {
  type: 'GET_STATE'
}

export interface TabVisible {
  type: 'TAB_VISIBLE'
}

export interface TabHidden {
  type: 'TAB_HIDDEN'
}

export interface TabUpdateToken {
  type: 'UPDATE_TOKEN'
  token: string
}

export interface TabRequestCache {
  type: 'REQUEST_CACHE'
  channelId: string
}

export interface TabRestoreQueue {
  type: 'RESTORE_QUEUE'
  entries: QueuedMessage[]
}

export interface TabGetLastSequence {
  type: 'GET_LAST_SEQUENCE'
  channelId: string
  requestId: string
}

export interface TabGetUserId {
  type: 'GET_USER_ID'
  requestId: string
}

export type TabToWorkerMessage =
  | TabConnect
  | TabDisconnect
  | TabJoinChannel
  | TabLeaveChannel
  | TabResumeChannel
  | TabSendMessage
  | TabAddReaction
  | TabRemoveReaction
  | TabSendTyping
  | TabDeleteMessage
  | TabGetState
  | TabVisible
  | TabHidden
  | TabUpdateToken
  | TabRequestCache
  | TabRestoreQueue
  | TabGetLastSequence
  | TabGetUserId

// ═══════════════════════════════════════════════════════════════════════════════
// Worker → Tab messages
// ═══════════════════════════════════════════════════════════════════════════════

export interface WorkerStateUpdate {
  type: 'STATE_UPDATE'
  state: ConnectionState
}

export interface WorkerMessage {
  type: 'MESSAGE'
  data: InboundNewMessage
}

export interface WorkerReplayStart {
  type: 'REPLAY_START'
  data: InboundReplayStart
}

export interface WorkerReplayMessage {
  type: 'REPLAY_MESSAGE'
  data: InboundReplayMessage
}

export interface WorkerReplayEnd {
  type: 'REPLAY_END'
  data: InboundReplayEnd
}

export interface WorkerTyping {
  type: 'TYPING'
  data: InboundTyping
}

export interface WorkerReactionUpdate {
  type: 'REACTION_UPDATE'
  data: InboundReactionUpdate
}

export interface WorkerMessageDeleted {
  type: 'MESSAGE_DELETED'
  data: InboundMessageDeleted
}

export interface WorkerPresenceUpdate {
  type: 'PRESENCE_UPDATE'
  data: InboundPresenceUpdate
}

export interface WorkerStreamEnded {
  type: 'STREAM_ENDED'
  data: InboundStreamEnded
}

export interface WorkerSessionExpired {
  type: 'SESSION_EXPIRED'
}

export interface WorkerConnectionQuality {
  type: 'CONNECTION_QUALITY'
  quality: ConnectionQuality
}

export interface WorkerCurrentState {
  type: 'CURRENT_STATE'
  state: ConnectionState
  quality: ConnectionQuality
  userId: string | null
}

export interface WorkerCacheSync {
  type: 'CACHE_SYNC'
  channelId: string
  messages: InboundNewMessage[]
}

export interface WorkerMessageQueued {
  type: 'MESSAGE_QUEUED'
  data: QueuedMessage
}

export interface WorkerMessageConfirmed {
  type: 'MESSAGE_CONFIRMED'
  idempotencyKey: string
  serverMsg: InboundNewMessage
}

export interface WorkerMessageFailed {
  type: 'MESSAGE_FAILED'
  idempotencyKey: string
}

export interface WorkerCatchingUp {
  type: 'CATCHING_UP'
  catching: boolean
}

export interface WorkerError {
  type: 'ERROR'
  data: InboundError
}

export interface WorkerLastSequenceResponse {
  type: 'LAST_SEQUENCE_RESPONSE'
  requestId: string
  sequence: number
}

export interface WorkerUserIdResponse {
  type: 'USER_ID_RESPONSE'
  requestId: string
  userId: string | null
}

export type WorkerToTabMessage =
  | WorkerStateUpdate
  | WorkerMessage
  | WorkerReplayStart
  | WorkerReplayMessage
  | WorkerReplayEnd
  | WorkerTyping
  | WorkerReactionUpdate
  | WorkerMessageDeleted
  | WorkerPresenceUpdate
  | WorkerStreamEnded
  | WorkerSessionExpired
  | WorkerConnectionQuality
  | WorkerCurrentState
  | WorkerCacheSync
  | WorkerMessageQueued
  | WorkerMessageConfirmed
  | WorkerMessageFailed
  | WorkerCatchingUp
  | WorkerError
  | WorkerLastSequenceResponse
  | WorkerUserIdResponse
