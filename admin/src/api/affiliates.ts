import client from './client'
import type { Affiliate, AffiliateDetail, AffiliateStats, Payout, PayoutBatch, SunsetProgress } from '../types'

const NAMES = ['James S.', 'Sarah J.', 'Mike W.', 'Lisa B.', 'Alex J.', 'Emma G.', 'Dave M.', 'Nina D.', 'Tom M.', 'Zoe W.']
const TIERS: (string | null)[] = [null, null, 'VIP', null, 'High Roller', null, 'Whale', null, null, 'VIP']

const MOCK_AFFILIATES: Affiliate[] = Array.from({ length: 30 }, (_, i) => ({
  id: `aff-${String(i + 1).padStart(3, '0')}`,
  user_id: `u-${String(i + 1).padStart(3, '0')}`,
  user_name: NAMES[i % 10],
  user_email: `affiliate${i + 1}@example.com`,
  referral_code: `${NAMES[i % 10].split(' ')[0].toUpperCase()}${100 + i}`,
  total_referrals: Math.floor(Math.random() * 50) + 1,
  total_chips: Math.floor(Math.random() * 200) + 10,
  vaulted_chips: Math.floor(Math.random() * 80),
  expired_chips: Math.floor(Math.random() * 20),
  reward_match_total: Math.round(Math.random() * 1500 * 100) / 100,
  pool_share_total: Math.round(Math.random() * 500 * 100) / 100,
  permanent_tier: TIERS[i % 10],
  referred_tins: Math.floor(Math.random() * 3000),
  created_at: new Date(Date.now() - (30 - i) * 86400000 * 3).toISOString(),
}))

const MOCK_BATCHES: PayoutBatch[] = Array.from({ length: 8 }, (_, i) => {
  const start = new Date(Date.now() - (8 - i) * 7 * 86400000)
  const end = new Date(start.getTime() + 6 * 86400000)
  return {
    id: `batch-${i + 1}`,
    period_start: start.toISOString(),
    period_end: end.toISOString(),
    affiliate_count: Math.floor(Math.random() * 20) + 5,
    total_amount: Math.round(Math.random() * 5000 * 100) / 100,
    status: i < 2 ? 'pending' : i < 4 ? 'approved' : 'paid',
    approved_by: i >= 2 ? 'Admin Josh' : null,
    executed_at: i >= 4 ? new Date(end.getTime() + 86400000).toISOString() : null,
  }
})

const MOCK_PAYOUTS: Payout[] = Array.from({ length: 20 }, (_, i) => {
  const batch = MOCK_BATCHES[i % 8]
  return {
    id: `pay-${String(i + 1).padStart(3, '0')}`,
    affiliate_id: MOCK_AFFILIATES[i % 30].id,
    affiliate_email: MOCK_AFFILIATES[i % 30].user_email,
    amount: Math.round(Math.random() * 300 * 100) / 100,
    payout_type: i % 3 === 0 ? 'pool_share' : 'reward_match',
    period_start: batch.period_start,
    period_end: batch.period_end,
    status: batch.status,
    tx_hash: batch.status === 'paid' ? `0x${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 14)}` : null,
    created_at: batch.period_end,
  }
})

export async function getAffiliateStats(): Promise<AffiliateStats> {
  try {
    const { data } = await client.get('/admin/affiliate/stats')
    return data
  } catch {
    const pending = MOCK_BATCHES.filter(b => b.status === 'pending')
    return {
      total_affiliates: MOCK_AFFILIATES.length,
      total_paid: MOCK_AFFILIATES.reduce((s, a) => s + a.reward_match_total + a.pool_share_total, 0),
      pending_count: pending.length,
      pending_value: pending.reduce((s, b) => s + b.total_amount, 0),
      sunset_percentage: 42.3,
    }
  }
}

export async function getAffiliates(
  page = 1,
  sort?: string,
  search?: string,
): Promise<{ items: Affiliate[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 20 }
    if (sort) params.sort = sort
    if (search) params.search = search
    const { data } = await client.get('/admin/affiliate/affiliates', { params })
    return data
  } catch {
    let filtered = [...MOCK_AFFILIATES]
    if (search) {
      const q = search.toLowerCase()
      filtered = filtered.filter(a => a.user_name.toLowerCase().includes(q) || a.referral_code.toLowerCase().includes(q) || a.user_email.toLowerCase().includes(q))
    }
    if (sort === 'earnings') filtered.sort((a, b) => (b.reward_match_total + b.pool_share_total) - (a.reward_match_total + a.pool_share_total))
    else if (sort === 'downline') filtered.sort((a, b) => b.total_referrals - a.total_referrals)
    else if (sort === 'chips') filtered.sort((a, b) => b.total_chips - a.total_chips)
    else filtered.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}

export async function getAffiliateDetail(affiliateId: string): Promise<AffiliateDetail> {
  try {
    const { data } = await client.get(`/admin/affiliate/affiliates/${affiliateId}`)
    return data
  } catch {
    const base = MOCK_AFFILIATES.find(a => a.id === affiliateId) || MOCK_AFFILIATES[0]
    return {
      ...base,
      custom_code: Math.random() > 0.5 ? base.referral_code.toLowerCase() : null,
      referral_link: `https://blakjaks.com/ref/${base.referral_code}`,
      downline: Array.from({ length: Math.min(base.total_referrals, 10) }, (_, i) => ({
        id: `dl-${i}`,
        user_name: NAMES[(i + 3) % 10],
        tier_name: ['Standard', 'Standard', 'VIP', 'Standard', 'High Roller'][i % 5],
        scan_count: Math.floor(Math.random() * 30),
        earnings_generated: Math.round(Math.random() * 80 * 100) / 100,
        joined_at: new Date(Date.now() - (10 - i) * 86400000 * 5).toISOString(),
      })),
      payouts: MOCK_PAYOUTS.filter(p => p.affiliate_id === base.id).slice(0, 10),
    }
  }
}

export async function getPayoutBatches(status?: string): Promise<PayoutBatch[]> {
  try {
    const params: Record<string, string> = {}
    if (status) params.status = status
    const { data } = await client.get('/admin/affiliate/payout-batches', { params })
    return data
  } catch {
    let filtered = [...MOCK_BATCHES]
    if (status) filtered = filtered.filter(b => b.status === status)
    return filtered
  }
}

export async function approvePayoutBatch(): Promise<{ approved: number; total_amount: number }> {
  try {
    const { data } = await client.post('/admin/affiliate/payouts/approve-batch')
    return data
  } catch {
    const pending = MOCK_BATCHES.filter(b => b.status === 'pending')
    return { approved: pending.length, total_amount: pending.reduce((s, b) => s + b.total_amount, 0) }
  }
}

export async function executeApprovedPayouts(): Promise<{ executed: number; total_amount: number }> {
  try {
    const { data } = await client.post('/admin/affiliate/payouts/execute-batch')
    return data
  } catch {
    const approved = MOCK_BATCHES.filter(b => b.status === 'approved')
    return { executed: approved.length, total_amount: approved.reduce((s, b) => s + b.total_amount, 0) }
  }
}

export async function getSunsetProgress(): Promise<SunsetProgress> {
  try {
    const { data } = await client.get('/admin/affiliate/sunset')
    return data
  } catch {
    return {
      monthly_volume: 4_230_000,
      rolling_3mo_avg: 3_890_000,
      threshold: 10_000_000,
      percentage: 38.9,
      is_triggered: false,
      triggered_at: null,
    }
  }
}

export async function checkSunset(): Promise<SunsetProgress> {
  try {
    const { data } = await client.post('/admin/affiliate/sunset/check')
    return data
  } catch {
    return getSunsetProgress()
  }
}
