'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Package, Box, Coins, Gift, Clock, ArrowRight } from 'lucide-react'
import StatCard from '@/components/StatCard'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { getDashboardStats, getRecentOrders } from '@/lib/api'
import { formatCurrency, formatNumber, formatDate } from '@/lib/utils'
import type { DashboardStats, RecentOrder } from '@/lib/types'

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [orders, setOrders] = useState<RecentOrder[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getDashboardStats(), getRecentOrders()])
      .then(([s, o]) => { setStats(s); setOrders(o) })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !stats) {
    return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>
  }

  const milestoneProgress = (stats.chips_earned / stats.next_milestone_chips) * 100

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatCard icon={Package} label="Total Orders" value={String(stats.total_orders)} />
        <StatCard icon={Box} label="Total Tins Ordered" value={formatNumber(stats.total_tins)} />
        <StatCard icon={Coins} label="Chips Earned" value={formatNumber(stats.chips_earned)} />
        <StatCard icon={Gift} label="Comps Received" value={formatCurrency(stats.comps_received)} />
        <StatCard icon={Clock} label="Pending Value" value={formatCurrency(stats.pending_order_value)} />
      </div>

      {/* Milestone Progress */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="text-sm font-semibold text-white">Next Milestone: {stats.next_milestone_name}</h3>
          <span className="text-sm text-[var(--color-text-muted)]">{formatNumber(stats.chips_earned)} / {formatNumber(stats.next_milestone_chips)} chips</span>
        </div>
        <div className="h-3 overflow-hidden rounded-full bg-[var(--color-border)]">
          <div className="gold-gradient h-full rounded-full transition-all" style={{ width: `${Math.min(milestoneProgress, 100)}%` }} />
        </div>
        <p className="mt-2 text-xs text-[var(--color-text-dim)]">{formatNumber(stats.next_milestone_chips - stats.chips_earned)} chips to go</p>
      </div>

      {/* Recent Orders */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
        <div className="flex items-center justify-between border-b border-[var(--color-border)] px-6 py-4">
          <h3 className="text-sm font-semibold text-white">Recent Orders</h3>
          <Link href="/orders" className="flex items-center gap-1 text-sm text-[var(--color-gold)] hover:underline">
            View All <ArrowRight size={14} />
          </Link>
        </div>
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-[var(--color-border)]">
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Order ID</th>
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Date</th>
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Tins</th>
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Total</th>
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map(o => (
              <tr key={o.id} className="border-b border-[var(--color-border)] last:border-0 hover:bg-[var(--color-bg-hover)]">
                <td className="px-6 py-3 font-mono text-xs text-[var(--color-gold)]">{o.order_number}</td>
                <td className="px-6 py-3 text-[var(--color-text-muted)]">{formatDate(o.date)}</td>
                <td className="px-6 py-3 text-white">{formatNumber(o.tins)}</td>
                <td className="px-6 py-3 font-mono text-white">{formatCurrency(o.total)}</td>
                <td className="px-6 py-3"><StatusBadge status={o.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
