'use client'

import { useState, useEffect, useRef } from 'react'
import { Radio, Eye, Send, Bell, Clock, Play, Calendar } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'
import type { Message, Tier } from '@/lib/types'
import Avatar from '@/components/ui/Avatar'
import TierBadge from '@/components/ui/TierBadge'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'
import Logo from '@/components/ui/Logo'
import Spinner from '@/components/ui/Spinner'
import { getTierColor, formatRelativeTime, formatDate } from '@/lib/utils'

const LIVE_CHAT_MESSAGES = [
  'Lets gooo!', 'Hype!', 'Great stream', 'When is the next giveaway?',
  'Spearmint gang', 'Love this community', 'GG', 'First time here, loving it',
  'Drop a like if you like Wintergreen', 'BlakJaks to the moon',
]

const MOCK_USERS: { id: string; username: string; tier: Tier }[] = [
  { id: 'usr_010', username: 'cryptoQueen', tier: 'high_roller' },
  { id: 'usr_011', username: 'mintFanatic', tier: 'standard' },
  { id: 'usr_012', username: 'whaleDave', tier: 'whale' },
  { id: 'usr_014', username: 'vipSarah', tier: 'vip' },
  { id: 'usr_015', username: 'blazeRunner', tier: 'vip' },
]

const UPCOMING_STREAMS = [
  { id: 's1', title: 'Community AMA with the Founders', date: '2025-02-20T20:00:00Z', host: 'BlakJaks Team' },
  { id: 's2', title: 'New Flavor Taste Test Live', date: '2025-02-25T19:00:00Z', host: 'whaleDave' },
  { id: 's3', title: 'Governance Deep Dive Q1', date: '2025-03-01T18:00:00Z', host: 'cryptoQueen' },
  { id: 's4', title: 'High Roller Friday Night Hangout', date: '2025-03-07T21:00:00Z', host: 'pouch_master' },
]

const PAST_STREAMS = [
  { id: 'p1', title: 'January Community Roundup', date: '2025-01-30T20:00:00Z', duration: '1h 23m' },
  { id: 'p2', title: 'Tier System Explained', date: '2025-01-20T19:00:00Z', duration: '45m' },
  { id: 'p3', title: 'Holiday Giveaway Stream', date: '2024-12-22T20:00:00Z', duration: '2h 10m' },
  { id: 'p4', title: 'Launch Day Celebration', date: '2024-12-01T18:00:00Z', duration: '1h 45m' },
]

export default function LiveStreamPage() {
  const { user } = useAuth()
  const [isLive, setIsLive] = useState(false)
  const [viewerCount, setViewerCount] = useState(0)
  const [chatMessages, setChatMessages] = useState<Message[]>([])
  const [chatInput, setChatInput] = useState('')
  const [notifiedStreams, setNotifiedStreams] = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(true)
  const chatEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    api.streaming.getLive().then(() => {
      // Mock: start as offline, user can toggle
      setLoading(false)
    })
  }, [])

  // Simulated live chat when "live"
  useEffect(() => {
    if (!isLive) return
    setViewerCount(1247)
    const interval = setInterval(() => {
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
      }
      setChatMessages(prev => [...prev.slice(-50), newMsg])
      setViewerCount(v => v + Math.floor(Math.random() * 5) - 2)
    }, 3000)
    return () => clearInterval(interval)
  }, [isLive])

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [chatMessages])

  const handleChatSend = async () => {
    const text = chatInput.trim()
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
    }
    setChatMessages(prev => [...prev, msg])
    setChatInput('')
  }

  const toggleNotify = (streamId: string) => {
    setNotifiedStreams(prev => {
      const next = new Set(prev)
      if (next.has(streamId)) next.delete(streamId)
      else next.add(streamId)
      return next
    })
  }

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Live Stream</h1>
          <p className="text-sm text-[var(--color-text-muted)]">Watch live events and community streams</p>
        </div>
        {/* Dev toggle for demo */}
        <GoldButton variant="secondary" size="sm" onClick={() => setIsLive(!isLive)}>
          {isLive ? 'Go Offline (Demo)' : 'Go Live (Demo)'}
        </GoldButton>
      </div>

      {/* Player + Live Chat */}
      <div className="flex gap-4 h-[480px]">
        {/* Video Player Area */}
        <div className="flex-1 rounded-2xl border border-[var(--color-border)] bg-black overflow-hidden flex flex-col">
          {isLive ? (
            <>
              {/* Live Header */}
              <div className="flex items-center justify-between px-4 py-3 bg-[var(--color-bg-surface)]">
                <div className="flex items-center gap-3">
                  <span className="flex items-center gap-1.5 rounded-md bg-red-600 px-2 py-0.5 text-xs font-bold text-white uppercase">
                    <Radio size={12} className="animate-pulse" />
                    Live
                  </span>
                  <div>
                    <h3 className="text-sm font-semibold text-white">Community AMA with the Founders</h3>
                    <p className="text-xs text-[var(--color-text-dim)]">Hosted by BlakJaks Team</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 text-sm text-[var(--color-text-muted)]">
                  <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse" />
                  <Eye size={14} />
                  <span>{viewerCount.toLocaleString()}</span>
                </div>
              </div>
              {/* Mock video area */}
              <div className="flex-1 flex items-center justify-center bg-gradient-to-b from-zinc-900 to-black">
                <div className="text-center opacity-50">
                  <Logo size="lg" />
                  <p className="mt-2 text-xs text-[var(--color-text-dim)]">Live stream video feed</p>
                </div>
              </div>
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center">
              <Logo size="lg" />
              <p className="mt-4 text-lg font-medium text-[var(--color-text-muted)]">No Live Stream</p>
              <p className="mt-1 text-sm text-[var(--color-text-dim)]">Stream starting soon...</p>
              <p className="mt-4 text-xs text-[var(--color-text-dim)]">
                Next stream: {formatDate(UPCOMING_STREAMS[0].date, 'long')}
              </p>
            </div>
          )}
        </div>

        {/* Live Chat Panel */}
        <div className="w-80 shrink-0 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] flex flex-col">
          <div className="shrink-0 border-b border-[var(--color-border)] px-4 py-3">
            <h3 className="text-sm font-semibold text-white">Live Chat</h3>
          </div>

          <div className="flex-1 overflow-y-auto px-3 py-2 space-y-2">
            {!isLive && chatMessages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-full text-center">
                <p className="text-sm text-[var(--color-text-dim)]">Chat will be active when the stream is live</p>
              </div>
            )}
            {chatMessages.map(msg => (
              <div key={msg.id} className="flex items-start gap-2">
                <Avatar name={msg.username} tier={msg.userTier} size="sm" />
                <div className="min-w-0">
                  <span className="text-xs font-medium" style={{ color: getTierColor(msg.userTier) }}>
                    {msg.username}
                  </span>
                  <p className="text-xs text-[var(--color-text)] break-words">{msg.content}</p>
                </div>
              </div>
            ))}
            <div ref={chatEndRef} />
          </div>

          <div className="shrink-0 border-t border-[var(--color-border)] p-3">
            <div className="flex gap-2">
              <input
                type="text"
                value={chatInput}
                onChange={e => setChatInput(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); handleChatSend() } }}
                placeholder={isLive ? 'Say something...' : 'Chat offline'}
                disabled={!isLive}
                className="flex-1 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 py-2 text-xs text-[var(--color-text)] placeholder-[var(--color-text-dim)] focus:border-[var(--color-gold)] focus:outline-none disabled:opacity-50"
              />
              <GoldButton size="sm" onClick={handleChatSend} disabled={!isLive || !chatInput.trim()}>
                <Send size={14} />
              </GoldButton>
            </div>
          </div>
        </div>
      </div>

      {/* Upcoming Streams */}
      <div>
        <h2 className="text-lg font-semibold text-white mb-4">Upcoming Streams</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {UPCOMING_STREAMS.map(stream => (
            <Card key={stream.id}>
              <div className="flex items-start justify-between mb-3">
                <Calendar size={16} className="text-[var(--color-gold)] mt-0.5" />
                <span className="text-xs text-[var(--color-text-dim)]">{formatDate(stream.date)}</span>
              </div>
              <h3 className="text-sm font-semibold text-white mb-1">{stream.title}</h3>
              <p className="text-xs text-[var(--color-text-dim)] mb-3">Hosted by {stream.host}</p>
              <div className="flex items-center gap-2 text-xs text-[var(--color-text-dim)]">
                <Clock size={12} />
                <span>{new Date(stream.date).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}</span>
              </div>
              <GoldButton
                variant={notifiedStreams.has(stream.id) ? 'ghost' : 'secondary'}
                size="sm"
                fullWidth
                className="mt-3"
                onClick={() => toggleNotify(stream.id)}
              >
                <Bell size={14} />
                {notifiedStreams.has(stream.id) ? 'Notified' : 'Notify Me'}
              </GoldButton>
            </Card>
          ))}
        </div>
      </div>

      {/* Past Streams */}
      <div>
        <h2 className="text-lg font-semibold text-white mb-4">Past Streams</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {PAST_STREAMS.map(stream => (
            <Card key={stream.id}>
              <div className="flex items-start justify-between mb-3">
                <Play size={16} className="text-[var(--color-text-dim)] mt-0.5" />
                <span className="text-xs text-[var(--color-text-dim)]">{formatDate(stream.date)}</span>
              </div>
              <h3 className="text-sm font-semibold text-white mb-1">{stream.title}</h3>
              <p className="text-xs text-[var(--color-text-dim)] mb-3">Duration: {stream.duration}</p>
              <GoldButton variant="ghost" size="sm" fullWidth disabled>
                VOD coming soon
              </GoldButton>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
