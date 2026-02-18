import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'
import type { Tier } from './types'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount)
}

export function formatDate(date: string | Date, format?: 'short' | 'long'): string {
  const d = typeof date === 'string' ? new Date(date) : date
  if (format === 'long') {
    return d.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
  }
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
}

export function formatRelativeTime(date: string | Date): string {
  const now = Date.now()
  const d = typeof date === 'string' ? new Date(date).getTime() : date.getTime()
  const diff = Math.floor((now - d) / 1000)

  if (diff < 60) return `${diff}s ago`
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`
  return formatDate(date)
}

export function truncateAddress(address: string, chars = 6): string {
  if (!address || address.length <= chars * 2 + 3) return address || ''
  return `${address.slice(0, chars)}...${address.slice(-chars)}`
}

export function getTierColor(tier: Tier): string {
  const colors: Record<Tier, string> = {
    standard: '#EF4444',
    vip: '#A1A1AA',
    high_roller: '#D4AF37',
    whale: '#E5E7EB',
  }
  return colors[tier]
}

export function getTierIcon(tier: Tier): string {
  const icons: Record<Tier, string> = {
    standard: '\u2660',
    vip: '\u2666',
    high_roller: '\u2663',
    whale: '\u265B',
  }
  return icons[tier]
}

export function getTierLabel(tier: Tier): string {
  const labels: Record<Tier, string> = {
    standard: 'Standard',
    vip: 'VIP',
    high_roller: 'High Roller',
    whale: 'Whale',
  }
  return labels[tier]
}

export const STATUS_COLORS: Record<string, string> = {
  delivered: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  active: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  completed: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  shipped: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  processing: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  pending: 'bg-zinc-500/20 text-zinc-400 border-zinc-500/30',
  cancelled: 'bg-red-500/20 text-red-400 border-red-500/30',
  failed: 'bg-red-500/20 text-red-400 border-red-500/30',
  inactive: 'bg-zinc-500/20 text-zinc-400 border-zinc-500/30',
}
