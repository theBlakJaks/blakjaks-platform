'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { getPayoutDetail } from '@/lib/api'
import { formatCurrency, formatDate, truncateHash, getPolygonscanUrl } from '@/lib/utils'
import type { PayoutDetail } from '@/lib/types'

export default function PayoutDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [detail, setDetail] = useState<PayoutDetail | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getPayoutDetail(id).then(setDetail).finally(() => setLoading(false))
  }, [id])

  if (loading || !detail) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  return (
    <div className="space-y-6">
      {/* Back link */}
      <Link href="/payouts" className="inline-flex items-center gap-1.5 text-sm text-[var(--color-text-muted)] hover:text-[var(--color-gold)]">
        <ArrowLeft size={16} /> Back to Payouts
      </Link>

      {/* Payout Summary */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="text-xs text-[var(--color-text-dim)]">Payout Amount</p>
            <p className="mt-1 text-2xl font-bold text-[var(--color-gold)]">{formatCurrency(detail.amount)}</p>
          </div>
          <div>
            <p className="text-xs text-[var(--color-text-dim)]">Date</p>
            <p className="mt-1 text-sm font-medium text-white">{formatDate(detail.date)}</p>
          </div>
          <div>
            <p className="text-xs text-[var(--color-text-dim)]">Status</p>
            <div className="mt-1"><StatusBadge status={detail.status} /></div>
          </div>
          {detail.tx_hash && (
            <div>
              <p className="text-xs text-[var(--color-text-dim)]">Transaction</p>
              <a href={getPolygonscanUrl(detail.tx_hash)} target="_blank" rel="noopener noreferrer" className="mt-1 inline-flex items-center gap-1 font-mono text-xs text-[var(--color-gold)] hover:underline">
                {truncateHash(detail.tx_hash)} <ExternalLink size={12} />
              </a>
            </div>
          )}
        </div>
      </div>

      {/* Earnings Breakdown */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
        <div className="border-b border-[var(--color-border)] px-6 py-4">
          <h3 className="text-sm font-semibold text-white">Earnings Breakdown ({detail.earnings.length} items)</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-[var(--color-border)] text-left text-xs text-[var(--color-text-dim)]">
                <th className="px-5 py-3 font-medium">Date</th>
                <th className="px-5 py-3 font-medium">Referral</th>
                <th className="px-5 py-3 font-medium">Type</th>
                <th className="px-5 py-3 font-medium text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {detail.earnings.map(e => (
                <tr key={e.id} className="border-b border-[var(--color-border)] last:border-0">
                  <td className="px-5 py-3 text-xs text-[var(--color-text-dim)]">{formatDate(e.date)}</td>
                  <td className="px-5 py-3 text-sm text-white">{e.referral_name}</td>
                  <td className="px-5 py-3 text-sm text-[var(--color-text-muted)]">{e.type}</td>
                  <td className="px-5 py-3 text-right font-mono text-sm text-[var(--color-gold)]">{formatCurrency(e.amount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="border-t border-[var(--color-border)] px-5 py-3 text-right">
          <span className="text-xs text-[var(--color-text-dim)]">Total:</span>
          <span className="ml-2 font-mono text-sm font-semibold text-[var(--color-gold)]">{formatCurrency(detail.amount)}</span>
        </div>
      </div>
    </div>
  )
}
