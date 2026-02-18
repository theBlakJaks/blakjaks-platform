import client from './client'
import type { User } from '../types'

const MOCK_USERS: User[] = Array.from({ length: 47 }, (_, i) => ({
  id: `u-${String(i + 1).padStart(3, '0')}`,
  email: `user${i + 1}@example.com`,
  first_name: ['James', 'Sarah', 'Mike', 'Lisa', 'Alex', 'Emma', 'Dave', 'Nina', 'Tom', 'Zoe'][i % 10],
  last_name: ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Martinez', 'Wilson'][i % 10],
  tier_id: null,
  tier_name: ['Standard', 'Standard', 'VIP', 'VIP', 'High Roller', 'Whale', 'Standard', 'VIP', 'Standard', 'High Roller'][i % 10],
  is_admin: i === 0,
  is_suspended: i === 5 || i === 22,
  created_at: new Date(Date.now() - (47 - i) * 86400000 * 2).toISOString(),
  scan_count: Math.floor(Math.random() * 60),
  wallet_balance: Math.round(Math.random() * 500 * 100) / 100,
}))

export interface UserScan {
  id: string
  product_name: string
  qr_code: string
  scanned_at: string
}

export interface UserTransaction {
  id: string
  type: string
  amount: number
  status: string
  tx_hash: string | null
  created_at: string
}

export interface UserOrder {
  id: string
  total: number
  item_count: number
  status: string
  created_at: string
}

export interface UserAffiliate {
  referral_code: string
  downline_count: number
  total_earnings: number
  permanent_tier: string | null
}

export interface UserActivity {
  id: string
  type: 'message' | 'vote'
  description: string
  timestamp: string
}

export interface UserDetailFull extends User {
  lifetime_scans: number
  lifetime_spend: number
  tier_progress: { current: number; next_tier: string; scans_needed: number }
  scans: UserScan[]
  transactions: UserTransaction[]
  orders: UserOrder[]
  affiliate: UserAffiliate | null
  activity: UserActivity[]
}

export async function getUsers(
  page = 1,
  search?: string,
  tier?: string,
  sort?: string,
): Promise<{ items: User[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 20 }
    if (search) params.search = search
    if (tier) params.tier = tier
    if (sort) params.sort = sort
    const { data } = await client.get('/admin/users', { params })
    return data
  } catch {
    // Mock fallback
    let filtered = [...MOCK_USERS]
    if (search) {
      const q = search.toLowerCase()
      filtered = filtered.filter(u => u.email.toLowerCase().includes(q) || u.first_name.toLowerCase().includes(q) || u.last_name.toLowerCase().includes(q))
    }
    if (tier && tier !== 'All') {
      filtered = filtered.filter(u => u.tier_name === tier)
    }
    if (sort === 'scans') filtered.sort((a, b) => b.scan_count - a.scan_count)
    else if (sort === 'balance') filtered.sort((a, b) => b.wallet_balance - a.wallet_balance)
    else filtered.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}

export async function getUser(userId: string): Promise<UserDetailFull> {
  try {
    const { data } = await client.get(`/admin/users/${userId}`)
    return data
  } catch {
    const base = MOCK_USERS.find(u => u.id === userId) || MOCK_USERS[0]
    return {
      ...base,
      lifetime_scans: base.scan_count + Math.floor(Math.random() * 20),
      lifetime_spend: Math.round(Math.random() * 800 * 100) / 100,
      tier_progress: { current: base.scan_count % 15, next_tier: 'High Roller', scans_needed: 15 - (base.scan_count % 15) },
      scans: Array.from({ length: 8 }, (_, i) => ({
        id: `s-${i}`,
        product_name: ['Mint Ice', 'Berry Blast', 'Citrus Rush', 'Cool Menthol'][i % 4],
        qr_code: `QR-${Math.random().toString(36).slice(2, 10).toUpperCase()}`,
        scanned_at: new Date(Date.now() - i * 86400000 * 3).toISOString(),
      })),
      transactions: Array.from({ length: 10 }, (_, i) => ({
        id: `tx-${i}`,
        type: ['comp', 'purchase', 'reward_match', 'comp', 'transfer'][i % 5],
        amount: Math.round((Math.random() * 100 - 20) * 100) / 100,
        status: i === 3 ? 'failed' : 'completed',
        tx_hash: i % 2 === 0 ? `0x${Math.random().toString(16).slice(2, 14)}` : null,
        created_at: new Date(Date.now() - i * 86400000 * 2).toISOString(),
      })),
      orders: Array.from({ length: 5 }, (_, i) => ({
        id: `ord-${i}`,
        total: Math.round(Math.random() * 80 * 100) / 100,
        item_count: Math.floor(Math.random() * 4) + 1,
        status: ['delivered', 'shipped', 'processing', 'delivered', 'delivered'][i],
        created_at: new Date(Date.now() - i * 86400000 * 5).toISOString(),
      })),
      affiliate: base.tier_name === 'Standard' ? null : {
        referral_code: `${base.first_name.toUpperCase()}${Math.floor(Math.random() * 999)}`,
        downline_count: Math.floor(Math.random() * 25),
        total_earnings: Math.round(Math.random() * 200 * 100) / 100,
        permanent_tier: base.tier_name === 'Whale' ? 'Whale' : null,
      },
      activity: Array.from({ length: 6 }, (_, i) => ({
        id: `act-${i}`,
        type: (i % 2 === 0 ? 'message' : 'vote') as 'message' | 'vote',
        description: i % 2 === 0
          ? `Posted in #general-chat: "Hey everyone!"`
          : `Voted "Mint" on "New Flavor Poll"`,
        timestamp: new Date(Date.now() - i * 86400000).toISOString(),
      })),
    }
  }
}

export async function updateUser(userId: string, updates: Partial<User>): Promise<User> {
  const { data } = await client.put(`/admin/users/${userId}`, updates)
  return data
}

export async function suspendUser(userId: string, suspend: boolean): Promise<User> {
  const { data } = await client.put(`/admin/users/${userId}/suspend`, { is_suspended: suspend })
  return data
}

export async function adjustTier(userId: string, tierName: string): Promise<User> {
  const { data } = await client.put(`/admin/users/${userId}/tier`, { tier_name: tierName })
  return data
}
