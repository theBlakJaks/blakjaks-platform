import { useCallback, useEffect, useState } from 'react'
import { Gift, DollarSign, Clock, AlertTriangle, Plus, RotateCcw, Filter, ExternalLink } from 'lucide-react'
import toast from 'react-hot-toast'
import StatsCard from '../components/StatsCard'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import { getComps, getCompStats, awardComp, bulkRetryFailed, searchUsers, COMP_TYPE_OPTIONS } from '../api/comps'
import { formatCurrency, formatDateTime, formatNumber } from '../utils/formatters'
import { COMP_TYPE_COLORS } from '../utils/constants'
import type { Comp, CompStats } from '../types'

export default function Comps() {
  const [comps, setComps] = useState<Comp[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [typeFilter, setTypeFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<CompStats | null>(null)
  const [selected, setSelected] = useState<Set<string>>(new Set())

  // Award modal state
  const [awardOpen, setAwardOpen] = useState(false)
  const [userQuery, setUserQuery] = useState('')
  const [userResults, setUserResults] = useState<{ id: string; email: string; name: string }[]>([])
  const [selectedUser, setSelectedUser] = useState<{ id: string; email: string; name: string } | null>(null)
  const [compType, setCompType] = useState(COMP_TYPE_OPTIONS[0].value)
  const [compAmount, setCompAmount] = useState(String(COMP_TYPE_OPTIONS[0].amount))
  const [compReason, setCompReason] = useState('')
  const [awarding, setAwarding] = useState(false)

  const fetchData = useCallback(async () => {
    setLoading(true)
    const [compsRes, statsRes] = await Promise.all([
      getComps(page, typeFilter || undefined, statusFilter || undefined),
      getCompStats(),
    ])
    setComps(compsRes.items)
    setTotal(compsRes.total)
    setStats(statsRes)
    setLoading(false)
  }, [page, typeFilter, statusFilter])

  useEffect(() => { fetchData() }, [fetchData])

  // User search debounce
  useEffect(() => {
    if (userQuery.length < 2) { setUserResults([]); return }
    const t = setTimeout(async () => {
      const results = await searchUsers(userQuery)
      setUserResults(results)
    }, 300)
    return () => clearTimeout(t)
  }, [userQuery])

  const handleCompTypeChange = (value: string) => {
    setCompType(value)
    const opt = COMP_TYPE_OPTIONS.find(o => o.value === value)
    if (opt) setCompAmount(String(opt.amount))
  }

  const handleAward = async () => {
    if (!selectedUser || !compAmount) return
    setAwarding(true)
    try {
      await awardComp(selectedUser.id, parseFloat(compAmount), compReason || 'Manual award', compType)
      toast.success(`Comp of ${formatCurrency(parseFloat(compAmount))} awarded to ${selectedUser.name}`)
      setAwardOpen(false)
      resetAwardForm()
      fetchData()
    } catch {
      toast.error('Failed to award comp')
    } finally {
      setAwarding(false)
    }
  }

  const resetAwardForm = () => {
    setSelectedUser(null)
    setUserQuery('')
    setUserResults([])
    setCompType(COMP_TYPE_OPTIONS[0].value)
    setCompAmount(String(COMP_TYPE_OPTIONS[0].amount))
    setCompReason('')
  }

  const handleBulkRetry = async () => {
    const failedIds = Array.from(selected).filter(id => comps.find(c => c.id === id)?.status === 'failed')
    if (failedIds.length === 0) { toast.error('No failed comps selected'); return }
    try {
      const res = await bulkRetryFailed(failedIds)
      toast.success(`Retrying ${res.retried} failed transaction${res.retried !== 1 ? 's' : ''}`)
      setSelected(new Set())
      fetchData()
    } catch {
      toast.error('Failed to retry')
    }
  }

  const toggleSelect = (id: string) => {
    setSelected(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id); else next.add(id)
      return next
    })
  }

  const totalPages = Math.ceil(total / 20)
  const failedSelected = Array.from(selected).filter(id => comps.find(c => c.id === id)?.status === 'failed').length

  return (
    <div className="space-y-6">
      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
          <StatsCard icon={Gift} label="Total Comps Awarded" value={formatNumber(stats.total_awarded)} />
          <StatsCard icon={DollarSign} label="Total Value Distributed" value={formatCurrency(stats.total_value)} />
          <StatsCard icon={Clock} label="Pending Payouts" value={String(stats.pending_count)} />
          <StatsCard icon={AlertTriangle} label="Failed Transactions" value={String(stats.failed_count)} />
        </div>
      )}

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <button
          onClick={() => { resetAwardForm(); setAwardOpen(true) }}
          className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
        >
          <Plus size={16} /> Manual Award
        </button>

        {failedSelected > 0 && (
          <button
            onClick={handleBulkRetry}
            className="flex items-center gap-1.5 rounded-lg bg-amber-50 px-4 py-2 text-sm font-medium text-amber-700 hover:bg-amber-100"
          >
            <RotateCcw size={16} /> Retry Failed ({failedSelected})
          </button>
        )}

        <div className="ml-auto flex items-center gap-3">
          <div className="flex items-center gap-2">
            <Filter size={16} className="text-slate-400" />
            <select
              value={typeFilter}
              onChange={(e) => { setTypeFilter(e.target.value); setPage(1) }}
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
            >
              <option value="">All Types</option>
              {COMP_TYPE_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
          >
            <option value="">All Status</option>
            <option value="pending">Pending</option>
            <option value="completed">Completed</option>
            <option value="failed">Failed</option>
          </select>
        </div>
      </div>

      <p className="text-sm text-slate-500">{total} comp{total !== 1 ? 's' : ''} found</p>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
      ) : comps.length === 0 ? (
        <EmptyState title="No comps found" message="Award a comp to get started." />
      ) : (
        <div className="overflow-hidden rounded-xl bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50">
                <th className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selected.size === comps.length && comps.length > 0}
                    onChange={() => selected.size === comps.length ? setSelected(new Set()) : setSelected(new Set(comps.map(c => c.id)))}
                    className="rounded border-slate-300"
                  />
                </th>
                <th className="px-4 py-3 font-medium text-slate-600">Recipient</th>
                <th className="px-4 py-3 font-medium text-slate-600">Type</th>
                <th className="px-4 py-3 font-medium text-slate-600">Amount</th>
                <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                <th className="px-4 py-3 font-medium text-slate-600">Tx Hash</th>
                <th className="px-4 py-3 font-medium text-slate-600">Affiliate Match</th>
                <th className="px-4 py-3 font-medium text-slate-600">Awarded At</th>
              </tr>
            </thead>
            <tbody>
              {comps.map(c => (
                <tr key={c.id} className="border-b border-slate-50 hover:bg-slate-50">
                  <td className="px-4 py-3">
                    <input
                      type="checkbox"
                      checked={selected.has(c.id)}
                      onChange={() => toggleSelect(c.id)}
                      className="rounded border-slate-300"
                    />
                  </td>
                  <td className="px-4 py-3">
                    <div>
                      <p className="font-medium text-slate-900">{c.user_name}</p>
                      <p className="text-xs text-slate-400">{c.user_email}</p>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${COMP_TYPE_COLORS[c.comp_type] || 'bg-slate-100 text-slate-800'}`}>
                      {c.comp_type.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-medium text-slate-900">{formatCurrency(c.amount)}</td>
                  <td className="px-4 py-3"><Badge label={c.status} /></td>
                  <td className="px-4 py-3">
                    {c.tx_hash ? (
                      <a
                        href={`https://polygonscan.com/tx/${c.tx_hash}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-1 font-mono text-xs text-indigo-600 hover:underline"
                      >
                        {c.tx_hash.slice(0, 10)}...
                        <ExternalLink size={12} />
                      </a>
                    ) : (
                      <span className="text-slate-400">-</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-slate-600">
                    {c.affiliate_match ? formatCurrency(c.affiliate_match) : '-'}
                  </td>
                  <td className="px-4 py-3 text-slate-500">{formatDateTime(c.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {totalPages > 1 && (
            <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
              <span className="text-sm text-slate-500">Page {page} of {totalPages}</span>
              <div className="flex gap-2">
                <button onClick={() => setPage(p => p - 1)} disabled={page <= 1} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Previous</button>
                <button onClick={() => setPage(p => p + 1)} disabled={page >= totalPages} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Next</button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Award Comp Modal */}
      <Modal open={awardOpen} onClose={() => setAwardOpen(false)} title="Manual Comp Award">
        <div className="space-y-4">
          {/* User search */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Recipient</label>
            {selectedUser ? (
              <div className="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50 px-3 py-2.5">
                <div>
                  <p className="text-sm font-medium text-slate-900">{selectedUser.name}</p>
                  <p className="text-xs text-slate-500">{selectedUser.email}</p>
                </div>
                <button onClick={() => { setSelectedUser(null); setUserQuery('') }} className="text-xs text-red-500 hover:underline">Remove</button>
              </div>
            ) : (
              <div className="relative">
                <input
                  type="text"
                  value={userQuery}
                  onChange={(e) => setUserQuery(e.target.value)}
                  placeholder="Search by email or name..."
                  className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
                />
                {userResults.length > 0 && (
                  <div className="absolute left-0 right-0 top-full z-10 mt-1 max-h-48 overflow-y-auto rounded-lg border border-slate-200 bg-white shadow-lg">
                    {userResults.map(u => (
                      <button
                        key={u.id}
                        onClick={() => { setSelectedUser(u); setUserQuery(''); setUserResults([]) }}
                        className="flex w-full items-center gap-3 px-3 py-2 text-left text-sm hover:bg-slate-50"
                      >
                        <div>
                          <p className="font-medium text-slate-900">{u.name}</p>
                          <p className="text-xs text-slate-500">{u.email}</p>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Comp Type</label>
            <select
              value={compType}
              onChange={(e) => handleCompTypeChange(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            >
              {COMP_TYPE_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Amount ($)</label>
            <input
              type="number"
              value={compAmount}
              onChange={(e) => setCompAmount(e.target.value)}
              min="0.01"
              step="0.01"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Reason</label>
            <input
              type="text"
              value={compReason}
              onChange={(e) => setCompReason(e.target.value)}
              placeholder="Manual award"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>

          <div className="flex justify-end gap-3">
            <button onClick={() => setAwardOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button
              onClick={handleAward}
              disabled={!selectedUser || !compAmount || awarding}
              className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40"
            >
              {awarding && <LoadingSpinner className="h-4 w-4" />}
              Award Comp
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
