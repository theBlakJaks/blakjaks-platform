import client from './client'
import type { Comp } from '../types'

export async function getComps(page = 1): Promise<{ items: Comp[]; total: number }> {
  const { data } = await client.get('/admin/comps', { params: { page, limit: 20 } })
  return data
}

export async function awardComp(userId: string, amount: number, reason: string): Promise<Comp> {
  const { data } = await client.post('/admin/comps', { user_id: userId, amount, reason })
  return data
}

export async function retryFailed(compId: string): Promise<Comp> {
  const { data } = await client.post(`/admin/comps/${compId}/retry`)
  return data
}
