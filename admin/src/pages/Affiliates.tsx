import { useCallback, useEffect, useState } from 'react'
import { Network, DollarSign, Clock, Sunset, Search, ArrowUpDown, Filter, ExternalLink, Eye } from 'lucide-react'
import toast from 'react-hot-toast'
import StatsCard from '../components/StatsCard'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import {
  getAffiliateStats, getAffiliates, getAffiliateDetail, getPayoutBatches,
  approvePayoutBatch, executeApprovedPayouts, getSunsetProgress, checkSunset,
} from '../api/affiliates'
import { formatCurrency, formatDate, formatDateTime, formatNumber, getPolygonscanUrl } from '../utils/formatters'
import type { Affiliate, AffiliateDetail, AffiliateStats, PayoutBatch, SunsetProgress } from '../types'

const TABS = ['Affiliates', 'Payouts'] as const
type Tab = typeof TABS[number]

const SORTS = [
  { value: 'date', label: 'Joined' },
  { value: 'earnings', label: 'Earnings' },
  { value: 'downline', label: 'Downline' },
  { value: 'chips', label: 'Chips' },
]

export default function Affiliates() {
  const [tab, setTab] = useState<Tab>('Affiliates')
  const [stats, setStats] = useState<AffiliateStats | null>(null)

  // Affiliates
  const [affiliates, setAffiliates] = useState<Affiliate[]>([])
  const [affTotal, setAffTotal] = useState(0)
  const [affPage, setAffPage] = useState(1)
  const [sort, setSort] = useState('date')
  const [search, setSearch] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [affLoading, setAffLoading] = useState(true)

  // Detail modal
  const [detailOpen, setDetailOpen] = useState(false)
  const [detail, setDetail] = useState<AffiliateDetail | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)

  // Payouts
  const [batches, setBatches] = useState<PayoutBatch[]>([])
  const [batchStatus, setBatchStatus] = useState('')
  const [batchLoading, setBatchLoading] = useState(true)
  const [approveOpen, setApproveOpen] = useState(false)
  const [executeOpen, setExecuteOpen] = useState(false)

  // Sunset
  const [sunset, setSunset] = useState<SunsetProgress | null>(null)

  const fetchStats = useCallback(async () => {
    const [s, sun] = await Promise.all([getAffiliateStats(), getSunsetProgress()])
    setStats(s)
    setSunset(sun)
  }, [])

  const fetchAffiliates = useCallback(async () => {
    setAffLoading(true)
    const res = await getAffiliates(affPage, sort, search || undefined)
    setAffiliates(res.items)
    setAffTotal(res.total)
    setAffLoading(false)
  }, [affPage, sort, search])

  const fetchBatches = useCallback(async () => {
    setBatchLoading(true)
    const data = await getPayoutBatches(batchStatus || undefined)
    setBatches(data)
    setBatchLoading(false)
  }, [batchStatus])

  useEffect(() => { fetchStats() }, [fetchStats])
  useEffect(() => { fetchAffiliates() }, [fetchAffiliates])
  useEffect(() => { if (tab === 'Payouts') fetchBatches() }, [tab, fetchBatches])

  useEffect(() => {
    const t = setTimeout(() => { setSearch(searchInput); setAffPage(1) }, 300)
    return () => clearTimeout(t)
  }, [searchInput])

  const handleViewDetail = async (affiliate: Affiliate) => {
    setDetailOpen(true)
    setDetailLoading(true)
    const data = await getAffiliateDetail(affiliate.id)
    setDetail(data)
    setDetailLoading(false)
  }

  const handleApprove = async () => {
    try {
      const res = await approvePayoutBatch()
      toast.success(`Approved ${res.approved} batches (${formatCurrency(res.total_amount)})`)
      fetchBatches()
      fetchStats()
    } catch { toast.error('Failed to approve') }
  }

  const handleExecute = async () => {
    try {
      const res = await executeApprovedPayouts()
      toast.success(`Executed ${res.executed} batches (${formatCurrency(res.total_amount)})`)
      fetchBatches()
      fetchStats()
    } catch { toast.error('Failed to execute') }
  }

  const handleCheckSunset = async () => {
    try {
      const data = await checkSunset()
      setSunset(data)
      toast.success('Sunset status checked')
    } catch { toast.error('Failed to check sunset status') }
  }

  const affTotalPages = Math.ceil(affTotal / 20)
  const pendingBatches = batches.filter(b => b.status === 'pending')
  const approvedBatches = batches.filter(b => b.status === 'approved')

  const tierThreshold = (tins: number) => {
    if (tins >= 21000) return '21,000 (Whale)'
    if (tins >= 2100) return `${tins.toLocaleString()} / 21,000`
    if (tins >= 210) return `${tins.toLocaleString()} / 2,100`
    return `${tins.toLocaleString()} / 210`
  }

  return (
    <div className="space-y-6">
      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-4">
          <StatsCard icon={Network} label="Total Affiliates" value={String(stats.total_affiliates)} />
          <StatsCard icon={DollarSign} label="Total Earnings Paid" value={formatCurrency(stats.total_paid)} />
          <StatsCard icon={Clock} label="Pending Payouts" value={`${stats.pending_count} (${formatCurrency(stats.pending_value)})`} />
          <StatsCard icon={Sunset} label="Sunset Progress" value={`${stats.sunset_percentage.toFixed(1)}%`} />
        </div>
      )}

      {/* Tabs */}
      <div className="border-b border-slate-200">
        <nav className="-mb-px flex gap-6">
          {TABS.map(t => (
            <button key={t} onClick={() => setTab(t)} className={`border-b-2 pb-3 text-sm font-medium transition-colors ${tab === t ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700'}`}>
              {t}
            </button>
          ))}
        </nav>
      </div>

      {/* Affiliates Tab */}
      {tab === 'Affiliates' && (
        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-3">
            <div className="flex flex-1 items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2">
              <Search size={18} className="text-slate-400" />
              <input type="text" value={searchInput} onChange={(e) => setSearchInput(e.target.value)} placeholder="Search by name or referral code..." className="flex-1 border-0 bg-transparent text-sm outline-none placeholder:text-slate-400" />
            </div>
            <div className="flex items-center gap-2">
              <ArrowUpDown size={16} className="text-slate-400" />
              <select value={sort} onChange={(e) => { setSort(e.target.value); setAffPage(1) }} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
                {SORTS.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
              </select>
            </div>
          </div>

          {affLoading ? (
            <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
          ) : affiliates.length === 0 ? (
            <EmptyState title="No affiliates" message="No affiliates match your search." />
          ) : (
            <div className="overflow-hidden rounded-xl bg-white shadow-sm">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 bg-slate-50">
                    <th className="px-4 py-3 font-medium text-slate-600">Username</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Referral Code</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Downline</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Chips</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Earnings</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Perm. Tier</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Referred Tins</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Joined</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {affiliates.map(a => (
                    <tr key={a.id} className="border-b border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3">
                        <div><p className="font-medium text-slate-900">{a.user_name}</p><p className="text-xs text-slate-400">{a.user_email}</p></div>
                      </td>
                      <td className="px-4 py-3 font-mono text-xs text-indigo-600">{a.referral_code}</td>
                      <td className="px-4 py-3 text-slate-700">{a.total_referrals}</td>
                      <td className="px-4 py-3 text-slate-700">{a.total_chips + a.vaulted_chips}</td>
                      <td className="px-4 py-3 font-medium text-slate-900">{formatCurrency(a.reward_match_total + a.pool_share_total)}</td>
                      <td className="px-4 py-3">{a.permanent_tier ? <Badge label={a.permanent_tier} variant="tier" /> : <span className="text-slate-400">-</span>}</td>
                      <td className="px-4 py-3 text-xs text-slate-600">{tierThreshold(a.referred_tins)}</td>
                      <td className="px-4 py-3 text-slate-500">{formatDate(a.created_at)}</td>
                      <td className="px-4 py-3">
                        <button onClick={() => handleViewDetail(a)} className="flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50"><Eye size={14} /> Detail</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {affTotalPages > 1 && (
                <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
                  <span className="text-sm text-slate-500">Page {affPage} of {affTotalPages}</span>
                  <div className="flex gap-2">
                    <button onClick={() => setAffPage(p => p - 1)} disabled={affPage <= 1} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Previous</button>
                    <button onClick={() => setAffPage(p => p + 1)} disabled={affPage >= affTotalPages} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Next</button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Payouts Tab */}
      {tab === 'Payouts' && (
        <div className="space-y-6">
          <div className="flex flex-wrap items-center gap-3">
            {pendingBatches.length > 0 && (
              <button onClick={() => setApproveOpen(true)} className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">
                Approve Pending ({pendingBatches.length})
              </button>
            )}
            {approvedBatches.length > 0 && (
              <button onClick={() => setExecuteOpen(true)} className="flex items-center gap-1.5 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700">
                Execute Approved ({approvedBatches.length})
              </button>
            )}
            <div className="ml-auto flex items-center gap-2">
              <Filter size={16} className="text-slate-400" />
              <select value={batchStatus} onChange={(e) => setBatchStatus(e.target.value)} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
                <option value="">All Status</option>
                <option value="pending">Pending</option>
                <option value="approved">Approved</option>
                <option value="paid">Paid</option>
                <option value="failed">Failed</option>
              </select>
            </div>
          </div>

          {batchLoading ? (
            <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
          ) : batches.length === 0 ? (
            <EmptyState title="No payout batches" message="No batches match your filter." />
          ) : (
            <div className="overflow-hidden rounded-xl bg-white shadow-sm">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 bg-slate-50">
                    <th className="px-4 py-3 font-medium text-slate-600">Week</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Affiliates</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Total Amount</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Approved By</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Executed At</th>
                  </tr>
                </thead>
                <tbody>
                  {batches.map(b => (
                    <tr key={b.id} className="border-b border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 text-slate-700">{formatDate(b.period_start)} — {formatDate(b.period_end)}</td>
                      <td className="px-4 py-3 text-slate-700">{b.affiliate_count}</td>
                      <td className="px-4 py-3 font-medium text-slate-900">{formatCurrency(b.total_amount)}</td>
                      <td className="px-4 py-3"><Badge label={b.status} /></td>
                      <td className="px-4 py-3 text-slate-600">{b.approved_by || '-'}</td>
                      <td className="px-4 py-3 text-slate-500">{b.executed_at ? formatDateTime(b.executed_at) : '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Sunset Progress */}
          {sunset && (
            <div className="rounded-xl bg-white p-6 shadow-sm">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-sm font-semibold text-slate-700">Sunset Progress</h3>
                <button onClick={handleCheckSunset} className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50">Check Status</button>
              </div>
              {sunset.is_triggered && (
                <div className="mb-4 rounded-lg bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
                  SUNSET ACTIVE — Triggered on {sunset.triggered_at ? formatDate(sunset.triggered_at) : 'N/A'}
                </div>
              )}
              <div className="mb-4">
                <div className="mb-1 flex justify-between text-xs text-slate-500">
                  <span>3-month rolling avg: {formatNumber(sunset.rolling_3mo_avg)} tins/mo</span>
                  <span>Threshold: {formatNumber(sunset.threshold)} tins/mo</span>
                </div>
                <div className="h-3 rounded-full bg-slate-100">
                  <div className={`h-3 rounded-full ${sunset.percentage >= 90 ? 'bg-red-500' : sunset.percentage >= 70 ? 'bg-amber-500' : 'bg-indigo-500'}`} style={{ width: `${Math.min(sunset.percentage, 100)}%` }} />
                </div>
                <p className="mt-1 text-right text-xs font-medium text-slate-600">{sunset.percentage.toFixed(1)}%</p>
              </div>
              <div className="grid grid-cols-3 gap-4 text-sm">
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-500">Monthly Volume</p><p className="font-semibold text-slate-900">{formatNumber(sunset.monthly_volume)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-500">3-Month Avg</p><p className="font-semibold text-slate-900">{formatNumber(sunset.rolling_3mo_avg)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-500">Threshold</p><p className="font-semibold text-slate-900">{formatNumber(sunset.threshold)}</p></div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Affiliate Detail Modal */}
      <Modal open={detailOpen} onClose={() => { setDetailOpen(false); setDetail(null) }} title="Affiliate Detail">
        {detailLoading ? (
          <div className="flex items-center justify-center py-8"><LoadingSpinner /></div>
        ) : detail && (
          <div className="max-h-[70vh] space-y-5 overflow-y-auto">
            <div className="rounded-lg bg-slate-50 p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-slate-900">{detail.user_name}</p>
                  <p className="text-xs text-slate-500">{detail.user_email}</p>
                </div>
                {detail.permanent_tier && <Badge label={detail.permanent_tier} variant="tier" />}
              </div>
              <dl className="mt-3 grid grid-cols-2 gap-2 text-sm">
                <div><dt className="text-xs text-slate-500">Referral Code</dt><dd className="font-mono text-indigo-600">{detail.referral_code}</dd></div>
                <div><dt className="text-xs text-slate-500">Custom Code</dt><dd className="text-slate-700">{detail.custom_code || '-'}</dd></div>
                <div className="col-span-2"><dt className="text-xs text-slate-500">Referral Link</dt><dd className="break-all text-xs text-slate-600">{detail.referral_link}</dd></div>
              </dl>
            </div>

            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-500">Reward Matching</p><p className="font-semibold text-slate-900">{formatCurrency(detail.reward_match_total)}</p></div>
              <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-500">Pool Share</p><p className="font-semibold text-slate-900">{formatCurrency(detail.pool_share_total)}</p></div>
            </div>

            <div className="grid grid-cols-3 gap-3 text-sm">
              <div className="rounded-lg bg-slate-50 p-3 text-center"><p className="text-xs text-slate-500">Active</p><p className="text-lg font-bold text-slate-900">{detail.total_chips}</p></div>
              <div className="rounded-lg bg-slate-50 p-3 text-center"><p className="text-xs text-slate-500">Vaulted</p><p className="text-lg font-bold text-indigo-600">{detail.vaulted_chips}</p></div>
              <div className="rounded-lg bg-slate-50 p-3 text-center"><p className="text-xs text-slate-500">Expired</p><p className="text-lg font-bold text-slate-400">{detail.expired_chips}</p></div>
            </div>

            {detail.downline.length > 0 && (
              <div>
                <h4 className="mb-2 text-xs font-semibold uppercase text-slate-500">Downline ({detail.downline.length})</h4>
                <div className="max-h-40 overflow-y-auto rounded-lg border border-slate-200">
                  <table className="w-full text-left text-xs">
                    <thead><tr className="border-b border-slate-100 bg-slate-50"><th className="px-3 py-2">Name</th><th className="px-3 py-2">Tier</th><th className="px-3 py-2">Scans</th><th className="px-3 py-2">Earned</th></tr></thead>
                    <tbody>
                      {detail.downline.map(d => (
                        <tr key={d.id} className="border-b border-slate-50"><td className="px-3 py-1.5 text-slate-700">{d.user_name}</td><td className="px-3 py-1.5"><Badge label={d.tier_name} variant="tier" /></td><td className="px-3 py-1.5 text-slate-600">{d.scan_count}</td><td className="px-3 py-1.5 text-slate-600">{formatCurrency(d.earnings_generated)}</td></tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {detail.payouts.length > 0 && (
              <div>
                <h4 className="mb-2 text-xs font-semibold uppercase text-slate-500">Payout History</h4>
                <div className="max-h-40 overflow-y-auto rounded-lg border border-slate-200">
                  <table className="w-full text-left text-xs">
                    <thead><tr className="border-b border-slate-100 bg-slate-50"><th className="px-3 py-2">Date</th><th className="px-3 py-2">Amount</th><th className="px-3 py-2">Type</th><th className="px-3 py-2">Status</th><th className="px-3 py-2">Tx</th></tr></thead>
                    <tbody>
                      {detail.payouts.map(p => (
                        <tr key={p.id} className="border-b border-slate-50">
                          <td className="px-3 py-1.5 text-slate-500">{formatDate(p.created_at)}</td>
                          <td className="px-3 py-1.5 font-medium text-slate-900">{formatCurrency(p.amount)}</td>
                          <td className="px-3 py-1.5 text-slate-600">{p.payout_type.replace('_', ' ')}</td>
                          <td className="px-3 py-1.5"><Badge label={p.status} /></td>
                          <td className="px-3 py-1.5">{p.tx_hash ? <a href={getPolygonscanUrl(p.tx_hash)} target="_blank" rel="noopener noreferrer" className="flex items-center gap-0.5 text-indigo-600 hover:underline">{p.tx_hash.slice(0, 8)}...<ExternalLink size={10} /></a> : '-'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}
      </Modal>

      <ConfirmDialog open={approveOpen} onClose={() => setApproveOpen(false)} onConfirm={handleApprove} title="Approve Pending Payouts" message={`Approve ${pendingBatches.length} pending batch(es) totaling ${formatCurrency(pendingBatches.reduce((s, b) => s + b.total_amount, 0))}?`} confirmLabel="Approve All" />
      <ConfirmDialog open={executeOpen} onClose={() => setExecuteOpen(false)} onConfirm={handleExecute} title="Execute Approved Payouts" message={`Execute ${approvedBatches.length} approved batch(es) totaling ${formatCurrency(approvedBatches.reduce((s, b) => s + b.total_amount, 0))}? This will send USDT to affiliates.`} confirmLabel="Execute Payouts" variant="danger" />
    </div>
  )
}
