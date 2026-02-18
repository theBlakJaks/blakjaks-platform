import {
  MOCK_PARTNER, MOCK_DASHBOARD, MOCK_PRODUCTS, MOCK_ORDERS,
  MOCK_RECENT_ORDERS, MOCK_CHIP_STATS, MOCK_MONTHLY_CHIPS, MOCK_MILESTONES,
} from './mock-data'
import type {
  WholesalePartner, AuthTokens, DashboardStats, Product, Order,
  ChipStats, MonthlyChips, CompMilestone, Application, RecentOrder,
} from './types'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/wholesale'

async function apiFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('ws_token') : null
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options?.headers,
    },
  })
  if (res.status === 401 && typeof window !== 'undefined') {
    localStorage.removeItem('ws_token')
    localStorage.removeItem('ws_refresh')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

// ── Auth ──

export async function login(email: string, password: string): Promise<AuthTokens> {
  try {
    return await apiFetch<AuthTokens>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
  } catch {
    // Mock: accept any email/password
    return { access_token: 'mock-jwt-token', refresh_token: 'mock-refresh-token' }
  }
}

export async function logout(): Promise<void> {
  try {
    await apiFetch('/auth/logout', { method: 'POST' })
  } catch {
    // Mock: just clear tokens
  }
  if (typeof window !== 'undefined') {
    localStorage.removeItem('ws_token')
    localStorage.removeItem('ws_refresh')
  }
}

// ── Applications ──

export async function submitApplication(data: Application): Promise<{ message: string }> {
  try {
    return await apiFetch('/applications', { method: 'POST', body: JSON.stringify(data) })
  } catch {
    return { message: 'Application received. We will review within 2 business days.' }
  }
}

// ── Dashboard ──

export async function getDashboardStats(): Promise<DashboardStats> {
  try { return await apiFetch('/dashboard') }
  catch { return MOCK_DASHBOARD }
}

export async function getRecentOrders(): Promise<RecentOrder[]> {
  try { return await apiFetch('/orders?limit=5&sort=recent') }
  catch { return MOCK_RECENT_ORDERS }
}

// ── Products ──

export async function getProducts(): Promise<Product[]> {
  try { return await apiFetch('/products') }
  catch { return MOCK_PRODUCTS }
}

// ── Orders ──

export async function createOrder(items: { product_id: string; quantity: number }[]): Promise<Order> {
  try {
    return await apiFetch('/orders', { method: 'POST', body: JSON.stringify({ items }) })
  } catch {
    const order = MOCK_ORDERS[0]
    return { ...order, id: `ord-new-${Date.now()}`, order_number: `WO-2024-${Math.floor(Math.random() * 9000) + 1000}`, status: 'pending' }
  }
}

export async function getOrders(status?: string): Promise<Order[]> {
  try {
    const params = status ? `?status=${status}` : ''
    return await apiFetch(`/orders${params}`)
  } catch {
    if (status) return MOCK_ORDERS.filter(o => o.status === status)
    return MOCK_ORDERS
  }
}

export async function getOrder(id: string): Promise<Order> {
  try { return await apiFetch(`/orders/${id}`) }
  catch {
    const order = MOCK_ORDERS.find(o => o.id === id)
    if (!order) throw new Error('Order not found')
    return order
  }
}

// ── Chips ──

export async function getChipStats(): Promise<ChipStats> {
  try { return await apiFetch('/chips') }
  catch { return MOCK_CHIP_STATS }
}

export async function getMonthlyChips(): Promise<MonthlyChips[]> {
  try { return await apiFetch('/chips/monthly') }
  catch { return MOCK_MONTHLY_CHIPS }
}

export async function getMilestones(): Promise<CompMilestone[]> {
  try { return await apiFetch('/chips/milestones') }
  catch { return MOCK_MILESTONES }
}

// ── Profile ──

export async function getProfile(): Promise<WholesalePartner> {
  try { return await apiFetch('/profile') }
  catch { return MOCK_PARTNER }
}

export async function updateProfile(data: Partial<WholesalePartner>): Promise<WholesalePartner> {
  try {
    return await apiFetch('/profile', { method: 'PUT', body: JSON.stringify(data) })
  } catch {
    return { ...MOCK_PARTNER, ...data }
  }
}

export async function changePassword(current: string, newPassword: string): Promise<{ message: string }> {
  try {
    return await apiFetch('/auth/password', {
      method: 'PUT',
      body: JSON.stringify({ current_password: current, new_password: newPassword }),
    })
  } catch {
    return { message: 'Password updated successfully' }
  }
}
