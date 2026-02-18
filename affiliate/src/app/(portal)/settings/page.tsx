'use client'

import { useEffect, useState } from 'react'
import { Wallet, Bell, CreditCard, Sunset, AlertTriangle, Check } from 'lucide-react'
import GoldButton from '@/components/GoldButton'
import Spinner from '@/components/Spinner'
import { getSettings, updateWallet, updateNotifications, updatePayoutMode, getSunsetStatus } from '@/lib/api'
import { formatNumber } from '@/lib/utils'
import type { AffiliateSettings, SunsetStatus } from '@/lib/types'

export default function SettingsPage() {
  const [settings, setSettings] = useState<AffiliateSettings | null>(null)
  const [sunset, setSunset] = useState<SunsetStatus | null>(null)
  const [loading, setLoading] = useState(true)

  const [walletInput, setWalletInput] = useState('')
  const [savingWallet, setSavingWallet] = useState(false)
  const [walletMsg, setWalletMsg] = useState('')
  const [notifs, setNotifs] = useState<AffiliateSettings['notifications'] | null>(null)
  const [savingNotifs, setSavingNotifs] = useState(false)
  const [notifsMsg, setNotifsMsg] = useState('')
  const [payoutMode, setPayoutMode] = useState<'auto' | 'manual'>('auto')
  const [savingMode, setSavingMode] = useState(false)
  const [modeMsg, setModeMsg] = useState('')

  useEffect(() => {
    Promise.all([getSettings(), getSunsetStatus()])
      .then(([s, sun]) => {
        setSettings(s)
        setWalletInput(s.wallet_address || '')
        setNotifs(s.notifications)
        setPayoutMode(s.payout_mode)
        setSunset(sun)
      })
      .finally(() => setLoading(false))
  }, [])

  if (loading || !settings || !notifs || !sunset) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  const handleSaveWallet = async () => {
    if (!walletInput.trim()) return
    setSavingWallet(true)
    const res = await updateWallet(walletInput.trim())
    setWalletMsg(res.message)
    setSavingWallet(false)
    setTimeout(() => setWalletMsg(''), 3000)
  }

  const handleSaveNotifs = async () => {
    if (!notifs) return
    setSavingNotifs(true)
    const res = await updateNotifications(notifs)
    setNotifsMsg(res.message)
    setSavingNotifs(false)
    setTimeout(() => setNotifsMsg(''), 3000)
  }

  const handlePayoutMode = async (mode: 'auto' | 'manual') => {
    setPayoutMode(mode)
    setSavingMode(true)
    const res = await updatePayoutMode(mode)
    setModeMsg(res.message)
    setSavingMode(false)
    setTimeout(() => setModeMsg(''), 3000)
  }

  const sunsetPct = Math.min(100, sunset.percentage)

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Wallet Address */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <div className="mb-4 flex items-center gap-2">
            <Wallet className="text-[var(--color-gold)]" size={18} />
            <h3 className="text-sm font-semibold text-white">Payout Wallet</h3>
          </div>
          <p className="mb-3 text-xs text-[var(--color-text-dim)]">USDC payouts are sent to this Polygon wallet address every Sunday.</p>
          <div className="flex gap-2">
            <input value={walletInput} onChange={e => setWalletInput(e.target.value)} placeholder="0x..." className="flex-1 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 font-mono text-sm text-white outline-none placeholder:text-[var(--color-text-dim)] focus:border-[var(--color-gold)]" />
            <GoldButton size="sm" onClick={handleSaveWallet} disabled={savingWallet}>
              {savingWallet ? <Spinner className="h-3 w-3" /> : 'Save'}
            </GoldButton>
          </div>
          {walletMsg && <p className="mt-2 flex items-center gap-1 text-xs text-emerald-400"><Check size={12} /> {walletMsg}</p>}
        </div>

        {/* Payout Mode */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <div className="mb-4 flex items-center gap-2">
            <CreditCard className="text-[var(--color-gold)]" size={18} />
            <h3 className="text-sm font-semibold text-white">Payout Mode</h3>
          </div>
          <p className="mb-3 text-xs text-[var(--color-text-dim)]">Choose how your weekly earnings are distributed.</p>
          <div className="space-y-2">
            {(['auto', 'manual'] as const).map(mode => (
              <label key={mode} className={`flex cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 ${payoutMode === mode ? 'border-[var(--color-gold)]/50 bg-[var(--color-gold)]/5' : 'border-[var(--color-border)]'}`}>
                <input type="radio" name="payout_mode" checked={payoutMode === mode} onChange={() => handlePayoutMode(mode)} className="accent-[var(--color-gold)]" />
                <div>
                  <p className="text-sm font-medium text-white">{mode === 'auto' ? 'Auto Payout' : 'Manual Claim'}</p>
                  <p className="text-xs text-[var(--color-text-dim)]">{mode === 'auto' ? 'Earnings are sent to your wallet every Sunday automatically.' : 'Accumulate earnings and claim manually when you choose.'}</p>
                </div>
              </label>
            ))}
          </div>
          {savingMode && <p className="mt-2 text-xs text-[var(--color-text-dim)]">Saving...</p>}
          {modeMsg && <p className="mt-2 flex items-center gap-1 text-xs text-emerald-400"><Check size={12} /> {modeMsg}</p>}
        </div>

        {/* Notifications */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <div className="mb-4 flex items-center gap-2">
            <Bell className="text-[var(--color-gold)]" size={18} />
            <h3 className="text-sm font-semibold text-white">Email Notifications</h3>
          </div>
          <div className="space-y-3">
            {([
              { key: 'weekly_summary' as const, label: 'Weekly Summary', desc: 'Receive a weekly earnings recap every Monday' },
              { key: 'referral_signup' as const, label: 'Referral Signups', desc: 'Get notified when someone signs up via your link' },
              { key: 'payout_confirmation' as const, label: 'Payout Confirmation', desc: 'Receive confirmation when a payout is processed' },
              { key: 'sunset_alerts' as const, label: 'Sunset Alerts', desc: 'Get notified about sunset clause status changes' },
            ] as const).map(n => (
              <label key={n.key} className="flex cursor-pointer items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
                <div>
                  <p className="text-sm text-white">{n.label}</p>
                  <p className="text-xs text-[var(--color-text-dim)]">{n.desc}</p>
                </div>
                <input type="checkbox" checked={notifs[n.key]} onChange={() => setNotifs(prev => prev ? { ...prev, [n.key]: !prev[n.key] } : prev)} className="h-4 w-4 accent-[var(--color-gold)]" />
              </label>
            ))}
          </div>
          <div className="mt-4 flex items-center gap-2">
            <GoldButton size="sm" onClick={handleSaveNotifs} disabled={savingNotifs}>
              {savingNotifs ? <Spinner className="h-3 w-3" /> : 'Save Preferences'}
            </GoldButton>
            {notifsMsg && <span className="flex items-center gap-1 text-xs text-emerald-400"><Check size={12} /> {notifsMsg}</span>}
          </div>
        </div>

        {/* Sunset Status */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <div className="mb-4 flex items-center gap-2">
            <Sunset className="text-[var(--color-gold)]" size={18} />
            <h3 className="text-sm font-semibold text-white">Sunset Clause</h3>
          </div>
          <p className="mb-4 text-xs text-[var(--color-text-dim)]">The affiliate program enters sunset when rolling 3-month average sales exceed the threshold. Commissions gradually phase out over 12 months.</p>

          {sunset.is_triggered ? (
            <div className="rounded-xl border border-yellow-500/30 bg-yellow-500/10 px-4 py-3">
              <div className="flex items-center gap-2">
                <AlertTriangle size={14} className="text-yellow-400" />
                <p className="text-sm font-medium text-yellow-400">Sunset Triggered</p>
              </div>
              <p className="mt-1 text-xs text-yellow-400/80">Triggered on {sunset.triggered_at ? new Date(sunset.triggered_at).toLocaleDateString() : 'N/A'}</p>
            </div>
          ) : (
            <>
              <div className="mb-2 flex items-center justify-between text-xs">
                <span className="text-[var(--color-text-dim)]">Progress to sunset</span>
                <span className="text-[var(--color-text-muted)]">{sunset.percentage.toFixed(1)}%</span>
              </div>
              <div className="mb-4 h-3 overflow-hidden rounded-full bg-[var(--color-bg)]">
                <div className="h-full rounded-full bg-gradient-to-r from-emerald-500 via-yellow-500 to-red-500" style={{ width: `${sunsetPct}%` }} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-[var(--color-text-dim)]">Monthly Volume</p>
                  <p className="mt-0.5 text-sm font-medium text-white">${formatNumber(sunset.monthly_volume)}</p>
                </div>
                <div>
                  <p className="text-xs text-[var(--color-text-dim)]">Rolling 3-Mo Avg</p>
                  <p className="mt-0.5 text-sm font-medium text-white">${formatNumber(sunset.rolling_3mo_avg)}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-xs text-[var(--color-text-dim)]">Threshold</p>
                  <p className="mt-0.5 text-sm font-medium text-[var(--color-gold)]">${formatNumber(sunset.threshold)}</p>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
