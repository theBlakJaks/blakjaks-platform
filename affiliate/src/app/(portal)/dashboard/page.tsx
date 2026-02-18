'use client'

import { useEffect, useState } from 'react'
import { DollarSign, TrendingUp, Clock, Users, MousePointerClick, Copy, Check, QrCode } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import StatCard from '@/components/StatCard'
import Spinner from '@/components/Spinner'
import { useAuth } from '@/lib/auth-context'
import { getDashboardStats, getMonthlyEarnings, getRecentActivity } from '@/lib/api'
import { formatCurrency, formatNumber, formatDate, formatDateTime } from '@/lib/utils'
import type { DashboardStats, MonthlyEarning, ActivityItem } from '@/lib/types'

export default function DashboardPage() {
  const { member } = useAuth()
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [monthly, setMonthly] = useState<MonthlyEarning[]>([])
  const [activity, setActivity] = useState<ActivityItem[]>([])
  const [loading, setLoading] = useState(true)
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    Promise.all([getDashboardStats(), getMonthlyEarnings(), getRecentActivity()])
      .then(([s, m, a]) => { setStats(s); setMonthly(m); setActivity(a) })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !stats) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  const monthChange = stats.last_month > 0 ? ((stats.this_month - stats.last_month) / stats.last_month * 100).toFixed(1) : '0'
  const isUp = Number(monthChange) >= 0
  const refUrl = `https://blakjaks.com/r/${member?.custom_code || member?.referral_code || ''}`

  const handleCopy = () => { navigator.clipboard.writeText(refUrl); setCopied(true); setTimeout(() => setCopied(false), 2000) }

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatCard icon={DollarSign} label="Lifetime Earnings" value={formatCurrency(stats.lifetime_earnings)} />
        <StatCard icon={TrendingUp} label="This Month" value={formatCurrency(stats.this_month)} sub={`${isUp ? '+' : ''}${monthChange}% vs last month`} />
        <StatCard icon={Clock} label="Pending Payout" value={formatCurrency(stats.pending_payout)} sub={`Next: ${formatDate(stats.next_payout_date)}`} />
        <StatCard icon={Users} label="Downline" value={`${stats.downline_active} / ${stats.downline_total}`} sub="Active / Total" />
        <StatCard icon={MousePointerClick} label="Conversion Rate" value={`${stats.conversion_rate}%`} sub={`${formatNumber(stats.total_signups)} signups`} />
      </div>

      {/* Referral Link Card */}
      <div className="flex items-center justify-between rounded-2xl border border-[var(--color-gold)]/30 bg-[var(--color-gold)]/5 px-6 py-4">
        <div>
          <p className="text-xs text-[var(--color-text-muted)]">Your Referral Link</p>
          <p className="mt-1 font-mono text-sm text-[var(--color-gold)]">{refUrl}</p>
        </div>
        <div className="flex gap-2">
          <button onClick={handleCopy} className="flex items-center gap-1.5 rounded-xl border border-[var(--color-gold)]/50 px-3 py-2 text-xs font-medium text-[var(--color-gold)] hover:bg-[var(--color-gold)]/10">
            {copied ? <Check size={14} /> : <Copy size={14} />} {copied ? 'Copied!' : 'Copy'}
          </button>
          <a href="/referral" className="flex items-center gap-1.5 rounded-xl border border-[var(--color-border)] px-3 py-2 text-xs font-medium text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)]">
            <QrCode size={14} /> QR Code
          </a>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Earnings Chart */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-4 text-sm font-semibold text-white">Monthly Earnings</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={monthly}>
              <CartesianGrid strokeDasharray="3 3" stroke="#27272A" />
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#A1A1AA' }} stroke="#3F3F46" />
              <YAxis tick={{ fontSize: 12, fill: '#A1A1AA' }} stroke="#3F3F46" tickFormatter={v => `$${v}`} />
              <Tooltip contentStyle={{ background: '#18181B', border: '1px solid #27272A', borderRadius: '12px', color: '#FAFAFA' }} formatter={(v) => [`$${v}`, 'Earnings']} />
              <Bar dataKey="amount" fill="#D4AF37" radius={[6, 6, 0, 0]} name="Earnings" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Recent Activity */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-4 text-sm font-semibold text-white">Recent Activity</h3>
          <div className="space-y-3">
            {activity.map(a => (
              <div key={a.id} className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
                <div>
                  <p className="text-sm text-white">{a.description}</p>
                  <p className="text-xs text-[var(--color-text-dim)]">{formatDateTime(a.timestamp)}</p>
                </div>
                {a.amount > 0 && <span className="font-mono text-sm font-medium text-[var(--color-gold)]">+{formatCurrency(a.amount)}</span>}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
