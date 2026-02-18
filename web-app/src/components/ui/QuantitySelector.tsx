'use client'

import { Minus, Plus } from 'lucide-react'

interface QuantitySelectorProps {
  value: number
  onChange: (value: number) => void
  min?: number
  max?: number
}

export default function QuantitySelector({ value, onChange, min = 1, max = 99 }: QuantitySelectorProps) {
  return (
    <div className="inline-flex items-center rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)]">
      <button
        onClick={() => onChange(Math.max(min, value - 1))}
        disabled={value <= min}
        className="flex h-9 w-9 items-center justify-center rounded-l-xl text-[var(--color-text-muted)] transition-colors hover:bg-[var(--color-bg-hover)] hover:text-white disabled:opacity-40"
      >
        <Minus size={14} />
      </button>
      <span className="flex h-9 w-10 items-center justify-center text-sm font-medium text-white">
        {value}
      </span>
      <button
        onClick={() => onChange(Math.min(max, value + 1))}
        disabled={value >= max}
        className="flex h-9 w-9 items-center justify-center rounded-r-xl text-[var(--color-text-muted)] transition-colors hover:bg-[var(--color-bg-hover)] hover:text-white disabled:opacity-40"
      >
        <Plus size={14} />
      </button>
    </div>
  )
}
