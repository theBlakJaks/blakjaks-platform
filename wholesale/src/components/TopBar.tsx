'use client'

import Link from 'next/link'
import { Plus, Coins } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { formatNumber } from '@/lib/utils'
import GoldButton from './GoldButton'

export default function TopBar() {
  const { partner } = useAuth()

  return (
    <header className="flex h-16 items-center justify-between border-b border-[var(--color-border)] bg-[var(--color-bg-card)] px-6">
      <div className="flex items-center gap-4">
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--color-gold)]/20 text-sm font-bold text-[var(--color-gold)]">
          {partner?.company_name?.charAt(0) || 'W'}
        </div>
        <div>
          <p className="text-sm font-medium text-white">{partner?.company_name || 'Wholesale Partner'}</p>
          <p className="text-xs text-[var(--color-text-dim)]">{partner?.partner_id || 'WP-0000'}</p>
        </div>
      </div>

      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-2">
          <Coins size={16} className="text-[var(--color-gold)]" />
          <span className="text-sm font-medium text-white">{formatNumber(18_400)} chips</span>
        </div>
        <Link href="/orders/new">
          <GoldButton size="sm">
            <Plus size={16} /> New Order
          </GoldButton>
        </Link>
      </div>
    </header>
  )
}
