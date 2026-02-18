'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { DollarSign, Clock, CheckCircle, TrendingUp } from 'lucide-react'
import StatCard from '@/components/StatCard'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { useAuth } from '@/lib/auth-context'
import { getPayouts, getDashboardStats } from '@/lib/api'
import { formatCurrency, formatDate, truncateHash, getPolygonscanUrl, getNextSunday } from '@/lib/utils'
import type { Payout, DashboardStats } from '@/lib/types'

export default function PayoutsPage() {
  const { member } = useAuth()
  const [payouts, setPayouts] = useState<Payout[]>([])
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getPayouts(), getDashboardStats()])
      .then(([p, s]) => { setPayouts(p); setStats(s) })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !stats) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  const completedTotal = payouts.filter(p => p.status === 'completed').reduce((sum, p) => sum + p.amount, 0)
  const pendingTotal = payouts.filter(p => p.status !== 'completed' && p.status !== 'failed').reduce((sum, p) => sum + p.amount, 0)

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={DollarSign} label="Lifetime Earnings" value={formatCurrency(stats.lifetime_earnings)} />
        <StatCard icon={TrendingUp} label="Total Paid Out" value={formatCurrency(completedTotal)} />
        <StatCard icon={Clock} label="Pending" value={formatCurrency(pendingTotal)} />
        <StatCard icon={CheckCircle} label="Completed Payouts" value={String(payouts.filter(p => p.status === 'completed').length)} />
      </div>

      {/* Next Payout Card */}
      <div className="flex items-center justify-between rounded-2xl border border-[var(--color-gold)]/30 bg-[var(--color-gold)]/5 px-6 py-4">
        <div>
          <p className="text-xs text-[var(--color-text-dim)]">Next Payout</p>
          <p className="mt-1 text-lg font-semibold text-white">{formatCurrency(stats.pending_payout)}</p>
        </div>
        <div className="text-right">
          <p className="text-xs text-[var(--color-text-dim)]">Scheduled</p>
          <p className="mt-1 text-sm font-medium text-[var(--color-gold)]">{formatDate(getNextSunday())}</p>
        </div>
        <div className="text-right">
          <p className="text-xs text-[var(--color-text-dim)]">Wallet</p>
          <p className="mt-1 font-mono text-xs text-[var(--color-text-muted)]">{member?.wallet_address ? truncateHash(member.wallet_address) : 'Not set'}</p>
        </div>
      </div>

      {/* Payout History Table */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
        <div className="border-b border-[var(--color-border)] px-6 py-4">
          <h3 className="text-sm font-semibold text-white">Payout History</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-[var(--color-border)] text-left text-xs text-[var(--color-text-dim)]">
                <th className="px-5 py-3 font-medium">Date</th>
                <th className="px-5 py-3 font-medium text-right">Amount</th>
                <th className="px-5 py-3 font-medium">Status</th>
                <th className="px-5 py-3 font-medium">Earnings</th>
                <th className="px-5 py-3 font-medium">Tx Hash</th>
              </tr>
            </thead>
            <tbody>
              {payouts.map(p => (
                <tr key={p.id} className="border-b border-[var(--color-border)] last:border-0 hover:bg-[var(--color-bg-hover)]">
                  <td className="px-5 py-3 text-sm text-white">{formatDate(p.date)}</td>
                  <td className="px-5 py-3 text-right font-mono text-sm font-medium text-[var(--color-gold)]">{formatCurrency(p.amount)}</td>
                  <td className="px-5 py-3"><StatusBadge status={p.status} /></td>
                  <td className="px-5 py-3">
                    <Link href={`/payouts/${p.id}`} className="text-sm text-[var(--color-gold)] hover:underline">{p.earnings_count} items</Link>
                  </td>
                  <td className="px-5 py-3 font-mono text-xs text-[var(--color-text-dim)]">
                    {p.tx_hash ? <a href={getPolygonscanUrl(p.tx_hash)} target="_blank" rel="noopener noreferrer" className="hover:text-[var(--color-gold)]">{truncateHash(p.tx_hash)}</a> : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
