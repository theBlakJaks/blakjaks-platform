import { Users, ScanLine, DollarSign, Network, Activity, Server } from 'lucide-react'
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import StatsCard from '../components/StatsCard'
import LoadingSpinner from '../components/LoadingSpinner'
import { useApi } from '../hooks/useApi'
import { getDashboardStats, getUserGrowth, getScanData, getRecentActivity, getSystemHealth } from '../api/analytics'
import { formatCurrency, formatNumber, formatDateTime } from '../utils/formatters'
import { HEALTH_COLORS } from '../utils/constants'
import type { DashboardStats as DashboardStatsType, ChartDataPoint, ActivityEvent, SystemHealth } from '../types'

const EVENT_ICONS: Record<string, string> = {
  signup: 'text-indigo-500',
  scan: 'text-emerald-500',
  order: 'text-amber-500',
  comp: 'text-purple-500',
}

export default function Dashboard() {
  const { data: stats, loading: statsLoading } = useApi<DashboardStatsType>(getDashboardStats)
  const { data: userGrowth, loading: ugLoading } = useApi<ChartDataPoint[]>(getUserGrowth)
  const { data: scanData, loading: sdLoading } = useApi<ChartDataPoint[]>(getScanData)
  const { data: activity, loading: actLoading } = useApi<ActivityEvent[]>(getRecentActivity)
  const { data: health, loading: hlLoading } = useApi<SystemHealth>(getSystemHealth)

  if (statsLoading) {
    return (
      <div className="flex items-center justify-center py-16">
        <LoadingSpinner />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
        <StatsCard
          icon={Users}
          label="Total Users"
          value={formatNumber(stats?.total_users ?? 0)}
          trend={stats?.users_growth}
        />
        <StatsCard
          icon={ScanLine}
          label="Today's Scans"
          value={formatNumber(stats?.todays_scans ?? 0)}
        />
        <StatsCard
          icon={DollarSign}
          label="Revenue This Month"
          value={formatCurrency(stats?.monthly_revenue ?? 0)}
          trend={stats?.revenue_growth}
        />
        <StatsCard
          icon={Network}
          label="Active Affiliates"
          value={formatNumber(stats?.active_affiliates ?? 0)}
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">User Signups (Last 30 Days)</h3>
          {ugLoading ? (
            <div className="flex h-64 items-center justify-center"><LoadingSpinner /></div>
          ) : (
            <ResponsiveContainer width="100%" height={264}>
              <LineChart data={userGrowth ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis
                  dataKey="date"
                  tickFormatter={(d: string) => d.slice(5)}
                  tick={{ fontSize: 12 }}
                  stroke="#94a3b8"
                />
                <YAxis tick={{ fontSize: 12 }} stroke="#94a3b8" />
                <Tooltip
                  labelFormatter={(d) => String(d)}
                  contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0' }}
                />
                <Line type="monotone" dataKey="value" stroke="#4f46e5" strokeWidth={2} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">Scans per Day (Last 30 Days)</h3>
          {sdLoading ? (
            <div className="flex h-64 items-center justify-center"><LoadingSpinner /></div>
          ) : (
            <ResponsiveContainer width="100%" height={264}>
              <BarChart data={scanData ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis
                  dataKey="date"
                  tickFormatter={(d: string) => d.slice(5)}
                  tick={{ fontSize: 12 }}
                  stroke="#94a3b8"
                />
                <YAxis tick={{ fontSize: 12 }} stroke="#94a3b8" />
                <Tooltip
                  labelFormatter={(d) => String(d)}
                  contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0' }}
                />
                <Bar dataKey="value" fill="#818cf8" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent Activity */}
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">Recent Activity</h3>
          {actLoading ? (
            <div className="flex h-48 items-center justify-center"><LoadingSpinner /></div>
          ) : (
            <div className="space-y-3">
              {activity?.map((event) => (
                <div key={event.id} className="flex items-start gap-3">
                  <div className={`mt-0.5 ${EVENT_ICONS[event.type] || 'text-slate-400'}`}>
                    <Activity size={16} />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm text-slate-700">{event.description}</p>
                    <p className="text-xs text-slate-400">{formatDateTime(event.timestamp)}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* System Health */}
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">System Health</h3>
          {hlLoading ? (
            <div className="flex h-48 items-center justify-center"><LoadingSpinner /></div>
          ) : (
            <div className="space-y-4">
              {health && Object.entries(health).map(([key, status]) => (
                <div key={key} className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-3">
                  <div className="flex items-center gap-3">
                    <Server size={18} className="text-slate-500" />
                    <span className="text-sm font-medium capitalize text-slate-700">{key}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`h-2.5 w-2.5 rounded-full ${
                      status === 'healthy' ? 'bg-emerald-500' :
                      status === 'degraded' ? 'bg-amber-500' : 'bg-red-500'
                    }`} />
                    <span className={`text-sm font-medium capitalize ${HEALTH_COLORS[status]}`}>
                      {status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
