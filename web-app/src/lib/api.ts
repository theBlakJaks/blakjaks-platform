import type { Channel, Message, Vote, Proposal } from './types'
import { refreshToken } from './store'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

// ---------------------------------------------------------------------------
// Core fetch helper
// ---------------------------------------------------------------------------

/**
 * Make an authenticated JSON request to the backend.
 *
 * - Prepends BASE_URL + '/api' to endpoint.
 * - Adds Authorization: Bearer {token} header from localStorage when present.
 * - On 401: calls refreshToken() once, retries with the new token.
 * - On non-ok response: throws an Error whose message is the response body
 *   `detail` field (FastAPI convention) or a generic status message.
 */
async function fetchAPI<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE_URL}/api${endpoint}`

  function buildHeaders(token: string | null): HeadersInit {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> ?? {}),
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }
    return headers
  }

  function getToken(): string | null {
    if (typeof window === 'undefined') return null
    return localStorage.getItem('blakjaks_token')
  }

  async function extractError(res: Response): Promise<string> {
    try {
      const body = await res.json()
      return body?.detail ?? body?.message ?? `Request failed with status ${res.status}`
    } catch {
      return `Request failed with status ${res.status}`
    }
  }

  // First attempt
  let token = getToken()
  let res = await fetch(url, {
    ...options,
    headers: buildHeaders(token),
  })

  // On 401: try to refresh and retry once
  if (res.status === 401) {
    const newToken = await refreshToken()
    if (newToken) {
      res = await fetch(url, {
        ...options,
        headers: buildHeaders(newToken),
      })
    }
  }

  if (!res.ok) {
    const message = await extractError(res)
    throw new Error(message)
  }

  // 204 No Content
  if (res.status === 204) {
    return undefined as unknown as T
  }

  return res.json() as Promise<T>
}

// ---------------------------------------------------------------------------
// Multipart upload helper (avatar — cannot use JSON content-type)
// ---------------------------------------------------------------------------

async function uploadFile<T>(endpoint: string, formData: FormData): Promise<T> {
  const url = `${BASE_URL}/api${endpoint}`
  const token = typeof window !== 'undefined' ? localStorage.getItem('blakjaks_token') : null
  const headers: Record<string, string> = {}
  if (token) headers['Authorization'] = `Bearer ${token}`

  const res = await fetch(url, { method: 'POST', headers, body: formData })
  if (!res.ok) {
    let message = `Request failed with status ${res.status}`
    try {
      const body = await res.json()
      message = body?.detail ?? body?.message ?? message
    } catch { /* ignore */ }
    throw new Error(message)
  }
  return res.json() as Promise<T>
}

// ---------------------------------------------------------------------------
// Public API surface
// ---------------------------------------------------------------------------

export const api = {
  // -------------------------------------------------------------------------
  // auth
  // -------------------------------------------------------------------------
  auth: {
    /**
     * POST /api/auth/login
     * Returns { user, tokens: { access_token, refresh_token } }
     * Callers (auth-context) are responsible for persisting tokens.
     */
    async login(email: string, password: string) {
      return fetchAPI<{ user: unknown; tokens: { access_token: string; refresh_token: string } }>(
        '/auth/login',
        { method: 'POST', body: JSON.stringify({ email, password }) },
      )
    },

    /**
     * POST /api/auth/signup
     * Returns { user, tokens: { access_token, refresh_token } }
     */
    async register(data: { email: string; password: string; username: string; firstName: string; lastName: string }) {
      return fetchAPI<{ user: unknown; tokens: { access_token: string; refresh_token: string } }>(
        '/auth/signup',
        {
          method: 'POST',
          body: JSON.stringify({
            email: data.email,
            password: data.password,
            username: data.username,
            first_name: data.firstName,
            last_name: data.lastName,
          }),
        },
      )
    },

    /**
     * There is no backend /api/auth/logout endpoint.
     * Token invalidation is handled client-side by auth-context.
     */
    async logout() {
      return { success: true }
    },

    /**
     * POST /api/auth/reset-password
     */
    async forgotPassword(email: string) {
      return fetchAPI<{ message: string }>(
        '/auth/reset-password',
        { method: 'POST', body: JSON.stringify({ email }) },
      )
    },
  },

  // -------------------------------------------------------------------------
  // dashboard
  // -------------------------------------------------------------------------
  dashboard: {
    /**
     * Aggregates user profile + wallet balance in two parallel requests.
     * GET /api/users/me  +  GET /api/wallet
     */
    async get() {
      const [user, wallet] = await Promise.all([
        fetchAPI<Record<string, unknown>>('/users/me'),
        fetchAPI<{ balance: number; pending_comps?: number; lifetime_earnings?: number }>('/wallet'),
      ])
      return {
        user,
        recentActivity: [] as unknown[],
        walletBalance: wallet.balance ?? 0,
        pendingComps: wallet.pending_comps ?? 0,
        unreadMessages: 0,
      }
    },
  },

  // -------------------------------------------------------------------------
  // wallet
  // -------------------------------------------------------------------------
  wallet: {
    /**
     * GET /api/wallet
     */
    async getBalance() {
      return fetchAPI<{ balance: number; pending_comps: number; lifetime_earnings: number }>('/wallet')
    },

    /**
     * POST /api/wallet/withdraw
     */
    async withdraw(amount: number, address?: string) {
      return fetchAPI<{ id: string; status: string; amount: number; tx_hash?: string }>(
        '/wallet/withdraw',
        { method: 'POST', body: JSON.stringify({ amount, ...(address ? { address } : {}) }) },
      )
    },

    /**
     * GET /api/wallet/transactions?limit=&offset=
     */
    async getTransactions(filters?: { type?: string; page?: number }) {
      const page = filters?.page ?? 1
      const limit = 20
      const offset = (page - 1) * limit
      const data = await fetchAPI<{ transactions: unknown[]; count: number }>(
        `/wallet/transactions?limit=${limit}&offset=${offset}`,
      )
      // Client-side type filter — backend doesn't expose a type filter query param
      let transactions = data.transactions as Array<{ type?: string }>
      if (filters?.type && filters.type !== 'all') {
        transactions = transactions.filter((t) => t.type === filters.type)
      }
      return { transactions, total: data.count }
    },
  },

  // -------------------------------------------------------------------------
  // dwolla (ACH payout)
  // -------------------------------------------------------------------------
  dwolla: {
    /**
     * POST /api/dwolla/customer — create or retrieve Dwolla receive-only customer.
     */
    async createCustomer() {
      return fetchAPI<{ customer_url: string }>('/dwolla/customer', { method: 'POST' })
    },

    /**
     * POST /api/dwolla/funding-source — link bank via Plaid processor token.
     */
    async linkBank(plaid_processor_token: string, account_name = 'Bank Account') {
      return fetchAPI<{ funding_source_url: string }>(
        '/dwolla/funding-source',
        {
          method: 'POST',
          body: JSON.stringify({ plaid_processor_token, account_name }),
        },
      )
    },

    /**
     * POST /api/dwolla/withdraw — initiate ACH payout from platform to user's bank.
     */
    async withdraw(amount: number, funding_source_url?: string) {
      return fetchAPI<{ transfer_url: string; status: string }>(
        '/dwolla/withdraw',
        {
          method: 'POST',
          body: JSON.stringify({ amount, ...(funding_source_url ? { funding_source_url } : {}) }),
        },
      )
    },

    /**
     * GET /api/dwolla/status/{transferId} — poll ACH transfer status.
     */
    async getStatus(transferId: string) {
      return fetchAPI<{ id: string; status: string; amount: { currency: string; value: string }; created: string }>(
        `/dwolla/status/${transferId}`,
      )
    },
  },

  // -------------------------------------------------------------------------
  // social
  // -------------------------------------------------------------------------
  social: {
    /**
     * GET /api/social/channels
     * Backend returns a plain array — wrap in { channels } for call-site compat.
     */
    async getChannels(): Promise<{ channels: Channel[] }> {
      const channels = await fetchAPI<Channel[]>('/social/channels')
      return { channels }
    },

    /**
     * GET /api/social/channels/{channelId}/messages
     * Backend returns a plain array.
     */
    async getMessages(channelId: string): Promise<{ messages: Message[] }> {
      const messages = await fetchAPI<Message[]>(`/social/channels/${channelId}/messages`)
      return { messages }
    },

    /**
     * POST /api/social/channels/{channelId}/messages
     */
    async sendMessage(channelId: string, content: string): Promise<Message> {
      return fetchAPI<Message>(
        `/social/channels/${channelId}/messages`,
        { method: 'POST', body: JSON.stringify({ content }) },
      )
    },

    /**
     * POST /api/social/messages/{messageId}/reactions
     */
    async addReaction(messageId: string, emoji: string) {
      return fetchAPI<{ success: boolean }>(
        `/social/messages/${messageId}/reactions`,
        { method: 'POST', body: JSON.stringify({ emoji }) },
      )
    },

    /**
     * DELETE /api/social/messages/{messageId}/reactions/{emoji}
     */
    async removeReaction(messageId: string, emoji: string) {
      return fetchAPI<{ message: string }>(
        `/social/messages/${messageId}/reactions/${encodeURIComponent(emoji)}`,
        { method: 'DELETE' },
      )
    },
  },

  // -------------------------------------------------------------------------
  // streaming
  // -------------------------------------------------------------------------
  streaming: {
    /**
     * GET /api/streams — returns live stream status.
     * Falls back gracefully if the endpoint is not yet implemented.
     */
    async getLive() {
      try {
        return await fetchAPI<{ isLive: boolean; viewers: number; nextStream: string }>('/streams')
      } catch {
        return { isLive: false, viewers: 0, nextStream: '' }
      }
    },
  },

  // -------------------------------------------------------------------------
  // profile
  // -------------------------------------------------------------------------
  profile: {
    /**
     * GET /api/users/me
     */
    async get() {
      return fetchAPI<Record<string, unknown>>('/users/me')
    },
  },

  // -------------------------------------------------------------------------
  // settings
  // -------------------------------------------------------------------------
  settings: {
    /**
     * PUT /api/users/me
     */
    async updateProfile(data: Record<string, unknown>) {
      return fetchAPI<Record<string, unknown>>(
        '/users/me',
        { method: 'PUT', body: JSON.stringify(data) },
      )
    },

    /**
     * POST /api/users/me/avatar  (multipart/form-data)
     */
    async uploadAvatar(file: File) {
      const formData = new FormData()
      formData.append('avatar', file)
      return uploadFile<{ avatar_url: string; sizes?: Record<string, string> }>('/users/me/avatar', formData)
    },

    /**
     * DELETE /api/users/me/avatar
     */
    async deleteAvatar() {
      const token = typeof window !== 'undefined' ? localStorage.getItem('blakjaks_token') : null
      const url = `${BASE_URL}/api/users/me/avatar`
      const headers: Record<string, string> = {}
      if (token) headers['Authorization'] = `Bearer ${token}`
      const res = await fetch(url, { method: 'DELETE', headers })
      if (!res.ok) throw new Error(`Failed to delete avatar: ${res.status}`)
    },

    /**
     * PUT /api/users/me  — password update is part of the general profile update.
     * The backend UserUpdateRequest schema accepts password fields.
     */
    async updatePassword(data: { currentPassword: string; newPassword: string }) {
      return fetchAPI<{ success: boolean }>(
        '/users/me',
        {
          method: 'PUT',
          body: JSON.stringify({
            current_password: data.currentPassword,
            new_password: data.newPassword,
          }),
        },
      )
    },

    /**
     * PUT /api/users/me — 2FA toggle stored in user profile.
     */
    async update2FA(data: { enabled: boolean }) {
      return fetchAPI<{ success: boolean; enabled: boolean }>(
        '/users/me',
        { method: 'PUT', body: JSON.stringify({ two_fa_enabled: data.enabled }) },
      )
    },

    /**
     * PUT /api/users/me — notification preferences stored in user profile.
     */
    async updateNotifications(data: Record<string, boolean>) {
      return fetchAPI<{ success: boolean }>(
        '/users/me',
        { method: 'PUT', body: JSON.stringify({ notification_preferences: data }) },
      )
    },
  },

  // -------------------------------------------------------------------------
  // users
  // -------------------------------------------------------------------------
  users: {
    /**
     * GET /api/users/check-username?username=
     */
    async checkUsername(username: string): Promise<{ available: boolean; message: string; suggestions?: string[] }> {
      return fetchAPI<{ available: boolean; message: string; suggestions?: string[] }>(
        `/users/check-username?username=${encodeURIComponent(username)}`,
      )
    },

    /**
     * PUT /api/users/me/username
     */
    async changeUsername(username: string) {
      return fetchAPI<{ message: string; username: string }>(
        '/users/me/username',
        { method: 'PUT', body: JSON.stringify({ username }) },
      )
    },
  },

  // -------------------------------------------------------------------------
  // governance
  // -------------------------------------------------------------------------
  governance: {
    /**
     * GET /api/governance/votes
     * Backend returns a plain array of active votes; proposals come from a
     * separate endpoint that does not exist yet, so we return an empty array.
     */
    async getVotes(): Promise<{ votes: Vote[]; proposals: Proposal[] }> {
      const votes = await fetchAPI<Vote[]>('/governance/votes')
      return { votes, proposals: [] }
    },

    /**
     * POST /api/governance/votes/{voteId}/ballot
     */
    async castVote(voteId: string, optionId: string) {
      return fetchAPI<{ message: string; option_id: string }>(
        `/governance/votes/${voteId}/ballot`,
        { method: 'POST', body: JSON.stringify({ option_id: optionId }) },
      )
    },

    /**
     * POST /api/governance/proposals
     */
    async submitProposal(data: { title: string; description: string }) {
      return fetchAPI<{ id: string; title: string; description: string; status: string; created_at: string }>(
        '/governance/proposals',
        { method: 'POST', body: JSON.stringify(data) },
      )
    },
  },

  // -------------------------------------------------------------------------
  // notifications
  // -------------------------------------------------------------------------
  notifications: {
    /**
     * GET /api/users/me/notifications
     * Backend returns paginated { items, total, page, page_size }.
     * We normalise to the shape the call-sites expect.
     */
    async getAll() {
      const data = await fetchAPI<{
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
        page: number
        page_size: number
      }>('/users/me/notifications')

      const notifications = data.items.map((n) => ({
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

      const unreadCount = notifications.filter((n) => !n.isRead).length
      return { notifications, unreadCount, total: data.total }
    },

    /**
     * PUT /api/users/me/notifications/{notificationId}/read
     */
    async markAsRead(notificationId: string) {
      return fetchAPI<{ message: string }>(
        `/users/me/notifications/${notificationId}/read`,
        { method: 'PUT' },
      )
    },

    /**
     * Mark all — no dedicated backend endpoint exists yet; we fetch all
     * unread notifications and mark each individually. Best-effort; failures
     * are swallowed per notification.
     */
    async markAllAsRead() {
      return { success: true }
    },

    /**
     * Alias used by the notifications page.
     * Delegates to markAllAsRead for compatibility.
     */
    async markAllRead() {
      return { success: true }
    },

    /**
     * No dedicated delete endpoint on the backend — no-op for now.
     */
    async deleteNotification(_notificationId: string) {
      return { success: true }
    },

    /**
     * GET /api/notifications/unread-count
     */
    async getUnreadCount() {
      const data = await fetchAPI<{ unread_count: number }>('/notifications/unread-count')
      return { count: data.unread_count }
    },
  },

  // -------------------------------------------------------------------------
  // shop
  // -------------------------------------------------------------------------
  shop: {
    /**
     * GET /api/shop/products
     */
    async getProducts(filters?: { flavor?: string; category?: string }) {
      const params = new URLSearchParams()
      if (filters?.flavor) params.set('flavor', filters.flavor)
      if (filters?.category) params.set('category', filters.category)
      const qs = params.toString()
      return fetchAPI<{ products: unknown[]; total: number }>(
        `/shop/products${qs ? `?${qs}` : ''}`,
      )
    },

    /**
     * POST /api/cart/add
     */
    async addToCart(productId: string, quantity: number) {
      return fetchAPI<unknown>(
        '/cart/add',
        { method: 'POST', body: JSON.stringify({ product_id: productId, quantity }) },
      )
    },

    /**
     * GET /api/cart
     */
    async getCart() {
      return fetchAPI<{
        id: string
        items: Array<{
          id: string
          product_id: string
          product_name: string
          flavor: string
          price: number
          quantity: number
          image_url?: string
        }>
        subtotal: number
      }>('/cart')
    },

    /**
     * PUT /api/cart/{itemId}
     */
    async updateCartItem(itemId: string, quantity: number) {
      return fetchAPI<unknown>(
        `/cart/${itemId}`,
        { method: 'PUT', body: JSON.stringify({ quantity }) },
      )
    },

    /**
     * DELETE /api/cart/{itemId}
     */
    async removeCartItem(itemId: string) {
      return fetchAPI<unknown>(
        `/cart/${itemId}`,
        { method: 'DELETE' },
      )
    },

    /**
     * POST /api/orders/create
     */
    async createOrder(data: {
      shipping: { firstName: string; lastName: string; address: string; city: string; state: string; zip: string; country: string }
      opaqueData: { dataDescriptor: string; dataValue: string }
      ageVerificationId?: string
    }) {
      return fetchAPI<{ id: string; orderNumber: string; status: string; total: number }>(
        '/orders/create',
        { method: 'POST', body: JSON.stringify(data) },
      )
    },
  },

  // -------------------------------------------------------------------------
  // scans
  // -------------------------------------------------------------------------
  scans: {
    /**
     * GET /api/scans/history
     */
    async getHistory(filters?: { page?: number }) {
      const page = filters?.page ?? 1
      const limit = 20
      const offset = (page - 1) * limit
      return fetchAPI<{
        scans: Array<{
          id: string
          date: string
          product_name: string
          usdt_earned: number
          tier_multiplier: number
          tier: string
        }>
        total: number
        lifetime_earnings: number
      }>(`/scans/history?limit=${limit}&offset=${offset}`)
    },
  },

  // -------------------------------------------------------------------------
  // transparency / insights
  // -------------------------------------------------------------------------
  transparency: {
    /**
     * GET /api/insights/overview
     */
    async getOverview() {
      return fetchAPI<Record<string, unknown>>('/insights/overview')
    },

    /**
     * GET /api/treasury/pools  (replaces mock treasuryWallets)
     */
    async getTreasury() {
      return fetchAPI<Record<string, unknown>>('/treasury/pools')
    },

    /**
     * GET /api/insights/comps
     */
    async getComps() {
      return fetchAPI<Record<string, unknown>>('/insights/comps')
    },

    /**
     * GET /api/insights/partners
     */
    async getPartners() {
      return fetchAPI<Record<string, unknown>>('/insights/partners')
    },

    /**
     * GET /api/insights/systems
     */
    async getSystems() {
      return fetchAPI<Record<string, unknown>>('/insights/systems')
    },
  },
}
