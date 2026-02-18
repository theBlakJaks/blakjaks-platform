import client from './client'
import type { Vote, Proposal, VoteOption } from '../types'

export async function createVote(
  title: string,
  description: string,
  voteType: string,
  options: VoteOption[],
  durationDays = 7
): Promise<Vote> {
  const { data } = await client.post('/admin/governance/votes', {
    title,
    description,
    vote_type: voteType,
    options,
    duration_days: durationDays,
  })
  return data
}

export async function closeVote(voteId: string): Promise<void> {
  await client.put(`/admin/governance/votes/${voteId}/close`)
}

export async function getProposals(status?: string): Promise<Proposal[]> {
  const params: Record<string, string> = {}
  if (status) params.status = status
  const { data } = await client.get('/admin/governance/proposals', { params })
  return data
}

export async function reviewProposal(
  proposalId: string,
  action: 'approve' | 'reject' | 'changes_requested',
  notes?: string
): Promise<{ message: string; vote_id?: string }> {
  const { data } = await client.put(`/admin/governance/proposals/${proposalId}/review`, {
    action,
    admin_notes: notes,
  })
  return data
}
