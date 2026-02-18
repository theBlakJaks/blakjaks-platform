import type { ReactNode, ButtonHTMLAttributes } from 'react'

interface GoldButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode
  variant?: 'primary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
}

export default function GoldButton({ children, variant = 'primary', size = 'md', className = '', ...props }: GoldButtonProps) {
  const sizes = { sm: 'px-3 py-1.5 text-xs', md: 'px-5 py-2.5 text-sm', lg: 'px-8 py-3 text-base' }
  const variants = {
    primary: 'gold-gradient text-black font-semibold hover:opacity-90 disabled:opacity-40',
    outline: 'border border-[var(--color-gold)] text-[var(--color-gold)] hover:bg-[var(--color-gold)]/10 disabled:opacity-40',
  }
  return (
    <button className={`inline-flex items-center justify-center gap-2 rounded-xl font-medium transition-all ${sizes[size]} ${variants[variant]} ${className}`} {...props}>
      {children}
    </button>
  )
}
