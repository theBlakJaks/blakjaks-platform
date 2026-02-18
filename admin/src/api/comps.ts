import client from './client'
import type { Comp, CompStats } from '../types'

const COMP_TYPES = ['crypto_100', 'crypto_1k', 'crypto_10k', 'casino_comp', 'guaranteed_5']
const STATUSES = ['completed', 'completed', 'completed', 'completed', 'pending', 'failed']
const NAMES = ['James S.', 'Sarah J.', 'Mike W.', 'Lisa B.', 'Alex J.', 'Emma G.', 'Dave M.', 'Nina D.', 'Tom M.', 'Zoe W.']

const MOCK_COMPS: Comp[] = Array.from({ length: 50 }, (_, i) => {
  const compType = COMP_TYPES[i % 5]
  const amounts: Record<string, number> = { crypto_100: 100, crypto_1k: 1000, crypto_10k: 10000, casino_comp: 250, guaranteed_5: 5 }
  const status = STATUSES[i % 6]
  const amount = amounts[compType]
  return {
    id: `comp-${String(i + 1).padStart(3, '0')}`,
    user_id: `u-${String((i % 20) + 1).padStart(3, '0')}`,
    user_email: `user${(i % 20) + 1}@example.com`,
    user_name: NAMES[i % 10],
    comp_type: compType,
    amount,
    reason: ['Quarterly scan reward', 'VIP bonus', 'Referral milestone', 'First purchase bonus', 'Contest winner'][i % 5],
    status,
    tx_hash: status === 'completed' ? `0x${Math.random().toString(16).slice(2, 14)}...${Math.random().toString(16).slice(2, 6)}` : null,
    affiliate_match: i % 3 === 0 ? Math.round(amount * 0.21 * 100) / 100 : null,
    created_at: new Date(Date.now() - (50 - i) * 86400000 * 1.2).toISOString(),
  }
})

export const COMP_TYPE_OPTIONS = [
  { value: 'crypto_100', label: '$100 Crypto', amount: 100 },
  { value: 'crypto_1k', label: '$1,000 Crypto', amount: 1000 },
  { value: 'crypto_10k', label: '$10,000 Crypto', amount: 10000 },
  { value: 'casino_comp', label: 'Casino Comp', amount: 250 },
  { value: 'guaranteed_5', label: 'Guaranteed $5', amount: 5 },
]

export async function getCompStats(): Promise<CompStats> {
  try {
    const { data } = await client.get('/admin/comps/stats')
    return data
  } catch {
    const total = MOCK_COMPS.length
    const totalValue = MOCK_COMPS.reduce((sum, c) => sum + c.amount, 0)
    const pending = MOCK_COMPS.filter(c => c.status === 'pending').length
    const failed = MOCK_COMPS.filter(c => c.status === 'failed').length
    return { total_awarded: total, total_value: totalValue, pending_count: pending, failed_count: failed }
  }
}

export async function getComps(
  page = 1,
  compType?: string,
  status?: string,
): Promise<{ items: Comp[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 20 }
    if (compType) params.comp_type = compType
    if (status) params.status = status
    const { data } = await client.get('/admin/comps', { params })
    return data
  } catch {
    let filtered = [...MOCK_COMPS]
    if (compType) filtered = filtered.filter(c => c.comp_type === compType)
    if (status) filtered = filtered.filter(c => c.status === status)
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}

export async function awardComp(
  userId: string,
  amount: number,
  reason: string,
  compType = 'manual',
): Promise<Comp> {
  try {
    const { data } = await client.post('/admin/comps', { user_id: userId, amount, reason, comp_type: compType })
    return data
  } catch {
    return {
      id: `comp-new-${Date.now()}`,
      user_id: userId,
      user_email: 'user@example.com',
      user_name: 'User',
      comp_type: compType,
      amount,
      reason,
      status: 'pending',
      tx_hash: null,
      affiliate_match: null,
      created_at: new Date().toISOString(),
    }
  }
}

export async function retryFailed(compId: string): Promise<Comp> {
  try {
    const { data } = await client.post(`/admin/comps/${compId}/retry`)
    return data
  } catch {
    const comp = MOCK_COMPS.find(c => c.id === compId)
    return { ...(comp || MOCK_COMPS[0]), status: 'pending' }
  }
}

export async function bulkRetryFailed(compIds: string[]): Promise<{ retried: number }> {
  try {
    const { data } = await client.post('/admin/comps/retry-bulk', { comp_ids: compIds })
    return data
  } catch {
    return { retried: compIds.length }
  }
}

export async function searchUsers(query: string): Promise<{ id: string; email: string; name: string }[]> {
  try {
    const { data } = await client.get('/admin/users', { params: { search: query, limit: 10 } })
    return (data.items || []).map((u: { id: string; email: string; first_name: string; last_name: string }) => ({
      id: u.id,
      email: u.email,
      name: `${u.first_name} ${u.last_name}`,
    }))
  } catch {
    const q = query.toLowerCase()
    return NAMES.filter((_, i) => `user${i + 1}@example.com`.includes(q) || NAMES[i].toLowerCase().includes(q))
      .slice(0, 10)
      .map((name, i) => ({ id: `u-${String(i + 1).padStart(3, '0')}`, email: `user${i + 1}@example.com`, name }))
  }
}
