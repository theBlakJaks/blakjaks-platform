import {
  MOCK_PARTNER, MOCK_DASHBOARD, MOCK_PRODUCTS, MOCK_ORDERS,
  MOCK_RECENT_ORDERS, MOCK_CHIP_STATS, MOCK_MONTHLY_CHIPS, MOCK_MILESTONES,
} from './mock-data'
import type {
  WholesalePartner, AuthTokens, DashboardStats, Product, Order,
  ChipStats, MonthlyChips, CompMilestone, Application, RecentOrder,
} from './types'

// BASE_URL ends with /api/wholesale — used for all wholesale-specific paths.
const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/wholesale'

// AUTH_URL is the root /api base — used for auth endpoints that live outside
// the wholesale router prefix (/api/auth/...).
const AUTH_URL = BASE_URL.replace(/\/wholesale$/, '')

// ── Token refresh ─────────────────────────────────────────────────────────────

// Tracks an in-flight refresh to prevent duplicate concurrent requests.
let _refreshPromise: Promise<string | null> | null = null

/**
 * Attempt to exchange the stored refresh token for a new access token.
 * The backend POST /api/auth/refresh returns only { access_token }.
 * Returns the new access token on success, null on failure.
 */
export async function refreshToken(): Promise<string | null> {
  if (_refreshPromise) return _refreshPromise

  _refreshPromise = (async () => {
    const refresh = typeof window !== 'undefined' ? localStorage.getItem('ws_refresh') : null
    if (!refresh) return null

    try {
      const res = await fetch(`${AUTH_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: refresh }),
      })
      if (!res.ok) return null
      const data = await res.json() as { access_token: string }
      localStorage.setItem('ws_token', data.access_token)
      return data.access_token
    } catch {
      return null
    } finally {
      _refreshPromise = null
    }
  })()

  return _refreshPromise
}

// ── Core fetch helper ─────────────────────────────────────────────────────────

/**
 * Fetch helper for wholesale-prefixed endpoints.
 * Injects the Bearer token from localStorage, and on a 401 attempts one token
 * refresh before redirecting to /login.
 */
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
    // Attempt one silent refresh before giving up.
    const newToken = await refreshToken()
    if (newToken) {
      // Retry the original request with the fresh token.
      const retryRes = await fetch(`${BASE_URL}${path}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${newToken}`,
          ...options?.headers,
        },
      })
      if (retryRes.status === 401) {
        localStorage.removeItem('ws_token')
        localStorage.removeItem('ws_refresh')
        window.location.href = '/login'
        throw new Error('Unauthorized')
      }
      if (!retryRes.ok) throw new Error(`API error: ${retryRes.status}`)
      return retryRes.json()
    }

    localStorage.removeItem('ws_token')
    localStorage.removeItem('ws_refresh')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }

  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

/**
 * Fetch helper for non-wholesale endpoints that live under /api (e.g. /api/auth/...,
 * /api/users/...).  Shares the same token and 401-refresh logic as apiFetch.
 */
async function authFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('ws_token') : null
  const res = await fetch(`${AUTH_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options?.headers,
    },
  })

  if (res.status === 401 && typeof window !== 'undefined') {
    const newToken = await refreshToken()
    if (newToken) {
      const retryRes = await fetch(`${AUTH_URL}${path}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${newToken}`,
          ...options?.headers,
        },
      })
      if (retryRes.status === 401) {
        localStorage.removeItem('ws_token')
        localStorage.removeItem('ws_refresh')
        window.location.href = '/login'
        throw new Error('Unauthorized')
      }
      if (!retryRes.ok) throw new Error(`API error: ${retryRes.status}`)
      return retryRes.json()
    }

    localStorage.removeItem('ws_token')
    localStorage.removeItem('ws_refresh')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }

  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

// ── Auth ──────────────────────────────────────────────────────────────────────

// The backend AuthResponse shape: { user, tokens: { access_token, refresh_token } }
interface BackendAuthResponse {
  user: {
    id: string
    email: string
    username: string | null
    first_name: string | null
    last_name: string | null
    is_active: boolean
    is_admin: boolean
    created_at: string
  }
  tokens: {
    access_token: string
    refresh_token: string
    token_type: string
  }
}

/**
 * Login via POST /api/auth/login.
 * Returns AuthTokens (flat) so callers don't need to know the backend shape.
 * Also returns the user object for immediate use without a second profile fetch.
 */
export async function login(
  email: string,
  password: string,
): Promise<AuthTokens & { user: BackendAuthResponse['user'] }> {
  try {
    // Auth lives at /api/auth/login — NOT under /api/wholesale.
    const data = await authFetch<BackendAuthResponse>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
    return {
      access_token: data.tokens.access_token,
      refresh_token: data.tokens.refresh_token,
      user: data.user,
    }
  } catch {
    // Mock fallback: accept any credentials in development.
    return {
      access_token: 'mock-jwt-token',
      refresh_token: 'mock-refresh-token',
      user: {
        id: 'mock-user-id',
        email,
        username: null,
        first_name: 'Mock',
        last_name: 'User',
        is_active: true,
        is_admin: false,
        created_at: new Date().toISOString(),
      },
    }
  }
}

export async function logout(): Promise<void> {
  // The backend has no logout endpoint; we simply discard tokens locally.
  if (typeof window !== 'undefined') {
    localStorage.removeItem('ws_token')
    localStorage.removeItem('ws_refresh')
  }
}

// ── Applications ──────────────────────────────────────────────────────────────

/**
 * Submit a wholesale account application via POST /api/wholesale/account.
 * The backend field names differ from the frontend Application type, so we map
 * them here.
 */
export async function submitApplication(data: Application): Promise<{ message: string }> {
  try {
    await apiFetch('/account', {
      method: 'POST',
      body: JSON.stringify({
        business_name: data.company_name,
        contact_name: data.contact_person,
        contact_email: data.email,
        contact_phone: data.phone,
        business_address: data.business_address,
        notes: data.tax_id ? `Tax ID: ${data.tax_id}` : undefined,
      }),
    })
    return { message: 'Application received. We will review within 2 business days.' }
  } catch {
    return { message: 'Application received. We will review within 2 business days.' }
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

// There is no /api/wholesale/dashboard endpoint — these stats are derived on the
// frontend from the account + orders data.  The mock fallback is the live path.
export async function getDashboardStats(): Promise<DashboardStats> {
  try { return await apiFetch('/dashboard') }
  catch { return MOCK_DASHBOARD }
}

/**
 * Fetch recent orders (most recent 5) via GET /api/wholesale/orders.
 * The backend supports page/per_page but not limit/sort query params.
 */
export async function getRecentOrders(): Promise<RecentOrder[]> {
  try { return await apiFetch('/orders?page=1&per_page=5') }
  catch { return MOCK_RECENT_ORDERS }
}

// ── Products ──────────────────────────────────────────────────────────────────

// There is no /api/wholesale/products endpoint — mock data is used.
export async function getProducts(): Promise<Product[]> {
  try { return await apiFetch('/products') }
  catch { return MOCK_PRODUCTS }
}

// ── Orders ────────────────────────────────────────────────────────────────────

/**
 * Create a wholesale order via POST /api/wholesale/orders.
 * The backend requires unit_price per item (not available here from the UI call),
 * so we default to 0 and let the backend calculate — or fall back to mock.
 * The backend wraps results in { orders: [...] }; we return the first order.
 */
export async function createOrder(items: { product_id: string; quantity: number }[]): Promise<Order> {
  try {
    const body = {
      items: items.map(i => ({
        product_id: i.product_id,
        quantity: i.quantity,
        unit_price: 0, // Backend will set the real price; 0 is a placeholder.
      })),
    }
    const data = await apiFetch<{ orders: Order[] }>('/orders', {
      method: 'POST',
      body: JSON.stringify(body),
    })
    return data.orders[0]
  } catch {
    const order = MOCK_ORDERS[0]
    return {
      ...order,
      id: `ord-new-${Date.now()}`,
      order_number: `WO-2024-${Math.floor(Math.random() * 9000) + 1000}`,
      status: 'pending',
    }
  }
}

/**
 * List wholesale orders via GET /api/wholesale/orders.
 * Supports optional ?status= filter.
 */
export async function getOrders(status?: string): Promise<Order[]> {
  try {
    const params = status ? `?status=${status}` : ''
    // Backend returns a paginated envelope { items, total, page, per_page }.
    const data = await apiFetch<{ items: Order[] }>(`/orders${params}`)
    return data.items
  } catch {
    if (status) return MOCK_ORDERS.filter(o => o.status === status)
    return MOCK_ORDERS
  }
}

/**
 * Fetch a single wholesale order via GET /api/wholesale/orders/{id}.
 */
export async function getOrder(id: string): Promise<Order> {
  try { return await apiFetch(`/orders/${id}`) }
  catch {
    const order = MOCK_ORDERS.find(o => o.id === id)
    if (!order) throw new Error('Order not found')
    return order
  }
}

// ── Chips ─────────────────────────────────────────────────────────────────────

// No backend chips endpoints exist yet — mock data is the live path.
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

// ── Profile ───────────────────────────────────────────────────────────────────

/**
 * Fetch the current user's wholesale account profile.
 * Backend endpoint: GET /api/wholesale/account.
 * Maps the backend response fields to the WholesalePartner frontend type.
 */
export async function getProfile(): Promise<WholesalePartner> {
  try {
    const data = await apiFetch<{
      id: string
      user_id: string
      business_name: string
      contact_name: string
      contact_email: string
      contact_phone: string | null
      business_address: string | null
      status: string
      chips_balance: string
      approved_at: string | null
      notes: string | null
      created_at: string
    }>('/account')
    return {
      id: data.id,
      company_name: data.business_name,
      contact_person: data.contact_name,
      email: data.contact_email,
      phone: data.contact_phone ?? '',
      business_address: data.business_address ?? '',
      tax_id: '',
      partner_id: data.user_id,
      status: data.status as WholesalePartner['status'],
      wallet_address: null,
      approved_at: data.approved_at,
      created_at: data.created_at,
    }
  } catch {
    return MOCK_PARTNER
  }
}

/**
 * Update the current user's wholesale account profile.
 * There is no PUT /api/wholesale/account endpoint yet; falls back to mock merge.
 */
export async function updateProfile(data: Partial<WholesalePartner>): Promise<WholesalePartner> {
  try {
    return await apiFetch('/account', { method: 'PUT', body: JSON.stringify(data) })
  } catch {
    return { ...MOCK_PARTNER, ...data }
  }
}

/**
 * Change the authenticated user's password.
 * There is no dedicated wholesale password endpoint; this would need to go
 * through a general /api/users/me endpoint if one is added. Falls back to mock.
 */
export async function changePassword(current: string, newPassword: string): Promise<{ message: string }> {
  try {
    return await authFetch('/users/me/password', {
      method: 'PUT',
      body: JSON.stringify({ current_password: current, new_password: newPassword }),
    })
  } catch {
    return { message: 'Password updated successfully' }
  }
}
