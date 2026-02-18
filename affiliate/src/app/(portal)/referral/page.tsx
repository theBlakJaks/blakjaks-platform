'use client'

import { useEffect, useState } from 'react'
import { Copy, Check, MousePointerClick, UserPlus, BarChart3, Share2, Pencil } from 'lucide-react'
import { QRCodeSVG } from 'qrcode.react'
import StatCard from '@/components/StatCard'
import GoldButton from '@/components/GoldButton'
import Spinner from '@/components/Spinner'
import { getReferralLink, updateReferralCode } from '@/lib/api'
import { formatNumber } from '@/lib/utils'
import type { ReferralLink } from '@/lib/types'

const SHARE_LINKS = [
  { label: 'X / Twitter', icon: '𝕏', getUrl: (url: string) => `https://twitter.com/intent/tweet?text=Check%20out%20BlakJaks!&url=${encodeURIComponent(url)}` },
  { label: 'Facebook', icon: 'f', getUrl: (url: string) => `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}` },
  { label: 'WhatsApp', icon: 'W', getUrl: (url: string) => `https://wa.me/?text=Check%20out%20BlakJaks!%20${encodeURIComponent(url)}` },
  { label: 'Telegram', icon: 'T', getUrl: (url: string) => `https://t.me/share/url?url=${encodeURIComponent(url)}&text=Check%20out%20BlakJaks!` },
  { label: 'Email', icon: '@', getUrl: (url: string) => `mailto:?subject=Check%20out%20BlakJaks&body=Check%20out%20BlakJaks!%20${encodeURIComponent(url)}` },
]

export default function ReferralPage() {
  const [link, setLink] = useState<ReferralLink | null>(null)
  const [loading, setLoading] = useState(true)
  const [copied, setCopied] = useState(false)
  const [editing, setEditing] = useState(false)
  const [codeInput, setCodeInput] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    getReferralLink().then(l => { setLink(l); setCodeInput(l.custom_code || '') }).finally(() => setLoading(false))
  }, [])

  if (loading || !link) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  const handleCopy = () => { navigator.clipboard.writeText(link.url); setCopied(true); setTimeout(() => setCopied(false), 2000) }

  const handleSaveCode = async () => {
    if (!codeInput.trim()) return
    setSaving(true)
    const updated = await updateReferralCode(codeInput.trim().toUpperCase())
    setLink(updated)
    setEditing(false)
    setSaving(false)
  }

  return (
    <div className="space-y-6">
      {/* Link Stats */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard icon={MousePointerClick} label="Total Clicks" value={formatNumber(link.total_clicks)} />
        <StatCard icon={UserPlus} label="Total Signups" value={formatNumber(link.total_signups)} />
        <StatCard icon={BarChart3} label="Conversion Rate" value={`${link.conversion_rate}%`} />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Referral Link + Copy */}
        <div className="space-y-6">
          <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
            <h3 className="mb-4 text-sm font-semibold text-white">Your Referral Link</h3>
            <div className="flex items-center gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3">
              <p className="flex-1 truncate font-mono text-sm text-[var(--color-gold)]">{link.url}</p>
              <button onClick={handleCopy} className="flex items-center gap-1.5 rounded-lg bg-[var(--color-gold)]/10 px-3 py-1.5 text-xs font-medium text-[var(--color-gold)] hover:bg-[var(--color-gold)]/20">
                {copied ? <Check size={14} /> : <Copy size={14} />} {copied ? 'Copied!' : 'Copy'}
              </button>
            </div>
          </div>

          {/* Custom Code Editor */}
          <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-sm font-semibold text-white">Custom Referral Code</h3>
              {!editing && <button onClick={() => setEditing(true)} className="flex items-center gap-1 text-xs text-[var(--color-gold)] hover:underline"><Pencil size={12} /> Edit</button>}
            </div>
            {editing ? (
              <div className="flex gap-2">
                <div className="flex flex-1 items-center rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4">
                  <span className="text-xs text-[var(--color-text-dim)]">blakjaks.com/r/</span>
                  <input value={codeInput} onChange={e => setCodeInput(e.target.value.replace(/[^a-zA-Z0-9_]/g, ''))} className="flex-1 bg-transparent px-1 py-3 text-sm text-white outline-none" placeholder="YOURCODE" />
                </div>
                <GoldButton size="sm" onClick={handleSaveCode} disabled={saving}>{saving ? <Spinner className="h-3 w-3" /> : 'Save'}</GoldButton>
                <GoldButton size="sm" variant="outline" onClick={() => setEditing(false)}>Cancel</GoldButton>
              </div>
            ) : (
              <p className="font-mono text-sm text-[var(--color-text-muted)]">
                blakjaks.com/r/<span className="text-[var(--color-gold)]">{link.custom_code || link.code}</span>
              </p>
            )}
          </div>

          {/* Social Share */}
          <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
            <h3 className="mb-4 text-sm font-semibold text-white">Share</h3>
            <div className="flex flex-wrap gap-2">
              {SHARE_LINKS.map(s => (
                <a key={s.label} href={s.getUrl(link.url)} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 rounded-xl border border-[var(--color-border)] px-4 py-2.5 text-sm font-medium text-[var(--color-text-muted)] hover:border-[var(--color-gold)] hover:text-[var(--color-gold)]">
                  <span className="text-xs">{s.icon}</span> {s.label}
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* QR Code */}
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-4 text-sm font-semibold text-white">QR Code</h3>
          <div className="flex flex-col items-center gap-4">
            <div className="rounded-2xl bg-white p-6">
              <QRCodeSVG value={link.url} size={220} fgColor="#0D0D0F" bgColor="#FFFFFF" />
            </div>
            <p className="text-center text-xs text-[var(--color-text-dim)]">Scan to visit your referral page. Perfect for in-person sharing.</p>
            <div className="flex items-center gap-2 text-[var(--color-text-muted)]">
              <Share2 size={14} />
              <span className="text-xs">Right-click to save QR code image</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
