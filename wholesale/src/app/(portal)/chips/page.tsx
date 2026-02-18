'use client'

import { useEffect, useState } from 'react'
import { Coins, TrendingUp, Gift, Lock, CheckCircle } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import StatCard from '@/components/StatCard'
import Spinner from '@/components/Spinner'
import { getChipStats, getMonthlyChips, getMilestones } from '@/lib/api'
import { formatNumber, formatCurrency } from '@/lib/utils'
import type { ChipStats, MonthlyChips, CompMilestone } from '@/lib/types'

const MILESTONE_COLORS: Record<string, string> = {
  Bronze: 'from-amber-700 to-amber-500',
  Silver: 'from-zinc-400 to-zinc-300',
  Gold: 'from-[var(--color-gold-dark)] to-[var(--color-gold-light)]',
  Platinum: 'from-indigo-400 to-indigo-300',
  Diamond: 'from-cyan-400 to-cyan-200',
}

export default function ChipTrackingPage() {
  const [stats, setStats] = useState<ChipStats | null>(null)
  const [monthly, setMonthly] = useState<MonthlyChips[]>([])
  const [milestones, setMilestones] = useState<CompMilestone[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getChipStats(), getMonthlyChips(), getMilestones()])
      .then(([s, m, ml]) => { setStats(s); setMonthly(m); setMilestones(ml) })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !stats) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  const monthDiff = stats.last_month > 0
    ? ((stats.this_month - stats.last_month) / stats.last_month * 100).toFixed(1)
    : '0'

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard icon={Coins} label="Lifetime Chips" value={formatNumber(stats.lifetime_chips)} />
        <StatCard icon={TrendingUp} label="This Month" value={formatNumber(stats.this_month)} sub={`${Number(monthDiff) >= 0 ? '+' : ''}${monthDiff}% vs last month`} />
        <StatCard icon={Gift} label="Comps Received" value={formatCurrency(stats.comps_received)} />
      </div>

      {/* Monthly Bar Chart */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
        <h3 className="mb-4 text-sm font-semibold text-white">Monthly Chip Earnings</h3>
        <ResponsiveContainer width="100%" height={250}>
          <BarChart data={monthly}>
            <CartesianGrid strokeDasharray="3 3" stroke="#27272A" />
            <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#A1A1AA' }} stroke="#3F3F46" />
            <YAxis tick={{ fontSize: 12, fill: '#A1A1AA' }} stroke="#3F3F46" />
            <Tooltip
              contentStyle={{ background: '#18181B', border: '1px solid #27272A', borderRadius: '12px', color: '#FAFAFA' }}
              labelStyle={{ color: '#A1A1AA' }}
            />
            <Bar dataKey="chips" fill="#D4AF37" radius={[6, 6, 0, 0]} name="Chips" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Comp Milestones */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
        <h3 className="mb-6 text-sm font-semibold text-white">Comp Milestones</h3>
        <div className="space-y-4">
          {milestones.map(m => {
            const progress = Math.min((m.current_chips / m.chips_required) * 100, 100)
            return (
              <div key={m.name} className={`rounded-2xl border p-5 ${m.achieved ? 'border-[var(--color-gold)]/30 bg-[var(--color-gold)]/5' : 'border-[var(--color-border)] bg-[var(--color-bg)]'}`}>
                <div className="mb-3 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    {m.achieved ? (
                      <CheckCircle size={20} className="text-[var(--color-gold)]" />
                    ) : (
                      <Lock size={20} className="text-[var(--color-text-dim)]" />
                    )}
                    <div>
                      <span className={`text-sm font-bold ${m.achieved ? 'text-[var(--color-gold)]' : 'text-white'}`}>{m.name}</span>
                      <p className="text-xs text-[var(--color-text-dim)]">{formatNumber(m.chips_required)} chips</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-[var(--color-gold)]">{formatCurrency(m.comp_value)}</p>
                    <p className="text-xs text-[var(--color-text-dim)]">{m.achieved ? 'Achieved' : 'Locked'}</p>
                  </div>
                </div>
                <div className="h-2 overflow-hidden rounded-full bg-[var(--color-border)]">
                  <div className={`h-full rounded-full bg-gradient-to-r ${MILESTONE_COLORS[m.name] || 'from-zinc-500 to-zinc-400'}`} style={{ width: `${progress}%` }} />
                </div>
                {!m.achieved && (
                  <p className="mt-2 text-xs text-[var(--color-text-dim)]">{formatNumber(m.chips_required - m.current_chips)} chips to unlock</p>
                )}
              </div>
            )
          })}
        </div>

        <p className="mt-6 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-xs text-[var(--color-text-dim)]">
          Comp awards are discretionary and granted by BlakJaks based on partnership performance. Reaching a milestone does not guarantee a comp award.
        </p>
      </div>
    </div>
  )
}
