'use client'

import { useState } from 'react'
import { QrCode, DollarSign, Award, Gift } from 'lucide-react'
import Card from '@/components/ui/Card'
import Avatar from '@/components/ui/Avatar'
import TierBadge from '@/components/ui/TierBadge'
import StatCard from '@/components/ui/StatCard'
import Badge from '@/components/ui/Badge'
import Spinner from '@/components/ui/Spinner'
import { useAuth } from '@/lib/auth-context'
import { formatCurrency, formatDate, getTierLabel } from '@/lib/utils'
import { comps, scans } from '@/lib/mock-data'
import type { CompAward, Scan } from '@/lib/types'

export default function ProfilePage() {
  const { user } = useAuth()
  const [allComps] = useState<CompAward[]>(comps)
  const [recentScans] = useState<Scan[]>(() => scans.slice(0, 15))
  const loading = false

  if (!user || loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner className="h-10 w-10" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Profile Header */}
      <Card className="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
        <Avatar name={`${user.firstName} ${user.lastName}`} tier={user.effectiveTier} size="lg" avatarUrl={user.avatarUrl} />
        <div className="text-center sm:text-left">
          <h1 className="text-xl font-bold text-white">{user.firstName} {user.lastName}</h1>
          <p className="text-sm text-[var(--color-text-muted)]">@{user.username}</p>
          <div className="mt-2 flex flex-wrap items-center justify-center gap-2 sm:justify-start">
            <TierBadge tier={user.effectiveTier} />
            <span className="text-xs text-[var(--color-text-dim)]">
              Member since {formatDate(user.memberSince, 'long')}
            </span>
          </div>
        </div>
      </Card>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard icon={QrCode} label="Total Scans" value={user.totalScans.toLocaleString()} />
        <StatCard icon={DollarSign} label="Lifetime USDC" value={formatCurrency(user.lifetimeUSDC)} color="#22C55E" />
        <StatCard icon={Award} label="Current Tier" value={getTierLabel(user.effectiveTier)} color="#D4AF37" />
        <StatCard icon={Gift} label="Comps Received" value={String(allComps.length)} color="#3B82F6" />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Comp History Table */}
        <Card className="lg:col-span-2">
          <h2 className="mb-4 text-lg font-semibold text-white">Comp History</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--color-border)]">
                  <th className="px-3 py-2.5 text-left text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">Date</th>
                  <th className="px-3 py-2.5 text-left text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">Amount</th>
                  <th className="px-3 py-2.5 text-left text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">Type</th>
                  <th className="px-3 py-2.5 text-left text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">Tx Hash</th>
                  <th className="px-3 py-2.5 text-left text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">Status</th>
                </tr>
              </thead>
              <tbody>
                {allComps.map((comp) => (
                  <tr key={comp.id} className="border-b border-[var(--color-border)]/50 transition-colors hover:bg-[var(--color-bg-hover)]">
                    <td className="px-3 py-2.5 text-sm text-[var(--color-text)]">{formatDate(comp.date)}</td>
                    <td className="px-3 py-2.5 text-sm font-medium text-emerald-400">{formatCurrency(comp.amount)}</td>
                    <td className="px-3 py-2.5">
                      <span className="rounded-full border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-2 py-0.5 text-xs capitalize text-[var(--color-text-muted)]">
                        {comp.type.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-3 py-2.5 text-sm">
                      {comp.txHash ? (
                        <a
                          href={`https://polygonscan.com/tx/${comp.txHash}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-[var(--color-gold)] hover:underline"
                        >
                          {comp.txHash}
                        </a>
                      ) : (
                        <span className="text-[var(--color-text-dim)]">--</span>
                      )}
                    </td>
                    <td className="px-3 py-2.5">
                      <Badge status={comp.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Recent Scans */}
        <Card>
          <h2 className="mb-4 text-lg font-semibold text-white">Recent Scans</h2>
          <div className="space-y-2">
            {recentScans.map((scan) => (
              <div key={scan.id} className="flex items-center justify-between rounded-lg border border-[var(--color-border)]/50 px-3 py-2">
                <div>
                  <p className="text-sm text-[var(--color-text)]">{scan.qrCodeId}</p>
                  {scan.product && (
                    <p className="text-xs text-[var(--color-text-dim)]">{scan.product}</p>
                  )}
                </div>
                <span className="text-xs text-[var(--color-text-dim)]">{formatDate(scan.date)}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
