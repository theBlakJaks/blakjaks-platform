import {
  currentUser, transactions, channels, messagesByChannel,
  votes, proposals, comps, scans, treasuryWallets, transparencyOverview,
  activityFeed, monthlyEarnings, compTierStats, partnerMetrics, systemHealth,
} from './mock-data'
import type { Transaction, Channel, Message, Vote, Proposal } from './types'

const delay = (ms?: number) => new Promise((r) => setTimeout(r, ms ?? (200 + Math.random() * 300)))

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || ''

// eslint-disable-next-line @typescript-eslint/no-unused-vars
async function fetchAPI<T>(_endpoint: string, _options?: RequestInit): Promise<T> {
  // When a real API is available, this will make actual fetch calls to BASE_URL
  // For now, all methods below return mock data
  throw new Error('Not implemented - use mock methods')
}

export const api = {
  auth: {
    async login(email: string, _password: string) {
      await delay(400)
      if (!email) throw new Error('Email is required')
      return { token: 'mock_jwt_token', user: currentUser }
    },
    async register(data: { email: string; password: string; username: string; firstName: string; lastName: string }) {
      await delay(500)
      return { token: 'mock_jwt_token', user: { ...currentUser, ...data } }
    },
    async logout() {
      await delay(200)
      return { success: true }
    },
    async forgotPassword(email: string) {
      await delay(400)
      return { message: `Password reset link sent to ${email}` }
    },
  },

  dashboard: {
    async get() {
      await delay()
      return {
        user: currentUser,
        recentActivity: activityFeed.slice(0, 10),
        walletBalance: 186.50,
        pendingComps: 0.50,
        unreadMessages: channels.reduce((s, c) => s + c.unreadCount, 0),
      }
    },
  },

  wallet: {
    async getBalance() {
      await delay()
      return { balance: 186.50, pendingComps: 0.50, lifetimeEarnings: 245.00 }
    },
    async getTransactions(filters?: { type?: string; page?: number }) {
      await delay()
      let filtered = transactions
      if (filters?.type && filters.type !== 'all') {
        filtered = filtered.filter((t) => t.type === filters.type)
      }
      return { transactions: filtered, total: filtered.length }
    },
  },

  social: {
    async getChannels(): Promise<{ channels: Channel[] }> {
      await delay()
      return { channels }
    },
    async getMessages(channelId: string): Promise<{ messages: Message[] }> {
      await delay()
      return { messages: messagesByChannel[channelId] || [] }
    },
    async sendMessage(channelId: string, content: string): Promise<Message> {
      await delay(300)
      return {
        id: `msg_${Date.now()}`,
        channelId,
        userId: currentUser.id,
        username: currentUser.username,
        userTier: currentUser.tier,
        content,
        timestamp: new Date().toISOString(),
        reactions: {},
        avatarUrl: currentUser.avatarUrl,
      }
    },
    async addReaction(_messageId: string, _emoji: string) {
      await delay(200)
      return { success: true }
    },
    async removeReaction(_messageId: string, _emoji: string) {
      await delay(200)
      return { success: true }
    },
  },

  streaming: {
    async getLive() {
      await delay()
      return { isLive: false, viewers: 0, nextStream: '2025-02-20T20:00:00Z' }
    },
  },

  profile: {
    async get() {
      await delay()
      return currentUser
    },
  },

  settings: {
    async updateProfile(data: Partial<typeof currentUser>) {
      await delay(400)
      return { ...currentUser, ...data }
    },
    async uploadAvatar(file: File) {
      await delay(800)
      // Simulate: generate a local object URL as the "uploaded" avatar
      const avatarUrl = URL.createObjectURL(file)
      currentUser.avatarUrl = avatarUrl
      return { avatarUrl }
    },
    async deleteAvatar() {
      await delay(400)
      currentUser.avatarUrl = undefined
    },
    async updatePassword(_data: { currentPassword: string; newPassword: string }) {
      await delay(400)
      return { success: true }
    },
    async update2FA(_data: { enabled: boolean }) {
      await delay(400)
      return { success: true, enabled: _data.enabled }
    },
    async updateNotifications(_data: Record<string, boolean>) {
      await delay(300)
      return { success: true }
    },
  },

  users: {
    async checkUsername(username: string): Promise<{ available: boolean; message: string; suggestions?: string[] }> {
      await delay(400)
      // Simulate: "jakemitch" is taken, everything else is available
      if (username.toLowerCase() === 'jakemitch') {
        return {
          available: false,
          message: 'Username already taken',
          suggestions: [`${username}_42`, `${username}99`, `${username}_BJ`],
        }
      }
      return { available: true, message: 'Username available' }
    },
    async changeUsername(username: string) {
      await delay(400)
      currentUser.username = username
      return { message: 'Username updated', username }
    },
  },

  governance: {
    async getVotes(): Promise<{ votes: Vote[]; proposals: Proposal[] }> {
      await delay()
      return { votes, proposals }
    },
    async castVote(voteId: string, optionId: string) {
      await delay(400)
      return { success: true, voteId, optionId }
    },
    async submitProposal(data: { title: string; description: string }) {
      await delay(500)
      return { id: `prop_${Date.now()}`, ...data, status: 'submitted', createdAt: new Date().toISOString() }
    },
  },

  notifications: {
    async getAll() {
      await delay()
      const mockNotifications = [
        {
          id: 'notif_001', type: 'chat_reply' as const, title: 'cryptoQueen replied to your message',
          body: 'The comp system is so generous. Love getting USDT just for scanning.', isRead: false,
          channelId: 'ch_001', messageId: 'msg_ch_001_003', senderUsername: 'cryptoQueen',
          senderAvatarUrl: 'https://i.pravatar.cc/150?u=usr_010', createdAt: new Date(Date.now() - 120000).toISOString(),
        },
        {
          id: 'notif_002', type: 'admin_broadcast' as const, title: 'New flavor just dropped!',
          body: 'Check out our new Midnight Mint flavor. Limited edition for VIP and above.', isRead: false,
          channelId: 'ch_007', messageId: 'msg_ch_007_005', senderUsername: 'BlakJaks',
          senderAvatarUrl: null, createdAt: new Date(Date.now() - 3600000).toISOString(),
        },
        {
          id: 'notif_003', type: 'chat_reply' as const, title: 'whaleDave replied to your message',
          body: 'Great point about the governance vote!', isRead: true,
          channelId: 'ch_001', messageId: 'msg_ch_001_010', senderUsername: 'whaleDave',
          senderAvatarUrl: 'https://i.pravatar.cc/150?u=usr_012', createdAt: new Date(Date.now() - 86400000).toISOString(),
        },
      ]
      return { notifications: mockNotifications, unreadCount: 2, total: 3 }
    },
    async markAsRead(_notificationId: string) {
      await delay(200)
      return { success: true }
    },
    async markAllAsRead() {
      await delay(200)
      return { success: true }
    },
    async deleteNotification(_notificationId: string) {
      await delay(200)
      return { success: true }
    },
    async getUnreadCount() {
      await delay(100)
      return { count: 2 }
    },
  },

  transparency: {
    async getOverview() {
      await delay()
      return transparencyOverview
    },
    async getTreasury() {
      await delay()
      return { wallets: treasuryWallets }
    },
    async getComps() {
      await delay()
      return { awards: comps, scans, tierStats: compTierStats, monthlyEarnings }
    },
    async getPartners() {
      await delay()
      return partnerMetrics
    },
    async getSystems() {
      await delay()
      return systemHealth
    },
  },
}
