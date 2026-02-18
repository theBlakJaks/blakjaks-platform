export interface WholesalePartner {
  id: string
  company_name: string
  contact_person: string
  email: string
  phone: string
  business_address: string
  tax_id: string
  partner_id: string
  status: 'pending' | 'approved' | 'suspended'
  wallet_address: string | null
  approved_at: string | null
  created_at: string
}

export interface AuthTokens {
  access_token: string
  refresh_token: string
}

export interface DashboardStats {
  total_orders: number
  total_tins: number
  chips_earned: number
  comps_received: number
  pending_order_value: number
  next_milestone_chips: number
  next_milestone_name: string
}

export interface Product {
  id: string
  name: string
  flavor: string
  strength: string
  price_per_tin: number
  min_order_qty: number
  image_url: string | null
  in_stock: boolean
}

export interface OrderItem {
  product_id: string
  product_name: string
  quantity: number
  unit_price: number
  line_total: number
}

export interface Order {
  id: string
  order_number: string
  items: OrderItem[]
  item_count: number
  total_tins: number
  total_cost: number
  chips_earned: number
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
  tracking_number: string | null
  created_at: string
  updated_at: string
}

export interface ChipStats {
  lifetime_chips: number
  this_month: number
  last_month: number
  comps_received: number
}

export interface MonthlyChips {
  month: string
  chips: number
}

export interface CompMilestone {
  name: string
  chips_required: number
  comp_value: number
  achieved: boolean
  current_chips: number
}

export interface Application {
  company_name: string
  contact_person: string
  email: string
  phone: string
  business_address: string
  tax_id: string
}

export interface RecentOrder {
  id: string
  order_number: string
  date: string
  tins: number
  total: number
  status: string
}
