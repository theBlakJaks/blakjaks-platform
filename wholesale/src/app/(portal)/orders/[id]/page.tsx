'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, Package, Truck, Coins, DollarSign } from 'lucide-react'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { getOrder } from '@/lib/api'
import { formatCurrency, formatNumber, formatDate } from '@/lib/utils'
import type { Order } from '@/lib/types'

export default function OrderDetailPage() {
  const params = useParams()
  const [order, setOrder] = useState<Order | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (params.id) {
      getOrder(params.id as string).then(setOrder).finally(() => setLoading(false))
    }
  }, [params.id])

  if (loading) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>
  if (!order) return <div className="py-16 text-center text-[var(--color-text-muted)]">Order not found</div>

  return (
    <div className="space-y-6">
      <Link href="/orders" className="inline-flex items-center gap-1.5 text-sm text-[var(--color-text-muted)] hover:text-white">
        <ArrowLeft size={14} /> Back to Orders
      </Link>

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-white">{order.order_number}</h1>
          <p className="text-sm text-[var(--color-text-muted)]">Placed on {formatDate(order.created_at)}</p>
        </div>
        <StatusBadge status={order.status} />
      </div>

      {/* Info Cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5">
          <Package size={18} className="mb-2 text-[var(--color-text-dim)]" />
          <p className="text-xs text-[var(--color-text-muted)]">Items</p>
          <p className="text-lg font-bold text-white">{order.item_count}</p>
        </div>
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5">
          <DollarSign size={18} className="mb-2 text-[var(--color-text-dim)]" />
          <p className="text-xs text-[var(--color-text-muted)]">Total Cost</p>
          <p className="text-lg font-bold text-[var(--color-gold)]">{formatCurrency(order.total_cost)}</p>
        </div>
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5">
          <Truck size={18} className="mb-2 text-[var(--color-text-dim)]" />
          <p className="text-xs text-[var(--color-text-muted)]">Tracking</p>
          <p className="truncate text-sm font-medium text-white">{order.tracking_number || '—'}</p>
        </div>
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5">
          <Coins size={18} className="mb-2 text-[var(--color-text-dim)]" />
          <p className="text-xs text-[var(--color-text-muted)]">Chips Earned</p>
          <p className="text-lg font-bold text-[var(--color-gold)]">{formatNumber(order.chips_earned)}</p>
        </div>
      </div>

      {/* Line Items */}
      <div className="overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
        <div className="border-b border-[var(--color-border)] px-6 py-4">
          <h3 className="text-sm font-semibold text-white">Line Items</h3>
        </div>
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-[var(--color-border)]">
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Product</th>
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Quantity</th>
              <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Unit Price</th>
              <th className="px-6 py-3 text-right font-medium text-[var(--color-text-muted)]">Line Total</th>
            </tr>
          </thead>
          <tbody>
            {order.items.map((item, i) => (
              <tr key={i} className="border-b border-[var(--color-border)] last:border-0">
                <td className="px-6 py-3 text-white">{item.product_name}</td>
                <td className="px-6 py-3 font-mono text-white">{formatNumber(item.quantity)}</td>
                <td className="px-6 py-3 font-mono text-[var(--color-text-muted)]">{formatCurrency(item.unit_price)}</td>
                <td className="px-6 py-3 text-right font-mono font-medium text-white">{formatCurrency(item.line_total)}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr className="border-t border-[var(--color-border-light)]">
              <td colSpan={3} className="px-6 py-3 text-right font-medium text-[var(--color-text-muted)]">Total ({formatNumber(order.total_tins)} tins)</td>
              <td className="px-6 py-3 text-right font-mono text-lg font-bold text-[var(--color-gold)]">{formatCurrency(order.total_cost)}</td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  )
}
