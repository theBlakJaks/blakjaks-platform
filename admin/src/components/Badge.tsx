import { TIER_COLORS, STATUS_COLORS } from '../utils/constants'

interface BadgeProps {
  label: string
  variant?: 'tier' | 'status'
}

export default function Badge({ label, variant = 'status' }: BadgeProps) {
  const colorMap = variant === 'tier' ? TIER_COLORS : STATUS_COLORS
  const colors = colorMap[label] || 'bg-slate-100 text-slate-800'

  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${colors}`}>
      {label}
    </span>
  )
}
