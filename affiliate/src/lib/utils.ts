export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount)
}

export function formatNumber(num: number): string {
  return num.toLocaleString('en-US')
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
}

export function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('en-US', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

export function truncateHash(hash: string, chars = 8): string {
  if (!hash || hash.length <= chars * 2 + 3) return hash || ''
  return `${hash.slice(0, chars)}...${hash.slice(-chars)}`
}

export function truncateAddress(addr: string, chars = 6): string {
  if (!addr || addr.length <= chars * 2 + 3) return addr || ''
  return `${addr.slice(0, chars)}...${addr.slice(-chars)}`
}

export function getPolygonscanUrl(hash: string): string {
  return `https://polygonscan.com/tx/${hash}`
}

export function getNextSunday(): string {
  const now = new Date()
  const day = now.getDay()
  const diff = day === 0 ? 7 : 7 - day
  const next = new Date(now)
  next.setDate(now.getDate() + diff)
  return next.toISOString()
}

export const STATUS_COLORS: Record<string, string> = {
  completed: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  active: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  approved: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  processing: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  pending_approval: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  pending: 'bg-zinc-500/20 text-zinc-400 border-zinc-500/30',
  inactive: 'bg-zinc-500/20 text-zinc-400 border-zinc-500/30',
  failed: 'bg-red-500/20 text-red-400 border-red-500/30',
  expired: 'bg-red-500/20 text-red-400 border-red-500/30',
  withdrawn: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
}

export const TIER_COLORS: Record<string, string> = {
  Member: 'bg-zinc-500/20 text-zinc-400 border-zinc-500/30',
  VIP: 'bg-zinc-400/20 text-zinc-300 border-zinc-400/30',
  'High Roller': 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  Whale: 'bg-cyan-500/20 text-cyan-300 border-cyan-500/30',
}
