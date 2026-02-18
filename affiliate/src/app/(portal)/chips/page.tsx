'use client'

import { useEffect, useState } from 'react'
import { Coins, Vault, Clock, TrendingUp, Gift, AlertTriangle } from 'lucide-react'
import StatCard from '@/components/StatCard'
import StatusBadge from '@/components/StatusBadge'
import GoldButton from '@/components/GoldButton'
import Spinner from '@/components/Spinner'
import { getChipStats, getVaultEntries, getChipHistory, getWeeklyPool, withdrawFromVault } from '@/lib/api'
import { formatNumber, formatDate, getNextSunday } from '@/lib/utils'
import type { ChipStats, VaultEntry, ChipHistoryEntry, WeeklyPoolInfo } from '@/lib/types'

const TYPE_LABELS: Record<string, string> = {
  referral_scan: 'Referral Scan',
  vault_bonus: 'Vault Bonus',
  pool_distribution: 'Pool Distribution',
}

export default function ChipsPage() {
  const [stats, setStats] = useState<ChipStats | null>(null)
  const [vault, setVault] = useState<VaultEntry[]>([])
  const [history, setHistory] = useState<ChipHistoryEntry[]>([])
  const [pool, setPool] = useState<WeeklyPoolInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [withdrawing, setWithdrawing] = useState(false)

  useEffect(() => {
    Promise.all([getChipStats(), getVaultEntries(), getChipHistory(), getWeeklyPool()])
      .then(([s, v, h, p]) => { setStats(s); setVault(v); setHistory(h); setPool(p) })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !stats || !pool) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  const handleWithdraw = async () => {
    if (!stats.in_vault) return
    setWithdrawing(true)
    await withdrawFromVault(stats.in_vault)
    const updated = await getChipStats()
    setStats(updated)
    setWithdrawing(false)
  }

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={Coins} label="Total Earned" value={formatNumber(stats.total_earned)} />
        <StatCard icon={Vault} label="In Vault" value={formatNumber(stats.in_vault)} sub={`+${formatNumber(stats.vault_bonus)} bonus`} />
        <StatCard icon={Clock} label="Expiring Soon" value={formatNumber(stats.expiring_soon)} />
        <StatCard icon={TrendingUp} label="Vault Bonus" value={formatNumber(stats.vault_bonus)} />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Weekly Pool Card */}
        <div className="rounded-2xl border border-[var(--color-gold)]/30 bg-[var(--color-gold)]/5 p-6">
          <div className="mb-4 flex items-center gap-2">
            <Gift className="text-[var(--color-gold)]" size={18} />
            <h3 className="text-sm font-semibold text-white">Weekly Pool</h3>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-[var(--color-text-dim)]">Pool Amount</p>
              <p className="mt-1 text-lg font-semibold text-white">${formatNumber(pool.pool_amount)}</p>
            </div>
            <div>
              <p className="text-xs text-[var(--color-text-dim)]">Your Est. Share</p>
              <p className="mt-1 text-lg font-semibold text-[var(--color-gold)]">${pool.your_share_estimate.toFixed(2)}</p>
            </div>
            <div>
              <p className="text-xs text-[var(--color-text-dim)]">Total Chips in Circulation</p>
              <p className="mt-1 text-sm font-medium text-[var(--color-text-muted)]">{formatNumber(pool.total_chips_circulation)}</p>
            </div>
            <div>
              <p className="text-xs text-[var(--color-text-dim)]">Your Chips</p>
              <p className="mt-1 text-sm font-medium text-[var(--color-text-muted)]">{formatNumber(pool.your_chips)}</p>
            </div>
          </div>
          <p className="mt-4 text-xs text-[var(--color-text-dim)]">Next distribution: {formatDate(getNextSunday())}</p>
        </div>

        {/* Vault Management */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="text-sm font-semibold text-white">Vault</h3>
            <GoldButton size="sm" onClick={handleWithdraw} disabled={withdrawing || stats.in_vault === 0}>
              {withdrawing ? <Spinner className="h-3 w-3" /> : 'Withdraw All'}
            </GoldButton>
          </div>
          {stats.expiring_soon > 0 && (
            <div className="mb-3 flex items-center gap-2 rounded-xl border border-yellow-500/30 bg-yellow-500/10 px-3 py-2">
              <AlertTriangle size={14} className="text-yellow-400" />
              <span className="text-xs text-yellow-400">{stats.expiring_soon} chips expiring soon</span>
            </div>
          )}
          <div className="space-y-2 max-h-[280px] overflow-y-auto">
            {vault.map(v => (
              <div key={v.id} className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
                <div>
                  <p className="text-sm text-white">{formatNumber(v.amount)} chips</p>
                  <p className="text-xs text-[var(--color-text-dim)]">Vaulted {formatDate(v.date_vaulted)} · Expires {formatDate(v.expiry_date)}</p>
                </div>
                <div className="flex items-center gap-2">
                  {v.bonus_earned > 0 && <span className="text-xs text-[var(--color-gold)]">+{v.bonus_earned} bonus</span>}
                  <StatusBadge status={v.status} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Chip History */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
        <h3 className="mb-4 text-sm font-semibold text-white">Chip History</h3>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-[var(--color-border)] text-left text-xs text-[var(--color-text-dim)]">
                <th className="px-4 py-3 font-medium">Date</th>
                <th className="px-4 py-3 font-medium">Type</th>
                <th className="px-4 py-3 font-medium text-right">Amount</th>
                <th className="px-4 py-3 font-medium text-center">Vaulted</th>
              </tr>
            </thead>
            <tbody>
              {history.map(h => (
                <tr key={h.id} className="border-b border-[var(--color-border)] last:border-0">
                  <td className="px-4 py-3 text-xs text-[var(--color-text-dim)]">{formatDate(h.date)}</td>
                  <td className="px-4 py-3 text-sm text-[var(--color-text-muted)]">{TYPE_LABELS[h.type] || h.type}</td>
                  <td className="px-4 py-3 text-right font-mono text-sm text-[var(--color-gold)]">+{h.amount}</td>
                  <td className="px-4 py-3 text-center text-xs">{h.vaulted ? <span className="text-emerald-400">Yes</span> : <span className="text-[var(--color-text-dim)]">No</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Redeem Placeholder */}
      <div className="rounded-2xl border border-dashed border-[var(--color-border)] bg-[var(--color-bg-card)]/50 p-8 text-center">
        <Coins className="mx-auto mb-3 text-[var(--color-text-dim)]" size={32} />
        <h3 className="text-sm font-semibold text-white">Chip Redemption</h3>
        <p className="mt-1 text-xs text-[var(--color-text-dim)]">Coming soon — redeem your gold chips for rewards, merch, and more.</p>
      </div>
    </div>
  )
}
