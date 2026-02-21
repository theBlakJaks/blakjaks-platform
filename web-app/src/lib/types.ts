export type Tier = 'standard' | 'vip' | 'high_roller' | 'whale'

export type OrderStatus = 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'

export type TransactionType = 'comp' | 'purchase' | 'withdrawal' | 'affiliate'

export type TransactionStatus = 'completed' | 'pending' | 'failed'

export type VoteStatus = 'active' | 'closed' | 'upcoming'

export type ProposalStatus = 'submitted' | 'under_review' | 'approved' | 'rejected'

export type CompType = 'scan' | 'referral' | 'tier_bonus' | 'governance' | 'promotion'

export interface User {
  id: string
  email: string
  username: string
  firstName: string
  lastName: string
  phone: string
  address: {
    street: string
    city: string
    state: string
    zip: string
    country: string
  }
  tier: Tier
  permanentTier: Tier
  effectiveTier: Tier
  totalScans: number
  quarterlyScans: number
  lifetimeUSDC: number
  walletAddress: string
  memberSince: string
  avatar?: string
  avatarUrl?: string
}

export interface Product {
  id: string
  name: string
  flavor: string
  strength: string
  price: number
  description: string
  image: string
  inStock: boolean
}

export interface CartItem {
  product: Product
  quantity: number
}

export interface OrderItem {
  product: Product
  quantity: number
  unitPrice: number
  subtotal: number
}

export interface Order {
  id: string
  orderNumber: string
  date: string
  items: OrderItem[]
  subtotal: number
  shipping: number
  tax: number
  total: number
  status: OrderStatus
  trackingNumber?: string
  ageVerificationId?: string
}

export interface Transaction {
  id: string
  date: string
  type: TransactionType
  amount: number
  status: TransactionStatus
  txHash?: string
  description?: string
}

export interface Channel {
  id: string
  name: string
  category: string
  description: string
  tierRequired: Tier
  unreadCount: number
  icon: string
}

export interface Message {
  id: string
  channelId: string
  userId: string
  username: string
  userTier: Tier
  content: string
  timestamp: string
  reactions: Record<string, string[]>
  replyTo?: string
  replyToContent?: string
  isSystem?: boolean
  originalLanguage?: string
  gifUrl?: string
  avatarUrl?: string
}

export interface VoteOption {
  id: string
  label: string
  votes: number
}

export interface Vote {
  id: string
  title: string
  description: string
  options: VoteOption[]
  deadline: string
  status: VoteStatus
  userVote?: string
  results?: Record<string, number>
  totalVotes: number
}

export interface Proposal {
  id: string
  title: string
  description: string
  submittedBy: string
  status: ProposalStatus
  createdAt: string
}

export interface CompAward {
  id: string
  date: string
  amount: number
  type: CompType
  txHash?: string
  status: TransactionStatus
}

export interface Scan {
  id: string
  date: string
  qrCodeId: string
  product?: string
}

export interface TreasuryWallet {
  name: string
  pool: string
  balance: number
  address: string
  utilization: number
  sparklineData: number[]
}

export interface TransparencyOverview {
  totalScans: number
  monthlySales: number
  activeMembers: number
  growthRate: number
}

export interface ActivityFeedItem {
  id: string
  message: string
  timestamp: string
  type: 'scan' | 'comp' | 'order' | 'governance' | 'social' | 'system'
}

export interface DashboardData {
  user: User
  recentActivity: ActivityFeedItem[]
  walletBalance: number
  pendingComps: number
  unreadMessages: number
}

export interface MonthlyEarning {
  month: string
  comps: number
  referrals: number
}
