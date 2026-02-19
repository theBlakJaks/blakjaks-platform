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

export const useNotificationStore = create<NotificationState>((set, get) => ({
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
