'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { Radio, Eye, Send, MessageSquare, X, PanelRightClose, PanelRightOpen, Reply, ChevronUp } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'
import { useUIStore } from '@/lib/store'
import type { Message, Tier } from '@/lib/types'
import Avatar from '@/components/ui/Avatar'
import GoldButton from '@/components/ui/GoldButton'
import Logo from '@/components/ui/Logo'
import Spinner from '@/components/ui/Spinner'
import { getTierColor, formatRelativeTime } from '@/lib/utils'
import GiphyPicker from '@/components/ui/GiphyPicker'
import EmoteParsedMessage from '@/components/ui/EmoteParsedMessage'
import EmotePicker from '@/components/ui/EmotePicker'
import EmoteAutocomplete from '@/components/ui/EmoteAutocomplete'
import EmoteChatInput from '@/components/ui/EmoteChatInput'
import type { EmoteChatInputHandle } from '@/components/ui/EmoteChatInput'
import { useEmoteStore } from '@/lib/emote-store'
import { prefixMatchEmotes } from '@/lib/emote-utils'
import type { CachedEmote } from '@/lib/emote-store'

const LIVE_CHAT_MESSAGES = [
  'Lets gooo!', 'Hype!', 'Great stream', 'When is the next giveaway?',
  'Spearmint gang', 'Love this community', 'GG', 'First time here, loving it',
  'Drop a like if you like Wintergreen', 'BlakJaks to the moon',
]

const MOCK_USERS: { id: string; username: string; tier: Tier; avatarUrl: string }[] = [
  { id: 'usr_010', username: 'cryptoQueen', tier: 'high_roller', avatarUrl: 'https://i.pravatar.cc/150?u=usr_010' },
  { id: 'usr_011', username: 'mintFanatic', tier: 'standard', avatarUrl: 'https://i.pravatar.cc/150?u=usr_011' },
  { id: 'usr_012', username: 'whaleDave', tier: 'whale', avatarUrl: 'https://i.pravatar.cc/150?u=usr_012' },
  { id: 'usr_014', username: 'vipSarah', tier: 'vip', avatarUrl: 'https://i.pravatar.cc/150?u=usr_014' },
  { id: 'usr_015', username: 'blazeRunner', tier: 'vip', avatarUrl: 'https://i.pravatar.cc/150?u=usr_015' },
]

const ALLOWED_REACTIONS = [
  { key: '100', emoji: '\uD83D\uDCAF' },
  { key: 'heart', emoji: '\u2764\uFE0F' },
  { key: 'laugh', emoji: '\uD83D\uDE02' },
  { key: 'check', emoji: '\u2705' },
  { key: 'x', emoji: '\u274C' },
]

export default function LiveStreamPage() {
  const { user } = useAuth()
  const { isLive } = useUIStore()
  const [viewerCount, setViewerCount] = useState(0)
  const [chatMessages, setChatMessages] = useState<Message[]>([])
  const [chatInput, setChatInput] = useState('')
  const [loading, setLoading] = useState(true)
  const [chatVisible, setChatVisible] = useState(true)
  const [gifPickerOpen, setGifPickerOpen] = useState(false)
  const [emotePickerOpen, setEmotePickerOpen] = useState(false)
  const [autocompleteMatches, setAutocompleteMatches] = useState<CachedEmote[]>([])
  const [inputFocused, setInputFocused] = useState(false)
  const [replyingTo, setReplyingTo] = useState<Message | null>(null)
  const [newMsgCount, setNewMsgCount] = useState(0)
  const [firstNewMsgId, setFirstNewMsgId] = useState<string | null>(null)
  const emoteList = useEmoteStore(s => s.emoteList)
  const emoteMap = useEmoteStore(s => s.emotes)
  const chatContainerRef = useRef<HTMLDivElement>(null)
  const liveChatInputRef = useRef<EmoteChatInputHandle>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const shouldAutoScrollRef = useRef(true)

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
    const el = document.getElementById(`live-msg-${msgId}`)
    if (el) el.scrollIntoView({ behavior: 'instant', block: 'center' })
    shouldAutoScrollRef.current = true
    setNewMsgCount(0)
    setFirstNewMsgId(null)
  }, [])

  // Clear the "new messages" pill when user scrolls back to bottom.
  // Re-registers when loading finishes so chatContainerRef is populated.
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
  }, [loading])

  useEffect(() => {
    api.streaming.getLive().then(() => {
      setLoading(false)
    })
  }, [])

  // Simulated live chat when "live"
  useEffect(() => {
    if (!isLive) return
    setViewerCount(1247)
    const interval = setInterval(() => {
      // Check scroll position BEFORE adding message
      shouldAutoScrollRef.current = isNearBottom()

      const randomUser = MOCK_USERS[Math.floor(Math.random() * MOCK_USERS.length)]
      const randomContent = LIVE_CHAT_MESSAGES[Math.floor(Math.random() * LIVE_CHAT_MESSAGES.length)]
      const newMsg: Message = {
        id: `live_msg_${Date.now()}`,
        channelId: 'live',
        userId: randomUser.id,
        username: randomUser.username,
        userTier: randomUser.tier,
        content: randomContent,
        timestamp: new Date().toISOString(),
        reactions: {},
        avatarUrl: randomUser.avatarUrl,
      }
      setChatMessages(prev => [...prev.slice(-50), newMsg])
      setViewerCount(v => v + Math.floor(Math.random() * 5) - 2)
      // Track new messages when scrolled up
      if (!shouldAutoScrollRef.current) {
        setNewMsgCount(c => {
          if (c === 0) setFirstNewMsgId(newMsg.id)
          return c + 1
        })
      }
    }, 3000)
    return () => clearInterval(interval)
  }, [isLive, isNearBottom])

  // Auto-scroll after DOM update — reads the flag set BEFORE the state update
  useEffect(() => {
    if (shouldAutoScrollRef.current) {
      const el = chatContainerRef.current
      if (el) el.scrollTop = el.scrollHeight
    }
  }, [chatMessages])

  const handleChatSend = async () => {
    const text = (liveChatInputRef.current?.getText().trim() || chatInput.trim())
    if (!text || !user) return
    const msg: Message = {
      id: `live_msg_${Date.now()}`,
      channelId: 'live',
      userId: user.id,
      username: user.username,
      userTier: user.tier,
      content: text,
      timestamp: new Date().toISOString(),
      reactions: {},
      avatarUrl: user.avatarUrl,
      replyTo: replyingTo?.username,
      replyToContent: replyingTo?.content,
    }
    // Always scroll to bottom when user sends their own message
    shouldAutoScrollRef.current = true
    setChatMessages(prev => [...prev, msg])
    liveChatInputRef.current?.clear()
    setChatInput('')
    setReplyingTo(null)
    setNewMsgCount(0)
    setFirstNewMsgId(null)
  }

  const handleGifSelect = (gifUrl: string) => {
    if (!user) return
    const gifMsg: Message = {
      id: `live_msg_gif_${Date.now()}`,
      channelId: 'live',
      userId: user.id,
      username: user.username,
      userTier: user.tier,
      content: '',
      gifUrl,
      timestamp: new Date().toISOString(),
      reactions: {},
      avatarUrl: user.avatarUrl,
    }
    setChatMessages(prev => [...prev, gifMsg])
    setGifPickerOpen(false)
  }

  const toggleReaction = (msgId: string, emoji: string) => {
    if (!user) return
    setChatMessages(prev => prev.map(msg => {
      if (msg.id !== msgId) return msg
      const users = msg.reactions[emoji] || []
      const hasReacted = users.includes(user.id)
      const updated = hasReacted ? users.filter(id => id !== user.id) : [...users, user.id]
      const reactions = { ...msg.reactions }
      if (updated.length === 0) { delete reactions[emoji] } else { reactions[emoji] = updated }
      return { ...msg, reactions }
    }))
  }

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center bg-black">
        <Spinner />
      </div>
    )
  }

  return (
    <div className="flex flex-col md:flex-row h-full overflow-hidden">
      {/* Video Player Area — fills all remaining space */}
      <div className="flex-1 min-h-0 bg-black flex flex-col relative">
        {isLive ? (
          <>
            {/* Live info overlay at top */}
            <div className="absolute top-0 left-0 right-0 z-10 flex items-center justify-between px-4 py-3 bg-gradient-to-b from-black/80 to-transparent">
              <div className="flex items-center gap-3">
                <span className="flex items-center gap-1.5 rounded bg-red-600 px-2 py-0.5 text-xs font-bold text-white uppercase">
                  <Radio size={12} className="animate-pulse" />
                  Live
                </span>
                <div>
                  <h3 className="text-sm font-semibold text-white drop-shadow">Community AMA with the Founders</h3>
                  <p className="text-xs text-white/60">Hosted by BlakJaks Team</p>
                </div>
              </div>
              <div className="flex items-center gap-1.5 text-sm text-white/80">
                <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse" />
                <Eye size={14} />
                <span>{viewerCount.toLocaleString()}</span>
              </div>
            </div>
            {/* Video area */}
            <div className="flex-1 flex items-center justify-center">
              <div className="text-center opacity-40">
                <Logo size="lg" />
                <p className="mt-2 text-xs text-white/50">Live stream video feed</p>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center">
            <Logo size="lg" />
            <p className="mt-4 text-lg font-medium text-[var(--color-text-muted)]">No Live Stream</p>
            <p className="mt-1 text-sm text-[var(--color-text-dim)]">Check #announcements for upcoming stream times</p>
          </div>
        )}

        {/* Chat toggle — shows when chat is hidden */}
        {!chatVisible && (
          <button
            onClick={() => setChatVisible(true)}
            className="absolute top-3 right-3 z-20 flex items-center gap-1.5 rounded-lg bg-white/10 backdrop-blur-sm px-3 py-2 text-xs font-medium text-white/80 hover:text-white hover:bg-white/20 transition-colors"
          >
            <PanelRightOpen size={16} />
            <span className="hidden sm:inline">Show Chat</span>
          </button>
        )}
      </div>

      {/* Live Chat Panel */}
      {chatVisible && (
      <div
        className="flex flex-col shrink-0 w-full md:w-[300px] lg:w-[340px] h-[50vh] md:h-full border-t md:border-t-0 md:border-l border-[var(--color-border)] bg-[#1A1A2E]"
      >
        {/* Chat header */}
        <div className="shrink-0 border-b border-[var(--color-border)] px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h3 className="text-sm font-semibold text-white">Live Chat</h3>
            {isLive && (
              <span className="flex items-center gap-1.5">
                <span className="h-2 w-2 rounded-full bg-green-500 shadow-[0_0_6px_rgba(34,197,94,0.6)]" />
                <span className="text-[10px] text-[var(--color-text-dim)]">{viewerCount.toLocaleString()} watching</span>
              </span>
            )}
          </div>
          <button
            onClick={() => setChatVisible(false)}
            className="text-[var(--color-text-dim)] hover:text-white transition-colors"
            title="Hide chat"
          >
            <PanelRightClose size={16} />
          </button>
        </div>

        {/* Chat messages */}
        <div ref={chatContainerRef} className="flex-1 overflow-y-auto px-3 py-2 space-y-2.5 min-h-0">
          {!isLive && chatMessages.length === 0 && (
            <div className="flex flex-col items-center justify-center h-full text-center px-4">
              <MessageSquare size={24} className="text-[var(--color-text-dim)] mb-2" />
              <p className="text-sm text-[var(--color-text-dim)]">Chat will be active when the stream is live</p>
            </div>
          )}
          {chatMessages.map(msg => {
            const reactionEntries = Object.entries(msg.reactions)
            return (
              <div key={msg.id} id={`live-msg-${msg.id}`} className="relative flex items-start gap-2 group">
                {/* Hover action bar */}
                <div className="absolute right-0 top-0 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity z-10 flex items-center gap-0.5 rounded-md border border-[var(--color-border)] bg-[var(--color-bg-card)] px-0.5 py-0.5 shadow-lg">
                  {ALLOWED_REACTIONS.map(r => (
                    <button
                      key={r.key}
                      onClick={() => toggleReaction(msg.id, r.emoji)}
                      className="hover:bg-[var(--color-bg-hover)] rounded px-0.5 py-0.5 text-xs transition-colors hover:scale-110"
                      title={r.key}
                    >
                      {r.emoji}
                    </button>
                  ))}
                  <div className="w-px h-3 bg-[var(--color-border)] mx-0.5" />
                  <button
                    onClick={() => setReplyingTo(msg)}
                    className="flex items-center gap-0.5 hover:bg-[var(--color-bg-hover)] rounded px-1 py-0.5 text-[10px] text-[var(--color-text-dim)] hover:text-white transition-colors"
                  >
                    <Reply size={10} />
                  </button>
                </div>

                <div className="shrink-0">
                  <Avatar name={msg.username} tier={msg.userTier} size="sm" avatarUrl={msg.userId === user?.id ? user.avatarUrl : msg.avatarUrl} />
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-1.5 flex-wrap">
                    <span className="shrink-0 text-xs font-semibold whitespace-nowrap" style={{ color: getTierColor(msg.userTier) }}>
                      {msg.username}
                    </span>
                    <span className="text-[10px] text-[var(--color-text-dim)]">{formatRelativeTime(msg.timestamp)}</span>
                    {reactionEntries.length > 0 && (
                      <div className="flex gap-0.5">
                        {reactionEntries.map(([emoji, users]) => {
                          const isMine = user ? users.includes(user.id) : false
                          return (
                            <button
                              key={emoji}
                              onClick={() => toggleReaction(msg.id, emoji)}
                              className={`inline-flex items-center gap-0.5 rounded-full border px-1.5 py-0 text-[10px] transition-colors cursor-pointer hover:border-[var(--color-gold)]/50 ${
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
                  {msg.replyTo && (
                    <div className="text-[10px] text-[var(--color-text-dim)] rounded bg-[var(--color-bg-surface)] border-l-2 border-[var(--color-gold)]/50 px-1.5 py-0.5 mt-0.5 mb-0.5">
                      <div className="flex items-center gap-1">
                        <Reply size={9} className="text-[var(--color-gold)]" />
                        <span className="text-[var(--color-gold)] font-medium">Replying to {msg.replyTo}:</span>
                      </div>
                      {msg.replyToContent && (
                        <p className="text-[var(--color-text-dim)] text-[9px] line-clamp-1 italic">{msg.replyToContent}</p>
                      )}
                    </div>
                  )}
                  {msg.gifUrl ? (
                    <img src={msg.gifUrl} alt="GIF" className="mt-0.5 rounded-md max-w-[180px]" loading="lazy" />
                  ) : (
                    <EmoteParsedMessage
                      content={msg.content}
                      className="text-[13px] leading-snug text-[var(--color-text)] break-words"
                      emoteSize="sm"
                    />
                  )}
                </div>
              </div>
            )
          })}
          <div ref={messagesEndRef} />
        </div>

        {/* New Messages indicator */}
        {newMsgCount > 0 && (
          <div className="shrink-0 flex justify-center -mt-1 mb-1 relative z-20">
            <button
              onClick={() => firstNewMsgId ? scrollToMessage(firstNewMsgId) : scrollToBottom()}
              className="flex items-center gap-1 rounded-full bg-[var(--color-gold)] px-3 py-1 text-[10px] font-semibold text-black shadow-lg hover:bg-[var(--color-gold)]/90 transition-colors"
            >
              <ChevronUp size={12} />
              {newMsgCount === 1 ? 'New Message' : `${newMsgCount} New Messages`}
            </button>
          </div>
        )}

        {/* Chat input */}
        <div className="shrink-0 border-t border-[var(--color-border)] p-3 relative">
          {replyingTo && (
            <div className="mb-2 flex items-start gap-1.5 text-[10px] rounded bg-[var(--color-bg-surface)] border-l-2 border-[var(--color-gold)] px-2 py-1.5">
              <Reply size={10} className="text-[var(--color-gold)] mt-0.5 shrink-0" />
              <div className="min-w-0 flex-1">
                <div>
                  <span className="text-[var(--color-text-dim)]">Replying to </span>
                  <span className="font-medium text-[var(--color-gold)]">{replyingTo.username}</span>
                </div>
                {replyingTo.content && (
                  <p className="text-[9px] text-[var(--color-text-dim)] mt-0.5 line-clamp-1 italic">{replyingTo.content}</p>
                )}
              </div>
              <button onClick={() => setReplyingTo(null)} className="shrink-0 text-[var(--color-text-dim)] hover:text-white transition-colors">
                <X size={12} />
              </button>
            </div>
          )}
          {autocompleteMatches.length > 0 && (
            <EmoteAutocomplete
              matches={autocompleteMatches}
              onSelect={(name) => {
                const emote = emoteMap.get(name)
                if (emote) liveChatInputRef.current?.insertEmote(name, emote.id)
                setAutocompleteMatches([])
                liveChatInputRef.current?.focus()
              }}
              onDismiss={() => setAutocompleteMatches([])}
            />
          )}
          {emotePickerOpen && (
            <EmotePicker
              onSelect={(emote) => {
                liveChatInputRef.current?.insertEmote(emote.name, emote.id)
                liveChatInputRef.current?.focus()
              }}
              onClose={() => setEmotePickerOpen(false)}
            />
          )}
          {gifPickerOpen && (
            <GiphyPicker onSelect={handleGifSelect} onClose={() => setGifPickerOpen(false)} />
          )}
          <div className="flex gap-2 items-center">
            <button
              onClick={() => { if (isLive) { setEmotePickerOpen(!emotePickerOpen); setGifPickerOpen(false) } }}
              disabled={!isLive}
              className={`shrink-0 px-1.5 py-1 rounded text-[10px] font-bold transition-colors disabled:opacity-50 ${
                emotePickerOpen ? 'text-[var(--color-gold)] bg-[var(--color-gold)]/10' : 'text-[var(--color-text-dim)] hover:text-white'
              }`}
              title="Emotes"
            >
              :)
            </button>
            <button
              onClick={() => { if (isLive) { setGifPickerOpen(!gifPickerOpen); setEmotePickerOpen(false) } }}
              disabled={!isLive}
              className={`shrink-0 px-1.5 py-1 rounded text-[10px] font-bold transition-colors disabled:opacity-50 ${
                gifPickerOpen ? 'text-[var(--color-gold)] bg-[var(--color-gold)]/10' : 'text-[var(--color-text-dim)] hover:text-white'
              }`}
              title="GIF"
            >
              GIF
            </button>
            <EmoteChatInput
              ref={liveChatInputRef}
              placeholder={isLive ? 'Say something...' : 'Chat offline'}
              disabled={!isLive}
              maxLength={500}
              className="flex-1 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 py-2 text-xs text-[var(--color-text)] placeholder-[var(--color-text-dim)] focus:border-[var(--color-gold)] focus:outline-none disabled:opacity-50"
              onChange={(text, isDeleting) => {
                setChatInput(text)
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
              onKeyDown={(e) => {
                if (autocompleteMatches.length > 0 && (e.key === 'Tab' || e.key === 'Escape')) {
                  e.preventDefault()
                  if (e.key === 'Tab') {
                    const emote = emoteMap.get(autocompleteMatches[0].name)
                    if (emote) liveChatInputRef.current?.insertEmote(emote.name, emote.id)
                  }
                  setAutocompleteMatches([])
                  return
                }
              }}
              onSubmit={() => { handleChatSend(); setAutocompleteMatches([]); setEmotePickerOpen(false) }}
            />
            <GoldButton size="sm" onClick={() => { handleChatSend(); setEmotePickerOpen(false) }} disabled={!isLive}>
              <Send size={14} />
            </GoldButton>
          </div>
          {inputFocused && (
            <div className={`mt-1 text-[10px] text-right ${chatInput.length >= 500 ? 'text-red-400' : 'text-[var(--color-text-dim)]'}`}>
              {chatInput.length}/500
            </div>
          )}
        </div>
      </div>
      )}
    </div>
  )
}
