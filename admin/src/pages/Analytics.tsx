import { useCallback, useEffect, useState } from 'react'
import { Download, Users, DollarSign, ScanLine, Gift } from 'lucide-react'
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend,
} from 'recharts'
import StatsCard from '../components/StatsCard'
import LoadingSpinner from '../components/LoadingSpinner'
import { formatCurrency, formatNumber } from '../utils/formatters'
import {
  getUserAnalytics, getSalesAnalytics, getScanAnalytics, getCompTreasuryAnalytics,
  type UserAnalytics, type SalesAnalytics, type ScanAnalytics, type CompTreasuryAnalytics,
} from '../api/analytics'

const TABS = ['Users', 'Sales', 'Scans', 'Comps & Treasury'] as const
type Tab = typeof TABS[number]

const PRESETS = [
  { label: 'Today', days: 0 },
  { label: 'This Week', days: 7 },
  { label: 'This Month', days: 30 },
  { label: 'This Quarter', days: 90 },
  { label: 'Custom', days: -1 },
] as const

const TIER_COLORS = ['#ef4444', '#94a3b8', '#f59e0b', '#cbd5e1']
const POOL_LINE_COLORS = { consumer: '#6366f1', affiliate: '#a855f7', wholesale: '#f59e0b' }
const COMP_COLORS = { crypto: '#6366f1', casino: '#f59e0b', trip: '#a855f7', guaranteed: '#10b981' }

const CHART_STYLE = { borderRadius: '8px', border: '1px solid #e2e8f0' }
const AXIS_PROPS = { tick: { fontSize: 12 }, stroke: '#94a3b8' }
const GRID_PROPS = { strokeDasharray: '3 3' as const, stroke: '#f1f5f9' }

function dateFmt(d: string) { return d.slice(5) }

function exportCsv(filename: string, headers: string[], rows: (string | number)[][]) {
  const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = filename
  a.click()
  URL.revokeObjectURL(a.href)
}

export default function Analytics() {
  const [tab, setTab] = useState<Tab>('Users')
  const [preset, setPreset] = useState<string>('This Month')
  const [customStart, setCustomStart] = useState('')
  const [customEnd, setCustomEnd] = useState('')
  const [loading, setLoading] = useState(true)

  const [userData, setUserData] = useState<UserAnalytics | null>(null)
  const [salesData, setSalesData] = useState<SalesAnalytics | null>(null)
  const [scanData, setScanData] = useState<ScanAnalytics | null>(null)
  const [compData, setCompData] = useState<CompTreasuryAnalytics | null>(null)

  const getRange = useCallback((): [string | undefined, string | undefined] => {
    if (preset === 'Custom') return [customStart || undefined, customEnd || undefined]
    const p = PRESETS.find(pr => pr.label === preset)
    if (!p || p.days <= 0) return [undefined, undefined]
    const end = new Date()
    const start = new Date()
    start.setDate(end.getDate() - p.days)
    return [start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
  }, [preset, customStart, customEnd])

  const fetchData = useCallback(async () => {
    setLoading(true)
    const [s, e] = getRange()
    if (tab === 'Users') setUserData(await getUserAnalytics(s, e))
    else if (tab === 'Sales') setSalesData(await getSalesAnalytics(s, e))
    else if (tab === 'Scans') setScanData(await getScanAnalytics(s, e))
    else setCompData(await getCompTreasuryAnalytics(s, e))
    setLoading(false)
  }, [tab, getRange])

  useEffect(() => { fetchData() }, [fetchData])

  const handleExportCsv = () => {
    if (tab === 'Users' && userData) {
      exportCsv('users_analytics.csv', ['Date', 'Signups', 'Active Users'], userData.daily_signups.map((d, i) => [d.date, d.value, userData.daily_active[i]?.value ?? 0]))
    } else if (tab === 'Sales' && salesData) {
      exportCsv('sales_analytics.csv', ['Date', 'Revenue', 'Units Sold'], salesData.daily_revenue.map((d, i) => [d.date, d.value, salesData.daily_units[i]?.value ?? 0]))
    } else if (tab === 'Scans' && scanData) {
      exportCsv('scans_analytics.csv', ['Date', 'Scans'], scanData.daily_scans.map(d => [d.date, d.value]))
    } else if (tab === 'Comps & Treasury' && compData) {
      exportCsv('comps_treasury_analytics.csv', ['Date', 'Crypto', 'Casino', 'Trip', 'Guaranteed'], compData.daily_comps.map(d => [d.date, d.crypto, d.casino, d.trip, d.guaranteed]))
    }
  }

  return (
    <div className="space-y-6">
      {/* Date Range Picker */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex gap-1 rounded-lg border border-slate-200 bg-white p-1">
          {PRESETS.map(p => (
            <button key={p.label} onClick={() => setPreset(p.label)} className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${preset === p.label ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-100'}`}>
              {p.label}
            </button>
          ))}
        </div>
        {preset === 'Custom' && (
          <div className="flex items-center gap-2">
            <input type="date" value={customStart} onChange={e => setCustomStart(e.target.value)} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm outline-none" />
            <span className="text-slate-400">to</span>
            <input type="date" value={customEnd} onChange={e => setCustomEnd(e.target.value)} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm outline-none" />
          </div>
        )}
        <button onClick={handleExportCsv} className="ml-auto flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">
          <Download size={16} /> Export CSV
        </button>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-200">
        <nav className="-mb-px flex gap-6">
          {TABS.map(t => (
            <button key={t} onClick={() => setTab(t)} className={`border-b-2 pb-3 text-sm font-medium transition-colors ${tab === t ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700'}`}>
              {t}
            </button>
          ))}
        </nav>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
      ) : (
        <>
          {/* Users Tab */}
          {tab === 'Users' && userData && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
                <StatsCard icon={Users} label="Total Users" value={formatNumber(userData.total_users)} />
                <StatsCard icon={Users} label="New This Month" value={String(userData.new_this_month)} />
                <StatsCard icon={Users} label="Churn Rate" value={`${userData.churn_rate}%`} />
                <StatsCard icon={Users} label="Avg Session" value={`${userData.avg_session_minutes} min`} />
              </div>

              <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Daily Signups</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <LineChart data={userData.daily_signups}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} />
                      <Tooltip labelFormatter={(d) => String(d)} contentStyle={CHART_STYLE} />
                      <Line type="monotone" dataKey="value" stroke="#4f46e5" strokeWidth={2} dot={false} name="Signups" />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Daily Active Users</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <LineChart data={userData.daily_active}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} />
                      <Tooltip labelFormatter={(d) => String(d)} contentStyle={CHART_STYLE} />
                      <Line type="monotone" dataKey="value" stroke="#10b981" strokeWidth={2} dot={false} name="Active Users" />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">Tier Distribution</h3>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie data={userData.tier_distribution} dataKey="count" nameKey="tier" cx="50%" cy="50%" outerRadius={100} label={(props) => `${props.name}: ${props.value}`}>
                      {userData.tier_distribution.map((_, i) => <Cell key={i} fill={TIER_COLORS[i % TIER_COLORS.length]} />)}
                    </Pie>
                    <Tooltip contentStyle={CHART_STYLE} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}

          {/* Sales Tab */}
          {tab === 'Sales' && salesData && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
                <StatsCard icon={DollarSign} label="Total Revenue" value={formatCurrency(salesData.total_revenue)} />
                <StatsCard icon={DollarSign} label="Total Orders" value={formatNumber(salesData.total_orders)} />
                <StatsCard icon={DollarSign} label="Avg Order Value" value={formatCurrency(salesData.avg_order_value)} />
                <StatsCard icon={DollarSign} label="Conversion Rate" value={`${salesData.conversion_rate}%`} />
              </div>

              <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Daily Revenue</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <LineChart data={salesData.daily_revenue}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} tickFormatter={(v) => `$${v}`} />
                      <Tooltip labelFormatter={(d) => String(d)} formatter={(v) => [`$${v}`, 'Revenue']} contentStyle={CHART_STYLE} />
                      <Line type="monotone" dataKey="value" stroke="#4f46e5" strokeWidth={2} dot={false} />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Units Sold Per Day</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <BarChart data={salesData.daily_units}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} />
                      <Tooltip labelFormatter={(d) => String(d)} contentStyle={CHART_STYLE} />
                      <Bar dataKey="value" fill="#818cf8" radius={[4, 4, 0, 0]} name="Units" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">Top Products</h3>
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-slate-100 bg-slate-50">
                      <th className="px-4 py-3 font-medium text-slate-600">#</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Product</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Units Sold</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Revenue</th>
                    </tr>
                  </thead>
                  <tbody>
                    {salesData.top_products.map((p, i) => (
                      <tr key={p.product_name} className="border-b border-slate-50 hover:bg-slate-50">
                        <td className="px-4 py-3 text-slate-400">{i + 1}</td>
                        <td className="px-4 py-3 font-medium text-slate-900">{p.product_name}</td>
                        <td className="px-4 py-3 text-slate-700">{p.units_sold.toLocaleString()}</td>
                        <td className="px-4 py-3 font-medium text-slate-900">{formatCurrency(p.revenue)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Scans Tab */}
          {tab === 'Scans' && scanData && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
                <StatsCard icon={ScanLine} label="Total Scans" value={formatNumber(scanData.total_scans)} />
                <StatsCard icon={ScanLine} label="Scans Today" value={String(scanData.scans_today)} />
                <StatsCard icon={ScanLine} label="Avg Scans/User" value={String(scanData.avg_scans_per_user)} />
                <StatsCard icon={ScanLine} label="Peak Hour" value={scanData.peak_hour} />
              </div>

              <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Daily Scans</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <LineChart data={scanData.daily_scans}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} />
                      <Tooltip labelFormatter={(d) => String(d)} contentStyle={CHART_STYLE} />
                      <Line type="monotone" dataKey="value" stroke="#10b981" strokeWidth={2} dot={false} name="Scans" />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Scans by Product</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <BarChart data={scanData.scans_by_product} layout="vertical">
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis type="number" {...AXIS_PROPS} />
                      <YAxis type="category" dataKey="product" {...AXIS_PROPS} width={90} />
                      <Tooltip contentStyle={CHART_STYLE} />
                      <Bar dataKey="count" fill="#6366f1" radius={[0, 4, 4, 0]} name="Scans" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">Tier Advancements This Quarter</h3>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                  {scanData.tier_advancements.map(a => (
                    <div key={`${a.from_tier}-${a.to_tier}`} className="rounded-lg bg-slate-50 p-4 text-center">
                      <p className="text-xs text-slate-500">{a.from_tier} → {a.to_tier}</p>
                      <p className="text-3xl font-bold text-indigo-600">{a.count}</p>
                      <p className="text-xs text-slate-400">users advanced</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Comps & Treasury Tab */}
          {tab === 'Comps & Treasury' && compData && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
                <StatsCard icon={Gift} label="Total Comps" value={formatNumber(compData.total_comps)} />
                <StatsCard icon={Gift} label="Total Value" value={formatCurrency(compData.total_value)} />
                <StatsCard icon={Gift} label="Avg Comp Value" value={formatCurrency(compData.avg_comp_value)} />
                <StatsCard icon={Gift} label="Largest Comp" value={formatCurrency(compData.largest_comp)} />
              </div>

              <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Comps Awarded Per Day</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <LineChart data={compData.daily_comps}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} />
                      <Tooltip labelFormatter={(d) => String(d)} contentStyle={CHART_STYLE} />
                      <Line type="monotone" dataKey="crypto" stroke={COMP_COLORS.crypto} strokeWidth={2} dot={false} name="Crypto" />
                      <Line type="monotone" dataKey="casino" stroke={COMP_COLORS.casino} strokeWidth={2} dot={false} name="Casino" />
                      <Line type="monotone" dataKey="trip" stroke={COMP_COLORS.trip} strokeWidth={2} dot={false} name="Trip" />
                      <Line type="monotone" dataKey="guaranteed" stroke={COMP_COLORS.guaranteed} strokeWidth={2} dot={false} name="Guaranteed" />
                      <Legend />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Pool Balance Trend</h3>
                  <ResponsiveContainer width="100%" height={264}>
                    <LineChart data={compData.pool_balance_trend}>
                      <CartesianGrid {...GRID_PROPS} />
                      <XAxis dataKey="date" tickFormatter={dateFmt} {...AXIS_PROPS} />
                      <YAxis {...AXIS_PROPS} tickFormatter={(v) => `$${(v / 1000).toFixed(0)}K`} />
                      <Tooltip labelFormatter={(d) => String(d)} formatter={(v) => [`$${Number(v).toLocaleString()}`, '']} contentStyle={CHART_STYLE} />
                      <Line type="monotone" dataKey="consumer" stroke={POOL_LINE_COLORS.consumer} strokeWidth={2} dot={false} name="Consumer" />
                      <Line type="monotone" dataKey="affiliate" stroke={POOL_LINE_COLORS.affiliate} strokeWidth={2} dot={false} name="Affiliate" />
                      <Line type="monotone" dataKey="wholesale" stroke={POOL_LINE_COLORS.wholesale} strokeWidth={2} dot={false} name="Wholesale" />
                      <Legend />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-2 text-sm font-semibold text-slate-700">Total Reward Matching Paid</h3>
                  <p className="text-3xl font-bold text-indigo-600">{formatCurrency(compData.total_matching_paid)}</p>
                </div>
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-2 text-sm font-semibold text-slate-700">Total Pool Share Distributed</h3>
                  <p className="text-3xl font-bold text-purple-600">{formatCurrency(compData.total_pool_distributed)}</p>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
