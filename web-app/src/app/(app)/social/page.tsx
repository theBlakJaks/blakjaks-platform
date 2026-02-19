'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import Link from 'next/link'
import { Hash, Lock, ChevronDown, ChevronRight, Send, Smile, Globe, Pin, Radio } from 'lucide-react'
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

const TIER_RANK: Record<Tier, number> = { standard: 0, vip: 1, high_roller: 2, whale: 3 }

const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English', es: 'Spanish', fr: 'French', pt: 'Portuguese',
  ja: 'Japanese', ko: 'Korean', zh: 'Chinese', de: 'German',
  ar: 'Arabic', hi: 'Hindi', ru: 'Russian', it: 'Italian',
}

const RANDOM_MESSAGES = [
  'Just grabbed another can of Spearmint. So good.',
  'Who is watching the next live stream?',
  'Comp just hit my wallet. Love it.',
  'Anyone else stacking scans this week?',
  'Wintergreen crew where you at?',
  'The governance vote on Mango Tango is going to be close.',
  'Blue Razz 6mg is my daily driver.',
  'Just referred a friend, easy bonus!',
  'This community is the best.',
  'Coffee flavor is growing on me ngl.',
]

const MOCK_USERS = [
  { id: 'usr_010', username: 'cryptoQueen', tier: 'high_roller' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_010' },
  { id: 'usr_011', username: 'mintFanatic', tier: 'standard' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_011' },
  { id: 'usr_012', username: 'whaleDave', tier: 'whale' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_012' },
  { id: 'usr_013', username: 'newbie42', tier: 'standard' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_013' },
  { id: 'usr_014', username: 'vipSarah', tier: 'vip' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_014' },
  { id: 'usr_015', username: 'blazeRunner', tier: 'vip' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_015' },
  { id: 'usr_016', username: 'pouch_master', tier: 'high_roller' as Tier, avatarUrl: 'https://i.pravatar.cc/150?u=usr_016' },
]

const SYSTEM_MESSAGES: Message[] = [
  {
    id: 'sys_001', channelId: 'ch_001', userId: 'system', username: 'System',
    userTier: 'standard', content: 'vipSarah just hit VIP tier!',
    timestamp: new Date(Date.now() - 7200000).toISOString(), reactions: {}, isSystem: true,
  },
  {
    id: 'sys_002', channelId: 'ch_001', userId: 'system', username: 'System',
    userTier: 'standard', content: 'Someone just won $1,000 in comps!',
    timestamp: new Date(Date.now() - 3600000).toISOString(), reactions: {}, isSystem: true,
  },
]

const PINNED_MESSAGE: Message = {
  id: 'pin_001', channelId: 'ch_001', userId: 'usr_012', username: 'whaleDave',
  userTier: 'whale', content: 'Welcome to BlakJaks Social! Read the rules and be respectful. New members, drop an intro in #Introductions!',
  timestamp: new Date(Date.now() - 86400000).toISOString(), reactions: { '\uD83D\uDC4D': ['usr_010', 'usr_014', 'usr_011'] },
  avatarUrl: 'https://i.pravatar.cc/150?u=usr_012',
}

const FOREIGN_MESSAGE: Message = {
  id: 'foreign_001', channelId: 'ch_001', userId: 'usr_017', username: 'tokyoDrifter',
  userTier: 'vip', content: '\u3053\u306E\u30B3\u30DF\u30E5\u30CB\u30C6\u30A3\u306F\u6700\u9AD8\u3067\u3059\uFF01',
  timestamp: new Date(Date.now() - 1800000).toISOString(), reactions: {}, originalLanguage: 'ja',
  avatarUrl: 'https://i.pravatar.cc/150?u=usr_017',
}

export default function SocialPage() {
  const { user } = useAuth()
  const [channels, setChannels] = useState<Channel[]>([])
  const [messages, setMessages] = useState<Message[]>([])
  const [activeChannel, setActiveChannel] = useState<string>('ch_001')
  const [collapsedCategories, setCollapsedCategories] = useState<Set<string>>(new Set())
  const [inputText, setInputText] = useState('')
  const [loading, setLoading] = useState(true)
  const [translations, setTranslations] = useState<Record<string, string>>({})
  const [translating, setTranslating] = useState<Set<string>>(new Set())
  const preferredLanguage = useUIStore((s) => s.preferredLanguage)
  const [cooldownActive, setCooldownActive] = useState(false)
  const [cooldownTime, setCooldownTime] = useState(0)
  const [gifPickerOpen, setGifPickerOpen] = useState(false)
  const [emotePickerOpen, setEmotePickerOpen] = useState(false)
  const [autocompleteMatches, setAutocompleteMatches] = useState<CachedEmote[]>([])
  const [inputFocused, setInputFocused] = useState(false)
  const emoteList = useEmoteStore(s => s.emoteList)
  const emotes = useEmoteStore(s => s.emotes)
  const chatInputRef = useRef<EmoteChatInputHandle>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const chatContainerRef = useRef<HTMLDivElement>(null)

  const userTier = user?.tier || 'standard'
  const userRank = TIER_RANK[userTier]

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [])

  // Load channels
  useEffect(() => {
    api.social.getChannels().then(({ channels: ch }) => {
      setChannels(ch)
      setLoading(false)
    })
  }, [])

  // Start with blank chat, populate one by one
  useEffect(() => {
    setMessages([])
    setTranslations({})
    translateQueue.current.clear()
  }, [activeChannel])

  // Scroll on new messages
  useEffect(() => {
    scrollToBottom()
  }, [messages, scrollToBottom])

  // Drip-feed mock messages one by one
  const mockIndexRef = useRef(0)
  const allMockMessages = useRef<Message[]>([])

  useEffect(() => {
    // Build the full mock message queue for this channel
    api.social.getMessages(activeChannel).then(({ messages: msgs }) => {
      const enriched = activeChannel === 'ch_001'
        ? [...msgs.slice(0, -2), SYSTEM_MESSAGES[0], ...msgs.slice(-2, -1), FOREIGN_MESSAGE, SYSTEM_MESSAGES[1], ...msgs.slice(-1)]
        : msgs
      allMockMessages.current = enriched
      mockIndexRef.current = 0
    })

    const interval = setInterval(() => {
      // If we still have pre-built messages to drip, use those
      if (mockIndexRef.current < allMockMessages.current.length) {
        const msg = allMockMessages.current[mockIndexRef.current]
        // Update timestamp to now so it feels live
        const liveMsg = { ...msg, timestamp: new Date().toISOString() }
        setMessages(prev => [...prev, liveMsg])
        mockIndexRef.current++
      } else {
        // Once exhausted, generate random new messages
        const randomUser = MOCK_USERS[Math.floor(Math.random() * MOCK_USERS.length)]
        const randomContent = RANDOM_MESSAGES[Math.floor(Math.random() * RANDOM_MESSAGES.length)]
        const newMsg: Message = {
          id: `msg_live_${Date.now()}`,
          channelId: activeChannel,
          userId: randomUser.id,
          username: randomUser.username,
          userTier: randomUser.tier,
          content: randomContent,
          timestamp: new Date().toISOString(),
          reactions: Math.random() > 0.7 ? { '\uD83D\uDD25': ['usr_010'] } : {},
          avatarUrl: randomUser.avatarUrl,
        }
        setMessages(prev => [...prev, newMsg])
      }
    }, 3000)

    return () => clearInterval(interval)
  }, [activeChannel])

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

  const handleSend = async () => {
    const text = chatInputRef.current?.getText().trim() || inputText.trim()
    if (!text || cooldownActive) return

    const newMsg = await api.social.sendMessage(activeChannel, text)
    setMessages(prev => [...prev, newMsg])
    chatInputRef.current?.clear()
    setInputText('')

    if (userTier === 'standard') {
      setCooldownActive(true)
      setCooldownTime(5)
    }
  }

  const handleGifSelect = (gifUrl: string) => {
    if (!user) return
    const gifMsg: Message = {
      id: `msg_gif_${Date.now()}`,
      channelId: activeChannel,
      userId: user.id,
      username: user.username,
      userTier: user.tier,
      content: '',
      gifUrl,
      timestamp: new Date().toISOString(),
      reactions: {},
      avatarUrl: user.avatarUrl,
    }
    setMessages(prev => [...prev, gifMsg])
    setGifPickerOpen(false)
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

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner />
      </div>
    )
  }

  return (
    <div className="flex h-[calc(100vh-120px)] overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
      {/* Left Sidebar - Channel List */}
      <div className="w-64 shrink-0 border-r border-[var(--color-border)] bg-[var(--color-bg-surface)] overflow-y-auto">
        <div className="p-4 border-b border-[var(--color-border)]">
          <h2 className="text-sm font-semibold text-white">Social Hub</h2>
          <p className="text-xs text-[var(--color-text-dim)] mt-0.5">Community Channels</p>
          <Link
            href="/social/live"
            className="mt-3 flex items-center gap-2 rounded-lg bg-red-500/10 px-3 py-2 text-xs font-medium text-red-400 hover:bg-red-500/20 transition-colors"
          >
            <Radio size={14} className="animate-pulse" /> Live Stream
          </Link>
        </div>

        <div className="py-2">
          {Object.entries(channelsByCategory).map(([category, chs]) => {
            const isCollapsed = collapsedCategories.has(category)
            return (
              <div key={category} className="mb-1">
                <button
                  onClick={() => toggleCategory(category)}
                  className="flex w-full items-center gap-1 px-3 py-1.5 text-xs font-semibold uppercase tracking-wider text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)] transition-colors"
                >
                  {isCollapsed ? <ChevronRight size={12} /> : <ChevronDown size={12} />}
                  {category}
                </button>

                {!isCollapsed && chs.map(ch => {
                  const isLocked = TIER_RANK[ch.tierRequired] > userRank
                  const isActive = ch.id === activeChannel

                  return (
                    <button
                      key={ch.id}
                      onClick={() => !isLocked && setActiveChannel(ch.id)}
                      disabled={isLocked}
                      className={`flex w-full items-center gap-2 px-3 py-1.5 mx-2 rounded-lg text-sm transition-colors ${
                        isActive
                          ? 'bg-[var(--color-gold)]/10 text-[var(--color-gold)]'
                          : isLocked
                            ? 'text-[var(--color-text-dim)] opacity-50 cursor-not-allowed'
                            : 'text-[var(--color-text-muted)] hover:text-white hover:bg-[var(--color-bg-hover)]'
                      }`}
                      style={{ maxWidth: 'calc(100% - 16px)' }}
                    >
                      {isLocked ? <Lock size={14} /> : <Hash size={14} />}
                      <span className="truncate flex-1 text-left">{ch.name}</span>
                      {ch.unreadCount > 0 && !isLocked && (
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
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex flex-1 flex-col min-w-0">
        {/* Channel Header */}
        <div className="shrink-0 border-b border-[var(--color-border)] px-6 py-3">
          <div className="flex items-center gap-2">
            <Hash size={18} className="text-[var(--color-text-dim)]" />
            <h3 className="font-semibold text-white">{currentChannel?.name || 'General Chat'}</h3>
          </div>
          <p className="text-xs text-[var(--color-text-dim)] mt-0.5 ml-7">
            {currentChannel?.description || ''}
          </p>
        </div>

        {/* Pinned Message */}
        {activeChannel === 'ch_001' && (
          <div className="shrink-0 mx-4 mt-3 flex items-start gap-3 rounded-xl border border-[var(--color-gold)]/30 bg-[var(--color-gold)]/5 px-4 py-3">
            <Pin size={14} className="mt-0.5 shrink-0 text-[var(--color-gold)]" />
            <div className="min-w-0">
              <span className="text-xs font-medium text-[var(--color-gold)]">Pinned by whaleDave</span>
              <p className="text-sm text-[var(--color-text)]">{PINNED_MESSAGE.content}</p>
            </div>
          </div>
        )}

        {/* Messages Feed */}
        <div ref={chatContainerRef} className="flex-1 overflow-y-auto px-4 py-4 space-y-1">
          {messages.map((msg, i) => {
            if (msg.isSystem) {
              return (
                <div key={msg.id} className="flex justify-center py-2">
                  <span className="rounded-full bg-[var(--color-bg-surface)] px-4 py-1 text-xs text-[var(--color-text-dim)]">
                    {msg.content}
                  </span>
                </div>
              )
            }

            const showHeader = i === 0 || messages[i - 1]?.userId !== msg.userId || messages[i - 1]?.isSystem
            const reactionEntries = Object.entries(msg.reactions)
            const isTranslated = !!translations[msg.id]
            const isTranslating = translating.has(msg.id)

            return (
              <div
                key={msg.id}
                className={`group flex gap-3 rounded-lg px-2 py-0.5 hover:bg-[var(--color-bg-surface)] ${showHeader ? 'mt-3' : ''}`}
              >
                {showHeader ? (
                  <Avatar name={msg.username} tier={msg.userTier} size="sm" avatarUrl={msg.userId === user?.id ? user.avatarUrl : msg.avatarUrl} />
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
                    </div>
                  )}

                  {msg.replyTo && (
                    <div className="text-xs text-[var(--color-text-dim)] mb-1 flex items-center gap-1">
                      <span className="inline-block h-3 w-3 rounded-full border-l-2 border-t-2 border-[var(--color-text-dim)]" />
                      Replying to <span className="text-[var(--color-gold)]">{msg.replyTo}</span>
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

                  {reactionEntries.length > 0 && (
                    <div className="mt-1 flex gap-1.5">
                      {reactionEntries.map(([emoji, users]) => (
                        <span
                          key={emoji}
                          className="inline-flex items-center gap-1 rounded-full border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-2 py-0.5 text-xs"
                        >
                          {emoji} <span className="text-[var(--color-text-dim)]">{users.length}</span>
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )
          })}
          <div ref={messagesEndRef} />
        </div>

        {/* Message Composer */}
        <div className="shrink-0 border-t border-[var(--color-border)] px-4 py-3">
          {cooldownActive && (
            <div className="mb-2 text-xs text-[var(--color-text-dim)]">
              Rate limited. You can send another message in {cooldownTime}s
            </div>
          )}
          <div className="flex items-end gap-2">
            <div className="flex-1 relative">
              <EmoteChatInput
                ref={chatInputRef}
                placeholder={`Message #${currentChannel?.name || 'general'}...`}
                disabled={cooldownActive}
                maxLength={500}
                className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2.5 pr-24 text-sm text-[var(--color-text)] focus:border-[var(--color-gold)] focus:outline-none focus:ring-1 focus:ring-[var(--color-gold)]/50 disabled:opacity-50"
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
                  className={`p-1 transition-colors ${emotePickerOpen ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)]'}`}
                  title="Emotes"
                >
                  <Smile size={18} />
                </button>
                <button
                  onClick={() => { setGifPickerOpen(!gifPickerOpen); setEmotePickerOpen(false) }}
                  className={`p-1 transition-colors ${gifPickerOpen ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)]'}`}
                  title="GIF"
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
              {emotePickerOpen && (
                <EmotePicker
                  onSelect={(emote) => {
                    chatInputRef.current?.insertEmote(emote.name, emote.id)
                  }}
                  onClose={() => setEmotePickerOpen(false)}
                />
              )}
              {gifPickerOpen && (
                <GiphyPicker onSelect={handleGifSelect} onClose={() => setGifPickerOpen(false)} />
              )}
            </div>
            <GoldButton onClick={() => { handleSend(); setEmotePickerOpen(false) }} disabled={!inputText.trim() || cooldownActive} size="md">
              <Send size={16} />
            </GoldButton>
          </div>
          {inputFocused && (
            <div className={`mt-1 text-xs text-right ${charCount >= 500 ? 'text-red-400' : 'text-[var(--color-text-dim)]'}`}>
              {charCount}/500
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
