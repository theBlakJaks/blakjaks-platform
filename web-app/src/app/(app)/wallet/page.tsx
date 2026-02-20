'use client'

import { useEffect, useState, useCallback } from 'react'
import { Copy, Check, ArrowDownCircle, RefreshCw, Wallet } from 'lucide-react'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'
import GoldButton from '@/components/ui/GoldButton'
import Badge from '@/components/ui/Badge'
import Modal from '@/components/ui/Modal'
import Tabs from '@/components/ui/Tabs'
import Table from '@/components/ui/Table'
import Input from '@/components/ui/Input'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'
import { formatCurrency, formatDate } from '@/lib/utils'

interface WalletBalance {
  balance: number
  pending_comps: number
  lifetime_earnings: number
}

interface Transaction {
  id: string
  date: string
  type: string
  amount: number
  status: string
  tx_hash?: string
  description?: string
}

const FILTER_TABS = [
  { id: 'all', label: 'All' },
  { id: 'comp', label: 'Earned' },
  { id: 'withdrawal', label: 'Withdrawn' },
  { id: 'purchase', label: 'Comps' },
]

function BalanceSkeleton() {
  return (
    <Card className="animate-pulse">
      <div className="space-y-3">
        <div className="h-4 w-32 rounded bg-[var(--color-bg-surface)]" />
        <div className="h-12 w-48 rounded bg-[var(--color-bg-surface)]" />
        <div className="h-4 w-64 rounded bg-[var(--color-bg-surface)]" />
      </div>
    </Card>
  )
}

function TableSkeleton() {
  return (
    <div className="space-y-3 animate-pulse">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="flex gap-4 px-4 py-3">
          <div className="h-4 w-24 rounded bg-[var(--color-bg-surface)]" />
          <div className="h-4 w-16 rounded bg-[var(--color-bg-surface)]" />
          <div className="h-4 w-20 rounded bg-[var(--color-bg-surface)]" />
          <div className="h-4 w-16 rounded bg-[var(--color-bg-surface)]" />
        </div>
      ))}
    </div>
  )
}

export default function WalletPage() {
  const { user } = useAuth()
  const [balance, setBalance] = useState<WalletBalance | null>(null)
  const [balanceLoading, setBalanceLoading] = useState(true)
  const [balanceError, setBalanceError] = useState<string | null>(null)

  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [txLoading, setTxLoading] = useState(true)
  const [txError, setTxError] = useState<string | null>(null)

  const [activeTab, setActiveTab] = useState('all')
  const [copied, setCopied] = useState(false)

  // Withdrawal modal
  const [withdrawOpen, setWithdrawOpen] = useState(false)
  const [withdrawAmount, setWithdrawAmount] = useState('')
  const [withdrawAddress, setWithdrawAddress] = useState('')
  const [withdrawing, setWithdrawing] = useState(false)
  const [withdrawError, setWithdrawError] = useState<string | null>(null)
  const [withdrawSuccess, setWithdrawSuccess] = useState(false)

  const loadBalance = useCallback(async () => {
    setBalanceLoading(true)
    setBalanceError(null)
    try {
      const data = await api.wallet.getBalance()
      setBalance(data)
    } catch (err) {
      setBalanceError(err instanceof Error ? err.message : 'Failed to load balance')
    } finally {
      setBalanceLoading(false)
    }
  }, [])

  const loadTransactions = useCallback(async (type?: string) => {
    setTxLoading(true)
    setTxError(null)
    try {
      const data = await api.wallet.getTransactions({ type: type === 'all' ? undefined : type })
      setTransactions(data.transactions as Transaction[])
    } catch (err) {
      setTxError(err instanceof Error ? err.message : 'Failed to load transactions')
    } finally {
      setTxLoading(false)
    }
  }, [])

  useEffect(() => {
    loadBalance()
    loadTransactions()
  }, [loadBalance, loadTransactions])

  function handleTabChange(tabId: string) {
    setActiveTab(tabId)
    loadTransactions(tabId)
  }

  function handleCopyAddress() {
    const address = user?.walletAddress ?? ''
    if (!address) return
    navigator.clipboard.writeText(address).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    })
  }

  async function handleWithdraw() {
    const amount = parseFloat(withdrawAmount)
    if (!amount || amount <= 0) {
      setWithdrawError('Enter a valid amount')
      return
    }
    if (balance && amount > balance.balance) {
      setWithdrawError('Amount exceeds available balance')
      return
    }
    setWithdrawing(true)
    setWithdrawError(null)
    try {
      await api.wallet.withdraw(amount, withdrawAddress || undefined)
      setWithdrawSuccess(true)
      loadBalance()
      loadTransactions()
    } catch (err) {
      setWithdrawError(err instanceof Error ? err.message : 'Withdrawal failed')
    } finally {
      setWithdrawing(false)
    }
  }

  function handleWithdrawClose() {
    setWithdrawOpen(false)
    setWithdrawAmount('')
    setWithdrawAddress('')
    setWithdrawError(null)
    setWithdrawSuccess(false)
  }

  const tableColumns = [
    {
      key: 'date',
      header: 'Date',
      render: (row: Record<string, unknown>) => formatDate(row.date as string),
    },
    {
      key: 'type',
      header: 'Type',
      render: (row: Record<string, unknown>) => <Badge status={row.type as string} />,
    },
    {
      key: 'amount',
      header: 'Amount',
      render: (row: Record<string, unknown>) => (
        <span
          className={
            (row.type as string) === 'withdrawal'
              ? 'text-red-400'
              : 'text-green-400'
          }
        >
          {(row.type as string) === 'withdrawal' ? '-' : '+'}
          {formatCurrency(row.amount as number)}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: Record<string, unknown>) => <Badge status={row.status as string} />,
    },
    {
      key: 'description',
      header: 'Description',
      render: (row: Record<string, unknown>) => (
        <span className="text-[var(--color-text-dim)]">
          {(row.description as string) || '—'}
        </span>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">Wallet</h1>
        <p className="mt-1 text-sm text-[var(--color-text-dim)]">
          Manage your USDT balance and transaction history
        </p>
      </div>

      {/* Balance card */}
      {balanceLoading ? (
        <BalanceSkeleton />
      ) : balanceError ? (
        <Card className="text-center">
          <p className="mb-4 text-[var(--color-danger)]">{balanceError}</p>
          <GoldButton onClick={loadBalance} variant="secondary">
            <RefreshCw size={14} /> Retry
          </GoldButton>
        </Card>
      ) : balance ? (
        <Card className="border-[var(--color-gold)]/20 bg-gradient-to-r from-[var(--color-bg-card)] to-[var(--color-bg-surface)]">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
            <div className="space-y-4">
              <p className="text-sm font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Available Balance
              </p>
              <p className="text-5xl font-bold text-[var(--color-gold)]">
                {formatCurrency(balance.balance)}
                <span className="ml-2 text-lg text-[var(--color-text-muted)]">USDT</span>
              </p>
              <div className="flex gap-6 text-sm text-[var(--color-text-muted)]">
                <div>
                  <p className="text-xs text-[var(--color-text-dim)]">Pending</p>
                  <p className="font-semibold text-white">{formatCurrency(balance.pending_comps)}</p>
                </div>
                <div>
                  <p className="text-xs text-[var(--color-text-dim)]">Lifetime Earned</p>
                  <p className="font-semibold text-white">{formatCurrency(balance.lifetime_earnings)}</p>
                </div>
              </div>
            </div>
            <GoldButton
              onClick={() => setWithdrawOpen(true)}
              size="lg"
              disabled={!balance.balance || balance.balance <= 0}
            >
              <ArrowDownCircle size={18} /> Withdraw
            </GoldButton>
          </div>
        </Card>
      ) : null}

      {/* Wallet address */}
      {user?.walletAddress && (
        <Card>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">
                Your USDT Wallet Address (TRC-20)
              </p>
              <p className="mt-1 font-mono text-sm text-[var(--color-text)]">{user.walletAddress}</p>
            </div>
            <button
              onClick={handleCopyAddress}
              className="flex items-center gap-2 rounded-xl border border-[var(--color-border)] px-4 py-2 text-sm text-[var(--color-text-muted)] transition-colors hover:border-[var(--color-gold)] hover:text-[var(--color-gold)]"
            >
              {copied ? (
                <>
                  <Check size={14} className="text-green-500" /> Copied!
                </>
              ) : (
                <>
                  <Copy size={14} /> Copy Address
                </>
              )}
            </button>
          </div>
        </Card>
      )}

      {/* Transactions */}
      <Card>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">Transaction History</h2>
          <button
            onClick={() => loadTransactions(activeTab)}
            className="rounded-lg p-2 text-[var(--color-text-dim)] transition-colors hover:text-white"
            aria-label="Refresh transactions"
          >
            <RefreshCw size={14} />
          </button>
        </div>

        <div className="mb-4">
          <Tabs tabs={FILTER_TABS} activeTab={activeTab} onChange={handleTabChange} />
        </div>

        {txLoading ? (
          <TableSkeleton />
        ) : txError ? (
          <div className="text-center py-8">
            <p className="mb-4 text-[var(--color-danger)]">{txError}</p>
            <GoldButton onClick={() => loadTransactions(activeTab)} variant="secondary">
              <RefreshCw size={14} /> Retry
            </GoldButton>
          </div>
        ) : transactions.length === 0 ? (
          <EmptyState
            icon={Wallet}
            message="No transactions yet. Earn USDT by scanning BlakJaks QR codes!"
          />
        ) : (
          <Table
            columns={tableColumns}
            data={transactions as unknown as Record<string, unknown>[]}
            keyField="id"
          />
        )}
      </Card>

      {/* Withdrawal Modal */}
      <Modal open={withdrawOpen} onClose={handleWithdrawClose} title="Withdraw USDT">
        {withdrawSuccess ? (
          <div className="space-y-4 text-center">
            <Check size={40} className="mx-auto text-green-500" />
            <p className="font-semibold text-white">Withdrawal Submitted</p>
            <p className="text-sm text-[var(--color-text-dim)]">
              Your withdrawal request has been submitted and will be processed within 24 hours.
            </p>
            <GoldButton onClick={handleWithdrawClose} fullWidth>
              Done
            </GoldButton>
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <p className="text-sm text-[var(--color-text-muted)]">
                Available: <span className="font-bold text-[var(--color-gold)]">{formatCurrency(balance?.balance ?? 0)} USDT</span>
              </p>
            </div>
            <Input
              label="Amount (USDT)"
              type="number"
              min="1"
              step="0.01"
              placeholder="0.00"
              value={withdrawAmount}
              onChange={(e) => setWithdrawAmount(e.target.value)}
            />
            <Input
              label="Withdrawal Address (optional — uses your wallet address)"
              placeholder="TRC-20 USDT address"
              value={withdrawAddress}
              onChange={(e) => setWithdrawAddress(e.target.value)}
            />
            {withdrawError && (
              <p className="text-sm text-[var(--color-danger)]">{withdrawError}</p>
            )}
            <div className="flex gap-3 pt-2">
              <GoldButton variant="ghost" fullWidth onClick={handleWithdrawClose}>
                Cancel
              </GoldButton>
              <GoldButton fullWidth loading={withdrawing} onClick={handleWithdraw}>
                Confirm Withdrawal
              </GoldButton>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
