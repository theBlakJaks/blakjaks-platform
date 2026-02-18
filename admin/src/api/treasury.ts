import client from './client'
import type { PoolBalance } from '../types'

export async function getPoolBalances(): Promise<PoolBalance[]> {
  const { data } = await client.get('/treasury/pools')
  return data
}

export async function sendFromPool(poolName: string, toAddress: string, amount: number): Promise<{ tx_hash: string }> {
  const { data } = await client.post('/treasury/send', {
    pool_name: poolName,
    to_address: toAddress,
    amount,
  })
  return data
}
