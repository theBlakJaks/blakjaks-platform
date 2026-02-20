'use client'

import { useEffect, useState, useCallback } from 'react'
import { QrCode, RefreshCw } from 'lucide-react'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'
import GoldButton from '@/components/ui/GoldButton'
import Badge from '@/components/ui/Badge'
import { api } from '@/lib/api'
import { formatCurrency, formatDate } from '@/lib/utils'

interface ScanRecord {
  id: string
  date: string
  product_name: string
  usdt_earned: number
  tier_multiplier: number
  tier: string
}

interface ScanHistory {
  scans: ScanRecord[]
  total: number
  lifetime_earnings: number
}

function SkeletonRow() {
  return (
    <div className="flex items-center gap-4 border-b border-[var(--color-border)]/50 px-4 py-4 animate-pulse">
      <div className="h-4 w-24 rounded bg-[var(--color-bg-surface)]" />
      <div className="h-4 flex-1 rounded bg-[var(--color-bg-surface)]" />
      <div className="h-5 w-16 rounded-full bg-[var(--color-bg-surface)]" />
      <div className="h-4 w-20 rounded bg-[var(--color-bg-surface)]" />
    </div>
  )
}

export default function ScansPage() {
  const [data, setData] = useState<ScanHistory | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await api.scans.getHistory()
      setData(result)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load scan history')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">Scan History</h1>
        <p className="mt-1 text-sm text-[var(--color-text-dim)]">
          Every QR code scan earns you USDT rewards
        </p>
      </div>

      {/* Lifetime earnings total */}
      {!loading && !error && data && (
        <Card className="border-[var(--color-gold)]/20 bg-gradient-to-r from-[var(--color-bg-card)] to-[var(--color-bg-surface)]">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-sm font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Lifetime Scan Earnings
              </p>
              <p className="text-4xl font-bold text-[var(--color-gold)]">
                {formatCurrency(data.lifetime_earnings)}
                <span className="ml-2 text-base text-[var(--color-text-muted)]">USDT</span>
              </p>
            </div>
            <div className="text-right">
              <p className="text-3xl font-bold text-white">{data.total.toLocaleString()}</p>
              <p className="text-sm text-[var(--color-text-dim)]">Total Scans</p>
            </div>
          </div>
        </Card>
      )}

      {/* Scan list */}
      <Card>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">Recent Scans</h2>
          {!loading && (
            <button
              onClick={load}
              className="rounded-lg p-2 text-[var(--color-text-dim)] transition-colors hover:text-white"
              aria-label="Refresh"
            >
              <RefreshCw size={14} />
            </button>
          )}
        </div>

        {/* Loading skeleton */}
        {loading && (
          <div>
            {Array.from({ length: 8 }).map((_, i) => (
              <SkeletonRow key={i} />
            ))}
          </div>
        )}

        {/* Error */}
        {!loading && error && (
          <div className="text-center py-8">
            <p className="mb-4 text-[var(--color-danger)]">{error}</p>
            <GoldButton onClick={load} variant="secondary">
              <RefreshCw size={14} /> Retry
            </GoldButton>
          </div>
        )}

        {/* Empty */}
        {!loading && !error && (!data || data.scans.length === 0) && (
          <EmptyState
            icon={QrCode}
            message="No scans yet — scan a QR code to start earning USDT rewards!"
          />
        )}

        {/* Scan rows */}
        {!loading && !error && data && data.scans.length > 0 && (
          <div>
            {/* Column headers */}
            <div className="flex items-center gap-4 border-b border-[var(--color-border)] px-4 py-2">
              <span className="w-28 text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Date
              </span>
              <span className="flex-1 text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Product
              </span>
              <span className="w-24 text-center text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Tier
              </span>
              <span className="w-24 text-right text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Earned
              </span>
            </div>

            {data.scans.map((scan) => (
              <div
                key={scan.id}
                className="flex items-center gap-4 border-b border-[var(--color-border)]/50 px-4 py-4 transition-colors hover:bg-[var(--color-bg-hover)]"
              >
                {/* Date */}
                <span className="w-28 text-sm text-[var(--color-text-dim)]">
                  {formatDate(scan.date)}
                </span>

                {/* Product */}
                <div className="flex flex-1 flex-col gap-0.5 min-w-0">
                  <span className="truncate text-sm font-medium text-white">
                    {scan.product_name || 'BlakJaks Product'}
                  </span>
                  {scan.tier_multiplier > 1 && (
                    <span className="text-xs text-[var(--color-gold)]">
                      {scan.tier_multiplier}× multiplier
                    </span>
                  )}
                </div>

                {/* Tier badge */}
                <div className="w-24 flex justify-center">
                  {scan.tier ? (
                    <Badge status={scan.tier} />
                  ) : (
                    <span className="text-[var(--color-text-dim)]">—</span>
                  )}
                </div>

                {/* USDT earned */}
                <span className="w-24 text-right text-sm font-semibold text-green-400">
                  +{formatCurrency(scan.usdt_earned)}
                </span>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  )
}
