'use client'

interface ProgressBarProps {
  value: number
  max: number
  height?: number
  label?: string
}

export default function ProgressBar({ value, max, height = 8, label }: ProgressBarProps) {
  const pct = Math.min((value / max) * 100, 100)
  return (
    <div>
      {label && (
        <div className="mb-1 flex items-center justify-between text-xs">
          <span className="text-[var(--color-text-muted)]">{label}</span>
          <span className="text-[var(--color-text-dim)]">{Math.round(pct)}%</span>
        </div>
      )}
      <div className="overflow-hidden rounded-full bg-[var(--color-border)]" style={{ height }}>
        <div className="gold-gradient h-full rounded-full transition-all duration-500" style={{ width: `${pct}%` }} />
      </div>
    </div>
  )
}
