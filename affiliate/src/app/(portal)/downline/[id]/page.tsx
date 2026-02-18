'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, User, ScanLine, ShoppingBag, DollarSign, Droplets } from 'lucide-react'
import TierBadge from '@/components/TierBadge'
import StatusBadge from '@/components/StatusBadge'
import StatCard from '@/components/StatCard'
import Spinner from '@/components/Spinner'
import { getDownlineDetail } from '@/lib/api'
import { formatCurrency, formatNumber, formatDateTime } from '@/lib/utils'
import type { DownlineDetail } from '@/lib/types'

const TIER_LABELS = [
  { key: 'vip' as const, label: 'VIP', required: 210 },
  { key: 'high_roller' as const, label: 'High Roller', required: 2_100 },
  { key: 'whale' as const, label: 'Whale', required: 21_000 },
]

export default function DownlineDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [detail, setDetail] = useState<DownlineDetail | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getDownlineDetail(id).then(setDetail).finally(() => setLoading(false))
  }, [id])

  if (loading || !detail) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  return (
    <div className="space-y-6">
      {/* Back link */}
      <Link href="/downline" className="inline-flex items-center gap-1.5 text-sm text-[var(--color-text-muted)] hover:text-[var(--color-gold)]">
        <ArrowLeft size={16} /> Back to Downline
      </Link>

      {/* Profile Card */}
      <div className="flex items-center gap-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-[var(--color-gold)]/10">
          <User className="text-[var(--color-gold)]" size={24} />
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h2 className="text-lg font-semibold text-white">{detail.name}</h2>
            <TierBadge tier={detail.tier} />
            <StatusBadge status={detail.status} />
          </div>
          <p className="mt-0.5 text-xs text-[var(--color-text-dim)]">Joined {formatDateTime(detail.joined_at)}</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={ScanLine} label="Total Scans" value={formatNumber(detail.total_scans)} />
        <StatCard icon={ShoppingBag} label="Tins Purchased" value={formatNumber(detail.total_tins_purchased)} />
        <StatCard icon={DollarSign} label="Match Earnings" value={formatCurrency(detail.match_earnings)} />
        <StatCard icon={Droplets} label="Pool Earnings" value={formatCurrency(detail.pool_earnings)} />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Permanent Tier Progress */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-4 text-sm font-semibold text-white">Permanent Tier Progress</h3>
          <div className="space-y-5">
            {TIER_LABELS.map(t => {
              const progress = detail.permanent_tier_progress[t.key]
              const pct = Math.min(100, (progress.current / progress.required) * 100)
              return (
                <div key={t.key}>
                  <div className="mb-1.5 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium text-white">{t.label}</span>
                      {progress.unlocked && <span className="rounded-full bg-emerald-500/20 px-2 py-0.5 text-[10px] font-medium text-emerald-400">Unlocked</span>}
                    </div>
                    <span className="text-xs text-[var(--color-text-dim)]">{formatNumber(progress.current)} / {formatNumber(progress.required)} tins</span>
                  </div>
                  <div className="h-2.5 overflow-hidden rounded-full bg-[var(--color-bg)]">
                    <div className={`h-full rounded-full ${progress.unlocked ? 'bg-emerald-500' : 'bg-[var(--color-gold)]'}`} style={{ width: `${pct}%` }} />
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        {/* Recent Activity */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-4 text-sm font-semibold text-white">Recent Activity</h3>
          <div className="space-y-3">
            {detail.recent_activity.map(a => (
              <div key={a.id} className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
                <div>
                  <p className="text-sm text-white">{a.description}</p>
                  <p className="text-xs text-[var(--color-text-dim)]">{formatDateTime(a.timestamp)}</p>
                </div>
                <span className={`rounded-full px-2.5 py-0.5 text-[10px] font-medium ${a.type === 'comp_win' ? 'bg-amber-500/20 text-amber-400' : 'bg-zinc-500/20 text-zinc-400'}`}>
                  {a.type === 'comp_win' ? 'Comp Win' : 'Scan'}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
