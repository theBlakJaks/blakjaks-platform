import { useCallback, useEffect, useState } from 'react'
import { Copy, Check, ExternalLink, ArrowUpRight, ArrowDownLeft, Filter, Send, RefreshCw, Building2, Link as LinkIcon } from 'lucide-react'
import toast from 'react-hot-toast'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import { getPoolBalances, getTransactionHistory, sendFromPool, getTellerBankAccounts, triggerTellerSync } from '../api/treasury'
import type { TellerBankAccount } from '../api/treasury'
import { formatCurrency, formatDateTime, truncateAddress, getPolygonscanUrl, isValidPolygonAddress } from '../utils/formatters'
import { POOL_COLORS } from '../utils/constants'
import type { PoolBalance, TreasuryTransaction } from '../types'

const POOL_LABELS: Record<string, string> = {
  consumer: 'Consumer Pool (50% GP)',
  affiliate: 'Affiliate Pool (5% GP)',
  wholesale: 'Wholesale Pool (5% GP)',
}

const POOL_BORDER: Record<string, string> = {
  consumer: 'border-indigo-200',
  affiliate: 'border-purple-200',
  wholesale: 'border-amber-200',
}

export default function Treasury() {
  const [pools, setPools] = useState<PoolBalance[]>([])
  const [poolsLoading, setPoolsLoading] = useState(true)

  // Transactions
  const [txns, setTxns] = useState<TreasuryTransaction[]>([])
  const [txTotal, setTxTotal] = useState(0)
  const [txPage, setTxPage] = useState(1)
  const [txPool, setTxPool] = useState('')
  const [txDir, setTxDir] = useState('')
  const [txLoading, setTxLoading] = useState(true)

  // Send modal
  const [sendOpen, setSendOpen] = useState(false)
  const [sendPool, setSendPool] = useState('')
  const [sendTo, setSendTo] = useState('')
  const [sendAmount, setSendAmount] = useState('')
  const [sendReason, setSendReason] = useState('')
  const [sendStep, setSendStep] = useState<'form' | 'review' | 'confirm'>('form')
  const [confirmText, setConfirmText] = useState('')
  const [sending, setSending] = useState(false)

  // Bank accounts (Teller)
  const [bankAccounts, setBankAccounts] = useState<TellerBankAccount[]>([])
  const [bankLoading, setBankLoading] = useState(true)
  const [bankError, setBankError] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [lastSyncedAt, setLastSyncedAt] = useState<string | null>(null)

  // Copy tracking
  const [copiedAddr, setCopiedAddr] = useState<string | null>(null)

  const fetchBankAccounts = useCallback(async () => {
    setBankLoading(true)
    setBankError(false)
    try {
      const data = await getTellerBankAccounts()
      setBankAccounts(data)
      if (data.length > 0) {
        const latestSync = data
          .map(a => a.last_synced_at)
          .filter((d): d is string => d !== null)
          .sort()
          .at(-1) ?? null
        setLastSyncedAt(latestSync)
      }
    } catch {
      setBankError(true)
      setBankAccounts([])
    } finally {
      setBankLoading(false)
    }
  }, [])

  const handleReSyncNow = async () => {
    setSyncing(true)
    try {
      const res = await triggerTellerSync()
      setLastSyncedAt(res.synced_at)
      toast.success('Bank accounts re-synced successfully')
      await fetchBankAccounts()
    } catch {
      toast.error('Teller sync failed. Please try again.')
    } finally {
      setSyncing(false)
    }
  }

  const fetchPools = useCallback(async () => {
    setPoolsLoading(true)
    const data = await getPoolBalances()
    setPools(data)
    setPoolsLoading(false)
  }, [])

  const fetchTxns = useCallback(async () => {
    setTxLoading(true)
    const res = await getTransactionHistory(txPage, txPool || undefined, txDir || undefined)
    setTxns(res.items)
    setTxTotal(res.total)
    setTxLoading(false)
  }, [txPage, txPool, txDir])

  useEffect(() => { fetchPools() }, [fetchPools])
  useEffect(() => { fetchTxns() }, [fetchTxns])
  useEffect(() => { fetchBankAccounts() }, [fetchBankAccounts])

  const openSend = (poolName: string) => {
    setSendPool(poolName)
    setSendTo('')
    setSendAmount('')
    setSendReason('')
    setSendStep('form')
    setConfirmText('')
    setSendOpen(true)
  }

  const handleCopyAddr = (addr: string) => {
    navigator.clipboard.writeText(addr)
    setCopiedAddr(addr)
    setTimeout(() => setCopiedAddr(null), 2000)
  }

  const handleReview = () => {
    if (!sendTo || !sendAmount || !sendReason) {
      toast.error('Fill in all fields')
      return
    }
    if (!isValidPolygonAddress(sendTo)) {
      toast.error('Invalid Polygon address (0x + 40 hex characters)')
      return
    }
    const pool = pools.find(p => p.pool_name === sendPool)
    if (pool && parseFloat(sendAmount) > pool.usdt_balance) {
      toast.error('Amount exceeds pool balance')
      return
    }
    setSendStep('review')
  }

  const handleConfirmSend = async () => {
    if (confirmText !== 'CONFIRM') {
      toast.error('Type CONFIRM to proceed')
      return
    }
    setSending(true)
    try {
      const res = await sendFromPool(sendPool, sendTo, parseFloat(sendAmount), sendReason)
      toast.success(`Transfer sent! TX: ${res.tx_hash.slice(0, 12)}...`)
      setSendOpen(false)
      fetchPools()
      fetchTxns()
    } catch {
      toast.error('Transfer failed')
    } finally {
      setSending(false)
    }
  }

  const txTotalPages = Math.ceil(txTotal / 20)
  const totalBalance = pools.reduce((s, p) => s + p.usdt_balance, 0)
  const selectedPool = pools.find(p => p.pool_name === sendPool)

  return (
    <div className="space-y-6">
      {/* Pool Cards */}
      {poolsLoading ? (
        <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
      ) : (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {pools.map(pool => (
            <div key={pool.pool_name} className={`rounded-xl border-2 bg-white p-6 shadow-sm ${POOL_BORDER[pool.pool_name] || 'border-slate-200'}`}>
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-sm font-semibold text-slate-700">{POOL_LABELS[pool.pool_name] || pool.pool_name}</h3>
                <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${POOL_COLORS[pool.pool_name] || 'bg-slate-100 text-slate-800'}`}>
                  {pool.allocation_pct}%
                </span>
              </div>

              <div className="mb-4">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs text-slate-500">{truncateAddress(pool.address)}</span>
                  <button onClick={() => handleCopyAddr(pool.address)} className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
                    {copiedAddr === pool.address ? <Check size={12} className="text-emerald-500" /> : <Copy size={12} />}
                  </button>
                  <a href={getPolygonscanUrl(pool.address, 'address')} target="_blank" rel="noopener noreferrer" className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-indigo-600">
                    <ExternalLink size={12} />
                  </a>
                </div>
              </div>

              <div className="mb-4 space-y-2">
                <div>
                  <p className="text-xs text-slate-500">USDT Balance</p>
                  <p className="text-2xl font-bold text-slate-900">${pool.usdt_balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
                </div>
                <div>
                  <p className="text-xs text-slate-500">MATIC (Gas)</p>
                  <p className="text-sm font-medium text-slate-600">{pool.matic_balance.toFixed(4)} MATIC</p>
                </div>
              </div>

              <button
                onClick={() => openSend(pool.pool_name)}
                className="flex w-full items-center justify-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700"
              >
                <Send size={16} /> Send USDT
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Pool Allocation Summary */}
      <div className="rounded-xl bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-sm font-semibold text-slate-700">Pool Allocation Summary</h3>
        <div className="mb-3 flex h-4 overflow-hidden rounded-full">
          <div className="bg-indigo-500" style={{ width: '50%' }} />
          <div className="bg-purple-500" style={{ width: '5%' }} />
          <div className="bg-amber-500" style={{ width: '5%' }} />
          <div className="bg-slate-300" style={{ width: '40%' }} />
        </div>
        <div className="flex flex-wrap gap-4 text-sm">
          <div className="flex items-center gap-2"><span className="h-3 w-3 rounded-full bg-indigo-500" /><span className="text-slate-600">50% Consumer</span></div>
          <div className="flex items-center gap-2"><span className="h-3 w-3 rounded-full bg-purple-500" /><span className="text-slate-600">5% Affiliate</span></div>
          <div className="flex items-center gap-2"><span className="h-3 w-3 rounded-full bg-amber-500" /><span className="text-slate-600">5% Wholesale</span></div>
          <div className="flex items-center gap-2"><span className="h-3 w-3 rounded-full bg-slate-300" /><span className="text-slate-600">40% Retained</span></div>
          <span className="ml-auto font-medium text-slate-900">Total: {formatCurrency(totalBalance)}</span>
        </div>
      </div>

      {/* Transaction History */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-semibold text-slate-700">Transaction History</h3>
          <div className="flex items-center gap-3">
            <Filter size={16} className="text-slate-400" />
            <select value={txPool} onChange={(e) => { setTxPool(e.target.value); setTxPage(1) }} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
              <option value="">All Pools</option>
              <option value="consumer">Consumer</option>
              <option value="affiliate">Affiliate</option>
              <option value="wholesale">Wholesale</option>
            </select>
            <select value={txDir} onChange={(e) => { setTxDir(e.target.value); setTxPage(1) }} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
              <option value="">All Directions</option>
              <option value="in">Incoming</option>
              <option value="out">Outgoing</option>
            </select>
          </div>
        </div>

        {txLoading ? (
          <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
        ) : txns.length === 0 ? (
          <EmptyState title="No transactions" message="No transactions match your filter." />
        ) : (
          <div className="overflow-hidden rounded-xl bg-white shadow-sm">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50">
                  <th className="px-4 py-3 font-medium text-slate-600">Pool</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Dir</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Amount</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Address</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Tx Hash</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Reason</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Timestamp</th>
                </tr>
              </thead>
              <tbody>
                {txns.map(tx => (
                  <tr key={tx.id} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${POOL_COLORS[tx.pool_name] || 'bg-slate-100 text-slate-800'}`}>
                        {tx.pool_name}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      {tx.direction === 'in' ? (
                        <span className="flex items-center gap-1 text-emerald-600"><ArrowDownLeft size={14} /> In</span>
                      ) : (
                        <span className="flex items-center gap-1 text-red-600"><ArrowUpRight size={14} /> Out</span>
                      )}
                    </td>
                    <td className={`px-4 py-3 font-medium ${tx.direction === 'in' ? 'text-emerald-600' : 'text-red-600'}`}>
                      {tx.direction === 'in' ? '+' : '-'}{formatCurrency(tx.amount)}
                    </td>
                    <td className="px-4 py-3">
                      <a href={getPolygonscanUrl(tx.address, 'address')} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 font-mono text-xs text-indigo-600 hover:underline">
                        {truncateAddress(tx.address)}<ExternalLink size={10} />
                      </a>
                    </td>
                    <td className="px-4 py-3">
                      <a href={getPolygonscanUrl(tx.tx_hash)} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 font-mono text-xs text-indigo-600 hover:underline">
                        {truncateAddress(tx.tx_hash, 8)}<ExternalLink size={10} />
                      </a>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{tx.reason}</td>
                    <td className="px-4 py-3 text-slate-500">{formatDateTime(tx.timestamp)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {txTotalPages > 1 && (
              <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
                <span className="text-sm text-slate-500">Page {txPage} of {txTotalPages}</span>
                <div className="flex gap-2">
                  <button onClick={() => setTxPage(p => p - 1)} disabled={txPage <= 1} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Previous</button>
                  <button onClick={() => setTxPage(p => p + 1)} disabled={txPage >= txTotalPages} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Next</button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Bank Accounts (Teller) */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-semibold text-slate-700">Bank Accounts</h3>
            {lastSyncedAt && (
              <p className="mt-0.5 text-xs text-slate-400">Last synced: {formatDateTime(lastSyncedAt)}</p>
            )}
          </div>
          <button
            onClick={handleReSyncNow}
            disabled={syncing || bankLoading}
            className="flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-40"
          >
            <RefreshCw size={14} className={syncing ? 'animate-spin' : ''} />
            {syncing ? 'Syncing…' : 'Re-sync Now'}
          </button>
        </div>

        {bankLoading ? (
          <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
        ) : (bankError || bankAccounts.length === 0) ? (
          <div className="rounded-xl border-2 border-dashed border-slate-200 bg-white p-10 text-center">
            <Building2 size={36} className="mx-auto mb-3 text-slate-300" />
            <p className="mb-1 text-sm font-semibold text-slate-600">Bank accounts not connected</p>
            <p className="mb-4 text-xs text-slate-400">Link your operating, reserve, and comp pool accounts via Teller to see live balances here.</p>
            <button
              disabled
              className="inline-flex items-center gap-2 rounded-lg bg-slate-100 px-4 py-2 text-sm font-medium text-slate-400 cursor-not-allowed"
            >
              <LinkIcon size={14} />
              Connect via Teller
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            {bankAccounts.map(account => (
              <div key={account.account_type} className="rounded-xl border-2 border-emerald-200 bg-white p-6 shadow-sm">
                <div className="mb-3 flex items-start justify-between">
                  <div>
                    <p className="text-xs font-medium uppercase tracking-wide text-slate-400">{account.name}</p>
                    <p className="mt-0.5 text-sm font-semibold text-slate-700">
                      {account.institution_name ?? 'Unknown Institution'}
                    </p>
                  </div>
                  <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                    account.sync_status === 'ok'
                      ? 'bg-emerald-100 text-emerald-700'
                      : account.sync_status === 'unconfigured'
                      ? 'bg-slate-100 text-slate-500'
                      : 'bg-red-100 text-red-600'
                  }`}>
                    {account.sync_status}
                  </span>
                </div>

                <p className="mb-4 font-mono text-xs text-slate-400">
                  {account.last_four ? `•••• •••• •••• ${account.last_four}` : 'Account # not on file'}
                </p>

                <div className="mb-3">
                  <p className="text-xs text-slate-500">Balance</p>
                  <p className="text-2xl font-bold text-slate-900">
                    {formatCurrency(account.balance)}
                    <span className="ml-1.5 text-sm font-normal text-slate-400">{account.currency}</span>
                  </p>
                </div>

                <p className="text-xs text-slate-400">
                  {account.last_synced_at
                    ? `Synced ${formatDateTime(account.last_synced_at)}`
                    : 'Never synced'}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Send USDT Modal — Two-step confirmation */}
      <Modal open={sendOpen} onClose={() => setSendOpen(false)} title={`Send USDT from ${POOL_LABELS[sendPool] || sendPool}`}>
        {sendStep === 'form' && (
          <div className="space-y-4">
            <div className="rounded-lg bg-slate-50 p-3">
              <p className="text-xs text-slate-500">Available Balance</p>
              <p className="text-lg font-bold text-slate-900">${selectedPool?.usdt_balance.toLocaleString('en-US', { minimumFractionDigits: 2 }) || '0.00'}</p>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">To Address</label>
              <input type="text" value={sendTo} onChange={(e) => setSendTo(e.target.value)} placeholder="0x..." className="w-full rounded-lg border border-slate-300 px-3 py-2.5 font-mono text-sm outline-none focus:border-indigo-500" />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Amount (USDT)</label>
              <input type="number" value={sendAmount} onChange={(e) => setSendAmount(e.target.value)} min="0.01" step="0.01" className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500" />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Reason / Note</label>
              <input type="text" value={sendReason} onChange={(e) => setSendReason(e.target.value)} placeholder="Audit trail note" className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500" />
            </div>
            <div className="flex justify-end gap-3">
              <button onClick={() => setSendOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
              <button onClick={handleReview} className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">Review Transfer</button>
            </div>
          </div>
        )}

        {sendStep === 'review' && (
          <div className="space-y-4">
            <div className="rounded-lg border border-amber-200 bg-amber-50 p-4">
              <p className="mb-3 text-sm font-medium text-amber-800">Please review this transfer carefully:</p>
              <dl className="space-y-2 text-sm">
                <div className="flex justify-between"><dt className="text-amber-700">From</dt><dd className="font-medium text-amber-900">{POOL_LABELS[sendPool]}</dd></div>
                <div className="flex justify-between"><dt className="text-amber-700">To</dt><dd className="break-all font-mono text-xs text-amber-900">{sendTo}</dd></div>
                <div className="flex justify-between"><dt className="text-amber-700">Amount</dt><dd className="text-lg font-bold text-amber-900">{formatCurrency(parseFloat(sendAmount || '0'))}</dd></div>
                <div className="flex justify-between"><dt className="text-amber-700">Reason</dt><dd className="text-amber-900">{sendReason}</dd></div>
              </dl>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Type <strong>CONFIRM</strong> to proceed</label>
              <input type="text" value={confirmText} onChange={(e) => setConfirmText(e.target.value)} placeholder="CONFIRM" className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-red-500" />
            </div>
            <div className="flex justify-end gap-3">
              <button onClick={() => setSendStep('form')} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Back</button>
              <button
                onClick={handleConfirmSend}
                disabled={confirmText !== 'CONFIRM' || sending}
                className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-40"
              >
                {sending && <LoadingSpinner className="h-4 w-4" />}
                Confirm & Send
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
