'use client'

import { useState } from 'react'
import { Copy, Check, DollarSign } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { formatCurrency } from '@/lib/utils'
import TierBadge from './TierBadge'

export default function TopBar() {
  const { member } = useAuth()
  const [copied, setCopied] = useState(false)

  const refLink = `blakjaks.com/r/${member?.custom_code || member?.referral_code || ''}`

  const handleCopy = () => {
    navigator.clipboard.writeText(`https://${refLink}`)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <header className="flex h-16 items-center justify-between border-b border-[var(--color-border)] bg-[var(--color-bg-card)] px-6">
      <div className="flex items-center gap-4">
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--color-gold)]/20 text-sm font-bold text-[var(--color-gold)]">
          {member?.first_name?.charAt(0) || 'A'}
        </div>
        <div>
          <div className="flex items-center gap-2">
            <p className="text-sm font-medium text-white">{member?.first_name} {member?.last_name_initial}.</p>
            {member?.tier && <TierBadge tier={member.tier} />}
          </div>
          <p className="text-xs text-[var(--color-text-dim)]">Affiliate</p>
        </div>
      </div>
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-2">
          <DollarSign size={16} className="text-[var(--color-gold)]" />
          <span className="text-sm font-medium text-white">{formatCurrency(member?.lifetime_earnings || 0)}</span>
        </div>
        <button onClick={handleCopy} className="flex items-center gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-3 py-2 text-xs text-[var(--color-text-muted)] hover:border-[var(--color-gold)] hover:text-[var(--color-gold)]">
          {copied ? <Check size={14} className="text-emerald-400" /> : <Copy size={14} />}
          <span className="hidden font-mono sm:inline">{refLink}</span>
        </button>
      </div>
    </header>
  )
}
