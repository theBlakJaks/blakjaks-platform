'use client'

/**
 * useChat — React hook wrapping ChatEngine.
 *
 * Handles:
 *  - Optimistic message insertion (sending → sent/failed)
 *  - Replay: dedup by id, prepend or replace based on full_resync
 *  - Message deletion (filter from state)
 *  - Reactions (update reaction map)
 *  - Channel switching (clear messages, REST load initial, join via WS)
 *  - Infinite scroll (loadMore via REST)
 *  - Presence tracking
 */

import { useCallback, useEffect, useRef, useState } from 'react'
import { getChatClient, isWorkerBridge } from '@/lib/chat'
import type {
  ConnectionQuality,
  ConnectionState,
  InboundNewMessage,
  InboundReplayMessage,
  QueuedMessage,
} from '@/lib/chat/types'
import type { Message, Tier } from '@/lib/types'
import { api } from '@/lib/api'

// Detect Giphy URLs in message content to render as GIF
const GIPHY_URL_RE = /^https:\/\/media\d*\.giphy\.com\/.+/i

// Maps a server wire message (snake_case) to frontend Message (camelCase)
function wireToMessage(
  msg: InboundNewMessage | InboundReplayMessage,
  status?: 'sending' | 'sent' | 'failed',
): Message {
  const gifUrl = GIPHY_URL_RE.test(msg.content.trim()) ? msg.content.trim() : undefined
  return {
    id: msg.id,
    channelId: msg.channel_id,
    userId: msg.user_id,
    username: msg.username,
    userTier: 'standard' as Tier,
    content: msg.content,
    timestamp: msg.timestamp,
    reactions: {},
    avatarUrl: msg.avatar_url ?? undefined,
    isSystem: msg.is_system,
    replyToId: msg.reply_to_id ?? undefined,
    replyToContent: msg.reply_to_content ?? undefined,
    replyTo: msg.reply_to_username ?? undefined,
    isPinned: false,
    sequence: msg.sequence,
    status: status ?? 'sent',
    idempotencyKey: msg.idempotency_key ?? undefined,
    gifUrl,
  }
}

export interface UseChatReturn {
  messages: Message[]
  connState: ConnectionState
  quality: ConnectionQuality
  catchingUp: boolean
  hasMore: boolean
  loadingMore: boolean
  presence: Map<string, Set<string>> // channelId → set of user_ids
  sendMessage: (content: string, replyToId?: string) => QueuedMessage | null
  loadMore: () => Promise<void>
  addReaction: (messageId: string, emoji: string) => void
  removeReaction: (messageId: string, emoji: string) => void
  sendTyping: () => void
  deleteMessage: (messageId: string) => void
  retryMessage: (idempotencyKey: string) => void
}

export function useChat(channelId: string | null): UseChatReturn {
  const [messages, setMessages] = useState<Message[]>([])
  const [connState, setConnState] = useState<ConnectionState>('disconnected')
  const [quality, setQuality] = useState<ConnectionQuality>('good')
  const [catchingUp, setCatchingUp] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [presence, setPresence] = useState<Map<string, Set<string>>>(new Map())

  const channelRef = useRef(channelId)
  const prevChannelRef = useRef<string | null>(null)

  // Keep channelRef in sync
  channelRef.current = channelId

  // ── Engine lifecycle ──
  useEffect(() => {
    const engine = getChatClient()

    const unsubs: (() => void)[] = []

    unsubs.push(engine.on('stateChange', (state) => setConnState(state)))
    unsubs.push(engine.on('qualityChange', (q) => setQuality(q)))
    unsubs.push(engine.on('catchingUp', (c) => setCatchingUp(c)))

    // New message from server (not our own optimistic)
    unsubs.push(
      engine.on('message', (msg) => {
        if (msg.channel_id !== channelRef.current) return
        const frontendMsg = wireToMessage(msg)
        setMessages((prev) => {
          // Dedup by id
          if (prev.some((m) => m.id === frontendMsg.id)) return prev
          return [...prev, frontendMsg]
        })
      }),
    )

    // Our optimistic message was confirmed by server
    unsubs.push(
      engine.on('messageConfirmed', (idempotencyKey, serverMsg) => {
        if (serverMsg.channel_id !== channelRef.current) return
        const confirmed = wireToMessage(serverMsg, 'sent')
        setMessages((prev) =>
          prev.map((m) =>
            m.idempotencyKey === idempotencyKey ? { ...confirmed } : m,
          ),
        )
      }),
    )

    // Our optimistic message failed
    unsubs.push(
      engine.on('messageFailed', (idempotencyKey) => {
        setMessages((prev) =>
          prev.map((m) =>
            m.idempotencyKey === idempotencyKey ? { ...m, status: 'failed' } : m,
          ),
        )
      }),
    )

    // Message deleted
    unsubs.push(
      engine.on('messageDeleted', (msg) => {
        if (msg.channel_id !== channelRef.current) return
        setMessages((prev) => {
          const filtered = prev.filter((m) => m.id !== msg.message_id)
          // If deleted message was a reply target, update reply preview
          return filtered.map((m) =>
            m.replyToId === msg.message_id
              ? { ...m, replyToContent: 'Original message deleted', replyTo: undefined }
              : m,
          )
        })
      }),
    )

    // Reaction update
    unsubs.push(
      engine.on('reactionUpdate', (msg) => {
        if (msg.channel_id !== channelRef.current) return
        setMessages((prev) =>
          prev.map((m) => {
            if (m.id !== msg.message_id) return m
            const reactions = { ...m.reactions }
            const users = reactions[msg.emoji] ? [...reactions[msg.emoji]] : []
            if (msg.action === 'add') {
              if (!users.includes(msg.user_id)) users.push(msg.user_id)
            } else {
              const idx = users.indexOf(msg.user_id)
              if (idx !== -1) users.splice(idx, 1)
            }
            if (users.length === 0) {
              delete reactions[msg.emoji]
            } else {
              reactions[msg.emoji] = users
            }
            return { ...m, reactions }
          }),
        )
      }),
    )

    // Replay end — REST fallback to verify no gaps after replay completes
    unsubs.push(
      engine.on('replayEnd', (msg) => {
        if (msg.channel_id !== channelRef.current) return
        const channelId = msg.channel_id

        // Get last sequence — async when using WorkerBridge, sync when inline
        const seqPromise = isWorkerBridge(engine)
          ? engine.getLastSequenceAsync(channelId)
          : Promise.resolve(engine.getLastSequence(channelId))

        seqPromise.then((lastSeq) => {
          if (lastSeq <= 0) return
          return api.social.getMessagesSinceSequence(channelId, lastSeq).then(({ messages: restMsgs }) => {
            if (restMsgs.length === 0) return
            setMessages((prev) => {
              const existingIds = new Set(prev.map((m) => m.id))
              const missing = restMsgs.filter((m) => !existingIds.has(m.id))
              if (missing.length === 0) return prev
              const merged = [...prev, ...missing]
              merged.sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0))
              return merged
            })
          })
        }).catch(() => {
          // Silent fail — no user-facing error
        })
      }),
    )

    // Replay message — insert individual replay messages
    unsubs.push(
      engine.on('replayMessage', (msg) => {
        if (msg.channel_id !== channelRef.current) return
        const frontendMsg = wireToMessage(msg)
        setMessages((prev) => {
          // Check if an optimistic message matches by idempotency key — server wins
          const optimisticIdx = msg.idempotency_key
            ? prev.findIndex((m) => m.idempotencyKey === msg.idempotency_key)
            : -1
          if (optimisticIdx !== -1) {
            const updated = [...prev]
            updated[optimisticIdx] = frontendMsg
            updated.sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0))
            return updated
          }
          // Dedup by id — if server message already exists, replace with latest server data
          const existingIdx = prev.findIndex((m) => m.id === frontendMsg.id)
          if (existingIdx !== -1) {
            const updated = [...prev]
            updated[existingIdx] = frontendMsg
            return updated
          }
          // New message — insert in sequence order
          const newMsgs = [...prev, frontendMsg]
          newMsgs.sort((a, b) => (a.sequence ?? 0) - (b.sequence ?? 0))
          return newMsgs
        })
      }),
    )

    // Replay start — if full_resync, clear messages for this channel
    unsubs.push(
      engine.on('replayStart', (msg) => {
        if (msg.channel_id !== channelRef.current) return
        if (msg.full_resync) {
          setMessages([])
        }
      }),
    )

    // Presence
    unsubs.push(
      engine.on('presenceUpdate', (msg) => {
        setPresence((prev) => {
          const next = new Map(prev)
          const channelPresence = new Set(next.get(msg.channel_id) ?? [])
          if (msg.status === 'online') {
            channelPresence.add(msg.user_id)
          } else {
            channelPresence.delete(msg.user_id)
          }
          next.set(msg.channel_id, channelPresence)
          return next
        })
      }),
    )

    return () => {
      unsubs.forEach((fn) => fn())
    }
  }, [])

  // ── Channel switching ──
  useEffect(() => {
    if (!channelId) return

    const engine = getChatClient()

    // Leave previous channel
    if (prevChannelRef.current && prevChannelRef.current !== channelId) {
      engine.leaveChannel(prevChannelRef.current)
    }
    prevChannelRef.current = channelId

    // Reset state for new channel
    setMessages([])
    setHasMore(true)
    setCatchingUp(false)

    // Load initial messages via REST
    let cancelled = false
    ;(async () => {
      try {
        const { messages: restMsgs } = await api.social.getMessages(channelId)
        if (cancelled) return
        setMessages(restMsgs)
        setHasMore(restMsgs.length >= 50)
      } catch {
        if (cancelled) return
        setMessages([])
        setHasMore(false)
      }

      // Resume channel via WS — the engine handles last_sequence=0 as a fresh join.
      // Using resumeChannel always is safe and works correctly with both inline
      // ChatEngine (reads sequence from local Map) and WorkerBridge (reads from
      // the worker's engine instance).
      engine.resumeChannel(channelId)
    })()

    return () => {
      cancelled = true
    }
  }, [channelId])

  // ── Send message ──
  const sendMessage = useCallback(
    (content: string, replyToId?: string): QueuedMessage | null => {
      if (!channelId) return null
      const engine = getChatClient()
      const queued = engine.sendMessage(channelId, content, replyToId)

      // Insert optimistic message into local state
      const gifUrl = GIPHY_URL_RE.test(content.trim()) ? content.trim() : undefined
      const optimistic: Message = {
        id: `optimistic-${queued.idempotencyKey}`,
        channelId,
        userId: engine.getUserId() ?? '',
        username: '', // Will be replaced on server confirmation
        userTier: 'standard' as Tier,
        content,
        timestamp: new Date().toISOString(),
        reactions: {},
        replyToId,
        status: 'sending',
        idempotencyKey: queued.idempotencyKey,
        gifUrl,
      }
      setMessages((prev) => [...prev, optimistic])

      return queued
    },
    [channelId],
  )

  // ── Load more (infinite scroll) ──
  const loadMore = useCallback(async () => {
    if (!channelId || loadingMore || !hasMore) return
    setLoadingMore(true)
    try {
      const oldest = messages[0]
      if (!oldest) {
        setHasMore(false)
        return
      }
      const { messages: older } = await api.social.getMessages(channelId, oldest.id)
      if (older.length === 0) {
        setHasMore(false)
      } else {
        setMessages((prev) => {
          // Dedup
          const existingIds = new Set(prev.map((m) => m.id))
          const newMsgs = older.filter((m) => !existingIds.has(m.id))
          return [...newMsgs, ...prev]
        })
        setHasMore(older.length >= 50)
      }
    } catch {
      // Silent fail — don't block UI
    } finally {
      setLoadingMore(false)
    }
  }, [channelId, loadingMore, hasMore, messages])

  // ── Reactions ──
  const addReaction = useCallback(
    (messageId: string, emoji: string) => {
      if (!channelId) return
      const engine = getChatClient()
      engine.addReaction(messageId, emoji, channelId)

      // Optimistic update
      setMessages((prev) =>
        prev.map((m) => {
          if (m.id !== messageId) return m
          const reactions = { ...m.reactions }
          const users = reactions[emoji] ? [...reactions[emoji]] : []
          const userId = engine.getUserId() ?? ''
          if (!users.includes(userId)) users.push(userId)
          reactions[emoji] = users
          return { ...m, reactions }
        }),
      )
    },
    [channelId],
  )

  const removeReaction = useCallback(
    (messageId: string, emoji: string) => {
      if (!channelId) return
      const engine = getChatClient()
      engine.removeReaction(messageId, emoji, channelId)

      // Optimistic update
      setMessages((prev) =>
        prev.map((m) => {
          if (m.id !== messageId) return m
          const reactions = { ...m.reactions }
          const users = reactions[emoji] ? [...reactions[emoji]] : []
          const userId = engine.getUserId() ?? ''
          const idx = users.indexOf(userId)
          if (idx !== -1) users.splice(idx, 1)
          if (users.length === 0) {
            delete reactions[emoji]
          } else {
            reactions[emoji] = users
          }
          return { ...m, reactions }
        }),
      )
    },
    [channelId],
  )

  // ── Typing ──
  const sendTyping = useCallback(() => {
    if (!channelId) return
    getChatClient().sendTyping(channelId)
  }, [channelId])

  // ── Delete message ──
  const deleteMessage = useCallback(
    (messageId: string) => {
      if (!channelId) return
      getChatClient().deleteMessage(messageId, channelId)
    },
    [channelId],
  )

  // ── Retry failed message ──
  const retryMessage = useCallback(
    (idempotencyKey: string) => {
      setMessages((prev) => {
        const msg = prev.find((m) => m.idempotencyKey === idempotencyKey)
        if (!msg || !channelId) return prev
        // Re-send via engine
        const engine = getChatClient()
        const queued = engine.sendMessage(channelId, msg.content, msg.replyToId)
        // Replace old optimistic with new one
        return prev.map((m) =>
          m.idempotencyKey === idempotencyKey
            ? { ...m, idempotencyKey: queued.idempotencyKey, status: 'sending' as const }
            : m,
        )
      })
    },
    [channelId],
  )

  return {
    messages,
    connState,
    quality,
    catchingUp,
    hasMore,
    loadingMore,
    presence,
    sendMessage,
    loadMore,
    addReaction,
    removeReaction,
    sendTyping,
    deleteMessage,
    retryMessage,
  }
}
