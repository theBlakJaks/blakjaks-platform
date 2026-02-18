import type {
  WholesalePartner, DashboardStats, Product, Order, ChipStats,
  MonthlyChips, CompMilestone, RecentOrder,
} from './types'

export const MOCK_PARTNER: WholesalePartner = {
  id: 'wp-001',
  company_name: 'Premium Smoke Shop LLC',
  contact_person: 'Marcus Johnson',
  email: 'marcus@premiumsmokeshop.com',
  phone: '(555) 234-5678',
  business_address: '1234 Commerce Blvd, Suite 200, Las Vegas, NV 89101',
  tax_id: '82-1234567',
  partner_id: 'WP-2024-0042',
  status: 'approved',
  wallet_address: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38',
  approved_at: '2024-08-15T10:00:00Z',
  created_at: '2024-08-10T14:30:00Z',
}

export const MOCK_DASHBOARD: DashboardStats = {
  total_orders: 24,
  total_tins: 18_400,
  chips_earned: 18_400,
  comps_received: 5_000,
  pending_order_value: 2_100,
  next_milestone_chips: 25_000,
  next_milestone_name: 'Gold',
}

export const MOCK_PRODUCTS: Product[] = [
  { id: 'prod-01', name: 'BlakJak Original 3mg', flavor: 'Original', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-02', name: 'BlakJak Original 6mg', flavor: 'Original', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-03', name: 'BlakJak Mint 3mg', flavor: 'Mint', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-04', name: 'BlakJak Mint 6mg', flavor: 'Mint', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-05', name: 'BlakJak Wintergreen 3mg', flavor: 'Wintergreen', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-06', name: 'BlakJak Wintergreen 6mg', flavor: 'Wintergreen', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-07', name: 'BlakJak Cinnamon 3mg', flavor: 'Cinnamon', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-08', name: 'BlakJak Cinnamon 6mg', flavor: 'Cinnamon', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-09', name: 'BlakJak Coffee 3mg', flavor: 'Coffee', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-10', name: 'BlakJak Coffee 6mg', flavor: 'Coffee', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-11', name: 'BlakJak Citrus 3mg', flavor: 'Citrus', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-12', name: 'BlakJak Citrus 6mg', flavor: 'Citrus', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
  { id: 'prod-13', name: 'BlakJak Berry 3mg', flavor: 'Berry', strength: '3mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: false },
  { id: 'prod-14', name: 'BlakJak Berry 6mg', flavor: 'Berry', strength: '6mg', price_per_tin: 2.10, min_order_qty: 100, image_url: null, in_stock: true },
]

const ORDER_ITEMS = [
  { product_id: 'prod-01', product_name: 'BlakJak Original 3mg', quantity: 500, unit_price: 2.10, line_total: 1050 },
  { product_id: 'prod-03', product_name: 'BlakJak Mint 3mg', quantity: 300, unit_price: 2.10, line_total: 630 },
  { product_id: 'prod-05', product_name: 'BlakJak Wintergreen 3mg', quantity: 200, unit_price: 2.10, line_total: 420 },
  { product_id: 'prod-07', product_name: 'BlakJak Cinnamon 3mg', quantity: 100, unit_price: 2.10, line_total: 210 },
]

const STATUSES: Order['status'][] = ['delivered', 'delivered', 'shipped', 'processing', 'pending', 'delivered', 'delivered', 'shipped']

export const MOCK_ORDERS: Order[] = Array.from({ length: 12 }, (_, i) => {
  const itemCount = Math.floor(Math.random() * 3) + 1
  const items = ORDER_ITEMS.slice(0, itemCount).map(item => {
    const qty = (Math.floor(Math.random() * 5) + 1) * 100
    return { ...item, quantity: qty, line_total: Math.round(qty * item.unit_price * 100) / 100 }
  })
  const totalTins = items.reduce((s, it) => s + it.quantity, 0)
  const totalCost = items.reduce((s, it) => s + it.line_total, 0)
  const status = STATUSES[i % STATUSES.length]
  return {
    id: `ord-${String(i + 1).padStart(3, '0')}`,
    order_number: `WO-2024-${String(1042 + i).padStart(4, '0')}`,
    items,
    item_count: items.length,
    total_tins: totalTins,
    total_cost: Math.round(totalCost * 100) / 100,
    chips_earned: totalTins,
    status,
    tracking_number: status === 'shipped' || status === 'delivered' ? `1Z999AA10123456${784 + i}` : null,
    created_at: new Date(Date.now() - (12 - i) * 7 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - (12 - i) * 5 * 86400000).toISOString(),
  }
})

export const MOCK_RECENT_ORDERS: RecentOrder[] = MOCK_ORDERS.slice(-5).reverse().map(o => ({
  id: o.id,
  order_number: o.order_number,
  date: o.created_at,
  tins: o.total_tins,
  total: o.total_cost,
  status: o.status,
}))

export const MOCK_CHIP_STATS: ChipStats = {
  lifetime_chips: 18_400,
  this_month: 2_800,
  last_month: 2_200,
  comps_received: 5_000,
}

export const MOCK_MONTHLY_CHIPS: MonthlyChips[] = [
  { month: 'Oct', chips: 3200 },
  { month: 'Nov', chips: 4100 },
  { month: 'Dec', chips: 3800 },
  { month: 'Jan', chips: 2200 },
  { month: 'Feb', chips: 2800 },
]

export const MOCK_MILESTONES: CompMilestone[] = [
  { name: 'Bronze', chips_required: 5000, comp_value: 1000, achieved: true, current_chips: 18400 },
  { name: 'Silver', chips_required: 10000, comp_value: 5000, achieved: true, current_chips: 18400 },
  { name: 'Gold', chips_required: 25000, comp_value: 10000, achieved: false, current_chips: 18400 },
  { name: 'Platinum', chips_required: 50000, comp_value: 25000, achieved: false, current_chips: 18400 },
  { name: 'Diamond', chips_required: 100000, comp_value: 50000, achieved: false, current_chips: 18400 },
]
