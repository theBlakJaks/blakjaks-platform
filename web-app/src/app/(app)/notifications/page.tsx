'use client'

import { useEffect, useState, useCallback } from 'react'
import { Bell, RefreshCw, Megaphone, MessageCircle, Zap, Users, Settings } from 'lucide-react'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'
import GoldButton from '@/components/ui/GoldButton'
import Tabs from '@/components/ui/Tabs'
import { api } from '@/lib/api'
import { formatRelativeTime } from '@/lib/utils'
import { cn } from '@/lib/utils'

interface Notification {
  id: string
  type: string
  title: string
  body: string | null
  isRead: boolean
  channelId: string | null
  messageId: string | null
  senderUsername: string | null
  senderAvatarUrl: string | null
  createdAt: string
}

const FILTER_TABS = [
  { id: 'all', label: 'All' },
  { id: 'admin_broadcast', label: 'System' },
  { id: 'comp', label: 'Comp' },
  { id: 'tier', label: 'Tier' },
  { id: 'chat_reply', label: 'Social' },
]

const TYPE_ICONS: Record<string, React.ElementType> = {
  admin_broadcast: Megaphone,
  chat_reply: MessageCircle,
  comp: Zap,
  tier: Users,
  system: Settings,
}

function NotificationIcon({ type }: { type: string }) {
  const Icon = TYPE_ICONS[type] ?? Bell
  const colorMap: Record<string, string> = {
    admin_broadcast: 'text-blue-400 bg-blue-400/10',
    chat_reply: 'text-purple-400 bg-purple-400/10',
    comp: 'text-green-400 bg-green-400/10',
    tier: 'text-[var(--color-gold)] bg-[var(--color-gold)]/10',
    system: 'text-[var(--color-text-dim)] bg-[var(--color-bg-surface)]',
  }
  const color = colorMap[type] ?? colorMap.system
  return (
    <div className={cn('flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl', color)}>
      <Icon size={18} />
    </div>
  )
}

function SkeletonNotification() {
  return (
    <div className="flex items-start gap-4 border-b border-[var(--color-border)]/50 px-4 py-4 animate-pulse">
      <div className="h-10 w-10 flex-shrink-0 rounded-xl bg-[var(--color-bg-surface)]" />
      <div className="flex-1 space-y-2">
        <div className="h-4 w-48 rounded bg-[var(--color-bg-surface)]" />
        <div className="h-3 w-full rounded bg-[var(--color-bg-surface)]" />
        <div className="h-3 w-24 rounded bg-[var(--color-bg-surface)]" />
      </div>
    </div>
  )
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState('all')
  const [markingAll, setMarkingAll] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await api.notifications.getAll()
      setNotifications(data.notifications as Notification[])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load notifications')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  async function handleMarkAllRead() {
    setMarkingAll(true)
    try {
      // Mark each unread notification individually using the per-item endpoint
      const unread = notifications.filter((n) => !n.isRead)
      await Promise.allSettled(unread.map((n) => api.notifications.markAsRead(n.id)))
      setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })))
    } catch {
      // best-effort
    } finally {
      setMarkingAll(false)
    }
  }

  const filtered =
    activeTab === 'all'
      ? notifications
      : notifications.filter((n) => n.type === activeTab)

  const unreadCount = notifications.filter((n) => !n.isRead).length

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Notifications</h1>
          <p className="mt-1 text-sm text-[var(--color-text-dim)]">
            {unreadCount > 0
              ? `${unreadCount} unread notification${unreadCount !== 1 ? 's' : ''}`
              : 'All caught up'}
          </p>
        </div>
        {unreadCount > 0 && !loading && (
          <GoldButton
            variant="secondary"
            size="sm"
            loading={markingAll}
            onClick={handleMarkAllRead}
          >
            Mark all read
          </GoldButton>
        )}
      </div>

      <Card>
        {/* Filter tabs */}
        <div className="mb-4 flex items-center justify-between gap-4 flex-wrap">
          <Tabs tabs={FILTER_TABS} activeTab={activeTab} onChange={setActiveTab} />
          <button
            onClick={load}
            className="rounded-lg p-2 text-[var(--color-text-dim)] transition-colors hover:text-white"
            aria-label="Refresh notifications"
          >
            <RefreshCw size={14} />
          </button>
        </div>

        {/* Loading skeleton */}
        {loading && (
          <div>
            {Array.from({ length: 6 }).map((_, i) => (
              <SkeletonNotification key={i} />
            ))}
          </div>
        )}

        {/* Error */}
        {!loading && error && (
          <div className="py-8 text-center">
            <p className="mb-4 text-[var(--color-danger)]">{error}</p>
            <GoldButton onClick={load} variant="secondary">
              <RefreshCw size={14} /> Retry
            </GoldButton>
          </div>
        )}

        {/* Empty */}
        {!loading && !error && filtered.length === 0 && (
          <EmptyState
            icon={Bell}
            message={
              activeTab === 'all'
                ? "You're all caught up — no notifications yet."
                : `No ${activeTab.replace('_', ' ')} notifications.`
            }
            actionLabel={activeTab !== 'all' ? 'Show All' : undefined}
            onAction={activeTab !== 'all' ? () => setActiveTab('all') : undefined}
          />
        )}

        {/* Notification list */}
        {!loading && !error && filtered.length > 0 && (
          <div>
            {filtered.map((notification) => (
              <div
                key={notification.id}
                className={cn(
                  'relative flex items-start gap-4 border-b border-[var(--color-border)]/50 px-4 py-4 transition-colors hover:bg-[var(--color-bg-hover)]',
                  !notification.isRead && 'bg-[var(--color-gold)]/5',
                )}
                onClick={() => {
                  if (!notification.isRead) {
                    api.notifications.markAsRead(notification.id).catch(() => {})
                    setNotifications((prev) =>
                      prev.map((n) =>
                        n.id === notification.id ? { ...n, isRead: true } : n,
                      ),
                    )
                  }
                }}
                role="button"
                tabIndex={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.currentTarget.click()
                  }
                }}
              >
                {/* Unread dot */}
                {!notification.isRead && (
                  <span
                    className="absolute left-1.5 top-1/2 h-2 w-2 -translate-y-1/2 rounded-full bg-[var(--color-gold)]"
                    aria-label="Unread"
                  />
                )}

                {/* Icon */}
                <NotificationIcon type={notification.type} />

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <p
                      className={cn(
                        'text-sm font-medium leading-snug',
                        notification.isRead ? 'text-[var(--color-text-muted)]' : 'text-white',
                      )}
                    >
                      {notification.title}
                    </p>
                    <span className="flex-shrink-0 text-xs text-[var(--color-text-dim)]">
                      {formatRelativeTime(notification.createdAt)}
                    </span>
                  </div>
                  {notification.body && (
                    <p className="mt-0.5 text-sm text-[var(--color-text-dim)] line-clamp-2">
                      {notification.body}
                    </p>
                  )}
                  {notification.senderUsername && (
                    <p className="mt-1 text-xs text-[var(--color-text-dim)]">
                      from{' '}
                      <span className="text-[var(--color-gold)]">@{notification.senderUsername}</span>
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}
