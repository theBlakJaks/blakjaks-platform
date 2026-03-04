'use client'

import { useState, useEffect, useRef, useCallback, Suspense } from 'react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { Lock, ChevronDown, ChevronRight, Send, Smile, Globe, Pin, Radio, Reply, X, ChevronUp, Loader2, Trash2 } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'
import type { Channel, Message, Tier } from '@/lib/types'
import Avatar from '@/components/ui/Avatar'
import TierBadge from '@/components/ui/TierBadge'
import GoldButton from '@/components/ui/GoldButton'
import Spinner from '@/components/ui/Spinner'
import { getTierColor, formatRelativeTime } from '@/lib/utils'
import { useUIStore } from '@/lib/store'
import GiphyPicker from '@/components/ui/GiphyPicker'
import EmoteParsedMessage from '@/components/ui/EmoteParsedMessage'
import EmotePicker from '@/components/ui/EmotePicker'
import EmoteAutocomplete from '@/components/ui/EmoteAutocomplete'
import EmoteChatInput from '@/components/ui/EmoteChatInput'
import type { EmoteChatInputHandle } from '@/components/ui/EmoteChatInput'
import { useEmoteStore } from '@/lib/emote-store'
import { prefixMatchEmotes } from '@/lib/emote-utils'
import type { CachedEmote } from '@/lib/emote-store'
import { getChatClient } from '@/lib/chat'
import { useChat } from '@/hooks/useChat'
import { MessageStatus } from '@/components/ui/MessageStatus'
import { ConnectionQualityDot, ConnectionQualityBanner } from '@/components/ui/ConnectionQualityIndicator'

const TIER_RANK: Record<Tier, number> = { standard: 0, vip: 1, high_roller: 2, whale: 3 }

const ALLOWED_REACTIONS = [
  { key: '100', emoji: '\uD83D\uDCAF' },
  { key: 'heart', emoji: '\u2764\uFE0F' },
  { key: 'laugh', emoji: '\uD83D\uDE02' },
  { key: 'check', emoji: '\u2705' },
  { key: 'x', emoji: '\u274C' },
]

const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English', es: 'Spanish', fr: 'French', pt: 'Portuguese',
  ja: 'Japanese', ko: 'Korean', zh: 'Chinese', de: 'German',
  ar: 'Arabic', hi: 'Hindi', ru: 'Russian', it: 'Italian',
}


export default function SocialPageWrapper() {
  return (
    <Suspense>
      <SocialPage />
    </Suspense>
  )
}

function SocialPage() {
  const { user } = useAuth()
  const searchParams = useSearchParams()
  const [channels, setChannels] = useState<Channel[]>([])
  const [activeChannel, setActiveChannel] = useState<string>(searchParams.get('channel') || '')
  const targetMsgId = useRef<string | null>(searchParams.get('msg'))
  const [collapsedCategories, setCollapsedCategories] = useState<Set<string>>(new Set())
  const [inputText, setInputText] = useState('')
  const [loading, setLoading] = useState(true)
  const [translations, setTranslations] = useState<Record<string, string>>({})
  const [translating, setTranslating] = useState<Set<string>>(new Set())
  const preferredLanguage = useUIStore((s) => s.preferredLanguage)
  const [cooldownActive, setCooldownActive] = useState(false)
  const [cooldownTime, setCooldownTime] = useState(0)
  const burstCountRef = useRef(0)
  const [gifPickerOpen, setGifPickerOpen] = useState(false)
  const [stagedGif, setStagedGif] = useState<{ url: string; previewUrl: string } | null>(null)
  const [emotePickerOpen, setEmotePickerOpen] = useState(false)
  const [autocompleteMatches, setAutocompleteMatches] = useState<CachedEmote[]>([])
  const [inputFocused, setInputFocused] = useState(false)
  const [replyingTo, setReplyingTo] = useState<Message | null>(null)
  const [newMsgCount, setNewMsgCount] = useState(0)
  const [firstNewMsgId, setFirstNewMsgId] = useState<string | null>(null)
  const [pinnedExpanded, setPinnedExpanded] = useState(true)
  const emoteList = useEmoteStore(s => s.emoteList)
  const emotes = useEmoteStore(s => s.emotes)
  const chatInputRef = useRef<EmoteChatInputHandle>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const chatContainerRef = useRef<HTMLDivElement>(null)
  const shouldAutoScrollRef = useRef(true)

  const userTier = user?.tier || 'standard'
  const userRank = TIER_RANK[userTier]

  // ── Chat engine + hook ──
  const {
    messages,
    connState,
    quality,
    catchingUp,
    hasMore,
    loadingMore,
    presence,
    sendMessage: chatSendMessage,
    loadMore,
    addReaction,
    removeReaction,
    sendTyping,
    deleteMessage,
    retryMessage,
  } = useChat(activeChannel || null)

  // Connect the chat engine on mount
  useEffect(() => {
    const engine = getChatClient()
    engine.connect(() => localStorage.getItem('blakjaks_token'))
    return () => {
      engine.disconnect()
    }
  }, [])

  const isNearBottom = useCallback(() => {
    const el = chatContainerRef.current
    if (!el) return true
    return el.scrollHeight - el.scrollTop - el.clientHeight < 100
  }, [])

  const scrollToBottom = useCallback(() => {
    shouldAutoScrollRef.current = true
    setNewMsgCount(0)
    setFirstNewMsgId(null)
    const el = chatContainerRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [])

  const scrollToMessage = useCallback((msgId: string) => {
    const el = document.getElementById(`msg-${msgId}`)
    if (el) el.scrollIntoView({ behavior: 'instant', block: 'center' })
    shouldAutoScrollRef.current = true
    setNewMsgCount(0)
    setFirstNewMsgId(null)
  }, [])

  // Clear the "new messages" pill when user scrolls back to bottom
  useEffect(() => {
    const el = chatContainerRef.current
    if (!el) return
    const onScroll = () => {
      if (el.scrollHeight - el.scrollTop - el.clientHeight < 80) {
        setNewMsgCount(0)
        setFirstNewMsgId(null)
      }
    }
    el.addEventListener('scroll', onScroll, { passive: true })
    return () => el.removeEventListener('scroll', onScroll)
  }, [loading, activeChannel])

  // Track new messages for pill indicator — listen for message array growth
  const prevMsgCountRef = useRef(0)
  useEffect(() => {
    if (messages.length > prevMsgCountRef.current && !shouldAutoScrollRef.current) {
      const newMsgs = messages.slice(prevMsgCountRef.current)
      setNewMsgCount(c => {
        if (c === 0 && newMsgs.length > 0) setFirstNewMsgId(newMsgs[0].id)
        return c + newMsgs.length
      })
    }
    prevMsgCountRef.current = messages.length
  }, [messages])

  // Load channels
  useEffect(() => {
    api.social.getChannels().then(({ channels: ch }) => {
      setChannels(ch)
      if (!activeChannel && ch.length > 0) {
        setActiveChannel(ch[0].id)
      }
      setLoading(false)
    })
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // Reset state on channel change
  useEffect(() => {
    if (!activeChannel) return
    setTranslations({})
    setNewMsgCount(0)
    setFirstNewMsgId(null)
    shouldAutoScrollRef.current = true
    translateQueue.current.clear()
    prevMsgCountRef.current = 0
  }, [activeChannel])

  // Auto-scroll after DOM update
  useEffect(() => {
    if (shouldAutoScrollRef.current) {
      const el = chatContainerRef.current
      if (el) el.scrollTop = el.scrollHeight
    }
  }, [messages])

  // Scroll to bottom after initial channel load
  useEffect(() => {
    if (messages.length > 0 && shouldAutoScrollRef.current) {
      requestAnimationFrame(() => {
        const el = chatContainerRef.current
        if (el) el.scrollTop = el.scrollHeight
      })
    }
  }, [activeChannel]) // eslint-disable-line react-hooks/exhaustive-deps

  // When navigating from a notification, scroll to the referenced message
  useEffect(() => {
    if (!targetMsgId.current) return
    const found = messages.find(m => m.id === targetMsgId.current)
    if (found) {
      const id = targetMsgId.current
      targetMsgId.current = null
      requestAnimationFrame(() => {
        const el = document.getElementById(`msg-${id}`)
        if (el) {
          el.scrollIntoView({ behavior: 'instant', block: 'center' })
          el.style.outline = '2px solid var(--color-gold)'
          el.style.borderRadius = '8px'
          setTimeout(() => { el.style.outline = ''; el.style.borderRadius = '' }, 2000)
        }
      })
    }
  }, [messages])

  // Cooldown timer
  useEffect(() => {
    if (!cooldownActive) return
    if (cooldownTime <= 0) {
      setCooldownActive(false)
      return
    }
    const timer = setTimeout(() => setCooldownTime(t => t - 1), 1000)
    return () => clearTimeout(timer)
  }, [cooldownActive, cooldownTime])

  // Infinite scroll — load older messages when scrolling near top
  useEffect(() => {
    const el = chatContainerRef.current
    if (!el) return
    const onScroll = () => {
      if (el.scrollTop < 100 && hasMore && !loadingMore) {
        shouldAutoScrollRef.current = false
        const prevHeight = el.scrollHeight
        loadMore().then(() => {
          requestAnimationFrame(() => {
            if (el) el.scrollTop = el.scrollHeight - prevHeight
          })
        })
      }
    }
    el.addEventListener('scroll', onScroll, { passive: true })
    return () => el.removeEventListener('scroll', onScroll)
  }, [hasMore, loadingMore, loadMore])

  const handleSend = async () => {
    const text = chatInputRef.current?.getText().trim() || inputText.trim()
    if (!text && !stagedGif) return
    if (cooldownActive) return

    shouldAutoScrollRef.current = true

    if (stagedGif) {
      // Send GIF — content is the URL, gifUrl detection happens in wireToMessage
      chatSendMessage(stagedGif.url, replyingTo?.id)
      setStagedGif(null)
    } else {
      chatSendMessage(text, replyingTo?.id)
    }
    if (replyingTo) setReplyingTo(null)

    chatInputRef.current?.clear()
    setInputText('')
    setNewMsgCount(0)
    setFirstNewMsgId(null)

    if (userTier === 'standard') {
      burstCountRef.current += 1
      if (burstCountRef.current >= 3) {
        setCooldownActive(true)
        setCooldownTime(5)
        burstCountRef.current = 0
      }
    }
  }

  const handleGifSelect = (gifUrl: string) => {
    if (!user || !activeChannel) return
    setStagedGif({ url: gifUrl, previewUrl: gifUrl })
    setGifPickerOpen(false)
  }

  const toggleReaction = (msgId: string, emoji: string) => {
    if (!user) return
    const msg = messages.find(m => m.id === msgId)
    if (!msg) return
    const users = msg.reactions[emoji] || []
    const hasReacted = users.includes(user.id)

    if (hasReacted) {
      removeReaction(msgId, emoji)
    } else {
      addReaction(msgId, emoji)
    }
  }

  // Auto-translate messages when preferred language is not English
  const translateQueue = useRef<Set<string>>(new Set())

  const autoTranslateMsg = useCallback(async (msg: Message) => {
    if (msg.isSystem || translations[msg.id] || translateQueue.current.has(msg.id)) return

    const msgLang = msg.originalLanguage || 'en'
    if (msgLang === preferredLanguage) return

    translateQueue.current.add(msg.id)
    setTranslating(prev => new Set(prev).add(msg.id))
    try {
      const res = await fetch('/api/translate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: msg.content, targetLang: preferredLanguage }),
      })
      const data = await res.json()
      if (data.translatedText) {
        setTranslations(prev => ({ ...prev, [msg.id]: data.translatedText }))
      }
    } catch {
      // silently fail
    } finally {
      translateQueue.current.delete(msg.id)
      setTranslating(prev => {
        const next = new Set(prev)
        next.delete(msg.id)
        return next
      })
    }
  }, [preferredLanguage, translations])

  useEffect(() => {
    if (preferredLanguage === 'en') return
    messages.forEach(msg => {
      const msgLang = msg.originalLanguage || 'en'
      if (msgLang !== preferredLanguage && !translations[msg.id] && !translateQueue.current.has(msg.id)) {
        autoTranslateMsg(msg)
      }
    })
  }, [messages, preferredLanguage, autoTranslateMsg, translations])

  // Clear translations when language changes back to English
  useEffect(() => {
    if (preferredLanguage === 'en') {
      setTranslations({})
    }
  }, [preferredLanguage])

  const toggleCategory = (category: string) => {
    setCollapsedCategories(prev => {
      const next = new Set(prev)
      if (next.has(category)) next.delete(category)
      else next.add(category)
      return next
    })
  }

  const toggleTranslate = async (msgId: string, content: string) => {
    if (translations[msgId]) {
      setTranslations(prev => {
        const next = { ...prev }
        delete next[msgId]
        return next
      })
      return
    }

    setTranslating(prev => new Set(prev).add(msgId))
    try {
      const res = await fetch('/api/translate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: content, targetLang: preferredLanguage }),
      })
      const data = await res.json()
      if (data.translatedText) {
        setTranslations(prev => ({ ...prev, [msgId]: data.translatedText }))
      }
    } catch {
      // silently fail
    } finally {
      setTranslating(prev => {
        const next = new Set(prev)
        next.delete(msgId)
        return next
      })
    }
  }

  const channelsByCategory = channels.reduce<Record<string, Channel[]>>((acc, ch) => {
    ;(acc[ch.category] ??= []).push(ch)
    return acc
  }, {})

  const currentChannel = channels.find(c => c.id === activeChannel)
  const charCount = inputText.length
  // Backend sends is_admin (snake_case), auth context does raw cast
  const isAdmin = (user as unknown as Record<string, unknown>)?.is_admin === true || user?.isAdmin === true
  const channelPresence = activeChannel ? presence.get(activeChannel) : undefined
  const disableGifEmote = quality === 'poor'

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner />
      </div>
    )
  }

  return (
    <div className="flex h-full overflow-hidden">
      {/* Left Sidebar - Channel List */}
      <aside className="w-60 shrink-0 border-r border-white/5 bg-[#111125] flex flex-col h-full">
        {/* Sidebar Header */}
        <div className="shrink-0 px-4 py-4 border-b border-white/5">
          <h2 className="text-lg font-bold text-white">Social Hub</h2>
          <p className="text-xs text-gray-500 mt-0.5">Community Channels</p>
        </div>

        {/* Live Stream Button */}
        <div className="shrink-0 px-3 py-2">
          <Link
            href="/social/live"
            className="flex w-full items-center gap-2 rounded-lg bg-red-500/10 px-3 py-2 text-xs font-medium text-red-400 hover:bg-red-500/20 transition-colors"
          >
            <Radio size={14} className="animate-pulse" /> Live Stream
          </Link>
        </div>

        {/* Channel List — scrollable */}
        <nav className="flex-1 overflow-y-auto px-2 py-1 space-y-1">
          {Object.entries(channelsByCategory).map(([category, chs]) => {
            const isCollapsed = collapsedCategories.has(category)
            return (
              <div key={category}>
                <button
                  onClick={() => toggleCategory(category)}
                  className="flex w-full items-center gap-1 px-2 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-gray-500 hover:text-gray-300 transition-colors"
                >
                  {isCollapsed ? <ChevronRight size={10} /> : <ChevronDown size={10} />}
                  {category}
                </button>

                {!isCollapsed && chs.map(ch => {
                  const isLocked = TIER_RANK[ch.tierRequired] > userRank
                  const isActive = ch.id === activeChannel
                  const hasUnread = ch.unreadCount > 0 && !isLocked

                  return (
                    <button
                      key={ch.id}
                      onClick={() => !isLocked && setActiveChannel(ch.id)}
                      disabled={isLocked}
                      className={`flex w-full items-center gap-2 px-2 py-1.5 rounded-md text-sm transition-colors ${
                        isActive
                          ? 'bg-white/10 text-white font-medium border-l-[3px] border-[var(--color-gold)] pl-[5px]'
                          : isLocked
                            ? 'text-gray-600 cursor-not-allowed'
                            : hasUnread
                              ? 'text-white font-medium hover:bg-white/5'
                              : 'text-gray-400 hover:bg-white/5 hover:text-gray-200'
                      }`}
                    >
                      {isLocked ? <Lock size={14} className="shrink-0 text-gray-600" /> : <span className="shrink-0 text-gray-500">#</span>}
                      <span className="truncate flex-1 text-left">{ch.name}</span>
                      {hasUnread && (
                        <span className="ml-auto shrink-0 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-[var(--color-gold)] px-1.5 text-[10px] font-bold text-black">
                          {ch.unreadCount}
                        </span>
                      )}
                    </button>
                  )
                })}
              </div>
            )
          })}
        </nav>
      </aside>

      {/* Main Chat Area */}
      <main className="flex flex-1 flex-col min-w-0 bg-[#0f0f23]">
        {/* Channel Header */}
        <header className="h-12 shrink-0 border-b border-white/5 px-4 flex items-center gap-3">
          <span className="text-gray-500 text-lg font-bold">#</span>
          <h1 className="text-white font-semibold">{currentChannel?.name || 'General Chat'}</h1>
          {currentChannel?.viewOnly && (
            <span className="rounded-full bg-amber-500/20 px-2 py-0.5 text-[10px] font-semibold text-amber-400">View Only</span>
          )}
          <span className="flex items-center gap-1.5">
            {connState === 'connected' ? (
              <>
                <ConnectionQualityDot quality={quality} />
                <span className="text-xs text-green-400">Connected</span>
              </>
            ) : connState === 'connecting' || connState === 'reconnecting' ? (
              <>
                <span className="h-2 w-2 rounded-full bg-yellow-500 animate-pulse" />
                <span className="text-xs text-yellow-400">{connState === 'reconnecting' ? 'Reconnecting...' : 'Connecting...'}</span>
              </>
            ) : connState === 'session_expired' ? (
              <>
                <span className="h-2 w-2 rounded-full bg-red-500" />
                <span className="text-xs text-red-400">Session Expired</span>
              </>
            ) : (
              <>
                <span className="h-2 w-2 rounded-full bg-red-500" />
                <span className="text-xs text-red-400">Disconnected</span>
              </>
            )}
          </span>
          <span className="text-gray-500 text-sm ml-1 hidden sm:inline">{currentChannel?.description || ''}</span>
        </header>

        {/* Session expired banner — terminal state, user must re-login */}
        {connState === 'session_expired' && (
          <div className="shrink-0 flex items-center justify-between px-4 py-2.5 bg-red-900/30 border-b border-red-800/40">
            <span className="text-sm text-red-300">Your session has expired. Please log in again to use chat.</span>
            <button
              onClick={() => {
                localStorage.removeItem('blakjaks_token')
                localStorage.removeItem('blakjaks_refresh_token')
                window.location.href = '/login'
              }}
              className="shrink-0 ml-4 rounded-lg bg-red-500 px-3 py-1 text-xs font-semibold text-white hover:bg-red-400 transition-colors"
            >
              Log In
            </button>
          </div>
        )}

        {/* Connection quality banner */}
        <ConnectionQualityBanner quality={quality} />

        {/* Catching up banner */}
        {catchingUp && (
          <div className="shrink-0 flex items-center gap-2 px-4 py-1.5 text-xs text-blue-300 bg-blue-900/20 border-b border-blue-800/30">
            <Loader2 size={12} className="animate-spin" />
            Catching up on missed messages...
          </div>
        )}

        {/* Pinned Messages — collapsible section */}
        {(() => {
          const pinned = messages.filter(m => m.isPinned)
          if (pinned.length === 0) return null
          return (
            <div className="shrink-0 border-b border-white/5 bg-[#111125]">
              <button
                onClick={() => setPinnedExpanded(!pinnedExpanded)}
                className="flex w-full items-center gap-2 px-4 py-2 text-xs font-medium text-[var(--color-gold)] hover:bg-white/5 transition-colors"
              >
                <Pin size={12} />
                {pinned.length} Pinned Message{pinned.length > 1 ? 's' : ''}
                {pinnedExpanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
              </button>
              {pinnedExpanded && pinned.map(p => (
                <div key={p.id} className="flex items-start gap-3 px-4 py-2 border-t border-white/5">
                  <Pin size={12} className="mt-0.5 shrink-0 text-[var(--color-gold)]/50" />
                  <div className="min-w-0 flex-1">
                    <span className="text-xs font-medium text-[var(--color-gold)]">{p.username}</span>
                    <p className="text-sm text-[var(--color-text)] line-clamp-2">{p.content}</p>
                  </div>
                  <button
                    onClick={() => scrollToMessage(p.id)}
                    className="shrink-0 text-[10px] text-[var(--color-text-dim)] hover:text-white transition-colors"
                  >
                    Jump
                  </button>
                </div>
              ))}
            </div>
          )
        })()}

        {/* Messages Feed */}
        <div ref={chatContainerRef} className="flex-1 overflow-y-auto px-4 py-2 space-y-1 relative">
          {/* Loading older messages indicator */}
          {loadingMore && (
            <div className="flex items-center justify-center py-4">
              <Loader2 size={20} className="animate-spin text-[var(--color-text-dim)]" />
              <span className="ml-2 text-xs text-[var(--color-text-dim)]">Loading older messages...</span>
            </div>
          )}
          {messages.map((msg, i) => {
            const msgDate = new Date(msg.timestamp).toDateString()
            const prevDate = i > 0 ? new Date(messages[i - 1].timestamp).toDateString() : null
            const showDateSep = i === 0 || msgDate !== prevDate
            const dateSeparator = showDateSep ? (
              <div className="flex items-center gap-3 py-2 my-2">
                <div className="flex-1 h-px bg-white/5" />
                <span className="text-[11px] font-medium text-gray-500">
                  {new Date(msg.timestamp).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                </span>
                <div className="flex-1 h-px bg-white/5" />
              </div>
            ) : null
            if (msg.isSystem) {
              return (
                <div key={msg.id}>
                  {dateSeparator}
                  <div id={`msg-${msg.id}`} className="flex justify-center py-2">
                    <span className="rounded-full bg-white/5 px-4 py-1 text-xs text-gray-500">
                      {msg.content}
                    </span>
                  </div>
                </div>
              )
            }

            const showHeader = showDateSep || i === 0 || messages[i - 1]?.userId !== msg.userId || messages[i - 1]?.isSystem
            const reactionEntries = Object.entries(msg.reactions)
            const isTranslated = !!translations[msg.id]
            const isTranslating = translating.has(msg.id)
            const isOwnMessage = msg.userId === user?.id
            const isOnline = channelPresence?.has(msg.userId)

            return (
              <div key={msg.id}>
                {dateSeparator}
              <div
                id={`msg-${msg.id}`}
                className={`group relative flex gap-3 rounded-lg px-2 py-0.5 hover:bg-white/[0.02] ${showHeader ? 'mt-3' : ''} ${msg.status === 'failed' ? 'opacity-60' : ''}`}
              >
                {/* Hover action bar */}
                <div className="absolute right-2 top-0 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity z-10 flex items-center gap-0.5 rounded-md border border-[var(--color-border)] bg-[var(--color-bg-card)] px-1 py-0.5 shadow-lg">
                  {ALLOWED_REACTIONS.map(r => (
                    <button
                      key={r.key}
                      onClick={() => toggleReaction(msg.id, r.emoji)}
                      className="hover:bg-[var(--color-bg-hover)] rounded px-1 py-0.5 text-sm transition-colors hover:scale-110"
                      title={r.key}
                    >
                      {r.emoji}
                    </button>
                  ))}
                  <div className="w-px h-4 bg-[var(--color-border)] mx-0.5" />
                  <button
                    onClick={() => setReplyingTo(msg)}
                    className="flex items-center gap-1 hover:bg-[var(--color-bg-hover)] rounded px-1.5 py-0.5 text-xs text-[var(--color-text-dim)] hover:text-white transition-colors"
                  >
                    <Reply size={12} />
                    Reply
                  </button>
                  {isAdmin && (
                    <>
                      <div className="w-px h-4 bg-[var(--color-border)] mx-0.5" />
                      <button
                        onClick={() => deleteMessage(msg.id)}
                        className="flex items-center gap-1 hover:bg-red-500/20 rounded px-1.5 py-0.5 text-xs text-red-400 hover:text-red-300 transition-colors"
                        title="Delete message"
                      >
                        <Trash2 size={12} />
                      </button>
                    </>
                  )}
                </div>

                {showHeader ? (
                  <div className="relative">
                    <Avatar name={msg.username} tier={msg.userTier} size="sm" avatarUrl={isOwnMessage ? user?.avatarUrl : msg.avatarUrl} />
                    {isOnline && (
                      <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-green-500 border-2 border-[#0f0f23]" />
                    )}
                  </div>
                ) : (
                  <div className="w-8 shrink-0" />
                )}

                <div className="min-w-0 flex-1">
                  {showHeader && (
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className="font-medium text-sm" style={{ color: getTierColor(msg.userTier) }}>
                        {msg.username}
                      </span>
                      <TierBadge tier={msg.userTier} size="sm" />
                      <span className="text-xs text-[var(--color-text-dim)]">
                        {formatRelativeTime(msg.timestamp)}
                      </span>
                      {isOwnMessage && msg.status && (
                        <MessageStatus
                          status={msg.status}
                          onRetry={msg.status === 'failed' && msg.idempotencyKey ? () => retryMessage(msg.idempotencyKey!) : undefined}
                        />
                      )}
                      {reactionEntries.length > 0 && (
                        <div className="flex gap-1 ml-1">
                          {reactionEntries.map(([emoji, users]) => {
                            const isMine = user ? users.includes(user.id) : false
                            return (
                              <button
                                key={emoji}
                                onClick={() => toggleReaction(msg.id, emoji)}
                                className={`inline-flex items-center gap-0.5 rounded-full border px-1.5 py-0 text-[11px] transition-colors cursor-pointer hover:border-[var(--color-gold)]/50 ${
                                  isMine
                                    ? 'border-[var(--color-gold)] bg-[var(--color-gold)]/10'
                                    : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'
                                }`}
                              >
                                {emoji} <span className={isMine ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)]'}>{users.length}</span>
                              </button>
                            )
                          })}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Show reactions inline for non-header messages */}
                  {!showHeader && reactionEntries.length > 0 && (
                    <div className="flex gap-1 mb-0.5">
                      {reactionEntries.map(([emoji, users]) => {
                        const isMine = user ? users.includes(user.id) : false
                        return (
                          <button
                            key={emoji}
                            onClick={() => toggleReaction(msg.id, emoji)}
                            className={`inline-flex items-center gap-0.5 rounded-full border px-1.5 py-0 text-[11px] transition-colors cursor-pointer hover:border-[var(--color-gold)]/50 ${
                              isMine
                                ? 'border-[var(--color-gold)] bg-[var(--color-gold)]/10'
                                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'
                            }`}
                          >
                            {emoji} <span className={isMine ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)]'}>{users.length}</span>
                          </button>
                        )
                      })}
                    </div>
                  )}

                  {msg.replyTo && (
                    <div className="text-xs text-[var(--color-text-dim)] mb-1 rounded-md bg-[var(--color-bg-surface)] border-l-2 border-[var(--color-gold)]/50 px-2 py-1">
                      <div className="flex items-center gap-1 mb-0.5">
                        <Reply size={10} className="text-[var(--color-gold)]" />
                        <span className="text-[var(--color-gold)] font-medium">Replying to {msg.replyTo}:</span>
                      </div>
                      {msg.replyToContent && (
                        <p className={`text-[var(--color-text-dim)] text-[11px] line-clamp-2 ${msg.replyToContent === 'Original message deleted' ? 'italic' : ''}`}>{msg.replyToContent}</p>
                      )}
                    </div>
                  )}

                  {msg.gifUrl ? (
                    <img
                      src={msg.gifUrl}
                      alt="GIF"
                      className="mt-1 rounded-lg max-w-[240px]"
                      loading="lazy"
                    />
                  ) : (
                    <EmoteParsedMessage
                      content={isTranslated ? translations[msg.id] : msg.content}
                      className="text-sm text-[var(--color-text)] break-words"
                      emoteSize="md"
                    />
                  )}

                  {isTranslated && (
                    <div className="mt-1.5 flex items-center gap-1.5 rounded-md bg-[var(--color-gold)]/5 border border-[var(--color-gold)]/20 px-2 py-1 w-fit">
                      <Globe size={11} className="text-[var(--color-gold)]" />
                      <span className="text-[11px] text-[var(--color-gold)]">
                        Translated from {LANGUAGE_NAMES[msg.originalLanguage || 'en'] || msg.originalLanguage || 'English'}
                      </span>
                      <button
                        onClick={() => toggleTranslate(msg.id, msg.content)}
                        className="ml-1 text-[11px] text-[var(--color-text-dim)] hover:text-white underline transition-colors"
                      >
                        Show Original
                      </button>
                    </div>
                  )}

                  {isTranslating && (
                    <p className="mt-1 flex items-center gap-1 text-xs text-[var(--color-text-dim)]">
                      <Globe size={12} className="animate-spin" /> Translating...
                    </p>
                  )}
                </div>
              </div>
              </div>
            )
          })}
          <div ref={messagesEndRef} />
        </div>

        {/* New Messages indicator */}
        {newMsgCount > 0 && (
          <div className="shrink-0 flex justify-center -mt-2 mb-1 relative z-20">
            <button
              onClick={() => firstNewMsgId ? scrollToMessage(firstNewMsgId) : scrollToBottom()}
              className="flex items-center gap-1.5 rounded-full bg-[var(--color-gold)] px-4 py-1.5 text-xs font-semibold text-black shadow-lg hover:bg-[var(--color-gold)]/90 transition-colors"
            >
              <ChevronUp size={14} />
              {newMsgCount === 1 ? 'New Message' : `${newMsgCount} New Messages`}
            </button>
          </div>
        )}

        {/* Message Composer */}
        {currentChannel?.viewOnly ? (
          <div className="shrink-0 border-t border-white/5 px-4 py-3 text-center text-sm text-[var(--color-text-dim)]">
            This channel is view only
          </div>
        ) : <div className="shrink-0 border-t border-white/5 px-4 py-3">
          {replyingTo && (
            <div className="mb-2 flex items-start gap-2 text-xs rounded-md bg-[var(--color-bg-surface)] border-l-2 border-[var(--color-gold)] px-3 py-2">
              <Reply size={12} className="text-[var(--color-gold)] mt-0.5 shrink-0" />
              <div className="min-w-0 flex-1">
                <span className="text-[var(--color-text-dim)]">Replying to </span>
                <span className="font-medium text-[var(--color-gold)]">{replyingTo.username}</span>
                {replyingTo.content && (
                  <p className="text-[11px] text-[var(--color-text-dim)] mt-0.5 line-clamp-1 italic">{replyingTo.content}</p>
                )}
              </div>
              <button onClick={() => setReplyingTo(null)} className="shrink-0 text-[var(--color-text-dim)] hover:text-white transition-colors">
                <X size={14} />
              </button>
            </div>
          )}
          {cooldownActive && (
            <div className="mb-2 text-xs text-[var(--color-text-dim)]">
              Rate limited. You can send another message in {cooldownTime}s
            </div>
          )}
          {stagedGif && (
            <div className="mb-2 flex items-start gap-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-2">
              <img src={stagedGif.previewUrl} alt="GIF preview" className="rounded-md max-w-[120px] max-h-[80px] object-cover" />
              <button onClick={() => setStagedGif(null)} className="shrink-0 text-[var(--color-text-dim)] hover:text-white transition-colors mt-0.5">
                <X size={14} />
              </button>
            </div>
          )}
          <div className="flex items-end gap-2">
            <div className="flex-1 relative">
              <EmoteChatInput
                ref={chatInputRef}
                placeholder={`Message #${currentChannel?.name || 'general'}...`}
                disabled={cooldownActive}
                maxLength={500}
                className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2.5 pr-24 text-sm text-[var(--color-text)] focus:border-[var(--color-gold)] focus:outline-none disabled:opacity-50"
                onChange={(text, isDeleting) => {
                  setInputText(text)
                  if (isDeleting) {
                    setAutocompleteMatches([])
                  } else {
                    const words = text.split(/\s/)
                    const lastWord = words[words.length - 1]
                    setAutocompleteMatches(lastWord.length >= 2 ? prefixMatchEmotes(lastWord, emoteList) : [])
                  }
                }}
                onFocus={() => setInputFocused(true)}
                onBlur={() => setInputFocused(false)}
                onSubmit={() => { handleSend(); setAutocompleteMatches([]); setEmotePickerOpen(false) }}
                onKeyDown={(e) => {
                  if (autocompleteMatches.length > 0 && (e.key === 'Tab' || e.key === 'Escape')) {
                    e.preventDefault()
                    if (e.key === 'Tab') {
                      const emote = autocompleteMatches[0]
                      chatInputRef.current?.insertEmote(emote.name, emote.id)
                    }
                    setAutocompleteMatches([])
                  }
                }}
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1.5">
                <button
                  onClick={() => { setEmotePickerOpen(!emotePickerOpen); setGifPickerOpen(false) }}
                  className={`p-1 transition-colors ${emotePickerOpen ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)]'} ${disableGifEmote ? 'opacity-50 cursor-not-allowed' : ''}`}
                  title="Emotes"
                  disabled={disableGifEmote}
                >
                  <Smile size={18} />
                </button>
                <button
                  onClick={() => { setGifPickerOpen(!gifPickerOpen); setEmotePickerOpen(false) }}
                  className={`p-1 transition-colors ${gifPickerOpen ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)]'} ${disableGifEmote ? 'opacity-50 cursor-not-allowed' : ''}`}
                  title="GIF"
                  disabled={disableGifEmote}
                >
                  <span className="text-xs font-bold">GIF</span>
                </button>
              </div>
              {autocompleteMatches.length > 0 && (
                <EmoteAutocomplete
                  matches={autocompleteMatches}
                  onSelect={(name) => {
                    const emote = emotes.get(name)
                    if (emote) chatInputRef.current?.insertEmote(emote.name, emote.id)
                    setAutocompleteMatches([])
                  }}
                  onDismiss={() => setAutocompleteMatches([])}
                />
              )}
              {emotePickerOpen && !disableGifEmote && (
                <EmotePicker
                  onSelect={(emote) => {
                    chatInputRef.current?.insertEmote(emote.name, emote.id)
                  }}
                  onClose={() => setEmotePickerOpen(false)}
                />
              )}
              {gifPickerOpen && !disableGifEmote && (
                <GiphyPicker onSelect={handleGifSelect} onClose={() => setGifPickerOpen(false)} />
              )}
            </div>
            <GoldButton onClick={() => { handleSend(); setEmotePickerOpen(false) }} disabled={(!inputText.trim() && !stagedGif) || cooldownActive} size="md">
              <Send size={16} />
            </GoldButton>
          </div>
          {inputFocused && (
            <div className={`mt-1 text-xs text-right ${charCount >= 500 ? 'text-red-400' : 'text-[var(--color-text-dim)]'}`}>
              {charCount}/500
            </div>
          )}
        </div>}
      </main>
    </div>
  )
}
