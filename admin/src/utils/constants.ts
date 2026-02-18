import {
  LayoutDashboard,
  Users,
  QrCode,
  ShoppingCart,
  Gift,
  Network,
  MessageSquare,
  Vote,
  Wallet,
  BarChart3,
  Settings,
} from 'lucide-react'

export const NAV_ITEMS = [
  { label: 'Dashboard', path: '/', icon: LayoutDashboard },
  { label: 'Users', path: '/users', icon: Users },
  { label: 'QR Codes', path: '/qr-codes', icon: QrCode },
  { label: 'Orders', path: '/orders', icon: ShoppingCart },
  { label: 'Comps', path: '/comps', icon: Gift },
  { label: 'Affiliates', path: '/affiliates', icon: Network },
  { label: 'Social Hub', path: '/social', icon: MessageSquare },
  { label: 'Governance', path: '/governance', icon: Vote },
  { label: 'Treasury', path: '/treasury', icon: Wallet },
  { label: 'Analytics', path: '/analytics', icon: BarChart3 },
  { label: 'Settings', path: '/settings', icon: Settings },
]

export const TIER_COLORS: Record<string, string> = {
  Standard: 'bg-red-500 text-white',
  VIP: 'bg-slate-400 text-white',
  'High Roller': 'bg-amber-500 text-white',
  Whale: 'bg-slate-300 text-slate-900',
}

export const STATUS_COLORS: Record<string, string> = {
  active: 'bg-emerald-100 text-emerald-800',
  pending: 'bg-amber-100 text-amber-800',
  completed: 'bg-blue-100 text-blue-800',
  closed: 'bg-slate-100 text-slate-800',
  rejected: 'bg-red-100 text-red-800',
  approved: 'bg-emerald-100 text-emerald-800',
  suspended: 'bg-red-100 text-red-800',
  paid: 'bg-emerald-100 text-emerald-800',
  failed: 'bg-red-100 text-red-800',
  draft: 'bg-slate-100 text-slate-800',
  unused: 'bg-emerald-100 text-emerald-800',
  scanned: 'bg-slate-100 text-slate-800',
  delivered: 'bg-emerald-100 text-emerald-800',
  shipped: 'bg-blue-100 text-blue-800',
  processing: 'bg-amber-100 text-amber-800',
  message: 'bg-indigo-100 text-indigo-800',
  vote: 'bg-purple-100 text-purple-800',
  admin: 'bg-indigo-100 text-indigo-800',
  cancelled: 'bg-red-100 text-red-800',
  refunded: 'bg-red-100 text-red-800',
  resolved: 'bg-emerald-100 text-emerald-800',
  dismissed: 'bg-slate-100 text-slate-800',
  changes_requested: 'bg-orange-100 text-orange-800',
}

export const VOTE_TYPE_COLORS: Record<string, string> = {
  flavor: 'bg-pink-100 text-pink-800',
  product: 'bg-blue-100 text-blue-800',
  loyalty: 'bg-amber-100 text-amber-800',
  corporate: 'bg-purple-100 text-purple-800',
}

export const VOTE_TYPE_MIN_TIER: Record<string, string> = {
  flavor: 'VIP',
  product: 'High Roller',
  loyalty: 'High Roller',
  corporate: 'Whale',
}

export const COMP_TYPE_COLORS: Record<string, string> = {
  crypto_100: 'bg-indigo-100 text-indigo-800',
  crypto_1k: 'bg-indigo-100 text-indigo-800',
  crypto_10k: 'bg-indigo-100 text-indigo-800',
  casino_comp: 'bg-amber-100 text-amber-800',
  guaranteed_5: 'bg-emerald-100 text-emerald-800',
  trip: 'bg-purple-100 text-purple-800',
  manual: 'bg-slate-100 text-slate-800',
}

export const POOL_COLORS: Record<string, string> = {
  consumer: 'bg-indigo-100 text-indigo-800',
  affiliate: 'bg-purple-100 text-purple-800',
  wholesale: 'bg-amber-100 text-amber-800',
}

export const HEALTH_COLORS: Record<string, string> = {
  healthy: 'text-emerald-500',
  degraded: 'text-amber-500',
  down: 'text-red-500',
}
