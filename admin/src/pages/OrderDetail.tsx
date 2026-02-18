import { useCallback, useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, RefreshCw, RotateCcw, CheckCircle, Circle, Truck } from 'lucide-react'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import ConfirmDialog from '../components/ConfirmDialog'
import { getOrder, updateOrderStatus, refundOrder, resendToFulfillment } from '../api/orders'
import { formatCurrency, formatDateTime } from '../utils/formatters'
import type { OrderDetail as OrderDetailType } from '../types'

const STATUS_FLOW = ['pending', 'processing', 'shipped', 'delivered']

export default function OrderDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [order, setOrder] = useState<OrderDetailType | null>(null)
  const [loading, setLoading] = useState(true)
  const [newStatus, setNewStatus] = useState('')
  const [trackingNumber, setTrackingNumber] = useState('')
  const [updating, setUpdating] = useState(false)
  const [refundOpen, setRefundOpen] = useState(false)

  const fetchOrder = useCallback(async () => {
    if (!id) return
    setLoading(true)
    const data = await getOrder(id)
    setOrder(data)
    const currentIdx = STATUS_FLOW.indexOf(data.status)
    setNewStatus(currentIdx < STATUS_FLOW.length - 1 ? STATUS_FLOW[currentIdx + 1] : data.status)
    setLoading(false)
  }, [id])

  useEffect(() => { fetchOrder() }, [fetchOrder])

  const handleStatusUpdate = async () => {
    if (!order) return
    setUpdating(true)
    try {
      await updateOrderStatus(order.id, newStatus, newStatus === 'shipped' ? trackingNumber : undefined)
      toast.success(`Status updated to ${newStatus}`)
      setTrackingNumber('')
      fetchOrder()
    } catch {
      toast.error('Failed to update status')
    } finally {
      setUpdating(false)
    }
  }

  const handleRefund = async () => {
    if (!order) return
    try {
      await refundOrder(order.id)
      toast.success('Order refunded')
      fetchOrder()
    } catch {
      toast.error('Failed to refund order')
    }
  }

  const handleResend = async () => {
    if (!order) return
    try {
      await resendToFulfillment(order.id)
      toast.success('Re-sent to fulfillment')
    } catch {
      toast.error('Failed to resend')
    }
  }

  if (loading || !order) {
    return <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
  }

  const currentIdx = STATUS_FLOW.indexOf(order.status)
  const canAdvance = currentIdx >= 0 && currentIdx < STATUS_FLOW.length - 1

  return (
    <div className="space-y-6">
      <button onClick={() => navigate('/orders')} className="flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700">
        <ArrowLeft size={16} /> Back to Orders
      </button>

      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-4 rounded-xl bg-white p-6 shadow-sm">
        <div>
          <div className="flex items-center gap-3">
            <h2 className="text-xl font-bold text-slate-900">Order {order.id}</h2>
            <Badge label={order.status} />
          </div>
          <p className="mt-1 text-sm text-slate-500">Placed on {formatDateTime(order.created_at)}</p>
        </div>

        <div className="flex flex-wrap gap-2">
          {/* Status update */}
          {canAdvance && (
            <div className="flex items-center gap-2">
              <select
                value={newStatus}
                onChange={(e) => setNewStatus(e.target.value)}
                className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
              >
                {STATUS_FLOW.slice(currentIdx + 1).map(s => (
                  <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>
                ))}
              </select>
              {newStatus === 'shipped' && (
                <input
                  type="text"
                  value={trackingNumber}
                  onChange={(e) => setTrackingNumber(e.target.value)}
                  placeholder="Tracking #"
                  className="rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-indigo-500"
                />
              )}
              <button
                onClick={handleStatusUpdate}
                disabled={updating}
                className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-3 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40"
              >
                {updating ? <LoadingSpinner className="h-4 w-4" /> : <CheckCircle size={16} />}
                Update Status
              </button>
            </div>
          )}

          <button
            onClick={handleResend}
            className="flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            <RefreshCw size={16} /> Resend to Fulfillment
          </button>
          <button
            onClick={() => setRefundOpen(true)}
            className="flex items-center gap-1.5 rounded-lg bg-red-50 px-3 py-2 text-sm font-medium text-red-700 hover:bg-red-100"
          >
            <RotateCcw size={16} /> Refund Order
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Customer Info */}
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">Customer Info</h3>
          <dl className="space-y-3 text-sm">
            <div>
              <dt className="text-slate-500">Name</dt>
              <dd className="font-medium text-slate-900">{order.customer_name}</dd>
            </div>
            <div>
              <dt className="text-slate-500">Email</dt>
              <dd className="text-slate-900">{order.user_email}</dd>
            </div>
            <div>
              <dt className="text-slate-500">Shipping Address</dt>
              <dd className="text-slate-900">{order.shipping_address}</dd>
            </div>
            {order.tracking_number && (
              <div>
                <dt className="text-slate-500">Tracking Number</dt>
                <dd className="font-mono text-sm text-slate-900">{order.tracking_number}</dd>
              </div>
            )}
          </dl>
        </div>

        {/* Order Items */}
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">Order Items</h3>
          <div className="space-y-3">
            {order.items.map(item => (
              <div key={item.id} className="flex items-center justify-between border-b border-slate-50 pb-2 last:border-0">
                <div>
                  <p className="text-sm font-medium text-slate-900">{item.product_name}</p>
                  <p className="text-xs text-slate-500">Qty: {item.quantity} x {formatCurrency(item.unit_price)}</p>
                </div>
                <span className="text-sm font-medium text-slate-900">{formatCurrency(item.total_price)}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Payment Summary */}
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 text-sm font-semibold text-slate-700">Payment Summary</h3>
          <dl className="space-y-3 text-sm">
            <div className="flex justify-between">
              <dt className="text-slate-500">Subtotal</dt>
              <dd className="text-slate-900">{formatCurrency(order.subtotal)}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Shipping</dt>
              <dd className="text-slate-900">{order.shipping_cost === 0 ? <span className="text-emerald-600">FREE</span> : formatCurrency(order.shipping_cost)}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Tax</dt>
              <dd className="text-slate-900">{formatCurrency(order.tax)}</dd>
            </div>
            <div className="flex justify-between border-t border-slate-100 pt-3">
              <dt className="font-semibold text-slate-900">Total</dt>
              <dd className="text-lg font-bold text-slate-900">{formatCurrency(order.total)}</dd>
            </div>
          </dl>
        </div>
      </div>

      {/* Order Timeline */}
      <div className="rounded-xl bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-sm font-semibold text-slate-700">Order Timeline</h3>
        <div className="space-y-4">
          {order.timeline.map((event, i) => {
            const isLast = i === order.timeline.length - 1
            return (
              <div key={event.id} className="flex gap-4">
                <div className="flex flex-col items-center">
                  {isLast ? (
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-indigo-100">
                      {event.status === 'shipped' ? <Truck size={14} className="text-indigo-600" /> : <CheckCircle size={14} className="text-indigo-600" />}
                    </div>
                  ) : (
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-slate-100">
                      <Circle size={14} className="text-slate-400" />
                    </div>
                  )}
                  {i < order.timeline.length - 1 && <div className="mt-1 h-8 w-px bg-slate-200" />}
                </div>
                <div className="pb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium capitalize text-slate-900">{event.status}</span>
                    <span className="text-xs text-slate-400">{formatDateTime(event.timestamp)}</span>
                  </div>
                  <p className="text-sm text-slate-500">{event.note}</p>
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Refund Confirm */}
      <ConfirmDialog
        open={refundOpen}
        onClose={() => setRefundOpen(false)}
        onConfirm={handleRefund}
        title="Refund Order"
        message={`Are you sure you want to refund order ${order.id}? This will return ${formatCurrency(order.total)} to the customer.`}
        confirmLabel="Refund"
        variant="danger"
      />
    </div>
  )
}
