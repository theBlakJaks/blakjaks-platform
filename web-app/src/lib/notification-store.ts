'use client'

import { create } from 'zustand'

export interface NotificationItem {
  id: string
  type: 'chat_reply' | 'admin_broadcast'
  title: string
  body: string | null
  isRead: boolean
  channelId: string | null
  messageId: string | null
  senderUsername: string | null
  senderAvatarUrl: string | null
  createdAt: string
}

interface NotificationState {
  notifications: NotificationItem[]
  unreadCount: number
  isDropdownOpen: boolean
  isPulsing: boolean

  setNotifications: (notifications: NotificationItem[]) => void
  addNotification: (notification: NotificationItem) => void
  removeNotification: (id: string) => void
  markAsRead: (id: string) => void
  markAllAsRead: () => void
  setUnreadCount: (count: number) => void
  setDropdownOpen: (open: boolean) => void
  triggerPulse: () => void
}

export const useNotificationStore = create<NotificationState>((set) => ({
  notifications: [],
  unreadCount: 0,
  isDropdownOpen: false,
  isPulsing: false,

  setNotifications: (notifications) => set({ notifications }),

  addNotification: (notification) => set(s => ({
    notifications: [notification, ...s.notifications],
    unreadCount: s.unreadCount + 1,
  })),

  removeNotification: (id) => set(s => {
    const notif = s.notifications.find(n => n.id === id)
    return {
      notifications: s.notifications.filter(n => n.id !== id),
      unreadCount: notif && !notif.isRead ? Math.max(0, s.unreadCount - 1) : s.unreadCount,
    }
  }),

  markAsRead: (id) => set(s => {
    const notif = s.notifications.find(n => n.id === id)
    if (!notif || notif.isRead) return s
    return {
      notifications: s.notifications.map(n => n.id === id ? { ...n, isRead: true } : n),
      unreadCount: Math.max(0, s.unreadCount - 1),
    }
  }),

  markAllAsRead: () => set(s => ({
    notifications: s.notifications.map(n => ({ ...n, isRead: true })),
    unreadCount: 0,
  })),

  setUnreadCount: (count) => set({ unreadCount: count }),
  setDropdownOpen: (open) => set({ isDropdownOpen: open }),

  triggerPulse: () => {
    set({ isPulsing: true })
    setTimeout(() => set({ isPulsing: false }), 1500)
  },
}))

// ---------------------------------------------------------------------------
// Real-time notification subscription
// ---------------------------------------------------------------------------

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

// Polling interval used as fallback when Socket.IO is unavailable (ms)
const POLL_INTERVAL = 30_000

let socketInstance: import('socket.io-client').Socket | null = null
let pollTimer: ReturnType<typeof setInterval> | null = null
let isSubscribed = false

/**
 * Fetch notifications from REST and sync them into the store.
 * Used both for initial load and as the Socket.IO fallback poller.
 */
async function pollNotifications(): Promise<void> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('blakjaks_token') : null
  if (!token) return

  try {
    const res = await fetch(`${BASE_URL}/api/users/me/notifications`, {
      headers: { Authorization: `Bearer ${token}` },
    })
    if (!res.ok) return

    const data = await res.json() as {
      items: Array<{
        id: string
        type: 'chat_reply' | 'admin_broadcast'
        title: string
        body: string | null
        is_read: boolean
        channel_id: string | null
        message_id: string | null
        sender_username: string | null
        sender_avatar_url: string | null
        created_at: string
      }>
      total: number
    }

    const notifications: NotificationItem[] = data.items.map((n) => ({
      id: n.id,
      type: n.type,
      title: n.title,
      body: n.body,
      isRead: n.is_read,
      channelId: n.channel_id,
      messageId: n.message_id,
      senderUsername: n.sender_username,
      senderAvatarUrl: n.sender_avatar_url,
      createdAt: n.created_at,
    }))

    const unreadCount = notifications.filter(n => !n.isRead).length
    useNotificationStore.getState().setNotifications(notifications)
    useNotificationStore.getState().setUnreadCount(unreadCount)
  } catch {
    // Silently swallow — user remains on last known state
  }
}

/**
 * Subscribe to real-time notifications.
 *
 * Strategy:
 * 1. Always perform an initial REST poll to hydrate the store immediately.
 * 2. Attempt to connect to the Socket.IO /notifications namespace.
 *    - On success: listen for `notification` events and prepend each to the store.
 *      Disable the polling fallback timer while the socket is connected.
 *    - On connect_error / disconnect: fall back to polling every POLL_INTERVAL ms.
 * 3. Calling subscribeToNotifications() when already subscribed is a no-op.
 *
 * Call unsubscribeFromNotifications() on logout / unmount to clean up.
 */
export async function subscribeToNotifications(): Promise<void> {
  if (isSubscribed) return
  if (typeof window === 'undefined') return

  isSubscribed = true

  // Initial REST hydration
  await pollNotifications()

  // Attempt Socket.IO connection
  try {
    const { io } = await import('socket.io-client')

    const token = localStorage.getItem('blakjaks_token')

    socketInstance = io(`${BASE_URL}/notifications`, {
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnectionAttempts: 5,
      reconnectionDelay: 2000,
    })

    socketInstance.on('connect', () => {
      // Socket connected — stop fallback polling
      if (pollTimer !== null) {
        clearInterval(pollTimer)
        pollTimer = null
      }
    })

    socketInstance.on('notification', (raw: unknown) => {
      // Expect the server to emit a notification shaped like NotificationItem
      // with snake_case fields.
      const n = raw as {
        id: string
        type: 'chat_reply' | 'admin_broadcast'
        title: string
        body?: string | null
        is_read?: boolean
        channel_id?: string | null
        message_id?: string | null
        sender_username?: string | null
        sender_avatar_url?: string | null
        created_at: string
      }

      const item: NotificationItem = {
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body ?? null,
        isRead: n.is_read ?? false,
        channelId: n.channel_id ?? null,
        messageId: n.message_id ?? null,
        senderUsername: n.sender_username ?? null,
        senderAvatarUrl: n.sender_avatar_url ?? null,
        createdAt: n.created_at,
      }

      const store = useNotificationStore.getState()
      store.addNotification(item)
      store.triggerPulse()
    })

    socketInstance.on('connect_error', () => {
      // Socket.IO unavailable — start polling fallback if not already running
      if (pollTimer === null) {
        pollTimer = setInterval(pollNotifications, POLL_INTERVAL)
      }
    })

    socketInstance.on('disconnect', () => {
      // Socket disconnected — fall back to polling until reconnect
      if (pollTimer === null) {
        pollTimer = setInterval(pollNotifications, POLL_INTERVAL)
      }
    })

    socketInstance.on('reconnect', () => {
      // Reconnected — stop polling, do one fresh fetch
      if (pollTimer !== null) {
        clearInterval(pollTimer)
        pollTimer = null
      }
      void pollNotifications()
    })
  } catch {
    // socket.io-client import failed or any other error — fall back to polling
    if (pollTimer === null) {
      pollTimer = setInterval(pollNotifications, POLL_INTERVAL)
    }
  }
}

/**
 * Tear down Socket.IO connection and polling timer.
 * Call on logout or top-level unmount.
 */
export function unsubscribeFromNotifications(): void {
  isSubscribed = false

  if (socketInstance) {
    socketInstance.disconnect()
    socketInstance = null
  }

  if (pollTimer !== null) {
    clearInterval(pollTimer)
    pollTimer = null
  }
}
