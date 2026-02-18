export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount)
}

export function formatNumber(num: number): string {
  return num.toLocaleString('en-US')
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

export function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export function truncateAddress(addr: string, chars = 6): string {
  if (!addr || addr.length <= chars * 2 + 3) return addr || ''
  return `${addr.slice(0, chars)}...${addr.slice(-chars)}`
}

export const STATUS_COLORS: Record<string, string> = {
  delivered: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  approved: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  shipped: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  processing: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  pending: 'bg-zinc-500/20 text-zinc-400 border-zinc-500/30',
  cancelled: 'bg-red-500/20 text-red-400 border-red-500/30',
  suspended: 'bg-red-500/20 text-red-400 border-red-500/30',
}
