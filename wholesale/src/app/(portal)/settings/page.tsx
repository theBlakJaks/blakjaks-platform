'use client'

import { useEffect, useState } from 'react'
import { Building2, Lock, Wallet, Shield, Save } from 'lucide-react'
import GoldButton from '@/components/GoldButton'
import StatusBadge from '@/components/StatusBadge'
import Spinner from '@/components/Spinner'
import { getProfile, updateProfile, changePassword } from '@/lib/api'
import { truncateAddress, formatDate } from '@/lib/utils'
import type { WholesalePartner } from '@/lib/types'

const TABS = ['Company Info', 'Change Password', 'Wallet', 'Account'] as const
type Tab = typeof TABS[number]

const TAB_ICONS = { 'Company Info': Building2, 'Change Password': Lock, Wallet: Wallet, Account: Shield }

export default function SettingsPage() {
  const [tab, setTab] = useState<Tab>('Company Info')
  const [profile, setProfile] = useState<WholesalePartner | null>(null)
  const [loading, setLoading] = useState(true)

  // Company form
  const [company, setCompany] = useState({ company_name: '', contact_person: '', email: '', phone: '', business_address: '' })
  const [companySaving, setCompanySaving] = useState(false)

  // Password form
  const [pw, setPw] = useState({ current: '', new_password: '', confirm: '' })
  const [pwError, setPwError] = useState('')
  const [pwSaving, setPwSaving] = useState(false)

  useEffect(() => {
    getProfile().then(p => {
      setProfile(p)
      setCompany({ company_name: p.company_name, contact_person: p.contact_person, email: p.email, phone: p.phone, business_address: p.business_address })
    }).finally(() => setLoading(false))
  }, [])

  const handleSaveCompany = async () => {
    setCompanySaving(true)
    try {
      const updated = await updateProfile(company)
      setProfile(updated)
    } catch { /* mock always succeeds */ }
    setCompanySaving(false)
  }

  const handleChangePassword = async () => {
    setPwError('')
    if (!pw.current || !pw.new_password || !pw.confirm) { setPwError('All fields required'); return }
    if (pw.new_password !== pw.confirm) { setPwError('Passwords do not match'); return }
    if (pw.new_password.length < 8) { setPwError('Password must be at least 8 characters'); return }
    setPwSaving(true)
    try {
      await changePassword(pw.current, pw.new_password)
      setPw({ current: '', new_password: '', confirm: '' })
    } catch { setPwError('Failed to change password') }
    setPwSaving(false)
  }

  if (loading) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="flex gap-2 overflow-x-auto">
        {TABS.map(t => {
          const Icon = TAB_ICONS[t]
          return (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`flex items-center gap-2 whitespace-nowrap rounded-xl px-4 py-2.5 text-sm font-medium transition-colors ${tab === t ? 'gold-gradient text-black' : 'border border-[var(--color-border)] text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)]'}`}
            >
              <Icon size={16} /> {t}
            </button>
          )
        })}
      </div>

      {/* Company Info */}
      {tab === 'Company Info' && (
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-6 text-sm font-semibold text-white">Company Information</h3>
          <div className="space-y-4">
            {([
              { key: 'company_name', label: 'Company Name' },
              { key: 'contact_person', label: 'Contact Person' },
              { key: 'email', label: 'Email' },
              { key: 'phone', label: 'Phone' },
              { key: 'business_address', label: 'Business Address' },
            ] as const).map(f => (
              <div key={f.key}>
                <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">{f.label}</label>
                <input
                  type="text"
                  value={company[f.key]}
                  onChange={e => setCompany(prev => ({ ...prev, [f.key]: e.target.value }))}
                  className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none focus:border-[var(--color-gold)]"
                />
              </div>
            ))}
            <GoldButton onClick={handleSaveCompany} disabled={companySaving}>
              {companySaving ? <Spinner className="h-4 w-4" /> : <><Save size={14} /> Save Changes</>}
            </GoldButton>
          </div>
        </div>
      )}

      {/* Change Password */}
      {tab === 'Change Password' && (
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-6 text-sm font-semibold text-white">Change Password</h3>
          {pwError && <div className="mb-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">{pwError}</div>}
          <div className="max-w-md space-y-4">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">Current Password</label>
              <input type="password" value={pw.current} onChange={e => setPw(prev => ({ ...prev, current: e.target.value }))} className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none focus:border-[var(--color-gold)]" />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">New Password</label>
              <input type="password" value={pw.new_password} onChange={e => setPw(prev => ({ ...prev, new_password: e.target.value }))} className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none focus:border-[var(--color-gold)]" />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">Confirm Password</label>
              <input type="password" value={pw.confirm} onChange={e => setPw(prev => ({ ...prev, confirm: e.target.value }))} className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none focus:border-[var(--color-gold)]" />
            </div>
            <GoldButton onClick={handleChangePassword} disabled={pwSaving}>
              {pwSaving ? <Spinner className="h-4 w-4" /> : 'Update Password'}
            </GoldButton>
          </div>
        </div>
      )}

      {/* Wallet */}
      {tab === 'Wallet' && profile && (
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-6 text-sm font-semibold text-white">Wallet Address</h3>
          <p className="mb-4 text-sm text-[var(--color-text-muted)]">Your Polygon USDT wallet address for comp payouts.</p>
          <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3">
            {profile.wallet_address ? (
              <div>
                <p className="font-mono text-sm text-[var(--color-gold)]">{profile.wallet_address}</p>
                <p className="mt-1 text-xs text-[var(--color-text-dim)]">Truncated: {truncateAddress(profile.wallet_address)}</p>
              </div>
            ) : (
              <p className="text-sm text-[var(--color-text-dim)]">No wallet address on file</p>
            )}
          </div>
          <p className="mt-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-xs text-[var(--color-text-dim)]">
            To update your wallet address, please contact support at wholesale@blakjaks.com
          </p>
        </div>
      )}

      {/* Account */}
      {tab === 'Account' && profile && (
        <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6">
          <h3 className="mb-6 text-sm font-semibold text-white">Account Details</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
              <span className="text-sm text-[var(--color-text-muted)]">Account Status</span>
              <StatusBadge status={profile.status} />
            </div>
            <div className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
              <span className="text-sm text-[var(--color-text-muted)]">Partner ID</span>
              <span className="font-mono text-sm text-[var(--color-gold)]">{profile.partner_id}</span>
            </div>
            <div className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
              <span className="text-sm text-[var(--color-text-muted)]">Tax ID / EIN</span>
              <span className="font-mono text-sm text-white">{profile.tax_id}</span>
            </div>
            {profile.approved_at && (
              <div className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
                <span className="text-sm text-[var(--color-text-muted)]">Approved Date</span>
                <span className="text-sm text-white">{formatDate(profile.approved_at)}</span>
              </div>
            )}
            <div className="flex items-center justify-between rounded-xl bg-[var(--color-bg)] px-4 py-3">
              <span className="text-sm text-[var(--color-text-muted)]">Account Created</span>
              <span className="text-sm text-white">{formatDate(profile.created_at)}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
