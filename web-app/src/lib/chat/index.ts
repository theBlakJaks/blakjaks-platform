/**
 * Chat client factory — returns a singleton chat client.
 *
 * Returns a WorkerBridge when SharedWorker is available (multi-tab dedup),
 * falling back to inline ChatEngine otherwise (Safari <16, SSR, etc).
 * Both implement the same public API via the ChatClient interface.
 */

import { ChatEngine } from './chat-engine'
import { WorkerBridge } from './worker-bridge'
import type {
  ChatEngineEvents,
  ConnectionQuality,
  ConnectionState,
  QueuedMessage,
} from './types'

type EventKey = keyof ChatEngineEvents
type Handler<K extends EventKey> = ChatEngineEvents[K]

/**
 * Common interface implemented by both ChatEngine and WorkerBridge.
 * Consumers (useChat, social page) program against this interface.
 */
export interface ChatClient {
  connect(getToken: () => string | null): void
  disconnect(): void
  joinChannel(channelId: string): void
  leaveChannel(channelId: string): void
  resumeChannel(channelId: string): void
  sendMessage(channelId: string, content: string, replyToId?: string, existingIdempotencyKey?: string): QueuedMessage
  addReaction(messageId: string, emoji: string, channelId: string): void
  removeReaction(messageId: string, emoji: string, channelId: string): void
  sendTyping(channelId: string): void
  deleteMessage(messageId: string, channelId: string): void
  getState(): ConnectionState
  getQuality(): ConnectionQuality
  getPresence(): Map<string, Set<string>>
  getLastSequence(channelId: string): number
  getSessionId(): string | null
  getUserId(): string | null
  on<K extends EventKey>(event: K, handler: Handler<K>): () => void
}

let _instance: ChatClient | null = null

export function getChatClient(): ChatClient {
  if (!_instance) {
    if (typeof SharedWorker !== 'undefined') {
      _instance = new WorkerBridge()
    } else {
      _instance = new ChatEngine()
    }
  }
  return _instance
}

/**
 * Type guard — returns true when the client is a WorkerBridge (has async methods).
 */
export function isWorkerBridge(client: ChatClient): client is WorkerBridge {
  return 'getLastSequenceAsync' in client
}

export { ChatEngine } from './chat-engine'
export { WorkerBridge } from './worker-bridge'
export { ConnectionQualityMonitor } from './connection-quality'
export type {
  ChatEngineEvents,
  ConnectionQuality,
  ConnectionState,
  InboundMessage,
  InboundNewMessage,
  InboundReplayMessage,
  MessageDeliveryStatus,
  OutboundMessage,
  QueuedMessage,
} from './types'
