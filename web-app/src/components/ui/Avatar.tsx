'use client'

import type { Tier } from '@/lib/types'
import { getTierColor } from '@/lib/utils'

interface AvatarProps {
  name: string
  tier?: Tier
  size?: 'sm' | 'md' | 'lg'
}

export default function Avatar({ name, tier, size = 'md' }: AvatarProps) {
  const initials = name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)

  const sizes = { sm: 'h-8 w-8 text-xs', md: 'h-10 w-10 text-sm', lg: 'h-14 w-14 text-lg' }
  const borderColor = tier ? getTierColor(tier) : 'var(--color-border-light)'

  return (
    <div
      className={`flex items-center justify-center rounded-full bg-[var(--color-bg-surface)] font-semibold text-[var(--color-text-muted)] border-2 ${sizes[size]}`}
      style={{ borderColor }}
    >
      {initials}
    </div>
  )
}
