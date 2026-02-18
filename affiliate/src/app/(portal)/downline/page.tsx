'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { Users, Search, ChevronDown, ChevronLeft, ChevronRight } from 'lucide-react'
import TierBadge from '@/components/TierBadge'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { getDownline } from '@/lib/api'
import { formatCurrency, formatNumber, formatDate } from '@/lib/utils'
import type { DownlineMember } from '@/lib/types'

const TIERS = ['all', 'Member', 'VIP', 'High Roller', 'Whale']
const STATUSES = ['all', 'active', 'inactive']
const SORTS = [
  { value: 'newest', label: 'Newest First' },
  { value: 'earnings', label: 'Most Earnings' },
  { value: 'scans', label: 'Most Scans' },
]

export default function DownlinePage() {
  const [members, setMembers] = useState<DownlineMember[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [tier, setTier] = useState('all')
  const [status, setStatus] = useState('all')
  const [sort, setSort] = useState('newest')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)

  const fetchData = useCallback(async () => {
    setLoading(true)
    const data = await getDownline({ tier: tier === 'all' ? undefined : tier, status: status === 'all' ? undefined : status, search: search || undefined, sort, page })
    setMembers(data.items)
    setTotal(data.total)
    setLoading(false)
  }, [tier, status, sort, search, page])

  useEffect(() => { fetchData() }, [fetchData])

  const totalPages = Math.max(1, Math.ceil(total / 20))

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Users className="text-[var(--color-gold)]" size={20} />
        <h2 className="text-lg font-semibold text-white">Your Downline</h2>
        <span className="rounded-full bg-[var(--color-gold)]/10 px-2.5 py-0.5 text-xs font-medium text-[var(--color-gold)]">{total} referrals</span>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative">
          <select value={tier} onChange={e => { setTier(e.target.value); setPage(1) }} className="appearance-none rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] pl-3 pr-8 py-2 text-sm text-white outline-none focus:border-[var(--color-gold)]">
            {TIERS.map(t => <option key={t} value={t}>{t === 'all' ? 'All Tiers' : t}</option>)}
          </select>
          <ChevronDown size={14} className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-[var(--color-text-dim)]" />
        </div>
        <div className="relative">
          <select value={status} onChange={e => { setStatus(e.target.value); setPage(1) }} className="appearance-none rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] pl-3 pr-8 py-2 text-sm text-white outline-none focus:border-[var(--color-gold)]">
            {STATUSES.map(s => <option key={s} value={s}>{s === 'all' ? 'All Status' : s.charAt(0).toUpperCase() + s.slice(1)}</option>)}
          </select>
          <ChevronDown size={14} className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-[var(--color-text-dim)]" />
        </div>
        <div className="relative">
          <select value={sort} onChange={e => { setSort(e.target.value); setPage(1) }} className="appearance-none rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] pl-3 pr-8 py-2 text-sm text-white outline-none focus:border-[var(--color-gold)]">
            {SORTS.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
          </select>
          <ChevronDown size={14} className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-[var(--color-text-dim)]" />
        </div>
        <div className="relative flex-1 min-w-[200px]">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-text-dim)]" />
          <input value={search} onChange={e => { setSearch(e.target.value); setPage(1) }} placeholder="Search by name..." className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] pl-9 pr-4 py-2 text-sm text-white outline-none placeholder:text-[var(--color-text-dim)] focus:border-[var(--color-gold)]" />
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
        {loading ? (
          <div className="flex items-center justify-center py-16"><Spinner className="h-8 w-8" /></div>
        ) : members.length === 0 ? (
          <div className="py-16 text-center text-sm text-[var(--color-text-dim)]">No referrals found</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-[var(--color-border)] text-left text-xs text-[var(--color-text-dim)]">
                <th className="px-5 py-3 font-medium">Name</th>
                <th className="px-5 py-3 font-medium">Tier</th>
                <th className="px-5 py-3 font-medium">Status</th>
                <th className="px-5 py-3 font-medium text-right">Scans</th>
                <th className="px-5 py-3 font-medium text-right">Earnings Generated</th>
                <th className="px-5 py-3 font-medium">Joined</th>
              </tr>
            </thead>
            <tbody>
              {members.map(m => (
                <tr key={m.id} className="border-b border-[var(--color-border)] last:border-0 hover:bg-[var(--color-bg-hover)]">
                  <td className="px-5 py-3"><Link href={`/downline/${m.id}`} className="text-sm font-medium text-white hover:text-[var(--color-gold)]">{m.name}</Link></td>
                  <td className="px-5 py-3"><TierBadge tier={m.tier} /></td>
                  <td className="px-5 py-3"><StatusBadge status={m.status} /></td>
                  <td className="px-5 py-3 text-right font-mono text-sm text-[var(--color-text-muted)]">{formatNumber(m.total_scans)}</td>
                  <td className="px-5 py-3 text-right font-mono text-sm text-[var(--color-gold)]">{formatCurrency(m.earnings_generated)}</td>
                  <td className="px-5 py-3 text-xs text-[var(--color-text-dim)]">{formatDate(m.joined_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-xs text-[var(--color-text-dim)]">Page {page} of {totalPages}</p>
          <div className="flex gap-2">
            <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} className="flex items-center gap-1 rounded-lg border border-[var(--color-border)] px-3 py-1.5 text-xs text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] disabled:opacity-40">
              <ChevronLeft size={14} /> Prev
            </button>
            <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)} className="flex items-center gap-1 rounded-lg border border-[var(--color-border)] px-3 py-1.5 text-xs text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] disabled:opacity-40">
              Next <ChevronRight size={14} />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
