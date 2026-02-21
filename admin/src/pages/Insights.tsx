import { useCallback, useEffect, useState } from 'react'
import {
  Activity, Database, Cpu, Zap, DollarSign, Gift, Users, RefreshCw, AlertTriangle, Building2,
} from 'lucide-react'
import LoadingSpinner from '../components/LoadingSpinner'
import StatsCard from '../components/StatsCard'
import {
  getSystemsHealth, getTreasuryInsights, getCompStats, getDwollaBalance,
  type SystemsHealth, type TreasuryInsights, type CompStats,
} from '../api/insights'

// ── Constants ─────────────────────────────────────────────────────────────────

const REFRESH_INTERVAL_MS = 30_000

const PRIZE_TIER_LABELS: Record<string, string> = {
  '100': '$100 Tier',
  '1000': '$1,000 Tier',
  '10000': '$10,000 Tier',
  '200000': '$200,000 Tier',
}

const PRIZE_TIER_COLORS: Record<string, string> = {
  '100': 'bg-emerald-100 text-emerald-800 border-emerald-200',
  '1000': 'bg-indigo-100 text-indigo-800 border-indigo-200',
  '10000': 'bg-purple-100 text-purple-800 border-purple-200',
  '200000': 'bg-amber-100 text-amber-800 border-amber-200',
}

const POOL_BORDER: Record<string, string> = {
  consumer: 'border-indigo-200',
  affiliate: 'border-purple-200',
  wholesale: 'border-amber-200',
}

const POOL_LABEL: Record<string, string> = {
  consumer: 'Consumer Pool',
  affiliate: 'Affiliate Pool',
  wholesale: 'Wholesale Pool',
}

const POOL_ACCENT: Record<string, string> = {
  consumer: 'text-indigo-600',
  affiliate: 'text-purple-600',
  wholesale: 'text-amber-600',
}

// ── Helpers ───────────────────────────────────────────────────────────────────

type HealthStatus = 'healthy' | 'degraded' | 'down' | string

function statusColor(status: HealthStatus): string {
  const s = status?.toLowerCase()
  if (s === 'healthy' || s === 'ok' || s === 'up') return 'bg-emerald-100 text-emerald-700 border-emerald-200'
  if (s === 'degraded' || s === 'slow' || s === 'warning') return 'bg-amber-100 text-amber-700 border-amber-200'
  return 'bg-red-100 text-red-700 border-red-200'
}

function statusDot(status: HealthStatus): string {
  const s = status?.toLowerCase()
  if (s === 'healthy' || s === 'ok' || s === 'up') return 'bg-emerald-500'
  if (s === 'degraded' || s === 'slow' || s === 'warning') return 'bg-amber-500'
  return 'bg-red-500'
}

function formatUsdt(amount: number): string {
  return `$${amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

function formatCompactNumber(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`
  return String(n)
}

// ── Sub-components ────────────────────────────────────────────────────────────

function SectionHeading({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="text-base font-semibold text-slate-800">{children}</h2>
  )
}

interface HealthCardProps {
  label: string
  status: HealthStatus
  icon: React.ReactNode
  detail?: string
}

function HealthCard({ label, status, icon, detail }: HealthCardProps) {
  return (
    <div className={`rounded-xl border bg-white p-5 shadow-sm ${statusColor(status).includes('emerald') ? 'border-emerald-100' : statusColor(status).includes('amber') ? 'border-amber-100' : 'border-red-100'}`}>
      <div className="flex items-start justify-between">
        <div className="rounded-lg bg-slate-50 p-2.5">
          {icon}
        </div>
        <span className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium capitalize ${statusColor(status)}`}>
          <span className={`h-1.5 w-1.5 rounded-full ${statusDot(status)}`} />
          {status || 'unknown'}
        </span>
      </div>
      <div className="mt-4">
        <p className="text-sm text-slate-500">{label}</p>
        {detail && <p className="mt-0.5 text-xs text-slate-400">{detail}</p>}
      </div>
    </div>
  )
}

// CSS sparkline-style bars built from an array of values
function SparklineBars({ values, color = 'bg-indigo-500' }: { values: number[]; color?: string }) {
  if (!values || values.length === 0) return null
  const max = Math.max(...values, 1)
  return (
    <div className="flex items-end gap-0.5" style={{ height: 40 }}>
      {values.map((v, i) => (
        <div
          key={i}
          className={`flex-1 rounded-sm ${color} opacity-80`}
          style={{ height: `${Math.max(4, Math.round((v / max) * 40))}px` }}
        />
      ))}
    </div>
  )
}

// ── Error Banner ──────────────────────────────────────────────────────────────

interface ErrorBannerProps {
  message: string
  onRetry: () => void
}

function ErrorBanner({ message, onRetry }: ErrorBannerProps) {
  return (
    <div className="flex items-center gap-3 rounded-xl border border-red-200 bg-red-50 px-5 py-4">
      <AlertTriangle size={18} className="shrink-0 text-red-500" />
      <p className="flex-1 text-sm text-red-700">{message}</p>
      <button
        onClick={onRetry}
        className="flex items-center gap-1.5 rounded-lg border border-red-300 bg-white px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-50"
      >
        <RefreshCw size={14} /> Retry
      </button>
    </div>
  )
}

// ── Main Component ────────────────────────────────────────────────────────────

export default function Insights() {
  const [systemsData, setSystemsData] = useState<SystemsHealth | null>(null)
  const [treasuryData, setTreasuryData] = useState<TreasuryInsights | null>(null)
  const [compData, setCompData] = useState<CompStats | null>(null)
  const [dwollaBalance, setDwollaBalance] = useState<number | null>(null)

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefreshed, setLastRefreshed] = useState<Date | null>(null)

  const fetchAll = useCallback(async () => {
    setError(null)
    try {
      const [systems, treasury, comps, dwolla] = await Promise.all([
        getSystemsHealth(),
        getTreasuryInsights(),
        getCompStats(),
        getDwollaBalance().catch(() => ({ balance_usd: 0 })),
      ])
      setSystemsData(systems)
      setTreasuryData(treasury)
      setCompData(comps)
      setDwollaBalance(dwolla.balance_usd)
      setLastRefreshed(new Date())
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to load insights data'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  // Initial load
  useEffect(() => {
    fetchAll()
  }, [fetchAll])

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchAll()
    }, REFRESH_INTERVAL_MS)
    return () => clearInterval(interval)
  }, [fetchAll])

  const handleRetry = () => {
    setLoading(true)
    fetchAll()
  }

  // ── Derived values ──────────────────────────────────────────────────────────

  const nodeHealth = systemsData?.node_health ?? {}
  const scanVelocity = systemsData?.scan_velocity
  const tellerSync = systemsData?.teller_sync
  const tierDist = systemsData?.tier_distribution ?? {}

  const sparklineValues: number[] = scanVelocity?.history ?? (
    scanVelocity ? Array.from({ length: 20 }, (_, i) =>
      Math.max(0, (scanVelocity.scans_per_minute ?? 0) + Math.sin(i) * 2)
    ) : []
  )

  const poolBalances = treasuryData?.pool_balances
  const blockchainHealth = treasuryData?.blockchain_health

  const prizeTiers = compData?.prize_tiers ?? {}
  const PRIZE_ORDER = ['100', '1000', '10000', '200000']

  // ── Render ──────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 py-24">
        <LoadingSpinner className="h-8 w-8" />
        <p className="text-sm text-slate-500">Loading insights…</p>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-slate-900">System Insights</h1>
          <p className="mt-0.5 text-sm text-slate-500">
            Live platform health, treasury, and payout metrics
            {lastRefreshed && (
              <span className="ml-2 text-slate-400">
                — updated {lastRefreshed.toLocaleTimeString()}
              </span>
            )}
          </p>
        </div>
        <button
          onClick={handleRetry}
          className="flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          <RefreshCw size={15} /> Refresh
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <ErrorBanner
          message={`Could not fetch insights data: ${error}`}
          onRetry={handleRetry}
        />
      )}

      {/* ── Panel 1: System Health ─────────────────────────────────────────── */}
      <section className="space-y-4">
        <SectionHeading>System Health</SectionHeading>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <HealthCard
            label="API Status"
            status={nodeHealth.api ?? 'unknown'}
            icon={<Activity size={20} className="text-indigo-600" />}
          />
          <HealthCard
            label="DB Connections"
            status={nodeHealth.database ?? 'unknown'}
            icon={<Database size={20} className="text-indigo-600" />}
          />
          <HealthCard
            label="Redis Memory"
            status={nodeHealth.redis ?? 'unknown'}
            icon={<Cpu size={20} className="text-indigo-600" />}
          />
          <HealthCard
            label="Polygon Node"
            status={nodeHealth.polygon_node ?? 'unknown'}
            icon={<Zap size={20} className="text-indigo-600" />}
            detail={
              blockchainHealth?.block_lag !== undefined
                ? `Block lag: ${blockchainHealth.block_lag}`
                : undefined
            }
          />
        </div>

        {/* Teller Sync + Blockchain side-by-side */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {tellerSync && (
            <div className="rounded-xl border border-slate-100 bg-white p-5 shadow-sm">
              <div className="mb-3 flex items-center gap-2">
                <div className="rounded-lg bg-slate-50 p-2">
                  <RefreshCw size={16} className="text-slate-500" />
                </div>
                <span className="text-sm font-medium text-slate-700">Teller Sync</span>
                <span className={`ml-auto inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium capitalize ${statusColor(tellerSync.status)}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${statusDot(tellerSync.status)}`} />
                  {tellerSync.status}
                </span>
              </div>
              <div className="space-y-1 text-sm text-slate-600">
                {tellerSync.last_sync && (
                  <div className="flex justify-between">
                    <span className="text-slate-400">Last sync</span>
                    <span>{new Date(tellerSync.last_sync).toLocaleString()}</span>
                  </div>
                )}
                {tellerSync.accounts_synced !== undefined && (
                  <div className="flex justify-between">
                    <span className="text-slate-400">Accounts synced</span>
                    <span className="font-medium">{tellerSync.accounts_synced.toLocaleString()}</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {blockchainHealth && (
            <div className="rounded-xl border border-slate-100 bg-white p-5 shadow-sm">
              <div className="mb-3 flex items-center gap-2">
                <div className="rounded-lg bg-slate-50 p-2">
                  <Zap size={16} className="text-amber-500" />
                </div>
                <span className="text-sm font-medium text-slate-700">Blockchain Health</span>
                <span className={`ml-auto inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium capitalize ${statusColor(blockchainHealth.status)}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${statusDot(blockchainHealth.status)}`} />
                  {blockchainHealth.status}
                </span>
              </div>
              <div className="space-y-1 text-sm text-slate-600">
                {blockchainHealth.last_block !== undefined && (
                  <div className="flex justify-between">
                    <span className="text-slate-400">Last block</span>
                    <span className="font-mono">{blockchainHealth.last_block.toLocaleString()}</span>
                  </div>
                )}
                {blockchainHealth.block_lag !== undefined && (
                  <div className="flex justify-between">
                    <span className="text-slate-400">Block lag</span>
                    <span className={`font-medium ${blockchainHealth.block_lag > 5 ? 'text-amber-600' : 'text-slate-700'}`}>
                      {blockchainHealth.block_lag} blocks
                    </span>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </section>

      {/* ── Panel 2: Scan Velocity ─────────────────────────────────────────── */}
      <section className="space-y-4">
        <SectionHeading>Scan Velocity</SectionHeading>

        <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-center">
            {/* Big stat */}
            <div className="shrink-0">
              <p className="text-sm text-slate-500">Scans / Minute</p>
              <p className="text-5xl font-bold tracking-tight text-indigo-600">
                {scanVelocity?.scans_per_minute?.toLocaleString() ?? '—'}
              </p>
              <p className="mt-1 text-xs text-slate-400">live rolling average</p>
            </div>

            {/* Sparkline */}
            <div className="flex-1">
              <p className="mb-2 text-xs font-medium text-slate-400 uppercase tracking-wide">Recent trend</p>
              <SparklineBars values={sparklineValues} color="bg-indigo-400" />
            </div>
          </div>

          {/* Tier distribution mini-grid */}
          {Object.keys(tierDist).length > 0 && (
            <div className="mt-6 border-t border-slate-100 pt-5">
              <p className="mb-3 text-xs font-medium uppercase tracking-wide text-slate-400">Tier Distribution</p>
              <div className="flex flex-wrap gap-3">
                {Object.entries(tierDist).map(([tier, count]) => (
                  <div key={tier} className="rounded-lg border border-slate-200 bg-slate-50 px-4 py-2 text-center">
                    <p className="text-xs text-slate-500 capitalize">{tier}</p>
                    <p className="text-lg font-bold text-slate-900">{Number(count).toLocaleString()}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </section>

      {/* ── Panel 3: Pool Balances ─────────────────────────────────────────── */}
      <section className="space-y-4">
        <SectionHeading>Pool Balances</SectionHeading>

        {poolBalances ? (
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
            {(['consumer', 'affiliate', 'wholesale'] as const).map((pool) => {
              const balance = poolBalances[pool]
              if (!balance) return null
              const sparkline = treasuryData?.sparklines?.[pool] ?? []
              const sparkValues = sparkline.map((p) => p.value)
              return (
                <div
                  key={pool}
                  className={`rounded-xl border-2 bg-white p-6 shadow-sm ${POOL_BORDER[pool]}`}
                >
                  <div className="mb-3 flex items-center justify-between">
                    <p className="text-sm font-semibold text-slate-700">{POOL_LABEL[pool]}</p>
                    {balance.trend !== undefined && (
                      <span className={`text-sm font-medium ${balance.trend >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                        {balance.trend >= 0 ? '+' : ''}{balance.trend.toFixed(1)}%
                      </span>
                    )}
                  </div>

                  <p className={`text-3xl font-bold ${POOL_ACCENT[pool]}`}>
                    {formatUsdt(balance.amount)}
                  </p>
                  <p className="mt-0.5 text-xs text-slate-400">{balance.currency ?? 'USDC'}</p>

                  {sparkValues.length > 0 && (
                    <div className="mt-4">
                      <p className="mb-1 text-xs text-slate-400">7-day sparkline</p>
                      <SparklineBars
                        values={sparkValues}
                        color={pool === 'consumer' ? 'bg-indigo-400' : pool === 'affiliate' ? 'bg-purple-400' : 'bg-amber-400'}
                      />
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        ) : (
          !error && (
            <div className="flex items-center justify-center py-10 text-sm text-slate-400">
              No pool balance data available.
            </div>
          )
        )}
      </section>

      {/* ── Panel 4: Comp Budget Health ───────────────────────────────────── */}
      <section className="space-y-4">
        <SectionHeading>Comp Budget Health</SectionHeading>

        <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
          <p className="mb-5 text-sm text-slate-500">Prize tier allocation counts across all active comp pools.</p>

          <div className="divide-y divide-slate-100">
            {PRIZE_ORDER.map((tier) => {
              const count = prizeTiers[tier] ?? 0
              const label = PRIZE_TIER_LABELS[tier] ?? `$${tier} Tier`
              const colorClass = PRIZE_TIER_COLORS[tier] ?? 'bg-slate-100 text-slate-800 border-slate-200'
              const totalCount = PRIZE_ORDER.reduce((acc, t) => acc + (prizeTiers[t] ?? 0), 0)
              const pct = totalCount > 0 ? (count / totalCount) * 100 : 0

              return (
                <div key={tier} className="flex items-center gap-4 py-3">
                  <span className={`inline-flex w-28 items-center justify-center rounded-full border px-3 py-0.5 text-xs font-semibold ${colorClass}`}>
                    {label}
                  </span>
                  <div className="flex-1">
                    <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className={`h-2 rounded-full transition-all ${colorClass.includes('emerald') ? 'bg-emerald-400' : colorClass.includes('indigo') ? 'bg-indigo-400' : colorClass.includes('purple') ? 'bg-purple-400' : 'bg-amber-400'}`}
                        style={{ width: `${pct.toFixed(1)}%` }}
                      />
                    </div>
                  </div>
                  <div className="w-20 text-right">
                    <span className="text-base font-bold text-slate-900">{count.toLocaleString()}</span>
                    <span className="ml-1 text-xs text-slate-400">comps</span>
                  </div>
                  <span className="w-12 text-right text-xs text-slate-400">{pct.toFixed(1)}%</span>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      {/* ── Panel 5: Dwolla Platform Balance ─────────────────────────────── */}
      <section className="space-y-4">
        <SectionHeading>Dwolla Platform Balance</SectionHeading>

        <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="rounded-xl bg-emerald-50 p-3">
                <Building2 size={24} className="text-emerald-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">ACH Payout Reserve</p>
                <p className="mt-0.5 text-3xl font-bold text-emerald-700">
                  {dwollaBalance !== null
                    ? `$${dwollaBalance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
                    : '—'}
                </p>
                <p className="mt-0.5 text-xs text-slate-400">USD · Dwolla master funding source</p>
              </div>
            </div>
            <div className="text-right">
              <span className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium ${
                dwollaBalance !== null && dwollaBalance > 0
                  ? 'border-emerald-200 bg-emerald-50 text-emerald-700'
                  : 'border-slate-200 bg-slate-50 text-slate-500'
              }`}>
                <span className={`h-1.5 w-1.5 rounded-full ${
                  dwollaBalance !== null && dwollaBalance > 0 ? 'bg-emerald-500' : 'bg-slate-400'
                }`} />
                {dwollaBalance !== null && dwollaBalance > 0 ? 'Funded' : 'Unfunded'}
              </span>
            </div>
          </div>
          {dwollaBalance !== null && dwollaBalance < 1000 && (
            <div className="mt-4 flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3">
              <AlertTriangle size={16} className="shrink-0 text-amber-500" />
              <p className="text-sm text-amber-700">
                Low ACH reserve — top up the Dwolla master funding source before scheduling payouts.
              </p>
            </div>
          )}
        </div>
      </section>

      {/* ── Panel 6: Payout Pipeline ──────────────────────────────────────── */}
      <section className="space-y-4">
        <SectionHeading>Payout Pipeline</SectionHeading>

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 xl:grid-cols-3">
          <StatsCard
            icon={DollarSign}
            label="Total Comps Paid"
            value={compData ? formatUsdt(compData.total_comps_paid) : '—'}
          />
          <StatsCard
            icon={Users}
            label="Active Members"
            value={compData ? formatCompactNumber(compData.active_members) : '—'}
          />
          <StatsCard
            icon={Gift}
            label="Total Prize Tiers"
            value={compData ? PRIZE_ORDER.reduce((acc, t) => acc + (compData.prize_tiers[t] ?? 0), 0).toLocaleString() : '—'}
          />
        </div>

        {/* Threshold breakdown summary */}
        {compData && (
          <div className="rounded-xl border border-slate-100 bg-white p-6 shadow-sm">
            <h3 className="mb-4 text-sm font-semibold text-slate-700">Prize Threshold Summary</h3>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              {PRIZE_ORDER.map((tier) => {
                const count = compData.prize_tiers[tier] ?? 0
                const dollarLabel = Number(tier) >= 1000
                  ? `$${(Number(tier) / 1000).toFixed(0)}K`
                  : `$${tier}`
                return (
                  <div key={tier} className="rounded-lg bg-slate-50 p-4 text-center">
                    <p className="text-xs font-medium text-slate-500">{dollarLabel} threshold</p>
                    <p className="mt-1 text-3xl font-bold text-indigo-600">{count.toLocaleString()}</p>
                    <p className="mt-0.5 text-xs text-slate-400">active comps</p>
                  </div>
                )
              })}
            </div>

            <div className="mt-6 border-t border-slate-100 pt-5">
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div className="flex items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3">
                  <span className="text-sm text-slate-500">Total comps paid out</span>
                  <span className="text-base font-bold text-slate-900">{formatUsdt(compData.total_comps_paid)}</span>
                </div>
                <div className="flex items-center justify-between rounded-lg border border-slate-200 bg-white px-4 py-3">
                  <span className="text-sm text-slate-500">Active enrolled members</span>
                  <span className="text-base font-bold text-slate-900">{compData.active_members.toLocaleString()}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </section>
    </div>
  )
}
