import { useCallback, useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Shield, ShieldOff, Star, Gift, UserCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import { getUser, suspendUser, adjustTier, type UserDetailFull } from '../api/users'
import { awardComp } from '../api/comps'
import { formatDate, formatDateTime, formatCurrency, formatTier } from '../utils/formatters'

const TABS = ['Overview', 'Scans', 'Wallet', 'Orders', 'Affiliate', 'Activity'] as const
type Tab = typeof TABS[number]
const TIER_OPTIONS = ['Standard', 'VIP', 'High Roller', 'Whale']

export default function UserDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [user, setUser] = useState<UserDetailFull | null>(null)
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<Tab>('Overview')

  // Modal state
  const [suspendOpen, setSuspendOpen] = useState(false)
  const [tierOpen, setTierOpen] = useState(false)
  const [compOpen, setCompOpen] = useState(false)
  const [selectedTier, setSelectedTier] = useState('')
  const [compAmount, setCompAmount] = useState('')
  const [compReason, setCompReason] = useState('')

  const fetchUser = useCallback(async () => {
    if (!id) return
    setLoading(true)
    const data = await getUser(id)
    setUser(data)
    setSelectedTier(formatTier(data.tier_name))
    setLoading(false)
  }, [id])

  useEffect(() => { fetchUser() }, [fetchUser])

  const handleSuspend = async () => {
    if (!user) return
    try {
      await suspendUser(user.id, !user.is_suspended)
      toast.success(user.is_suspended ? 'User activated' : 'User suspended')
      fetchUser()
    } catch {
      toast.error('Failed to update user status')
    }
  }

  const handleTierChange = async () => {
    if (!user) return
    try {
      await adjustTier(user.id, selectedTier)
      toast.success(`Tier updated to ${selectedTier}`)
      setTierOpen(false)
      fetchUser()
    } catch {
      toast.error('Failed to update tier')
    }
  }

  const handleGrantComp = async () => {
    if (!user || !compAmount) return
    try {
      await awardComp(user.id, parseFloat(compAmount), compReason || 'Admin override')
      toast.success(`Comp of ${compAmount} BJAK granted`)
      setCompOpen(false)
      setCompAmount('')
      setCompReason('')
      fetchUser()
    } catch {
      toast.error('Failed to grant comp')
    }
  }

  if (loading || !user) {
    return <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
  }

  return (
    <div className="space-y-6">
      {/* Back button + header */}
      <button onClick={() => navigate('/users')} className="flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700">
        <ArrowLeft size={16} /> Back to Users
      </button>

      <div className="flex flex-wrap items-start justify-between gap-4 rounded-xl bg-white p-6 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-indigo-100">
            <UserCircle size={32} className="text-indigo-600" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">{user.first_name} {user.last_name}</h2>
            <p className="text-sm text-slate-500">{user.email}</p>
            <div className="mt-1 flex items-center gap-2">
              <Badge label={formatTier(user.tier_name)} variant="tier" />
              <Badge label={user.is_suspended ? 'suspended' : 'active'} />
              {user.is_admin && <Badge label="admin" />}
              <span className="text-xs text-slate-400">Member since {formatDate(user.created_at)}</span>
            </div>
          </div>
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => setSuspendOpen(true)}
            className={`flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium ${
              user.is_suspended
                ? 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                : 'bg-red-50 text-red-700 hover:bg-red-100'
            }`}
          >
            {user.is_suspended ? <Shield size={16} /> : <ShieldOff size={16} />}
            {user.is_suspended ? 'Activate' : 'Suspend'}
          </button>
          <button
            onClick={() => setTierOpen(true)}
            className="flex items-center gap-1.5 rounded-lg bg-amber-50 px-3 py-2 text-sm font-medium text-amber-700 hover:bg-amber-100"
          >
            <Star size={16} /> Adjust Tier
          </button>
          <button
            onClick={() => setCompOpen(true)}
            className="flex items-center gap-1.5 rounded-lg bg-indigo-50 px-3 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100"
          >
            <Gift size={16} /> Grant Comp
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-200">
        <nav className="-mb-px flex gap-6">
          {TABS.map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`border-b-2 pb-3 text-sm font-medium transition-colors ${
                tab === t
                  ? 'border-indigo-600 text-indigo-600'
                  : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700'
              }`}
            >
              {t}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab content */}
      <div>
        {tab === 'Overview' && <OverviewTab user={user} />}
        {tab === 'Scans' && <ScansTab user={user} />}
        {tab === 'Wallet' && <WalletTab user={user} />}
        {tab === 'Orders' && <OrdersTab user={user} />}
        {tab === 'Affiliate' && <AffiliateTab user={user} />}
        {tab === 'Activity' && <ActivityTab user={user} />}
      </div>

      {/* Modals */}
      <ConfirmDialog
        open={suspendOpen}
        onClose={() => setSuspendOpen(false)}
        onConfirm={handleSuspend}
        title={user.is_suspended ? 'Activate User' : 'Suspend User'}
        message={
          user.is_suspended
            ? `Are you sure you want to reactivate ${user.email}?`
            : `Are you sure you want to suspend ${user.email}? They will lose access to the platform.`
        }
        confirmLabel={user.is_suspended ? 'Activate' : 'Suspend'}
        variant={user.is_suspended ? 'primary' : 'danger'}
      />

      <Modal open={tierOpen} onClose={() => setTierOpen(false)} title="Adjust Tier">
        <div className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">New Tier</label>
            <select
              value={selectedTier}
              onChange={(e) => setSelectedTier(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            >
              {TIER_OPTIONS.map(t => <option key={t} value={t}>{t}</option>)}
            </select>
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setTierOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button onClick={handleTierChange} className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">Update Tier</button>
          </div>
        </div>
      </Modal>

      <Modal open={compOpen} onClose={() => setCompOpen(false)} title="Grant Comp Override">
        <div className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Amount (BJAK)</label>
            <input
              type="number"
              value={compAmount}
              onChange={(e) => setCompAmount(e.target.value)}
              min="0.01"
              step="0.01"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
              placeholder="50.00"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Reason</label>
            <input
              type="text"
              value={compReason}
              onChange={(e) => setCompReason(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
              placeholder="Admin override"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setCompOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button onClick={handleGrantComp} disabled={!compAmount} className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40">Grant Comp</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}

/* ── Tab Components ──────────────────────────────────────────────── */

function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg bg-slate-50 p-4">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 text-lg font-semibold text-slate-900">{value}</p>
    </div>
  )
}

function OverviewTab({ user }: { user: UserDetailFull }) {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <StatBox label="Lifetime Scans" value={String(user.lifetime_scans)} />
        <StatBox label="Lifetime Spend" value={formatCurrency(user.lifetime_spend)} />
        <StatBox label="Wallet Balance" value={formatCurrency(user.wallet_balance)} />
        <StatBox label="Current Scans" value={String(user.scan_count)} />
      </div>

      <div className="rounded-xl bg-white p-6 shadow-sm">
        <h3 className="mb-3 text-sm font-semibold text-slate-700">Tier Progress</h3>
        <div className="flex items-center gap-4">
          <Badge label={formatTier(user.tier_name)} variant="tier" />
          <div className="flex-1">
            <div className="mb-1 flex justify-between text-xs text-slate-500">
              <span>{user.tier_progress.current} scans this quarter</span>
              <span>{user.tier_progress.scans_needed} more for {user.tier_progress.next_tier}</span>
            </div>
            <div className="h-2 rounded-full bg-slate-100">
              <div
                className="h-2 rounded-full bg-indigo-500"
                style={{ width: `${Math.min((user.tier_progress.current / user.tier_progress.scans_needed) * 100, 100)}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-3 text-sm font-semibold text-slate-700">Profile Info</h3>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between"><dt className="text-slate-500">Email</dt><dd className="text-slate-900">{user.email}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Name</dt><dd className="text-slate-900">{user.first_name} {user.last_name}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Joined</dt><dd className="text-slate-900">{formatDate(user.created_at)}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Admin</dt><dd className="text-slate-900">{user.is_admin ? 'Yes' : 'No'}</dd></div>
          </dl>
        </div>
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-3 text-sm font-semibold text-slate-700">Quick Stats</h3>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between"><dt className="text-slate-500">Total Orders</dt><dd className="text-slate-900">{user.orders.length}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Total Transactions</dt><dd className="text-slate-900">{user.transactions.length}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Referral Code</dt><dd className="text-slate-900">{user.affiliate?.referral_code ?? 'N/A'}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Downline</dt><dd className="text-slate-900">{user.affiliate?.downline_count ?? 0}</dd></div>
          </dl>
        </div>
      </div>
    </div>
  )
}

function ScansTab({ user }: { user: UserDetailFull }) {
  return (
    <div className="overflow-hidden rounded-xl bg-white shadow-sm">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b border-slate-100 bg-slate-50">
            <th className="px-4 py-3 font-medium text-slate-600">Date</th>
            <th className="px-4 py-3 font-medium text-slate-600">Product</th>
            <th className="px-4 py-3 font-medium text-slate-600">QR Code</th>
          </tr>
        </thead>
        <tbody>
          {user.scans.map(s => (
            <tr key={s.id} className="border-b border-slate-50 hover:bg-slate-50">
              <td className="px-4 py-3 text-slate-500">{formatDateTime(s.scanned_at)}</td>
              <td className="px-4 py-3 text-slate-700">{s.product_name}</td>
              <td className="px-4 py-3 font-mono text-xs text-slate-500">{s.qr_code}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {user.scans.length === 0 && <div className="py-8 text-center text-sm text-slate-400">No scans yet</div>}
    </div>
  )
}

function WalletTab({ user }: { user: UserDetailFull }) {
  return (
    <div className="space-y-4">
      <div className="rounded-xl bg-white p-6 shadow-sm">
        <p className="text-sm text-slate-500">Current Balance</p>
        <p className="text-3xl font-bold text-slate-900">{formatCurrency(user.wallet_balance)}</p>
      </div>
      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-slate-100 bg-slate-50">
              <th className="px-4 py-3 font-medium text-slate-600">Date</th>
              <th className="px-4 py-3 font-medium text-slate-600">Type</th>
              <th className="px-4 py-3 font-medium text-slate-600">Amount</th>
              <th className="px-4 py-3 font-medium text-slate-600">Status</th>
              <th className="px-4 py-3 font-medium text-slate-600">TX Hash</th>
            </tr>
          </thead>
          <tbody>
            {user.transactions.map(tx => (
              <tr key={tx.id} className="border-b border-slate-50 hover:bg-slate-50">
                <td className="px-4 py-3 text-slate-500">{formatDateTime(tx.created_at)}</td>
                <td className="px-4 py-3 capitalize text-slate-700">{tx.type.replace('_', ' ')}</td>
                <td className={`px-4 py-3 font-medium ${tx.amount >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                  {tx.amount >= 0 ? '+' : ''}{formatCurrency(tx.amount)}
                </td>
                <td className="px-4 py-3"><Badge label={tx.status} /></td>
                <td className="px-4 py-3 font-mono text-xs text-slate-400">{tx.tx_hash ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

function OrdersTab({ user }: { user: UserDetailFull }) {
  return (
    <div className="overflow-hidden rounded-xl bg-white shadow-sm">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b border-slate-100 bg-slate-50">
            <th className="px-4 py-3 font-medium text-slate-600">Date</th>
            <th className="px-4 py-3 font-medium text-slate-600">Items</th>
            <th className="px-4 py-3 font-medium text-slate-600">Total</th>
            <th className="px-4 py-3 font-medium text-slate-600">Status</th>
          </tr>
        </thead>
        <tbody>
          {user.orders.map(o => (
            <tr key={o.id} className="border-b border-slate-50 hover:bg-slate-50">
              <td className="px-4 py-3 text-slate-500">{formatDate(o.created_at)}</td>
              <td className="px-4 py-3 text-slate-700">{o.item_count} item{o.item_count !== 1 ? 's' : ''}</td>
              <td className="px-4 py-3 font-medium text-slate-900">{formatCurrency(o.total)}</td>
              <td className="px-4 py-3"><Badge label={o.status} /></td>
            </tr>
          ))}
        </tbody>
      </table>
      {user.orders.length === 0 && <div className="py-8 text-center text-sm text-slate-400">No orders yet</div>}
    </div>
  )
}

function AffiliateTab({ user }: { user: UserDetailFull }) {
  if (!user.affiliate) {
    return (
      <div className="rounded-xl bg-white p-8 text-center shadow-sm">
        <p className="text-slate-500">This user does not have an affiliate account.</p>
      </div>
    )
  }
  const a = user.affiliate
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <StatBox label="Referral Code" value={a.referral_code} />
        <StatBox label="Downline" value={String(a.downline_count)} />
        <StatBox label="Total Earnings" value={formatCurrency(a.total_earnings)} />
        <StatBox label="Permanent Tier" value={a.permanent_tier ?? 'None'} />
      </div>
    </div>
  )
}

function ActivityTab({ user }: { user: UserDetailFull }) {
  return (
    <div className="space-y-3">
      {user.activity.map(a => (
        <div key={a.id} className="flex items-start gap-3 rounded-lg bg-white p-4 shadow-sm">
          <Badge label={a.type} />
          <div className="flex-1">
            <p className="text-sm text-slate-700">{a.description}</p>
            <p className="text-xs text-slate-400">{formatDateTime(a.timestamp)}</p>
          </div>
        </div>
      ))}
      {user.activity.length === 0 && (
        <div className="rounded-xl bg-white p-8 text-center shadow-sm">
          <p className="text-slate-500">No recent activity.</p>
        </div>
      )}
    </div>
  )
}
