export interface AffiliateMember {
  id: string
  email: string
  first_name: string
  last_name_initial: string
  username: string
  tier: 'Member' | 'VIP' | 'High Roller' | 'Whale'
  permanent_tier: string | null
  lifetime_earnings: number
  pending_payout: number
  referral_code: string
  custom_code: string | null
  wallet_address: string | null
  created_at: string
}

export interface AuthTokens {
  access_token: string
  refresh_token: string
}

export interface DashboardStats {
  lifetime_earnings: number
  this_month: number
  last_month: number
  pending_payout: number
  next_payout_date: string
  downline_total: number
  downline_active: number
  conversion_rate: number
  total_clicks: number
  total_signups: number
}

export interface MonthlyEarning {
  month: string
  amount: number
}

export interface ActivityItem {
  id: string
  description: string
  amount: number
  timestamp: string
}

export interface ReferralLink {
  url: string
  code: string
  custom_code: string | null
  total_clicks: number
  total_signups: number
  conversion_rate: number
}

export interface DownlineMember {
  id: string
  name: string
  tier: string
  total_scans: number
  earnings_generated: number
  status: 'active' | 'inactive'
  joined_at: string
}

export interface DownlineDetail {
  id: string
  name: string
  tier: string
  status: 'active' | 'inactive'
  joined_at: string
  total_scans: number
  total_tins_purchased: number
  current_tier: string
  match_earnings: number
  pool_earnings: number
  permanent_tier_progress: {
    vip: { required: number; current: number; unlocked: boolean }
    high_roller: { required: number; current: number; unlocked: boolean }
    whale: { required: number; current: number; unlocked: boolean }
  }
  recent_activity: { id: string; type: string; description: string; timestamp: string }[]
}

export interface ChipStats {
  total_earned: number
  in_vault: number
  vault_bonus: number
  expiring_soon: number
}

export interface VaultEntry {
  id: string
  date_vaulted: string
  amount: number
  bonus_earned: number
  expiry_date: string
  status: 'active' | 'expired' | 'withdrawn'
}

export interface ChipHistoryEntry {
  id: string
  date: string
  type: 'referral_scan' | 'vault_bonus' | 'pool_distribution'
  amount: number
  vaulted: boolean
}

export interface WeeklyPoolInfo {
  pool_amount: number
  total_chips_circulation: number
  your_chips: number
  your_share_estimate: number
}

export interface Payout {
  id: string
  date: string
  amount: number
  status: 'pending_approval' | 'approved' | 'processing' | 'completed' | 'failed'
  tx_hash: string | null
  earnings_count: number
}

export interface PayoutDetail extends Payout {
  earnings: { id: string; type: string; referral_name: string; amount: number; date: string }[]
}

export interface AffiliateSettings {
  wallet_address: string | null
  notifications: {
    weekly_summary: boolean
    referral_signup: boolean
    payout_confirmation: boolean
    sunset_alerts: boolean
  }
  payout_mode: 'auto' | 'manual'
}

export interface SunsetStatus {
  monthly_volume: number
  rolling_3mo_avg: number
  threshold: number
  percentage: number
  is_triggered: boolean
  triggered_at: string | null
}
