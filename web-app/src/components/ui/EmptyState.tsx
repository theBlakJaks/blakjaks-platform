'use client'

import type { LucideIcon } from 'lucide-react'
import GoldButton from './GoldButton'

interface EmptyStateProps {
  icon: LucideIcon
  message: string
  actionLabel?: string
  onAction?: () => void
}

export default function EmptyState({ icon: Icon, message, actionLabel, onAction }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-[var(--color-bg-surface)]">
        <Icon size={28} className="text-[var(--color-text-dim)]" />
      </div>
      <p className="mb-4 text-[var(--color-text-muted)]">{message}</p>
      {actionLabel && onAction && (
        <GoldButton onClick={onAction}>{actionLabel}</GoldButton>
      )}
    </div>
  )
}
