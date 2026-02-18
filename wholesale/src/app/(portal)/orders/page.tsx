'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { ClipboardList } from 'lucide-react'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { getOrders } from '@/lib/api'
import { formatCurrency, formatNumber, formatDate } from '@/lib/utils'
import type { Order } from '@/lib/types'

const FILTERS = ['all', 'pending', 'processing', 'shipped', 'delivered'] as const

export default function OrderHistoryPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<string>('all')

  useEffect(() => {
    setLoading(true)
    getOrders(filter === 'all' ? undefined : filter)
      .then(setOrders)
      .finally(() => setLoading(false))
  }, [filter])

  return (
    <div className="space-y-6">
      {/* Filters */}
      <div className="flex gap-2">
        {FILTERS.map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`rounded-xl px-4 py-2 text-sm font-medium capitalize transition-colors ${filter === f ? 'gold-gradient text-black' : 'border border-[var(--color-border)] text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)]'}`}
          >
            {f}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>
      ) : orders.length === 0 ? (
        <div className="flex flex-col items-center py-16 text-center">
          <ClipboardList size={48} className="text-[var(--color-text-dim)]" />
          <p className="mt-4 text-sm text-[var(--color-text-muted)]">No orders found</p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-[var(--color-border)]">
                <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Order ID</th>
                <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Date</th>
                <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Items</th>
                <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Tins</th>
                <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Total</th>
                <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Status</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(o => (
                <Link key={o.id} href={`/orders/${o.id}`} className="contents">
                  <tr className="cursor-pointer border-b border-[var(--color-border)] last:border-0 hover:bg-[var(--color-bg-hover)]">
                    <td className="px-6 py-4 font-mono text-xs text-[var(--color-gold)]">{o.order_number}</td>
                    <td className="px-6 py-4 text-[var(--color-text-muted)]">{formatDate(o.created_at)}</td>
                    <td className="px-6 py-4 text-white">{o.item_count}</td>
                    <td className="px-6 py-4 text-white">{formatNumber(o.total_tins)}</td>
                    <td className="px-6 py-4 font-mono font-medium text-white">{formatCurrency(o.total_cost)}</td>
                    <td className="px-6 py-4"><StatusBadge status={o.status} /></td>
                  </tr>
                </Link>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
