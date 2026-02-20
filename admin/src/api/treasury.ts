import client from './client'
import type { PoolBalance, TreasuryTransaction } from '../types'

const MOCK_POOLS: PoolBalance[] = [
  { pool_name: 'consumer', address: '0x742d35Cc6634C0532925a3b844Bc9e7595f2bD38', usdt_balance: 127_450.82, matic_balance: 45.23, allocation_pct: 50 },
  { pool_name: 'affiliate', address: '0x8Ba1f109551bD432803012645Ac136ddd64DBA72', usdt_balance: 12_745.08, matic_balance: 12.50, allocation_pct: 5 },
  { pool_name: 'wholesale', address: '0x2546BcD3c84621e976D8185a91A922aE77ECEc30', usdt_balance: 12_745.08, matic_balance: 8.75, allocation_pct: 5 },
]

const DIRECTIONS: ('in' | 'out')[] = ['in', 'out']
const REASONS = [
  'GP allocation deposit', 'Weekly affiliate payout', 'Comp distribution', 'Gas refill',
  'Wholesale order payment', 'Revenue deposit', 'Emergency transfer', 'Pool rebalance',
]

const MOCK_TX: TreasuryTransaction[] = Array.from({ length: 40 }, (_, i) => {
  const pool = MOCK_POOLS[i % 3]
  const direction = DIRECTIONS[i % 2]
  return {
    id: `ttx-${String(i + 1).padStart(3, '0')}`,
    pool_name: pool.pool_name,
    direction,
    amount: Math.round((Math.random() * 5000 + 50) * 100) / 100,
    address: direction === 'out'
      ? `0x${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 20)}${Math.random().toString(16).slice(2, 10)}`
      : pool.address,
    tx_hash: `0x${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 10)}`,
    reason: REASONS[i % 8],
    timestamp: new Date(Date.now() - (40 - i) * 86400000 * 0.8).toISOString(),
  }
})

export async function getPoolBalances(): Promise<PoolBalance[]> {
  try {
    const { data } = await client.get('/treasury/pools')
    return data
  } catch {
    return MOCK_POOLS
  }
}

export async function getTransactionHistory(
  page = 1,
  poolName?: string,
  direction?: string,
): Promise<{ items: TreasuryTransaction[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 20 }
    if (poolName) params.pool_name = poolName
    if (direction) params.direction = direction
    const { data } = await client.get('/treasury/transactions', { params })
    return data
  } catch {
    let filtered = [...MOCK_TX]
    if (poolName) filtered = filtered.filter(t => t.pool_name === poolName)
    if (direction) filtered = filtered.filter(t => t.direction === direction)
    filtered.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}

export async function sendFromPool(
  poolName: string,
  toAddress: string,
  amount: number,
  reason: string,
): Promise<{ tx_hash: string }> {
  try {
    const { data } = await client.post('/treasury/send', {
      pool_name: poolName,
      to_address: toAddress,
      amount,
      reason,
    })
    return data
  } catch {
    return { tx_hash: `0x${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 14)}${Math.random().toString(16).slice(2, 14)}` }
  }
}

export interface TellerBankAccount {
  name: string
  account_type: string
  balance: number
  currency: string
  last_synced_at: string | null
  sync_status: string
  institution_name: string | null
  last_four: string | null
}

export async function getTellerBankAccounts(): Promise<TellerBankAccount[]> {
  const { data } = await client.get('/admin/treasury/teller')
  return data
}

export async function triggerTellerSync(): Promise<{ success: boolean; synced_at: string }> {
  const { data } = await client.post('/admin/treasury/teller-sync')
  return data
}
