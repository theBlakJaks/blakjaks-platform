import { getNextSunday } from './utils'
import type {
  AffiliateMember, DashboardStats, MonthlyEarning, ActivityItem, ReferralLink,
  DownlineMember, DownlineDetail, ChipStats, VaultEntry, ChipHistoryEntry,
  WeeklyPoolInfo, Payout, PayoutDetail, AffiliateSettings, SunsetStatus,
} from './types'

export const MOCK_MEMBER: AffiliateMember = {
  id: 'aff-001',
  email: 'marcus@example.com',
  first_name: 'Marcus',
  last_name_initial: 'J',
  username: 'marcusj',
  tier: 'High Roller',
  permanent_tier: 'VIP',
  lifetime_earnings: 8_742.50,
  pending_payout: 312.80,
  referral_code: 'MARCUSJ',
  custom_code: null,
  wallet_address: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38',
  created_at: '2024-03-15T10:00:00Z',
}

export const MOCK_DASHBOARD: DashboardStats = {
  lifetime_earnings: 8_742.50,
  this_month: 1_245.30,
  last_month: 980.20,
  pending_payout: 312.80,
  next_payout_date: getNextSunday(),
  downline_total: 47,
  downline_active: 38,
  conversion_rate: 14.2,
  total_clicks: 2_340,
  total_signups: 332,
}

export const MOCK_MONTHLY_EARNINGS: MonthlyEarning[] = [
  { month: 'Sep', amount: 720 },
  { month: 'Oct', amount: 890 },
  { month: 'Nov', amount: 1_120 },
  { month: 'Dec', amount: 1_340 },
  { month: 'Jan', amount: 980 },
  { month: 'Feb', amount: 1_245 },
]

export const MOCK_ACTIVITY: ActivityItem[] = [
  { id: 'act-1', description: 'Sarah J. scanned — you earned $4.20', amount: 4.20, timestamp: new Date(Date.now() - 2 * 3600000).toISOString() },
  { id: 'act-2', description: 'Mike T. won $100 comp — you earned $21.00', amount: 21.00, timestamp: new Date(Date.now() - 5 * 3600000).toISOString() },
  { id: 'act-3', description: 'Emma G. scanned — you earned $4.20', amount: 4.20, timestamp: new Date(Date.now() - 8 * 3600000).toISOString() },
  { id: 'act-4', description: 'Lisa B. signed up via your link', amount: 0, timestamp: new Date(Date.now() - 12 * 3600000).toISOString() },
  { id: 'act-5', description: 'Dave M. won $50 comp — you earned $10.50', amount: 10.50, timestamp: new Date(Date.now() - 18 * 3600000).toISOString() },
]

export const MOCK_REFERRAL_LINK: ReferralLink = {
  url: 'https://blakjaks.com/r/MARCUSJ',
  code: 'MARCUSJ',
  custom_code: null,
  total_clicks: 2_340,
  total_signups: 332,
  conversion_rate: 14.2,
}

const NAMES = ['Sarah J.', 'Mike T.', 'Emma G.', 'Lisa B.', 'Dave M.', 'Alex K.', 'Nina D.', 'Tom R.', 'Zoe W.', 'Chris P.', 'Amy L.', 'Jake S.', 'Mia C.', 'Ethan F.', 'Olivia H.', 'Noah A.', 'Sophia V.']
const TIERS: DownlineMember['tier'][] = ['Member', 'Member', 'VIP', 'Member', 'High Roller', 'Member', 'VIP', 'Member', 'Whale', 'Member', 'VIP', 'Member', 'Member', 'High Roller', 'VIP', 'Member', 'Member']

export const MOCK_DOWNLINE: DownlineMember[] = Array.from({ length: 17 }, (_, i) => ({
  id: `dl-${String(i + 1).padStart(3, '0')}`,
  name: NAMES[i],
  tier: TIERS[i],
  total_scans: Math.floor(Math.random() * 120) + 5,
  earnings_generated: Math.round((Math.random() * 400 + 10) * 100) / 100,
  status: (i === 3 || i === 11 ? 'inactive' : 'active') as 'active' | 'inactive',
  joined_at: new Date(Date.now() - (17 - i) * 14 * 86400000).toISOString(),
}))

export function getMockDownlineDetail(id: string): DownlineDetail {
  const member = MOCK_DOWNLINE.find(m => m.id === id) || MOCK_DOWNLINE[0]
  const tins = Math.floor(Math.random() * 500) + 20
  return {
    id: member.id,
    name: member.name,
    tier: member.tier,
    status: member.status,
    joined_at: member.joined_at,
    total_scans: member.total_scans,
    total_tins_purchased: tins,
    current_tier: member.tier,
    match_earnings: Math.round(member.earnings_generated * 0.7 * 100) / 100,
    pool_earnings: Math.round(member.earnings_generated * 0.3 * 100) / 100,
    permanent_tier_progress: {
      vip: { required: 210, current: Math.min(tins, 210), unlocked: tins >= 210 },
      high_roller: { required: 2100, current: Math.min(tins, 2100), unlocked: tins >= 2100 },
      whale: { required: 21000, current: Math.min(tins, 21000), unlocked: tins >= 21000 },
    },
    recent_activity: Array.from({ length: 5 }, (_, j) => ({
      id: `ra-${j}`,
      type: j % 3 === 0 ? 'comp_win' : 'scan',
      description: j % 3 === 0 ? `Won $${(Math.random() * 100 + 10).toFixed(0)} comp` : 'Scanned QR code',
      timestamp: new Date(Date.now() - j * 48 * 3600000).toISOString(),
    })),
  }
}

export const MOCK_CHIP_STATS: ChipStats = {
  total_earned: 1_842,
  in_vault: 620,
  vault_bonus: 37,
  expiring_soon: 12,
}

export const MOCK_VAULT_ENTRIES: VaultEntry[] = Array.from({ length: 6 }, (_, i) => ({
  id: `ve-${i + 1}`,
  date_vaulted: new Date(Date.now() - (6 - i) * 30 * 86400000).toISOString(),
  amount: Math.floor(Math.random() * 80) + 20,
  bonus_earned: Math.floor(Math.random() * 8),
  expiry_date: new Date(Date.now() + (6 + i) * 30 * 86400000).toISOString(),
  status: (i === 0 ? 'expired' : i === 1 ? 'withdrawn' : 'active') as VaultEntry['status'],
}))

export const MOCK_CHIP_HISTORY: ChipHistoryEntry[] = Array.from({ length: 20 }, (_, i) => ({
  id: `ch-${String(i + 1).padStart(3, '0')}`,
  date: new Date(Date.now() - (20 - i) * 2 * 86400000).toISOString(),
  type: (i % 5 === 0 ? 'vault_bonus' : i % 7 === 0 ? 'pool_distribution' : 'referral_scan') as ChipHistoryEntry['type'],
  amount: i % 5 === 0 ? Math.floor(Math.random() * 5) + 1 : i % 7 === 0 ? Math.floor(Math.random() * 20) + 5 : 1,
  vaulted: i % 3 === 0,
}))

export const MOCK_WEEKLY_POOL: WeeklyPoolInfo = {
  pool_amount: 12_450,
  total_chips_circulation: 284_000,
  your_chips: 1_842,
  your_share_estimate: 80.72,
}

const TX_HASHES = Array.from({ length: 8 }, () => `0x${Array.from({ length: 64 }, () => Math.floor(Math.random() * 16).toString(16)).join('')}`)

export const MOCK_PAYOUTS: Payout[] = Array.from({ length: 8 }, (_, i) => ({
  id: `pay-${String(i + 1).padStart(3, '0')}`,
  date: new Date(Date.now() - (8 - i) * 7 * 86400000).toISOString(),
  amount: Math.round((Math.random() * 400 + 50) * 100) / 100,
  status: (i < 1 ? 'pending_approval' : i < 2 ? 'processing' : 'completed') as Payout['status'],
  tx_hash: i >= 2 ? TX_HASHES[i] : null,
  earnings_count: Math.floor(Math.random() * 15) + 3,
}))

export function getMockPayoutDetail(id: string): PayoutDetail {
  const payout = MOCK_PAYOUTS.find(p => p.id === id) || MOCK_PAYOUTS[0]
  return {
    ...payout,
    earnings: Array.from({ length: payout.earnings_count }, (_, j) => ({
      id: `earn-${j}`,
      type: j % 3 === 0 ? '21% match' : 'pool share',
      referral_name: NAMES[j % NAMES.length],
      amount: Math.round((Math.random() * 30 + 2) * 100) / 100,
      date: new Date(new Date(payout.date).getTime() - j * 86400000).toISOString(),
    })),
  }
}

export const MOCK_SETTINGS: AffiliateSettings = {
  wallet_address: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38',
  notifications: {
    weekly_summary: true,
    referral_signup: true,
    payout_confirmation: true,
    sunset_alerts: false,
  },
  payout_mode: 'auto',
}

export const MOCK_SUNSET: SunsetStatus = {
  monthly_volume: 4_230_000,
  rolling_3mo_avg: 3_890_000,
  threshold: 10_000_000,
  percentage: 38.9,
  is_triggered: false,
  triggered_at: null,
}
