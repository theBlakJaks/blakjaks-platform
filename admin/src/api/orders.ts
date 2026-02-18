import client from './client'
import type { Order } from '../types'

export async function getOrders(page = 1, status?: string): Promise<{ items: Order[]; total: number }> {
  const params: Record<string, string | number> = { page, limit: 20 }
  if (status) params.status = status
  const { data } = await client.get('/admin/orders', { params })
  return data
}

export async function getOrder(orderId: string): Promise<Order> {
  const { data } = await client.get(`/admin/orders/${orderId}`)
  return data
}

export async function updateOrderStatus(orderId: string, status: string): Promise<Order> {
  const { data } = await client.put(`/admin/orders/${orderId}/status`, { status })
  return data
}
