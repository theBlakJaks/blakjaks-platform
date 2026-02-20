import client from './client'

// ── Types ─────────────────────────────────────────────────────────────────

export interface WholesaleAccount {
  id: string
  user_id: string
  business_name: string
  contact_name: string
  contact_email: string
  contact_phone: string | null
  business_address: string | null
  status: string // pending | approved | suspended | rejected
  chips_balance: string
  approved_at: string | null
  approved_by: string | null
  notes: string | null
  created_at: string
}

export interface WholesaleOrder {
  id: string
  account_id: string
  product_sku: string | null
  quantity: number
  unit_price: string
  total_amount: string
  chips_earned: string
  status: string
  shipping_address: string | null
  tracking_number: string | null
  notes: string | null
  created_at: string
}

export interface AccountsResponse {
  items: WholesaleAccount[]
  total: number
  page: number
  per_page: number
}

export interface OrdersResponse {
  items: WholesaleOrder[]
  total: number
  page: number
  per_page: number
}

// ── Mock data ─────────────────────────────────────────────────────────────

const MOCK_ACCOUNTS: WholesaleAccount[] = [
  {
    id: 'ws-001',
    user_id: 'u-001',
    business_name: 'Peak Casino Supply Co.',
    contact_name: 'Rachel Torres',
    contact_email: 'rachel@peakcasino.com',
    contact_phone: '+1-702-555-0101',
    business_address: '3800 S Las Vegas Blvd, Las Vegas, NV 89109',
    status: 'pending',
    chips_balance: '0.00',
    approved_at: null,
    approved_by: null,
    notes: 'Large venue, 200+ tables',
    created_at: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
  {
    id: 'ws-002',
    user_id: 'u-002',
    business_name: 'Gold Chip Distributors LLC',
    contact_name: 'Marcus Webb',
    contact_email: 'marcus@goldchip.com',
    contact_phone: '+1-702-555-0202',
    business_address: '100 Fremont St, Las Vegas, NV 89101',
    status: 'pending',
    chips_balance: '0.00',
    approved_at: null,
    approved_by: null,
    notes: null,
    created_at: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
  {
    id: 'ws-003',
    user_id: 'u-003',
    business_name: 'Desert Gaming Group',
    contact_name: 'Sandra Kim',
    contact_email: 'sandra@desertgaming.com',
    contact_phone: '+1-480-555-0303',
    business_address: '7500 E Camelback Rd, Scottsdale, AZ 85251',
    status: 'approved',
    chips_balance: '25000.00',
    approved_at: new Date(Date.now() - 14 * 86400000).toISOString(),
    approved_by: 'admin',
    notes: null,
    created_at: new Date(Date.now() - 20 * 86400000).toISOString(),
  },
  {
    id: 'ws-004',
    user_id: 'u-004',
    business_name: 'Royal Flush Resorts',
    contact_name: 'James Donovan',
    contact_email: 'james@royalflush.com',
    contact_phone: '+1-702-555-0404',
    business_address: '2000 Las Vegas Blvd N, Las Vegas, NV 89030',
    status: 'approved',
    chips_balance: '47500.00',
    approved_at: new Date(Date.now() - 30 * 86400000).toISOString(),
    approved_by: 'admin',
    notes: 'Priority account',
    created_at: new Date(Date.now() - 45 * 86400000).toISOString(),
  },
]

const MOCK_ORDERS: WholesaleOrder[] = [
  {
    id: 'ord-001',
    account_id: 'ws-003',
    product_sku: 'BJ-CHIP-100',
    quantity: 500,
    unit_price: '10.00',
    total_amount: '5000.00',
    chips_earned: '500.00',
    status: 'delivered',
    shipping_address: '7500 E Camelback Rd, Scottsdale, AZ 85251',
    tracking_number: '1Z999AA10123456784',
    notes: null,
    created_at: new Date(Date.now() - 10 * 86400000).toISOString(),
  },
  {
    id: 'ord-002',
    account_id: 'ws-003',
    product_sku: 'BJ-CHIP-500',
    quantity: 200,
    unit_price: '45.00',
    total_amount: '9000.00',
    chips_earned: '900.00',
    status: 'processing',
    shipping_address: '7500 E Camelback Rd, Scottsdale, AZ 85251',
    tracking_number: null,
    notes: 'Rush order',
    created_at: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
  {
    id: 'ord-003',
    account_id: 'ws-004',
    product_sku: 'BJ-CHIP-100',
    quantity: 1000,
    unit_price: '10.00',
    total_amount: '10000.00',
    chips_earned: '1000.00',
    status: 'delivered',
    shipping_address: '2000 Las Vegas Blvd N, Las Vegas, NV 89030',
    tracking_number: '1Z999AA10123456785',
    notes: null,
    created_at: new Date(Date.now() - 20 * 86400000).toISOString(),
  },
  {
    id: 'ord-004',
    account_id: 'ws-004',
    product_sku: 'BJ-CHIP-1000',
    quantity: 50,
    unit_price: '85.00',
    total_amount: '4250.00',
    chips_earned: '425.00',
    status: 'shipped',
    shipping_address: '2000 Las Vegas Blvd N, Las Vegas, NV 89030',
    tracking_number: '1Z999AA10123456786',
    notes: null,
    created_at: new Date(Date.now() - 7 * 86400000).toISOString(),
  },
  {
    id: 'ord-005',
    account_id: 'ws-004',
    product_sku: 'BJ-CHIP-500',
    quantity: 100,
    unit_price: '45.00',
    total_amount: '4500.00',
    chips_earned: '450.00',
    status: 'pending',
    shipping_address: '2000 Las Vegas Blvd N, Las Vegas, NV 89030',
    tracking_number: null,
    notes: null,
    created_at: new Date(Date.now() - 1 * 86400000).toISOString(),
  },
]

// ── API functions ─────────────────────────────────────────────────────────

/**
 * GET /admin/wholesale/accounts
 * List all wholesale accounts with optional status filter.
 */
export async function listWholesaleAccounts(
  status?: string,
  page = 1,
  perPage = 20,
): Promise<AccountsResponse> {
  try {
    const params: Record<string, string | number> = { page, per_page: perPage }
    if (status) params.status = status
    const { data } = await client.get('/admin/wholesale/accounts', { params })
    return data
  } catch {
    let filtered = [...MOCK_ACCOUNTS]
    if (status) filtered = filtered.filter(a => a.status === status)
    const start = (page - 1) * perPage
    return {
      items: filtered.slice(start, start + perPage),
      total: filtered.length,
      page,
      per_page: perPage,
    }
  }
}

/**
 * POST /admin/wholesale/accounts/{account_id}/approve
 * Approve a pending wholesale account.
 */
export async function approveWholesaleAccount(accountId: string): Promise<WholesaleAccount> {
  try {
    const { data } = await client.post(`/admin/wholesale/accounts/${accountId}/approve`)
    return data
  } catch {
    const account = MOCK_ACCOUNTS.find(a => a.id === accountId) || MOCK_ACCOUNTS[0]
    return {
      ...account,
      status: 'approved',
      approved_at: new Date().toISOString(),
      approved_by: 'admin',
    }
  }
}

/**
 * POST /admin/wholesale/accounts/{account_id}/reject
 * Reject a pending wholesale account.
 * Note: This endpoint is not yet defined in the backend; falls back to mock on error.
 */
export async function rejectWholesaleAccount(accountId: string): Promise<WholesaleAccount> {
  try {
    const { data } = await client.post(`/admin/wholesale/accounts/${accountId}/reject`)
    return data
  } catch {
    const account = MOCK_ACCOUNTS.find(a => a.id === accountId) || MOCK_ACCOUNTS[0]
    return {
      ...account,
      status: 'rejected',
    }
  }
}

/**
 * GET /admin/wholesale/orders
 * List wholesale orders, optionally filtered by account_id.
 */
export async function listWholesaleOrders(
  accountId?: string,
  status?: string,
  page = 1,
  perPage = 20,
): Promise<OrdersResponse> {
  try {
    const params: Record<string, string | number> = { page, per_page: perPage }
    if (accountId) params.account_id = accountId
    if (status) params.status = status
    const { data } = await client.get('/admin/wholesale/orders', { params })
    return data
  } catch {
    let filtered = [...MOCK_ORDERS]
    if (accountId) filtered = filtered.filter(o => o.account_id === accountId)
    if (status) filtered = filtered.filter(o => o.status === status)
    const start = (page - 1) * perPage
    return {
      items: filtered.slice(start, start + perPage),
      total: filtered.length,
      page,
      per_page: perPage,
    }
  }
}

/**
 * PATCH /admin/wholesale/orders/{order_id}/status
 * Update the status of a wholesale order.
 */
export async function updateWholesaleOrderStatus(
  orderId: string,
  status: string,
): Promise<WholesaleOrder> {
  try {
    const { data } = await client.patch(`/admin/wholesale/orders/${orderId}/status`, { status })
    return data
  } catch {
    const order = MOCK_ORDERS.find(o => o.id === orderId) || MOCK_ORDERS[0]
    return { ...order, status }
  }
}

/**
 * POST /admin/comps
 * Award a comp to the user associated with a wholesale account.
 * Uses the existing comps endpoint with comp_type = 'wholesale_comp'.
 */
export async function awardWholesaleComp(
  userId: string,
  amount: number,
  reason: string,
): Promise<{ id: string; status: string }> {
  try {
    const { data } = await client.post('/admin/comps', {
      user_id: userId,
      amount,
      reason,
      comp_type: 'wholesale_comp',
    })
    return data
  } catch {
    return { id: `comp-ws-${Date.now()}`, status: 'pending' }
  }
}
