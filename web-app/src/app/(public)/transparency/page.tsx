'use client'

import { useState, useEffect } from 'react'
import {
  Scan, Coins, Users, TrendingUp, Activity, Wallet, Shield, ExternalLink,
  Copy, CheckCircle2, Award, Gem, Crown, Star, Server, Zap,
  UserCheck, Package, Gift, CircleDollarSign, Layers, BarChart3,
} from 'lucide-react'
import Tabs from '@/components/ui/Tabs'
import Card from '@/components/ui/Card'
import StatCard from '@/components/ui/StatCard'
import ProgressBar from '@/components/ui/ProgressBar'
import Badge from '@/components/ui/Badge'
import { formatCurrency } from '@/lib/utils'
import {
  transparencyOverview, treasuryWallets, compTierStats,
  partnerMetrics, systemHealth,
} from '@/lib/mock-data'
import type { TreasuryWallet } from '@/lib/types'

/* ── Tabs config ── */
const tabList = [
  { id: 'overview', label: 'Overview' },
  { id: 'treasury', label: 'Treasury' },
  { id: 'comps', label: 'Comps' },
  { id: 'partners', label: 'Partners' },
  { id: 'systems', label: 'Systems' },
]

/* ── SVG Sparkline ── */
function Sparkline({ data, width = 200, height = 50, color = '#D4AF37' }: { data: number[]; width?: number; height?: number; color?: string }) {
  if (!data.length) return null
  const min = Math.min(...data)
  const max = Math.max(...data)
  const range = max - min || 1
  const points = data.map((v, i) => {
    const x = (i / (data.length - 1)) * width
    const y = height - ((v - min) / range) * (height - 4) - 2
    return `${x},${y}`
  }).join(' ')

  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} className="overflow-visible">
      <defs>
        <linearGradient id={`grad-${color.replace('#', '')}`} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.3" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <polygon
        points={`0,${height} ${points} ${width},${height}`}
        fill={`url(#grad-${color.replace('#', '')})`}
      />
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

/* ── Copy button ── */
function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)
  const handleCopy = () => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    })
  }
  return (
    <button onClick={handleCopy} className="p-1.5 rounded-lg hover:bg-[var(--color-bg-hover)] transition-colors" title="Copy address">
      {copied ? <CheckCircle2 size={14} className="text-emerald-400" /> : <Copy size={14} className="text-[var(--color-text-dim)]" />}
    </button>
  )
}

/* ── Live incrementing counter ── */
function useLiveCounter(base: number) {
  const [value, setValue] = useState(base)
  useEffect(() => {
    const interval = setInterval(() => {
      setValue((v) => v + Math.floor(Math.random() * 3) + 1)
    }, 1000)
    return () => clearInterval(interval)
  }, [])
  return value
}

/* ── Activity feed items ── */
const feedTemplates = [
  { msg: 'Someone earned a $0.50 scan comp!', type: 'comp' as const },
  { msg: 'New member joined BlakJaks!', type: 'scan' as const },
  { msg: 'Someone won a $100 comp prize!', type: 'comp' as const },
  { msg: 'Affiliate earned $21 match bonus!', type: 'comp' as const },
  { msg: 'QR code verified on Polygon', type: 'scan' as const },
  { msg: 'Someone reached VIP tier!', type: 'system' as const },
  { msg: 'Wholesale order processed', type: 'order' as const },
  { msg: 'Treasury balance verified on-chain', type: 'system' as const },
  { msg: 'Someone scanned their first POP code!', type: 'scan' as const },
  { msg: 'High Roller tier bonus distributed', type: 'comp' as const },
]

function useLiveFeed() {
  const [items, setItems] = useState(() =>
    Array.from({ length: 8 }, (_, i) => ({
      id: `init-${i}`,
      message: feedTemplates[i % feedTemplates.length].msg,
      ago: (i + 1) * 4,
    }))
  )

  useEffect(() => {
    const interval = setInterval(() => {
      const tpl = feedTemplates[Math.floor(Math.random() * feedTemplates.length)]
      setItems((prev) => [
        { id: `live-${Date.now()}`, message: tpl.msg, ago: 0 },
        ...prev.slice(0, 9),
      ])
    }, 2000)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const interval = setInterval(() => {
      setItems((prev) => prev.map((item) => ({ ...item, ago: item.ago + 1 })))
    }, 1000)
    return () => clearInterval(interval)
  }, [])

  return items
}

/* ── OVERVIEW TAB ── */
function OverviewTab() {
  const liveScanCount = useLiveCounter(transparencyOverview.totalScans)
  const feedItems = useLiveFeed()

  return (
    <div className="space-y-8">
      {/* Live scan counter */}
      <Card className="text-center py-10">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[#D4AF37]/10 mb-4">
          <Scan size={32} className="text-[#D4AF37]" />
        </div>
        <p className="text-sm text-[var(--color-text-muted)] mb-2">Live Scan Counter</p>
        <p className="text-5xl sm:text-6xl font-black gold-gradient-text tabular-nums">
          {liveScanCount.toLocaleString()}
        </p>
        <div className="mt-3 flex items-center justify-center gap-2">
          <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
          <span className="text-xs text-emerald-400">Live</span>
        </div>
      </Card>

      {/* Key metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Scan} label="Total Scans (All-Time)" value={transparencyOverview.totalScans.toLocaleString()} color="#D4AF37" />
        <StatCard icon={CircleDollarSign} label="Monthly Sales Volume" value={formatCurrency(transparencyOverview.monthlySales)} color="#3B82F6" />
        <StatCard icon={Users} label="Active Members (30d)" value={transparencyOverview.activeMembers.toLocaleString()} color="#22C55E" />
        <StatCard icon={TrendingUp} label="Growth Rate" value={`${transparencyOverview.growthRate}%`} sub="Month over month" color="#A78BFA" />
      </div>

      {/* Live activity feed */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Activity size={18} className="text-[#D4AF37]" />
          <h3 className="font-bold text-white">Live Activity Feed</h3>
          <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
        </div>
        <div className="space-y-0 max-h-80 overflow-y-auto">
          {feedItems.map((item) => (
            <div
              key={item.id}
              className="flex items-center justify-between py-3 border-b border-[var(--color-border)] last:border-0 animate-[fadeIn_0.3s_ease]"
            >
              <div className="flex items-center gap-3">
                <div className="h-2 w-2 rounded-full bg-[#D4AF37]" />
                <span className="text-sm text-[var(--color-text-muted)]">{item.message}</span>
              </div>
              <span className="text-xs text-[var(--color-text-dim)] shrink-0 ml-4 tabular-nums">
                {item.ago}s ago
              </span>
            </div>
          ))}
        </div>
      </Card>
    </div>
  )
}

/* ── TREASURY TAB ── */
function TreasuryTab() {
  const poolLabels: Record<string, string> = {
    member: '50% of Gross Profit',
    affiliate: '5% of Gross Profit',
    wholesale: '5% of Gross Profit',
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {treasuryWallets.map((wallet: TreasuryWallet) => (
          <Card key={wallet.name} className="relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-1 gold-gradient" />
            <div className="mb-4">
              <div className="flex items-center gap-2 mb-1">
                <Wallet size={18} className="text-[#D4AF37]" />
                <h3 className="font-bold text-white">{wallet.name}</h3>
              </div>
              <p className="text-xs text-[var(--color-text-dim)]">{poolLabels[wallet.pool] || wallet.pool}</p>
            </div>

            <p className="text-3xl font-black text-white mb-4">
              {formatCurrency(wallet.balance)}
            </p>

            <ProgressBar value={wallet.utilization} max={100} label="Pool Utilization" />

            <div className="mt-4 flex items-center justify-between rounded-xl bg-[var(--color-bg-surface)] px-3 py-2">
              <span className="text-xs text-[var(--color-text-dim)] font-mono">{wallet.address}</span>
              <CopyButton text={wallet.address} />
            </div>

            <a
              href={`https://polygonscan.com/address/${wallet.address}`}
              target="_blank"
              rel="noopener noreferrer"
              className="mt-3 flex items-center gap-1.5 text-xs text-[#D4AF37] hover:underline"
            >
              Verify on Blockchain <ExternalLink size={12} />
            </a>

            <div className="mt-4">
              <p className="text-xs text-[var(--color-text-dim)] mb-2">30-Day Balance Trend</p>
              <Sparkline data={wallet.sparklineData} width={280} height={40} />
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}

/* ── COMPS TAB ── */
function CompsTab() {
  const prizeTiers = [
    { amount: 100, label: '$100 Comp', awarded: 1247, eligibility: 'All tiers', frequency: 'Every 21 scans' },
    { amount: 1000, label: '$1,000 Comp', awarded: 89, eligibility: 'VIP and above', frequency: 'Every 210 scans' },
    { amount: 10000, label: '$10,000 Comp', awarded: 12, eligibility: 'High Roller and above', frequency: 'Every 2,100 scans' },
    { amount: 200000, label: '$200K Trip', awarded: 2, eligibility: 'Whale only', frequency: 'Every 21,000 scans' },
  ]

  const tierEligibility = [
    { tier: 'Standard', icon: Star, color: '#EF4444', comps: [true, false, false, false] },
    { tier: 'VIP', icon: Award, color: '#A1A1AA', comps: [true, true, false, false] },
    { tier: 'High Roller', icon: Gem, color: '#D4AF37', comps: [true, true, true, false] },
    { tier: 'Whale', icon: Crown, color: '#E5E7EB', comps: [true, true, true, true] },
  ]

  return (
    <div className="space-y-8">
      {/* Prize tiers grid */}
      <div>
        <h3 className="text-lg font-bold text-white mb-4">Prize Tiers</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {prizeTiers.map((tier) => (
            <Card key={tier.label}>
              <p className="text-2xl font-black gold-gradient-text mb-1">{formatCurrency(tier.amount)}</p>
              <p className="text-sm font-medium text-white mb-3">{tier.label}</p>
              <div className="space-y-2 text-xs text-[var(--color-text-muted)]">
                <div className="flex justify-between"><span>Awarded</span><span className="text-white font-medium">{tier.awarded.toLocaleString()}</span></div>
                <div className="flex justify-between"><span>Eligibility</span><span className="text-white font-medium">{tier.eligibility}</span></div>
                <div className="flex justify-between"><span>Frequency</span><span className="text-white font-medium">{tier.frequency}</span></div>
              </div>
            </Card>
          ))}
        </div>
      </div>

      {/* Next milestones */}
      <Card>
        <h3 className="text-lg font-bold text-white mb-4">Next Milestones (example member)</h3>
        <div className="space-y-4">
          <div>
            <div className="flex justify-between text-sm mb-1">
              <span className="text-[var(--color-text-muted)]">Next $100 Comp</span>
              <span className="text-white font-medium">13 / 21 scans</span>
            </div>
            <ProgressBar value={13} max={21} />
            <p className="text-xs text-[var(--color-text-dim)] mt-1">8 scans until next $100</p>
          </div>
          <div>
            <div className="flex justify-between text-sm mb-1">
              <span className="text-[var(--color-text-muted)]">Next $1,000 Comp</span>
              <span className="text-white font-medium">602 / 1,210 scans</span>
            </div>
            <ProgressBar value={602} max={1210} />
            <p className="text-xs text-[var(--color-text-dim)] mt-1">608 scans until next $1,000</p>
          </div>
        </div>
      </Card>

      {/* Trip comp section */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Crown size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">$200K Luxury Trip Comp</h3>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Eligible Whales</p>
            <p className="text-2xl font-bold text-white">{compTierStats[3].members}</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Trips This Month</p>
            <p className="text-2xl font-bold text-white">0</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Trips Lifetime</p>
            <p className="text-2xl font-bold text-white">2</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Reserve Funds</p>
            <p className="text-2xl font-bold gold-gradient-text">$400,000</p>
          </div>
        </div>
        <div>
          <div className="flex justify-between text-sm mb-1">
            <span className="text-[var(--color-text-muted)]">Progress to next 500K global scans</span>
            <span className="text-white font-medium">347,523 / 500,000</span>
          </div>
          <ProgressBar value={347523} max={500000} />
        </div>
      </Card>

      {/* New member guarantee */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Gift size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">New Member Guarantee</h3>
        </div>
        <div className="grid sm:grid-cols-2 gap-4">
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Guarantees Paid</p>
            <p className="text-2xl font-bold text-white">4,821</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Total Value</p>
            <p className="text-2xl font-bold gold-gradient-text">$24,105</p>
          </div>
        </div>
      </Card>

      {/* Tier eligibility table */}
      <Card>
        <h3 className="text-lg font-bold text-white mb-4">Tier Eligibility Matrix</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-[var(--color-border)]">
                <th className="text-left py-3 text-[var(--color-text-muted)] font-medium">Tier</th>
                <th className="text-center py-3 text-[var(--color-text-muted)] font-medium">$100</th>
                <th className="text-center py-3 text-[var(--color-text-muted)] font-medium">$1,000</th>
                <th className="text-center py-3 text-[var(--color-text-muted)] font-medium">$10,000</th>
                <th className="text-center py-3 text-[var(--color-text-muted)] font-medium">$200K Trip</th>
              </tr>
            </thead>
            <tbody>
              {tierEligibility.map(({ tier, icon: Icon, color, comps }) => (
                <tr key={tier} className="border-b border-[var(--color-border)] last:border-0">
                  <td className="py-3">
                    <div className="flex items-center gap-2">
                      <Icon size={16} style={{ color }} />
                      <span className="font-medium text-white">{tier}</span>
                    </div>
                  </td>
                  {comps.map((eligible, i) => (
                    <td key={i} className="text-center py-3">
                      {eligible
                        ? <CheckCircle2 size={16} className="text-emerald-400 mx-auto" />
                        : <span className="text-[var(--color-text-dim)]">&mdash;</span>
                      }
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Vault economy */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Layers size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">Vault Economy</h3>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Total Vaulted</p>
            <p className="text-xl font-bold text-white">$89,400</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Bonus Issued</p>
            <p className="text-xl font-bold text-emerald-400">$12,350</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Expired</p>
            <p className="text-xl font-bold text-red-400">$2,100</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Net Active</p>
            <p className="text-xl font-bold gold-gradient-text">$87,300</p>
          </div>
        </div>
        <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
          <h4 className="text-sm font-medium text-white mb-2">Vault Rules</h4>
          <ul className="space-y-1.5 text-xs text-[var(--color-text-muted)]">
            <li className="flex items-start gap-2"><CheckCircle2 size={12} className="text-[#D4AF37] mt-0.5 shrink-0" />Comps over $100 are vaulted for 30 days before withdrawal</li>
            <li className="flex items-start gap-2"><CheckCircle2 size={12} className="text-[#D4AF37] mt-0.5 shrink-0" />Vaulted funds earn a 2% bonus upon release</li>
            <li className="flex items-start gap-2"><CheckCircle2 size={12} className="text-[#D4AF37] mt-0.5 shrink-0" />Unclaimed vaulted funds expire after 90 days</li>
            <li className="flex items-start gap-2"><CheckCircle2 size={12} className="text-[#D4AF37] mt-0.5 shrink-0" />Whale tier members have instant vault access (no waiting period)</li>
          </ul>
        </div>
      </Card>
    </div>
  )
}

/* ── PARTNERS TAB ── */
function PartnersTab() {
  return (
    <div className="space-y-8">
      {/* Affiliate metrics */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <UserCheck size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">Affiliate Program</h3>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Active Affiliates</p>
            <div className="flex items-center gap-2">
              <p className="text-2xl font-bold text-white">{partnerMetrics.activeAffiliates}</p>
              <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
            </div>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Total Affiliates</p>
            <p className="text-2xl font-bold text-white">{partnerMetrics.totalAffiliates}</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Chips Issued</p>
            <p className="text-2xl font-bold text-white">14,280</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Sunset Status</p>
            <Badge status="active" />
          </div>
        </div>

        <div className="grid sm:grid-cols-2 gap-4 mb-6">
          <Card className="!bg-[var(--color-bg-surface)] !p-4">
            <div className="flex items-center gap-2 mb-2">
              <Coins size={16} className="text-[#D4AF37]" />
              <h4 className="text-sm font-medium text-white">Weekly Pool</h4>
            </div>
            <p className="text-xl font-bold text-white mb-1">{formatCurrency(4200)}</p>
            <p className="text-xs text-[var(--color-text-dim)]">Last payout: Feb 14, 2025</p>
            <p className="text-xs text-emerald-400 mt-1">Accruing this week: $1,850</p>
          </Card>
          <Card className="!bg-[var(--color-bg-surface)] !p-4">
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp size={16} className="text-[#D4AF37]" />
              <h4 className="text-sm font-medium text-white">21% Match (No Cap)</h4>
            </div>
            <p className="text-xl font-bold gold-gradient-text mb-1">{formatCurrency(partnerMetrics.affiliatePayouts)}</p>
            <p className="text-xs text-[var(--color-text-dim)]">Lifetime total paid</p>
          </Card>
        </div>

        {/* Permanent tier floors */}
        <div>
          <h4 className="text-sm font-medium text-white mb-3">Permanent Tier Floors</h4>
          <div className="grid grid-cols-3 gap-3">
            {[
              { tier: 'VIP', tins: '210', icon: Award, color: '#A1A1AA' },
              { tier: 'High Roller', tins: '2,100', icon: Gem, color: '#D4AF37' },
              { tier: 'Whale', tins: '21,000', icon: Crown, color: '#E5E7EB' },
            ].map(({ tier, tins, icon: Icon, color }) => (
              <div key={tier} className="rounded-xl bg-[var(--color-bg-surface)] p-3 text-center">
                <Icon size={20} className="mx-auto mb-1" style={{ color }} />
                <p className="text-xs font-medium text-white">{tier}</p>
                <p className="text-xs text-[var(--color-text-dim)]">{tins} tins</p>
              </div>
            ))}
          </div>
        </div>

        <p className="text-xs text-[var(--color-text-dim)] mt-3">Last chip check: Feb 17, 2025</p>
      </Card>

      {/* Wholesale */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Package size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">Wholesale Partners</h3>
        </div>
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Active Accounts</p>
            <p className="text-2xl font-bold text-white">{partnerMetrics.activeWholesalers}</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Chips Issued</p>
            <p className="text-2xl font-bold text-white">6,480</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Comps Distributed</p>
            <p className="text-2xl font-bold text-white">$48,200</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Total Volume</p>
            <p className="text-2xl font-bold gold-gradient-text">{formatCurrency(partnerMetrics.wholesaleVolume)}</p>
          </div>
        </div>
      </Card>

      {/* Partner treasuries */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Wallet size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">Partner Treasuries</h3>
        </div>
        <div className="grid sm:grid-cols-2 gap-4">
          {treasuryWallets.filter((w) => w.pool !== 'member').map((wallet) => (
            <div key={wallet.name} className="rounded-xl bg-[var(--color-bg-surface)] p-4">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-white">{wallet.name}</h4>
                <a
                  href={`https://polygonscan.com/address/${wallet.address}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-xs text-[#D4AF37] hover:underline"
                >
                  Verify <ExternalLink size={10} />
                </a>
              </div>
              <p className="text-xl font-bold text-white mb-2">{formatCurrency(wallet.balance)}</p>
              <div className="flex items-center gap-2">
                <span className="text-xs text-[var(--color-text-dim)] font-mono">{wallet.address}</span>
                <CopyButton text={wallet.address} />
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  )
}

/* ── SYSTEMS TAB ── */
function SystemsTab() {
  const tierDistribution = compTierStats.map((t) => ({
    ...t,
    total: compTierStats.reduce((s, c) => s + c.members, 0),
  }))
  const totalMembers = tierDistribution[0]?.total || 1

  const budgetAllocated = 72
  const onTrack = budgetAllocated < 85

  return (
    <div className="space-y-8">
      {/* Comp budget health */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <BarChart3 size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">Comp Budget Health</h3>
        </div>
        <div className="grid sm:grid-cols-2 gap-4 mb-4">
          <div>
            <p className="text-sm text-[var(--color-text-muted)] mb-2">Budget Allocated</p>
            <ProgressBar value={budgetAllocated} max={100} label={`${budgetAllocated}% of quarterly budget`} />
          </div>
          <div className="flex items-center gap-3 rounded-xl bg-[var(--color-bg-surface)] p-4">
            <div className={`h-3 w-3 rounded-full ${onTrack ? 'bg-emerald-400' : 'bg-red-400'}`} />
            <div>
              <p className="text-sm font-medium text-white">{onTrack ? 'On Track' : 'Over Budget'}</p>
              <p className="text-xs text-[var(--color-text-dim)]">Quarterly budget status</p>
            </div>
          </div>
        </div>
      </Card>

      {/* Reconciliation */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <CheckCircle2 size={18} className="text-emerald-400" />
          <h3 className="text-lg font-bold text-white">Reconciliation</h3>
        </div>
        <div className="grid sm:grid-cols-2 gap-4">
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Last Reconciliation</p>
            <p className="text-lg font-bold text-white">Feb 17, 2025</p>
          </div>
          <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
            <p className="text-xs text-[var(--color-text-dim)] mb-1">Status</p>
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-emerald-400" />
              <p className="text-lg font-bold text-emerald-400">Balanced</p>
            </div>
          </div>
        </div>
      </Card>

      {/* Tier distribution */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Users size={18} className="text-[#D4AF37]" />
          <h3 className="text-lg font-bold text-white">Tier Distribution</h3>
        </div>
        <div className="space-y-4">
          {[
            { name: 'Standard', members: compTierStats[0].members, color: '#EF4444', icon: Star },
            { name: 'VIP', members: compTierStats[1].members, color: '#A1A1AA', icon: Award },
            { name: 'High Roller', members: compTierStats[2].members, color: '#D4AF37', icon: Gem },
            { name: 'Whale', members: compTierStats[3].members, color: '#E5E7EB', icon: Crown },
          ].map(({ name, members, color, icon: Icon }) => {
            const pct = ((members / totalMembers) * 100).toFixed(1)
            return (
              <div key={name}>
                <div className="flex items-center justify-between mb-1.5">
                  <div className="flex items-center gap-2">
                    <Icon size={14} style={{ color }} />
                    <span className="text-sm font-medium text-white">{name}</span>
                  </div>
                  <div className="flex items-center gap-3 text-xs">
                    <span className="text-[var(--color-text-muted)]">{members.toLocaleString()} members</span>
                    <span className="text-white font-medium">{pct}%</span>
                  </div>
                </div>
                <div className="overflow-hidden rounded-full bg-[var(--color-border)] h-2">
                  <div className="h-full rounded-full transition-all duration-500" style={{ width: `${pct}%`, backgroundColor: color }} />
                </div>
              </div>
            )
          })}
        </div>
      </Card>

      {/* Uptime and API response */}
      <div className="grid sm:grid-cols-2 gap-6">
        <Card>
          <div className="flex items-center gap-2 mb-4">
            <Server size={18} className="text-[#D4AF37]" />
            <h3 className="text-lg font-bold text-white">System Uptime</h3>
          </div>
          <p className="text-4xl font-black text-emerald-400">{systemHealth.uptime}%</p>
          <p className="text-xs text-[var(--color-text-dim)] mt-1">Last 30 days</p>
        </Card>
        <Card>
          <div className="flex items-center gap-2 mb-4">
            <Zap size={18} className="text-[#D4AF37]" />
            <h3 className="text-lg font-bold text-white">API Response Time</h3>
          </div>
          <p className="text-4xl font-black text-white">{systemHealth.apiResponseTime}<span className="text-lg text-[var(--color-text-dim)]">ms</span></p>
          <p className="text-xs text-[var(--color-text-dim)] mt-1">Average (last 24h)</p>
        </Card>
      </div>
    </div>
  )
}

/* ── MAIN TRANSPARENCY PAGE ── */
export default function TransparencyPage() {
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <div className="py-8 sm:py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#D4AF37]/10">
              <Shield size={20} className="text-[#D4AF37]" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-black text-white">
              Transparency <span className="gold-gradient-text">Dashboard</span>
            </h1>
          </div>
          <p className="text-[var(--color-text-muted)] max-w-2xl">
            Full public visibility into BlakJaks operations. Every metric, every wallet, every payout &mdash; verifiable on-chain.
          </p>
        </div>

        {/* Tabs */}
        <div className="mb-8 overflow-x-auto">
          <Tabs tabs={tabList} activeTab={activeTab} onChange={setActiveTab} />
        </div>

        {/* Tab content */}
        {activeTab === 'overview' && <OverviewTab />}
        {activeTab === 'treasury' && <TreasuryTab />}
        {activeTab === 'comps' && <CompsTab />}
        {activeTab === 'partners' && <PartnersTab />}
        {activeTab === 'systems' && <SystemsTab />}
      </div>
    </div>
  )
}
