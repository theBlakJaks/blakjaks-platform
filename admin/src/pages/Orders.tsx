import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ShoppingCart, DollarSign, Clock, TrendingUp, Eye, Filter, ChevronDown, ChevronUp } from 'lucide-react'
import StatsCard from '../components/StatsCard'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import { getOrders, getOrderStats } from '../api/orders'
import { formatCurrency, formatDate } from '../utils/formatters'
import type { Order, OrderStats } from '../types'

const DATE_RANGES = [
  { value: '', label: 'All Time' },
  { value: 'week', label: 'This Week' },
  { value: 'month', label: 'This Month' },
]

const STATUS_OPTIONS = [
  { value: '', label: 'All Status' },
  { value: 'pending', label: 'Pending' },
  { value: 'processing', label: 'Processing' },
  { value: 'shipped', label: 'Shipped' },
  { value: 'delivered', label: 'Delivered' },
  { value: 'cancelled', label: 'Cancelled' },
]

export default function Orders() {
  const navigate = useNavigate()
  const [orders, setOrders] = useState<Order[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState('')
  const [dateRange, setDateRange] = useState('')
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<OrderStats | null>(null)
  const [expandedRow, setExpandedRow] = useState<string | null>(null)

  const fetchData = useCallback(async () => {
    setLoading(true)
    const [ordersRes, statsRes] = await Promise.all([
      getOrders(page, statusFilter || undefined, dateRange || undefined),
      getOrderStats(),
    ])
    setOrders(ordersRes.items)
    setTotal(ordersRes.total)
    setStats(statsRes)
    setLoading(false)
  }, [page, statusFilter, dateRange])

  useEffect(() => { fetchData() }, [fetchData])

  const totalPages = Math.ceil(total / 20)

  return (
    <div className="space-y-6">
      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
          <StatsCard icon={ShoppingCart} label="Total Orders" value={String(stats.total_orders)} />
          <StatsCard icon={DollarSign} label="Revenue Today" value={formatCurrency(stats.revenue_today)} />
          <StatsCard icon={Clock} label="Pending Fulfillment" value={String(stats.pending_fulfillment)} />
          <StatsCard icon={TrendingUp} label="Avg Order Value" value={formatCurrency(stats.avg_order_value)} />
        </div>
      )}

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="ml-auto flex items-center gap-3">
          <div className="flex items-center gap-2">
            <Filter size={16} className="text-slate-400" />
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
            >
              {STATUS_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <select
            value={dateRange}
            onChange={(e) => { setDateRange(e.target.value); setPage(1) }}
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
          >
            {DATE_RANGES.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        </div>
      </div>

      <p className="text-sm text-slate-500">{total} order{total !== 1 ? 's' : ''} found</p>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
      ) : orders.length === 0 ? (
        <EmptyState title="No orders found" message="No orders match your filters." />
      ) : (
        <div className="overflow-hidden rounded-xl bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50">
                <th className="w-8 px-4 py-3" />
                <th className="px-4 py-3 font-medium text-slate-600">Order ID</th>
                <th className="px-4 py-3 font-medium text-slate-600">Customer</th>
                <th className="px-4 py-3 font-medium text-slate-600">Items</th>
                <th className="px-4 py-3 font-medium text-slate-600">Subtotal</th>
                <th className="px-4 py-3 font-medium text-slate-600">Shipping</th>
                <th className="px-4 py-3 font-medium text-slate-600">Tax</th>
                <th className="px-4 py-3 font-medium text-slate-600">Total</th>
                <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                <th className="px-4 py-3 font-medium text-slate-600">Date</th>
                <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(o => (
                <>
                  <tr key={o.id} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="px-4 py-3">
                      <button
                        onClick={() => setExpandedRow(expandedRow === o.id ? null : o.id)}
                        className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
                      >
                        {expandedRow === o.id ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                      </button>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-slate-600">{o.id.slice(0, 12)}...</td>
                    <td className="px-4 py-3">
                      <div>
                        <p className="font-medium text-slate-900">{o.user_name}</p>
                        <p className="text-xs text-slate-400">{o.user_email}</p>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-700">{o.items.length}</td>
                    <td className="px-4 py-3 text-slate-700">{formatCurrency(o.subtotal)}</td>
                    <td className="px-4 py-3 text-slate-700">{o.shipping_cost === 0 ? <span className="text-emerald-600">FREE</span> : formatCurrency(o.shipping_cost)}</td>
                    <td className="px-4 py-3 text-slate-700">{formatCurrency(o.tax)}</td>
                    <td className="px-4 py-3 font-medium text-slate-900">{formatCurrency(o.total)}</td>
                    <td className="px-4 py-3"><Badge label={o.status} /></td>
                    <td className="px-4 py-3 text-slate-500">{formatDate(o.created_at)}</td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => navigate(`/orders/${o.id}`)}
                        className="flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50"
                      >
                        <Eye size={14} /> View
                      </button>
                    </td>
                  </tr>
                  {expandedRow === o.id && (
                    <tr key={`${o.id}-exp`} className="border-b border-slate-50 bg-slate-50/50">
                      <td colSpan={11} className="px-8 py-3">
                        <div className="space-y-1">
                          {o.items.map(item => (
                            <div key={item.id} className="flex items-center justify-between text-sm">
                              <span className="text-slate-700">{item.product_name} x{item.quantity}</span>
                              <span className="text-slate-600">{formatCurrency(item.total_price)}</span>
                            </div>
                          ))}
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))}
            </tbody>
          </table>

          {totalPages > 1 && (
            <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
              <span className="text-sm text-slate-500">Page {page} of {totalPages}</span>
              <div className="flex gap-2">
                <button onClick={() => setPage(p => p - 1)} disabled={page <= 1} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Previous</button>
                <button onClick={() => setPage(p => p + 1)} disabled={page >= totalPages} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Next</button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
