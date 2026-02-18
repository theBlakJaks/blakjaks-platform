import client from './client'
import type { Affiliate, Payout } from '../types'

export async function getAffiliates(page = 1, sort?: string): Promise<{ items: Affiliate[]; total: number }> {
  const params: Record<string, string | number> = { page, limit: 20 }
  if (sort) params.sort = sort
  const { data } = await client.get('/admin/affiliate/affiliates', { params })
  return data
}

export async function getAffiliate(affiliateId: string): Promise<Affiliate> {
  const { data } = await client.get(`/admin/affiliate/affiliates/${affiliateId}`)
  return data
}

export async function approvePayouts(payoutIds: string[]): Promise<{ approved: number }> {
  const { data } = await client.post('/admin/affiliate/payouts/approve', { payout_ids: payoutIds })
  return data
}

export async function executePayouts(payoutIds: string[]): Promise<{ executed: number }> {
  const { data } = await client.post('/admin/affiliate/payouts/execute', { payout_ids: payoutIds })
  return data
}

export async function getPendingPayouts(): Promise<Payout[]> {
  const { data } = await client.get('/admin/affiliate/payouts/pending')
  return data
}
