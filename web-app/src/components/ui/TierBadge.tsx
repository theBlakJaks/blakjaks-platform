'use client'

import type { Tier } from '@/lib/types'
import { getTierColor, getTierIcon, getTierLabel } from '@/lib/utils'

export default function TierBadge({ tier, size = 'md' }: { tier: Tier; size?: 'sm' | 'md' | 'lg' }) {
  const color = getTierColor(tier)
  const sizes = { sm: 'text-xs px-2 py-0.5', md: 'text-sm px-3 py-1', lg: 'text-base px-4 py-1.5' }

  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border font-medium ${sizes[size]}`}
      style={{ color, borderColor: `${color}4d`, backgroundColor: `${color}1a` }}
    >
      <span>{getTierIcon(tier)}</span>
      <span>{getTierLabel(tier)}</span>
    </span>
  )
}
