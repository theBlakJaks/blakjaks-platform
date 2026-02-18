'use client'

import type { ReactNode, ButtonHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'
import Spinner from './Spinner'

interface GoldButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  fullWidth?: boolean
  loading?: boolean
}

export default function GoldButton({
  children, variant = 'primary', size = 'md', fullWidth, loading, disabled, className, ...props
}: GoldButtonProps) {
  const sizes = {
    sm: 'px-3 py-1.5 text-xs rounded-lg',
    md: 'px-5 py-2.5 text-sm rounded-xl',
    lg: 'px-8 py-3 text-base rounded-xl',
  }

  const variants = {
    primary: 'gold-gradient text-black font-semibold hover:opacity-90',
    secondary: 'border border-[var(--color-gold)] text-[var(--color-gold)] hover:bg-[var(--color-gold)]/10',
    ghost: 'text-[var(--color-text-muted)] hover:text-[var(--color-text)] hover:bg-[var(--color-bg-hover)]',
    danger: 'bg-red-500/20 text-red-400 border border-red-500/30 hover:bg-red-500/30',
  }

  return (
    <button
      className={cn(
        'inline-flex items-center justify-center gap-2 font-medium transition-all disabled:opacity-40 disabled:cursor-not-allowed',
        sizes[size],
        variants[variant],
        fullWidth && 'w-full',
        className,
      )}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <Spinner className="h-4 w-4" />}
      {children}
    </button>
  )
}
