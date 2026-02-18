import type { DashboardStats, ChartDataPoint, ActivityEvent, SystemHealth } from '../types'

function generateDays(count: number, baseValue: number, variance: number, startDate?: Date): ChartDataPoint[] {
  const points: ChartDataPoint[] = []
  const end = startDate || new Date()
  for (let i = count - 1; i >= 0; i--) {
    const date = new Date(end)
    date.setDate(date.getDate() - i)
    points.push({
      date: date.toISOString().split('T')[0],
      value: Math.max(0, Math.round(baseValue + (Math.random() - 0.5) * variance)),
    })
  }
  return points
}

function filterByRange(data: ChartDataPoint[], startDate?: string, endDate?: string): ChartDataPoint[] {
  if (!startDate && !endDate) return data
  return data.filter(d => {
    if (startDate && d.date < startDate) return false
    if (endDate && d.date > endDate) return false
    return true
  })
}

// Dashboard (kept for backward compat)
export async function getDashboardStats(): Promise<DashboardStats> {
  return {
    total_users: 2847,
    users_growth: 12.3,
    todays_scans: 342,
    monthly_revenue: 18420.5,
    revenue_growth: 8.7,
    active_affiliates: 156,
  }
}

export async function getUserGrowth(): Promise<ChartDataPoint[]> {
  return generateDays(30, 45, 30)
}

export async function getScanData(): Promise<ChartDataPoint[]> {
  return generateDays(30, 300, 150)
}

export async function getSalesData(): Promise<ChartDataPoint[]> {
  return generateDays(30, 650, 300)
}

export async function getRecentActivity(): Promise<ActivityEvent[]> {
  return [
    { id: '1', type: 'signup', description: 'New user john@example.com registered', timestamp: new Date(Date.now() - 5 * 60000).toISOString() },
    { id: '2', type: 'scan', description: 'QR code scanned by sarah@example.com', timestamp: new Date(Date.now() - 12 * 60000).toISOString() },
    { id: '3', type: 'order', description: 'Order #1042 placed — $34.99', timestamp: new Date(Date.now() - 18 * 60000).toISOString() },
    { id: '4', type: 'comp', description: 'Comp awarded to mike@example.com — 50 BJAK', timestamp: new Date(Date.now() - 25 * 60000).toISOString() },
    { id: '5', type: 'signup', description: 'New user lisa@example.com registered', timestamp: new Date(Date.now() - 32 * 60000).toISOString() },
    { id: '6', type: 'scan', description: '3 QR codes scanned by alex@example.com', timestamp: new Date(Date.now() - 45 * 60000).toISOString() },
    { id: '7', type: 'order', description: 'Order #1041 shipped', timestamp: new Date(Date.now() - 55 * 60000).toISOString() },
    { id: '8', type: 'signup', description: 'New user dave@example.com registered via referral', timestamp: new Date(Date.now() - 70 * 60000).toISOString() },
    { id: '9', type: 'comp', description: 'Reward match — 10.5 BJAK to affiliate #42', timestamp: new Date(Date.now() - 90 * 60000).toISOString() },
    { id: '10', type: 'scan', description: 'QR code scanned by emma@example.com', timestamp: new Date(Date.now() - 120 * 60000).toISOString() },
  ]
}

export async function getSystemHealth(): Promise<SystemHealth> {
  return { api: 'healthy', database: 'healthy', websocket: 'healthy' }
}

// ── Analytics: Users Tab ──

export interface UserAnalytics {
  daily_signups: ChartDataPoint[]
  daily_active: ChartDataPoint[]
  total_users: number
  new_this_month: number
  churn_rate: number
  avg_session_minutes: number
  tier_distribution: { tier: string; count: number }[]
}

export async function getUserAnalytics(startDate?: string, endDate?: string): Promise<UserAnalytics> {
  const signups = filterByRange(generateDays(90, 45, 30), startDate, endDate)
  const active = filterByRange(generateDays(90, 820, 200), startDate, endDate)
  return {
    daily_signups: signups,
    daily_active: active,
    total_users: 2847,
    new_this_month: 342,
    churn_rate: 3.2,
    avg_session_minutes: 8.4,
    tier_distribution: [
      { tier: 'Standard', count: 1842 },
      { tier: 'VIP', count: 623 },
      { tier: 'High Roller', count: 298 },
      { tier: 'Whale', count: 84 },
    ],
  }
}

// ── Analytics: Sales Tab ──

export interface SalesAnalytics {
  daily_revenue: ChartDataPoint[]
  daily_units: ChartDataPoint[]
  total_revenue: number
  total_orders: number
  avg_order_value: number
  conversion_rate: number
  top_products: { product_name: string; units_sold: number; revenue: number }[]
}

export async function getSalesAnalytics(startDate?: string, endDate?: string): Promise<SalesAnalytics> {
  const revenue = filterByRange(generateDays(90, 650, 300), startDate, endDate)
  const units = filterByRange(generateDays(90, 42, 20), startDate, endDate)
  return {
    daily_revenue: revenue,
    daily_units: units,
    total_revenue: 184_205.40,
    total_orders: 4_231,
    avg_order_value: 43.54,
    conversion_rate: 12.8,
    top_products: [
      { product_name: 'BlakJak Original (6ct)', units_sold: 1245, revenue: 37_350.00 },
      { product_name: 'BlakJak Mint (6ct)', units_sold: 1102, revenue: 33_060.00 },
      { product_name: 'BlakJak Wintergreen (6ct)', units_sold: 987, revenue: 29_610.00 },
      { product_name: 'BlakJak Cinnamon (6ct)', units_sold: 876, revenue: 26_280.00 },
      { product_name: 'BlakJak Variety Pack (12ct)', units_sold: 654, revenue: 32_700.00 },
      { product_name: 'BlakJak Coffee (6ct)', units_sold: 543, revenue: 16_290.00 },
      { product_name: 'BlakJak Citrus (6ct)', units_sold: 421, revenue: 12_630.00 },
      { product_name: 'BlakJak Berry (6ct)', units_sold: 398, revenue: 11_940.00 },
    ],
  }
}

// ── Analytics: Scans Tab ──

export interface ScanAnalytics {
  daily_scans: ChartDataPoint[]
  total_scans: number
  scans_today: number
  avg_scans_per_user: number
  peak_hour: string
  scans_by_product: { product: string; count: number }[]
  tier_advancements: { from_tier: string; to_tier: string; count: number }[]
}

export async function getScanAnalytics(startDate?: string, endDate?: string): Promise<ScanAnalytics> {
  const scans = filterByRange(generateDays(90, 300, 150), startDate, endDate)
  return {
    daily_scans: scans,
    total_scans: 87_432,
    scans_today: 342,
    avg_scans_per_user: 30.7,
    peak_hour: '2:00 PM',
    scans_by_product: [
      { product: 'Original', count: 18_420 },
      { product: 'Mint', count: 16_230 },
      { product: 'Wintergreen', count: 14_105 },
      { product: 'Cinnamon', count: 12_340 },
      { product: 'Coffee', count: 9_870 },
      { product: 'Citrus', count: 8_430 },
      { product: 'Berry', count: 8_037 },
    ],
    tier_advancements: [
      { from_tier: 'Standard', to_tier: 'VIP', count: 87 },
      { from_tier: 'VIP', to_tier: 'High Roller', count: 34 },
      { from_tier: 'High Roller', to_tier: 'Whale', count: 12 },
    ],
  }
}

// ── Analytics: Comps & Treasury Tab ──

export interface CompTreasuryAnalytics {
  daily_comps: { date: string; crypto: number; casino: number; trip: number; guaranteed: number }[]
  total_comps: number
  total_value: number
  avg_comp_value: number
  largest_comp: number
  pool_balance_trend: { date: string; consumer: number; affiliate: number; wholesale: number }[]
  total_matching_paid: number
  total_pool_distributed: number
}

export async function getCompTreasuryAnalytics(startDate?: string, endDate?: string): Promise<CompTreasuryAnalytics> {
  const now = new Date()
  const days = 90

  const daily_comps = Array.from({ length: days }, (_, i) => {
    const date = new Date(now)
    date.setDate(date.getDate() - (days - 1 - i))
    return {
      date: date.toISOString().split('T')[0],
      crypto: Math.floor(Math.random() * 8) + 1,
      casino: Math.floor(Math.random() * 4),
      trip: Math.random() > 0.85 ? 1 : 0,
      guaranteed: Math.floor(Math.random() * 15) + 5,
    }
  }).filter(d => {
    if (startDate && d.date < startDate) return false
    if (endDate && d.date > endDate) return false
    return true
  })

  const pool_balance_trend = Array.from({ length: days }, (_, i) => {
    const date = new Date(now)
    date.setDate(date.getDate() - (days - 1 - i))
    return {
      date: date.toISOString().split('T')[0],
      consumer: Math.round(100_000 + i * 300 + (Math.random() - 0.5) * 5000),
      affiliate: Math.round(10_000 + i * 30 + (Math.random() - 0.5) * 800),
      wholesale: Math.round(10_000 + i * 30 + (Math.random() - 0.5) * 800),
    }
  }).filter(d => {
    if (startDate && d.date < startDate) return false
    if (endDate && d.date > endDate) return false
    return true
  })

  return {
    daily_comps,
    total_comps: 3_247,
    total_value: 142_830.50,
    avg_comp_value: 43.99,
    largest_comp: 10_000,
    pool_balance_trend,
    total_matching_paid: 28_430.25,
    total_pool_distributed: 8_720.50,
  }
}
