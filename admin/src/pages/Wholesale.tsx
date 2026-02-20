import { Fragment, useCallback, useEffect, useState } from 'react'
import { Building2, CheckCircle, XCircle, Eye, Gift, ChevronDown, ChevronUp, AlertCircle, RefreshCw } from 'lucide-react'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import {
  listWholesaleAccounts,
  approveWholesaleAccount,
  rejectWholesaleAccount,
  listWholesaleOrders,
  awardWholesaleComp,
} from '../api/wholesale'
import type { WholesaleAccount, WholesaleOrder } from '../api/wholesale'
import { formatCurrency, formatDate } from '../utils/formatters'

// ── Tab definition ────────────────────────────────────────────────────────

const TABS = ['Applications', 'Active Accounts'] as const
type Tab = typeof TABS[number]

// ── Applications Tab ──────────────────────────────────────────────────────

function ApplicationsTab() {
  const [applications, setApplications] = useState<WholesaleAccount[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Approve / reject confirm dialogs
  const [approveTarget, setApproveTarget] = useState<WholesaleAccount | null>(null)
  const [rejectTarget, setRejectTarget] = useState<WholesaleAccount | null>(null)

  const fetchApplications = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await listWholesaleAccounts('pending')
      setApplications(res.items)
    } catch (err) {
      setError('Failed to load applications. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchApplications() }, [fetchApplications])

  const handleApprove = async () => {
    if (!approveTarget) return
    try {
      await approveWholesaleAccount(approveTarget.id)
      toast.success(`Approved ${approveTarget.business_name}`)
      setApplications(prev => prev.filter(a => a.id !== approveTarget.id))
    } catch {
      toast.error('Failed to approve application')
    }
  }

  const handleReject = async () => {
    if (!rejectTarget) return
    try {
      await rejectWholesaleAccount(rejectTarget.id)
      toast.success(`Rejected ${rejectTarget.business_name}`)
      setApplications(prev => prev.filter(a => a.id !== rejectTarget.id))
    } catch {
      toast.error('Failed to reject application')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <LoadingSpinner />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center gap-4 py-16">
        <div className="flex items-center gap-2 text-red-600">
          <AlertCircle size={20} />
          <span className="text-sm font-medium">{error}</span>
        </div>
        <button
          onClick={fetchApplications}
          className="flex items-center gap-1.5 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          <RefreshCw size={14} /> Retry
        </button>
      </div>
    )
  }

  if (applications.length === 0) {
    return (
      <EmptyState
        title="No pending applications"
        message="All wholesale applications have been reviewed."
      />
    )
  }

  return (
    <>
      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-slate-100 bg-slate-50">
              <th className="px-4 py-3 font-medium text-slate-600">Company Name</th>
              <th className="px-4 py-3 font-medium text-slate-600">Contact</th>
              <th className="px-4 py-3 font-medium text-slate-600">Email</th>
              <th className="px-4 py-3 font-medium text-slate-600">Date Applied</th>
              <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {applications.map(app => (
              <tr key={app.id} className="border-b border-slate-50 hover:bg-slate-50">
                <td className="px-4 py-3">
                  <div>
                    <p className="font-medium text-slate-900">{app.business_name}</p>
                    {app.notes && (
                      <p className="text-xs text-slate-400 mt-0.5">{app.notes}</p>
                    )}
                  </div>
                </td>
                <td className="px-4 py-3 text-slate-700">{app.contact_name}</td>
                <td className="px-4 py-3 text-slate-600">{app.contact_email}</td>
                <td className="px-4 py-3 text-slate-500">{formatDate(app.created_at)}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setApproveTarget(app)}
                      className="flex items-center gap-1 rounded-lg bg-emerald-50 px-3 py-1.5 text-xs font-medium text-emerald-700 hover:bg-emerald-100"
                    >
                      <CheckCircle size={13} /> Approve
                    </button>
                    <button
                      onClick={() => setRejectTarget(app)}
                      className="flex items-center gap-1 rounded-lg bg-red-50 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-100"
                    >
                      <XCircle size={13} /> Reject
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <ConfirmDialog
        open={approveTarget !== null}
        onClose={() => setApproveTarget(null)}
        onConfirm={handleApprove}
        title="Approve Wholesale Application"
        message={`Approve the application for "${approveTarget?.business_name}"? They will gain full wholesale account access.`}
        confirmLabel="Approve"
      />

      <ConfirmDialog
        open={rejectTarget !== null}
        onClose={() => setRejectTarget(null)}
        onConfirm={handleReject}
        title="Reject Wholesale Application"
        message={`Reject the application for "${rejectTarget?.business_name}"? This action cannot be undone.`}
        confirmLabel="Reject"
        variant="danger"
      />
    </>
  )
}

// ── Award Comp Modal ───────────────────────────────────────────────────────

interface AwardCompModalProps {
  open: boolean
  account: WholesaleAccount | null
  onClose: () => void
  onSuccess: () => void
}

function AwardCompModal({ open, account, onClose, onSuccess }: AwardCompModalProps) {
  const [amount, setAmount] = useState('10000')
  const [reason, setReason] = useState('')
  const [awarding, setAwarding] = useState(false)

  const handleAward = async () => {
    if (!account) return
    const parsedAmount = parseFloat(amount)
    if (!parsedAmount || parsedAmount <= 0) {
      toast.error('Please enter a valid amount')
      return
    }
    setAwarding(true)
    try {
      await awardWholesaleComp(
        account.user_id,
        parsedAmount,
        reason || `Wholesale comp for ${account.business_name}`,
      )
      toast.success(`Comp of ${formatCurrency(parsedAmount)} awarded to ${account.business_name}`)
      setAmount('10000')
      setReason('')
      onSuccess()
      onClose()
    } catch {
      toast.error('Failed to award comp')
    } finally {
      setAwarding(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Award Comp">
      <div className="space-y-4">
        {account && (
          <div className="rounded-lg bg-slate-50 px-4 py-3">
            <p className="text-sm font-medium text-slate-900">{account.business_name}</p>
            <p className="text-xs text-slate-500">{account.contact_email}</p>
          </div>
        )}

        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">Amount ($)</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            min="0.01"
            step="0.01"
            placeholder="10000"
            className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
          />
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium text-slate-700">Reason (optional)</label>
          <input
            type="text"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder={`Wholesale comp for ${account?.business_name ?? 'account'}`}
            className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
          />
        </div>

        <div className="flex justify-end gap-3">
          <button
            onClick={onClose}
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            Cancel
          </button>
          <button
            onClick={handleAward}
            disabled={!amount || awarding}
            className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40"
          >
            {awarding && <LoadingSpinner className="h-4 w-4" />}
            <Gift size={14} /> Award Comp
          </button>
        </div>
      </div>
    </Modal>
  )
}

// ── Account Detail Panel ───────────────────────────────────────────────────

interface AccountDetailPanelProps {
  account: WholesaleAccount
  onAwardComp: (account: WholesaleAccount) => void
}

function AccountDetailPanel({ account, onAwardComp }: AccountDetailPanelProps) {
  const [orders, setOrders] = useState<WholesaleOrder[]>([])
  const [ordersLoading, setOrdersLoading] = useState(true)
  const [ordersError, setOrdersError] = useState<string | null>(null)

  const fetchOrders = useCallback(async () => {
    setOrdersLoading(true)
    setOrdersError(null)
    try {
      const res = await listWholesaleOrders(account.id)
      setOrders(res.items)
    } catch {
      setOrdersError('Failed to load orders.')
    } finally {
      setOrdersLoading(false)
    }
  }, [account.id])

  useEffect(() => { fetchOrders() }, [fetchOrders])

  return (
    <div className="border-t border-slate-100 bg-slate-50 px-6 py-5">
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        {/* Account info */}
        <div>
          <h4 className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Account Info</h4>
          <dl className="space-y-2 text-sm">
            <div className="flex gap-2">
              <dt className="w-28 shrink-0 text-slate-500">Company</dt>
              <dd className="font-medium text-slate-900">{account.business_name}</dd>
            </div>
            <div className="flex gap-2">
              <dt className="w-28 shrink-0 text-slate-500">Contact</dt>
              <dd className="text-slate-700">{account.contact_name}</dd>
            </div>
            <div className="flex gap-2">
              <dt className="w-28 shrink-0 text-slate-500">Email</dt>
              <dd className="text-slate-700">{account.contact_email}</dd>
            </div>
            {account.contact_phone && (
              <div className="flex gap-2">
                <dt className="w-28 shrink-0 text-slate-500">Phone</dt>
                <dd className="text-slate-700">{account.contact_phone}</dd>
              </div>
            )}
            {account.business_address && (
              <div className="flex gap-2">
                <dt className="w-28 shrink-0 text-slate-500">Address</dt>
                <dd className="text-slate-700">{account.business_address}</dd>
              </div>
            )}
            <div className="flex gap-2">
              <dt className="w-28 shrink-0 text-slate-500">Chips Balance</dt>
              <dd className="font-medium text-indigo-600">{formatCurrency(parseFloat(account.chips_balance))}</dd>
            </div>
            {account.approved_at && (
              <div className="flex gap-2">
                <dt className="w-28 shrink-0 text-slate-500">Approved</dt>
                <dd className="text-slate-700">{formatDate(account.approved_at)}</dd>
              </div>
            )}
          </dl>

          <div className="mt-4">
            <button
              onClick={() => onAwardComp(account)}
              className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-3 py-2 text-xs font-medium text-white hover:bg-indigo-700"
            >
              <Gift size={13} /> Award Comp
            </button>
          </div>
        </div>

        {/* Order history */}
        <div>
          <h4 className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Order History</h4>
          {ordersLoading ? (
            <div className="flex items-center justify-center py-8">
              <LoadingSpinner />
            </div>
          ) : ordersError ? (
            <div className="flex flex-col items-center gap-3 py-6">
              <div className="flex items-center gap-2 text-red-600 text-xs">
                <AlertCircle size={14} />
                <span>{ordersError}</span>
              </div>
              <button
                onClick={fetchOrders}
                className="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-white"
              >
                <RefreshCw size={12} /> Retry
              </button>
            </div>
          ) : orders.length === 0 ? (
            <p className="py-6 text-center text-xs text-slate-400">No orders yet</p>
          ) : (
            <div className="max-h-56 overflow-y-auto rounded-lg border border-slate-200 bg-white">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-slate-100 bg-slate-50">
                    <th className="px-3 py-2 font-medium text-slate-500">Order ID</th>
                    <th className="px-3 py-2 font-medium text-slate-500">Date</th>
                    <th className="px-3 py-2 font-medium text-slate-500">SKU</th>
                    <th className="px-3 py-2 font-medium text-slate-500">Qty</th>
                    <th className="px-3 py-2 font-medium text-slate-500">Total</th>
                    <th className="px-3 py-2 font-medium text-slate-500">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {orders.map(order => (
                    <tr key={order.id} className="border-b border-slate-50 last:border-0">
                      <td className="px-3 py-2 font-mono text-slate-500">{order.id.slice(0, 8)}</td>
                      <td className="px-3 py-2 text-slate-600">{formatDate(order.created_at)}</td>
                      <td className="px-3 py-2 text-slate-700">{order.product_sku ?? '-'}</td>
                      <td className="px-3 py-2 text-slate-700">{order.quantity}</td>
                      <td className="px-3 py-2 font-medium text-slate-900">
                        {formatCurrency(parseFloat(order.total_amount))}
                      </td>
                      <td className="px-3 py-2">
                        <Badge label={order.status} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// ── Active Accounts Tab ────────────────────────────────────────────────────

function ActiveAccountsTab() {
  const [accounts, setAccounts] = useState<WholesaleAccount[]>([])
  const [orderCounts, setOrderCounts] = useState<Record<string, number>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [expandedId, setExpandedId] = useState<string | null>(null)

  // Award comp modal
  const [compTarget, setCompTarget] = useState<WholesaleAccount | null>(null)
  const [compOpen, setCompOpen] = useState(false)

  const fetchAccounts = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await listWholesaleAccounts('approved')
      setAccounts(res.items)
      // Fetch order counts for each account in parallel
      const counts: Record<string, number> = {}
      await Promise.all(
        res.items.map(async (account) => {
          try {
            const ordersRes = await listWholesaleOrders(account.id, undefined, 1, 1)
            counts[account.id] = ordersRes.total
          } catch {
            counts[account.id] = 0
          }
        }),
      )
      setOrderCounts(counts)
    } catch {
      setError('Failed to load accounts. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchAccounts() }, [fetchAccounts])

  const toggleExpanded = (id: string) => {
    setExpandedId(prev => (prev === id ? null : id))
  }

  const handleOpenComp = (account: WholesaleAccount) => {
    setCompTarget(account)
    setCompOpen(true)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <LoadingSpinner />
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center gap-4 py-16">
        <div className="flex items-center gap-2 text-red-600">
          <AlertCircle size={20} />
          <span className="text-sm font-medium">{error}</span>
        </div>
        <button
          onClick={fetchAccounts}
          className="flex items-center gap-1.5 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          <RefreshCw size={14} /> Retry
        </button>
      </div>
    )
  }

  if (accounts.length === 0) {
    return (
      <EmptyState
        title="No active accounts"
        message="Approved wholesale accounts will appear here."
      />
    )
  }

  return (
    <>
      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b border-slate-100 bg-slate-50">
              <th className="px-4 py-3 font-medium text-slate-600">Company Name</th>
              <th className="px-4 py-3 font-medium text-slate-600">Contact</th>
              <th className="px-4 py-3 font-medium text-slate-600">Status</th>
              <th className="px-4 py-3 font-medium text-slate-600">Orders</th>
              <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {accounts.map(account => (
              <Fragment key={account.id}>
                <tr
                  className="cursor-pointer border-b border-slate-50 hover:bg-slate-50"
                  onClick={() => toggleExpanded(account.id)}
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <Building2 size={16} className="shrink-0 text-slate-400" />
                      <div>
                        <p className="font-medium text-slate-900">{account.business_name}</p>
                        <p className="text-xs text-slate-400">{account.contact_email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-slate-700">{account.contact_name}</td>
                  <td className="px-4 py-3">
                    <Badge label={account.status} />
                  </td>
                  <td className="px-4 py-3 text-slate-700">{orderCounts[account.id] ?? '—'}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={(e) => { e.stopPropagation(); toggleExpanded(account.id) }}
                        className="flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50"
                      >
                        <Eye size={13} /> View
                        {expandedId === account.id ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
                      </button>
                      <button
                        onClick={(e) => { e.stopPropagation(); handleOpenComp(account) }}
                        className="flex items-center gap-1 rounded-lg bg-indigo-50 px-2.5 py-1.5 text-xs font-medium text-indigo-700 hover:bg-indigo-100"
                      >
                        <Gift size={13} /> Comp
                      </button>
                    </div>
                  </td>
                </tr>
                {expandedId === account.id && (
                  <tr>
                    <td colSpan={5} className="p-0">
                      <AccountDetailPanel
                        account={account}
                        onAwardComp={handleOpenComp}
                      />
                    </td>
                  </tr>
                )}
              </Fragment>
            ))}
          </tbody>
        </table>
      </div>

      <AwardCompModal
        open={compOpen}
        account={compTarget}
        onClose={() => { setCompOpen(false); setCompTarget(null) }}
        onSuccess={fetchAccounts}
      />
    </>
  )
}

// ── Main Page ─────────────────────────────────────────────────────────────

export default function Wholesale() {
  const [tab, setTab] = useState<Tab>('Applications')

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-xl font-semibold text-slate-900">Wholesale Management</h1>
        <p className="mt-1 text-sm text-slate-500">
          Review applications and manage active wholesale accounts.
        </p>
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
      {tab === 'Applications' && <ApplicationsTab />}
      {tab === 'Active Accounts' && <ActiveAccountsTab />}
    </div>
  )
}
