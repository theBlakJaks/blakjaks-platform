'use client'

import type { LucideIcon } from 'lucide-react'

interface StatCardProps {
  icon: LucideIcon
  label: string
  value: string
  sub?: string
  color?: string
}

export default function StatCard({ icon: Icon, label, value, sub, color }: StatCardProps) {
  return (
    <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6 transition-transform hover:-translate-y-0.5">
      <div
        className="mb-4 flex h-10 w-10 items-center justify-center rounded-xl"
        style={{ backgroundColor: `${color || 'var(--color-gold)'}1a` }}
      >
        <Icon size={20} style={{ color: color || 'var(--color-gold)' }} />
      </div>
      <p className="text-sm text-[var(--color-text-muted)]">{label}</p>
      <p className="mt-1 text-2xl font-bold text-white">{value}</p>
      {sub && <p className="mt-1 text-xs text-[var(--color-text-dim)]">{sub}</p>}
    </div>
  )
}
