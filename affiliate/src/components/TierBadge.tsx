import { TIER_COLORS } from '@/lib/utils'

export default function TierBadge({ tier }: { tier: string }) {
  const colors = TIER_COLORS[tier] || TIER_COLORS.Member
  return (
    <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${colors}`}>
      {tier}
    </span>
  )
}
