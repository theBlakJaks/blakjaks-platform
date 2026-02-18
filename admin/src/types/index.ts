export interface User {
  id: string
  email: string
  first_name: string
  last_name: string
  tier_id: string | null
  tier_name: string | null
  is_admin: boolean
  is_suspended: boolean
  created_at: string
  scan_count: number
  wallet_balance: number
}

export interface Tier {
  id: string
  name: string
  min_scans: number
}

export interface QRCode {
  id: string
  batch_id: string
  product_id: string
  product_name: string
  code: string
  is_scanned: boolean
  scanned_by: string | null
  scanned_at: string | null
  created_at: string
}

export interface Order {
  id: string
  user_id: string
  user_email: string
  user_name: string
  status: string
  subtotal: number
  shipping_cost: number
  tax: number
  total: number
  items: OrderItem[]
  created_at: string
  updated_at: string
}

export interface OrderItem {
  id: string
  product_id: string
  product_name: string
  quantity: number
  unit_price: number
  total_price: number
}

export interface Comp {
  id: string
  user_id: string
  user_email: string
  user_name: string
  comp_type: string
  amount: number
  reason: string
  status: string
  tx_hash: string | null
  affiliate_match: number | null
  created_at: string
}

export interface CompStats {
  total_awarded: number
  total_value: number
  pending_count: number
  failed_count: number
}

export interface OrderStats {
  total_orders: number
  revenue_today: number
  pending_fulfillment: number
  avg_order_value: number
}

export interface OrderDetail extends Order {
  customer_name: string
  shipping_address: string
  subtotal: number
  shipping_cost: number
  tax: number
  tracking_number: string | null
  timeline: OrderEvent[]
}

export interface OrderEvent {
  id: string
  status: string
  note: string
  timestamp: string
}

export interface Affiliate {
  id: string
  user_id: string
  user_name: string
  user_email: string
  referral_code: string
  total_referrals: number
  total_chips: number
  vaulted_chips: number
  expired_chips: number
  reward_match_total: number
  pool_share_total: number
  permanent_tier: string | null
  referred_tins: number
  created_at: string
}

export interface AffiliateDetail extends Affiliate {
  custom_code: string | null
  referral_link: string
  downline: DownlineMember[]
  payouts: Payout[]
}

export interface DownlineMember {
  id: string
  user_name: string
  tier_name: string
  scan_count: number
  earnings_generated: number
  joined_at: string
}

export interface AffiliateStats {
  total_affiliates: number
  total_paid: number
  pending_count: number
  pending_value: number
  sunset_percentage: number
}

export interface PayoutBatch {
  id: string
  period_start: string
  period_end: string
  affiliate_count: number
  total_amount: number
  status: string
  approved_by: string | null
  executed_at: string | null
}

export interface SunsetProgress {
  monthly_volume: number
  rolling_3mo_avg: number
  threshold: number
  percentage: number
  is_triggered: boolean
  triggered_at: string | null
}

export interface Vote {
  id: string
  title: string
  description: string
  vote_type: string
  options_json: VoteOption[]
  min_tier_required: string
  status: string
  start_date: string
  end_date: string
  created_by: string
  total_ballots: number
  created_at: string
}

export interface VoteOption {
  id: string
  label: string
}

export interface VoteResult {
  option_id: string
  label: string
  count: number
  percentage: number
}

export interface ChatReport {
  id: string
  reporter_id: string
  reporter_name: string
  reporter_email: string
  reported_user_id: string
  reported_user_name: string
  reported_user_email: string
  message_id: string
  message_content: string
  channel_name: string
  reason: string
  status: string
  created_at: string
}

export interface SocialStats {
  pending_reports: number
  active_mutes: number
  banned_users: number
}

export interface ModerationLogEntry {
  id: string
  admin_name: string
  action: string
  target_user: string
  channel: string
  details: string
  timestamp: string
}

export interface Proposal {
  id: string
  user_id: string
  user_name: string
  user_email: string
  title: string
  description: string
  proposed_vote_type: string
  proposed_options: VoteOption[] | null
  status: string
  admin_notes: string | null
  created_at: string
}

export interface PoolBalance {
  pool_name: string
  address: string
  usdt_balance: number
  matic_balance: number
  allocation_pct: number
}

export interface TreasuryTransaction {
  id: string
  pool_name: string
  direction: 'in' | 'out'
  amount: number
  address: string
  tx_hash: string
  reason: string
  timestamp: string
}

export interface DashboardStats {
  total_users: number
  users_growth: number
  todays_scans: number
  monthly_revenue: number
  revenue_growth: number
  active_affiliates: number
}

export interface ChartDataPoint {
  date: string
  value: number
}

export interface ActivityEvent {
  id: string
  type: 'signup' | 'scan' | 'order' | 'comp'
  description: string
  timestamp: string
}

export interface SystemHealth {
  api: 'healthy' | 'degraded' | 'down'
  database: 'healthy' | 'degraded' | 'down'
  websocket: 'healthy' | 'degraded' | 'down'
}

export interface Payout {
  id: string
  affiliate_id: string
  affiliate_email: string
  amount: number
  payout_type: string
  period_start: string
  period_end: string
  status: string
  tx_hash: string | null
  created_at: string
}
