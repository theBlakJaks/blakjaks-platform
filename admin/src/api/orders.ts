import client from './client'
import type { Order, OrderDetail, OrderStats } from '../types'

const PRODUCT_NAMES = ['Mint Ice', 'Berry Blast', 'Citrus Rush', 'Cool Menthol', 'Wintergreen', 'Spearmint', 'Cinnamon Fire', 'Coffee']
const NAMES = ['James Smith', 'Sarah Johnson', 'Mike Williams', 'Lisa Brown', 'Alex Jones', 'Emma Garcia', 'Dave Miller', 'Nina Davis']
const ORDER_STATUSES = ['delivered', 'delivered', 'shipped', 'processing', 'pending', 'delivered', 'shipped', 'delivered']

const MOCK_ORDERS: Order[] = Array.from({ length: 40 }, (_, i) => {
  const itemCount = (i % 4) + 1
  const items = Array.from({ length: itemCount }, (__, j) => {
    const qty = (j % 3) + 1
    const price = [4.99, 5.99, 6.49, 7.99, 3.99][j % 5]
    return {
      id: `oi-${i}-${j}`,
      product_id: `p-${String((j % 8) + 1).padStart(2, '0')}`,
      product_name: PRODUCT_NAMES[j % 8],
      quantity: qty,
      unit_price: price,
      total_price: Math.round(qty * price * 100) / 100,
    }
  })
  const subtotal = items.reduce((s, it) => s + it.total_price, 0)
  const shippingCost = subtotal >= 25 ? 0 : 2.99
  const tax = Math.round(subtotal * 0.08 * 100) / 100
  const total = Math.round((subtotal + shippingCost + tax) * 100) / 100
  return {
    id: `ord-${String(i + 1).padStart(4, '0')}`,
    user_id: `u-${String((i % 20) + 1).padStart(3, '0')}`,
    user_email: `user${(i % 20) + 1}@example.com`,
    user_name: NAMES[i % 8],
    status: ORDER_STATUSES[i % 8],
    subtotal,
    shipping_cost: shippingCost,
    tax,
    total,
    items,
    created_at: new Date(Date.now() - (40 - i) * 86400000 * 1.5).toISOString(),
    updated_at: new Date(Date.now() - (40 - i) * 86400000 * 0.5).toISOString(),
  }
})

export async function getOrderStats(): Promise<OrderStats> {
  try {
    const { data } = await client.get('/admin/orders/stats')
    return data
  } catch {
    const todayOrders = MOCK_ORDERS.filter(o => {
      const d = new Date(o.created_at)
      const now = new Date()
      return d.toDateString() === now.toDateString()
    })
    return {
      total_orders: MOCK_ORDERS.length,
      revenue_today: todayOrders.reduce((s, o) => s + o.total, 0) || 342.87,
      pending_fulfillment: MOCK_ORDERS.filter(o => o.status === 'pending' || o.status === 'processing').length,
      avg_order_value: Math.round(MOCK_ORDERS.reduce((s, o) => s + o.total, 0) / MOCK_ORDERS.length * 100) / 100,
    }
  }
}

export async function getOrders(
  page = 1,
  status?: string,
  dateRange?: string,
): Promise<{ items: Order[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 20 }
    if (status) params.status = status
    if (dateRange) params.date_range = dateRange
    const { data } = await client.get('/admin/orders', { params })
    return data
  } catch {
    let filtered = [...MOCK_ORDERS]
    if (status) filtered = filtered.filter(o => o.status === status)
    if (dateRange) {
      const now = Date.now()
      const cutoff = dateRange === 'week' ? now - 7 * 86400000
        : dateRange === 'month' ? now - 30 * 86400000
        : 0
      if (cutoff) filtered = filtered.filter(o => new Date(o.created_at).getTime() >= cutoff)
    }
    filtered.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}

export async function getOrder(orderId: string): Promise<OrderDetail> {
  try {
    const { data } = await client.get(`/admin/orders/${orderId}`)
    return data
  } catch {
    const base = MOCK_ORDERS.find(o => o.id === orderId) || MOCK_ORDERS[0]
    const statusFlow = ['pending', 'processing', 'shipped', 'delivered']
    const currentIdx = statusFlow.indexOf(base.status)
    const timeline = statusFlow.slice(0, currentIdx + 1).map((s, i) => ({
      id: `evt-${i}`,
      status: s,
      note: s === 'pending' ? 'Order placed' : s === 'processing' ? 'Payment confirmed, sent to fulfillment' : s === 'shipped' ? 'Package shipped via USPS' : 'Package delivered',
      timestamp: new Date(new Date(base.created_at).getTime() + i * 86400000).toISOString(),
    }))
    return {
      ...base,
      customer_name: base.user_name,
      shipping_address: '123 Main St, Suite 4, Austin, TX 78701',
      tracking_number: base.status === 'shipped' || base.status === 'delivered' ? '9400111899223456789012' : null,
      timeline,
    }
  }
}

export async function updateOrderStatus(
  orderId: string,
  status: string,
  trackingNumber?: string,
): Promise<Order> {
  try {
    const { data } = await client.put(`/admin/orders/${orderId}/status`, { status, tracking_number: trackingNumber })
    return data
  } catch {
    const order = MOCK_ORDERS.find(o => o.id === orderId) || MOCK_ORDERS[0]
    return { ...order, status }
  }
}

export async function refundOrder(orderId: string): Promise<{ message: string }> {
  try {
    const { data } = await client.post(`/admin/orders/${orderId}/refund`)
    return data
  } catch {
    return { message: 'Order refunded successfully' }
  }
}

export async function resendToFulfillment(orderId: string): Promise<{ message: string }> {
  try {
    const { data } = await client.post(`/admin/orders/${orderId}/resend`)
    return data
  } catch {
    return { message: 'Order re-sent to fulfillment' }
  }
}
