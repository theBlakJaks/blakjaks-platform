'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { QrCode, DollarSign, Zap, Flame, MessageCircle, Eye, ArrowRight } from 'lucide-react'
import Card from '@/components/ui/Card'
import StatCard from '@/components/ui/StatCard'
import TierBadge from '@/components/ui/TierBadge'
import ProgressBar from '@/components/ui/ProgressBar'
import GoldButton from '@/components/ui/GoldButton'
import Spinner from '@/components/ui/Spinner'
import Badge from '@/components/ui/Badge'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'
import { formatCurrency, formatRelativeTime, formatDate, getTierLabel } from '@/lib/utils'
import type { ActivityFeedItem, CompAward } from '@/lib/types'
import { comps as mockComps } from '@/lib/mock-data'

const TIER_THRESHOLDS = {
  standard: { next: 'vip', scansNeeded: 25 },
  vip: { next: 'high_roller', scansNeeded: 75 },
  high_roller: { next: 'whale', scansNeeded: 200 },
  whale: { next: null, scansNeeded: 0 },
} as const

const ACTIVITY_ICONS: Record<string, string> = {
  scan: '📱',
  comp: '💰',
  order: '📦',
  governance: '🗳️',
  social: '💬',
  system: '⚙️',
}

export default function DashboardPage() {
  const { user } = useAuth()
  const [activity, setActivity] = useState<ActivityFeedItem[]>([])
  const [recentComps, setRecentComps] = useState<CompAward[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      try {
        const data = await api.dashboard.get()
        setActivity((data.recentActivity as ActivityFeedItem[]).slice(0, 5))
        setRecentComps(mockComps.slice(0, 3))
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  if (!user || loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner className="h-10 w-10" />
      </div>
    )
  }

  const tierInfo = TIER_THRESHOLDS[user.tier]
  const scansToNext = tierInfo.scansNeeded > 0 ? Math.max(0, tierInfo.scansNeeded - user.quarterlyScans) : 0

  return (
    <div className="space-y-6">
      {/* Welcome */}
      <div>
        <h1 className="text-2xl font-bold text-white">Welcome back, {user.firstName}</h1>
        <p className="mt-1 text-sm text-[var(--color-text-dim)]">Here&apos;s what&apos;s happening with your account</p>
      </div>

      {/* Tier Status Card */}
      <Card className="border-[var(--color-gold)]/20 bg-gradient-to-r from-[var(--color-bg-card)] to-[var(--color-bg-surface)]">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-4">
            <TierBadge tier={user.effectiveTier} size="lg" />
            <div>
              <h2 className="text-lg font-bold text-white">{getTierLabel(user.effectiveTier)} Member</h2>
              {user.permanentTier !== user.tier && (
                <p className="text-xs text-[var(--color-text-dim)]">
                  Permanent: {getTierLabel(user.permanentTier)} | Quarterly: {getTierLabel(user.tier)}
                </p>
              )}
              <p className="text-sm text-[var(--color-text-muted)]">
                {user.quarterlyScans} scans this quarter
              </p>
            </div>
          </div>
          {tierInfo.next && (
            <div className="w-full sm:w-64">
              <ProgressBar
                value={user.quarterlyScans}
                max={tierInfo.scansNeeded}
                label={`${scansToNext} scans to ${getTierLabel(tierInfo.next as 'standard' | 'vip' | 'high_roller' | 'whale')}`}
              />
            </div>
          )}
        </div>
      </Card>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard icon={QrCode} label="Total Scans" value={user.totalScans.toLocaleString()} sub="Lifetime" />
        <StatCard icon={DollarSign} label="USDC Earned" value={formatCurrency(user.lifetimeUSDC)} sub="Lifetime" color="#22C55E" />
        <StatCard icon={Zap} label="Quarter Scans" value={String(user.quarterlyScans)} sub="Current quarter" color="#3B82F6" />
        <StatCard icon={Flame} label="Active Streak" value="12 days" sub="Keep it going!" color="#EF4444" />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Recent Activity */}
        <Card className="lg:col-span-2">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="text-lg font-semibold text-white">Recent Activity</h3>
          </div>
          <div className="space-y-3">
            {activity.map((item) => (
              <div key={item.id} className="flex items-start gap-3 rounded-lg p-2 transition-colors hover:bg-[var(--color-bg-hover)]">
                <span className="mt-0.5 text-base">{ACTIVITY_ICONS[item.type] || '📌'}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-[var(--color-text)]">{item.message}</p>
                  <p className="text-xs text-[var(--color-text-dim)]">{formatRelativeTime(item.timestamp)}</p>
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* Quick Actions + Comp Preview */}
        <div className="space-y-6">
          <Card>
            <h3 className="mb-4 text-lg font-semibold text-white">Quick Actions</h3>
            <div className="space-y-3">
              <Link href="/social">
                <GoldButton variant="secondary" fullWidth>
                  <MessageCircle size={16} /> Join Chat
                </GoldButton>
              </Link>
              <Link href="/transparency">
                <GoldButton variant="ghost" fullWidth>
                  <Eye size={16} /> View Transparency
                </GoldButton>
              </Link>
            </div>
          </Card>

          <Card>
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-white">Recent Comps</h3>
              <Link href="/profile" className="text-xs text-[var(--color-gold)] hover:underline flex items-center gap-1">
                View All <ArrowRight size={12} />
              </Link>
            </div>
            <div className="space-y-2">
              {recentComps.map((comp) => (
                <div key={comp.id} className="flex items-center justify-between rounded-lg border border-[var(--color-border)]/50 px-3 py-2">
                  <div>
                    <p className="text-sm font-medium text-white">{formatCurrency(comp.amount)}</p>
                    <p className="text-xs text-[var(--color-text-dim)]">{formatDate(comp.date)}</p>
                  </div>
                  <Badge status={comp.type === 'tier_bonus' ? 'tier bonus' : comp.type} />
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}
