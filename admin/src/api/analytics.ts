import type { DashboardStats, ChartDataPoint, ActivityEvent, SystemHealth } from '../types'

function generateLast30Days(baseValue: number, variance: number): ChartDataPoint[] {
  const points: ChartDataPoint[] = []
  const now = new Date()
  for (let i = 29; i >= 0; i--) {
    const date = new Date(now)
    date.setDate(date.getDate() - i)
    points.push({
      date: date.toISOString().split('T')[0],
      value: Math.round(baseValue + (Math.random() - 0.5) * variance),
    })
  }
  return points
}

export async function getDashboardStats(): Promise<DashboardStats> {
  // Mock data - will be replaced with real API calls
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
  return generateLast30Days(45, 30)
}

export async function getScanData(): Promise<ChartDataPoint[]> {
  return generateLast30Days(300, 150)
}

export async function getSalesData(): Promise<ChartDataPoint[]> {
  return generateLast30Days(650, 300)
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
  return {
    api: 'healthy',
    database: 'healthy',
    websocket: 'healthy',
  }
}
