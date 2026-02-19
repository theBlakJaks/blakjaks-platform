'use client'

import { useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { Bell } from 'lucide-react'
import { useNotificationStore, type NotificationItem } from '@/lib/notification-store'
import Avatar from '@/components/ui/Avatar'
import { formatRelativeTime } from '@/lib/utils'

function NotificationRow({ item, onTap }: { item: NotificationItem; onTap: (item: NotificationItem) => void }) {
  return (
    <button
      onClick={() => onTap(item)}
      className={`flex w-full items-start gap-3 px-4 py-3 text-left transition-colors hover:bg-[var(--color-bg-hover)] ${
        !item.isRead ? 'bg-[var(--color-gold)]/5' : ''
      }`}
    >
      <div className="shrink-0 mt-0.5">
        {item.senderAvatarUrl ? (
          <Avatar name={item.senderUsername || 'User'} size="sm" avatarUrl={item.senderAvatarUrl} />
        ) : (
          <div className="h-8 w-8 rounded-full bg-[var(--color-gold)]/20 flex items-center justify-center text-[var(--color-gold)] text-xs font-bold">BJ</div>
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className={`text-sm ${!item.isRead ? 'font-semibold text-white' : 'text-[var(--color-text-muted)]'}`}>
          {item.title}
        </p>
        {item.body && (
          <p className="text-xs text-[var(--color-text-dim)] mt-0.5 line-clamp-2">{item.body}</p>
        )}
        <p className="text-[10px] text-[var(--color-text-dim)] mt-1">{formatRelativeTime(item.createdAt)}</p>
      </div>
      {!item.isRead && (
        <span className="mt-2 shrink-0 h-2 w-2 rounded-full bg-[var(--color-gold)]" />
      )}
    </button>
  )
}

export default function NotificationBell() {
  const { notifications, unreadCount, isDropdownOpen, isPulsing, setDropdownOpen, markAsRead, markAllAsRead } = useNotificationStore()
  const dropdownRef = useRef<HTMLDivElement>(null)
  const router = useRouter()

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false)
      }
    }
    function handleEscape(e: KeyboardEvent) {
      if (e.key === 'Escape') setDropdownOpen(false)
    }
    document.addEventListener('mousedown', handleClick)
    document.addEventListener('keydown', handleEscape)
    return () => {
      document.removeEventListener('mousedown', handleClick)
      document.removeEventListener('keydown', handleEscape)
    }
  }, [setDropdownOpen])

  const sorted = [...notifications].sort((a, b) => {
    if (a.isRead !== b.isRead) return a.isRead ? 1 : -1
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  })

  const handleTap = (item: NotificationItem) => {
    // Mark as read
    if (!item.isRead) markAsRead(item.id)
    setDropdownOpen(false)

    // Navigate to the referenced chat
    if (item.channelId) {
      const params = new URLSearchParams({ channel: item.channelId })
      if (item.messageId) params.set('msg', item.messageId)
      router.push(`/social?${params.toString()}`)
    }
  }

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setDropdownOpen(!isDropdownOpen)}
        className={`relative flex h-9 w-9 items-center justify-center rounded-full border transition-all ${
          isPulsing
            ? 'border-[var(--color-gold)] animate-[bellPulse_1.5s_ease-out]'
            : 'border-[var(--color-gold)]/30 hover:bg-[var(--color-gold)]/10'
        }`}
        style={isPulsing ? { animation: 'bellPulse 1.5s ease-out' } : undefined}
      >
        <Bell
          size={18}
          className={`text-[var(--color-gold)] ${isPulsing ? 'animate-[bellRing_0.8s_ease-in-out]' : ''}`}
          style={isPulsing ? { animation: 'bellRing 0.8s ease-in-out' } : undefined}
        />
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white border border-[#1A1A2E]">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {isDropdownOpen && (
        <div className="absolute right-0 top-full mt-2 w-[360px] max-h-[420px] flex flex-col rounded-xl border border-[var(--color-gold)]/15 bg-[#1A1A2E] shadow-[0_8px_32px_rgba(0,0,0,0.5)] z-50 overflow-hidden">
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-[var(--color-border)]">
            <h3 className="text-sm font-bold text-white">Notifications</h3>
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                className="text-xs text-[var(--color-gold)] hover:underline"
              >
                Mark all as read
              </button>
            )}
          </div>

          {/* List */}
          <div className="flex-1 overflow-y-auto">
            {sorted.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 px-4">
                <Bell size={28} className="text-[var(--color-text-dim)] mb-2" />
                <p className="text-sm text-[var(--color-text-dim)]">No notifications</p>
              </div>
            ) : (
              sorted.map(item => (
                <NotificationRow key={item.id} item={item} onTap={handleTap} />
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
