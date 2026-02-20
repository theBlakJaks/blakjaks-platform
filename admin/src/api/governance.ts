import client from './client'
import type { Vote, Proposal, VoteOption, VoteResult } from '../types'

const MOCK_VOTES: Vote[] = [
  { id: 'v-001', title: 'New Summer Flavor', description: 'Vote on the next summer limited edition flavor', vote_type: 'flavor', options_json: [{ id: 'mango', label: 'Tropical Mango' }, { id: 'watermelon', label: 'Watermelon Mint' }, { id: 'coconut', label: 'Coconut Ice' }], min_tier_required: 'VIP', status: 'active', start_date: new Date(Date.now() - 5 * 86400000).toISOString(), end_date: new Date(Date.now() + 9 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 127, created_at: new Date(Date.now() - 5 * 86400000).toISOString() },
  { id: 'v-002', title: 'Product Line Expansion', description: 'Should we expand into CBD pouches?', vote_type: 'product', options_json: [{ id: 'yes', label: 'Yes, expand' }, { id: 'no', label: 'No, stay focused' }, { id: 'later', label: 'Maybe next year' }], min_tier_required: 'High Roller', status: 'active', start_date: new Date(Date.now() - 3 * 86400000).toISOString(), end_date: new Date(Date.now() + 11 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 42, created_at: new Date(Date.now() - 3 * 86400000).toISOString() },
  { id: 'v-003', title: 'Board Seat Election', description: 'Community board representative election', vote_type: 'corporate', options_json: [{ id: 'alice', label: 'Alice W.' }, { id: 'bob', label: 'Bob K.' }, { id: 'carol', label: 'Carol M.' }], min_tier_required: 'Whale', status: 'active', start_date: new Date(Date.now() - 1 * 86400000).toISOString(), end_date: new Date(Date.now() + 13 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 8, created_at: new Date(Date.now() - 1 * 86400000).toISOString() },
  { id: 'v-004', title: 'Loyalty Points Multiplier', description: 'Vote on the loyalty points multiplier for Q2', vote_type: 'loyalty', options_json: [{ id: '2x', label: '2x Multiplier' }, { id: '3x', label: '3x Multiplier' }], min_tier_required: 'High Roller', status: 'closed', start_date: new Date(Date.now() - 30 * 86400000).toISOString(), end_date: new Date(Date.now() - 16 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 89, created_at: new Date(Date.now() - 30 * 86400000).toISOString() },
  { id: 'v-005', title: 'Best Menthol Variant', description: 'Which menthol is your favorite?', vote_type: 'flavor', options_json: [{ id: 'cool', label: 'Cool Menthol' }, { id: 'ice', label: 'Mint Ice' }, { id: 'pepper', label: 'Peppermint' }], min_tier_required: 'VIP', status: 'closed', start_date: new Date(Date.now() - 25 * 86400000).toISOString(), end_date: new Date(Date.now() - 11 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 214, created_at: new Date(Date.now() - 25 * 86400000).toISOString() },
  { id: 'v-006', title: 'Subscription Box Design', description: 'Pick the next subscription box design', vote_type: 'product', options_json: [{ id: 'minimal', label: 'Minimalist Black' }, { id: 'colorful', label: 'Vibrant Colors' }, { id: 'retro', label: 'Retro Style' }], min_tier_required: 'High Roller', status: 'closed', start_date: new Date(Date.now() - 20 * 86400000).toISOString(), end_date: new Date(Date.now() - 6 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 56, created_at: new Date(Date.now() - 20 * 86400000).toISOString() },
  { id: 'v-007', title: 'Charitable Donation Recipient', description: 'Where should our quarterly charitable donation go?', vote_type: 'corporate', options_json: [{ id: 'health', label: 'Public Health Fund' }, { id: 'education', label: 'STEM Education' }, { id: 'environment', label: 'Environmental Cleanup' }], min_tier_required: 'Whale', status: 'closed', start_date: new Date(Date.now() - 40 * 86400000).toISOString(), end_date: new Date(Date.now() - 26 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 12, created_at: new Date(Date.now() - 40 * 86400000).toISOString() },
  { id: 'v-008', title: 'Holiday Special Edition', description: 'Vote on the holiday special edition flavor', vote_type: 'flavor', options_json: [{ id: 'gingerbread', label: 'Gingerbread' }, { id: 'eggnog', label: 'Eggnog Spice' }, { id: 'cranberry', label: 'Cranberry Mint' }], min_tier_required: 'VIP', status: 'active', start_date: new Date(Date.now() - 2 * 86400000).toISOString(), end_date: new Date(Date.now() + 12 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 73, created_at: new Date(Date.now() - 2 * 86400000).toISOString() },
  { id: 'v-009', title: 'Referral Bonus Increase', description: 'Should we increase referral bonuses for Q3?', vote_type: 'loyalty', options_json: [{ id: 'yes', label: 'Yes' }, { id: 'no', label: 'No' }], min_tier_required: 'High Roller', status: 'closed', start_date: new Date(Date.now() - 50 * 86400000).toISOString(), end_date: new Date(Date.now() - 36 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 67, created_at: new Date(Date.now() - 50 * 86400000).toISOString() },
  { id: 'v-010', title: 'App Icon Redesign', description: 'Choose the new app icon', vote_type: 'product', options_json: [{ id: 'modern', label: 'Modern Flat' }, { id: 'classic', label: 'Classic 3D' }], min_tier_required: 'High Roller', status: 'active', start_date: new Date(Date.now() - 1 * 86400000).toISOString(), end_date: new Date(Date.now() + 6 * 86400000).toISOString(), created_by: 'Admin', total_ballots: 31, created_at: new Date(Date.now() - 1 * 86400000).toISOString() },
]

const MOCK_RESULTS: Record<string, VoteResult[]> = {
  'v-001': [{ option_id: 'mango', label: 'Tropical Mango', count: 52, percentage: 40.9 }, { option_id: 'watermelon', label: 'Watermelon Mint', count: 48, percentage: 37.8 }, { option_id: 'coconut', label: 'Coconut Ice', count: 27, percentage: 21.3 }],
  'v-002': [{ option_id: 'yes', label: 'Yes, expand', count: 22, percentage: 52.4 }, { option_id: 'no', label: 'No, stay focused', count: 12, percentage: 28.6 }, { option_id: 'later', label: 'Maybe next year', count: 8, percentage: 19.0 }],
  'v-003': [{ option_id: 'alice', label: 'Alice W.', count: 4, percentage: 50.0 }, { option_id: 'bob', label: 'Bob K.', count: 3, percentage: 37.5 }, { option_id: 'carol', label: 'Carol M.', count: 1, percentage: 12.5 }],
  'v-004': [{ option_id: '2x', label: '2x Multiplier', count: 34, percentage: 38.2 }, { option_id: '3x', label: '3x Multiplier', count: 55, percentage: 61.8 }],
  'v-005': [{ option_id: 'cool', label: 'Cool Menthol', count: 89, percentage: 41.6 }, { option_id: 'ice', label: 'Mint Ice', count: 78, percentage: 36.4 }, { option_id: 'pepper', label: 'Peppermint', count: 47, percentage: 22.0 }],
  'v-006': [{ option_id: 'minimal', label: 'Minimalist Black', count: 28, percentage: 50.0 }, { option_id: 'colorful', label: 'Vibrant Colors', count: 18, percentage: 32.1 }, { option_id: 'retro', label: 'Retro Style', count: 10, percentage: 17.9 }],
  'v-007': [{ option_id: 'health', label: 'Public Health Fund', count: 3, percentage: 25.0 }, { option_id: 'education', label: 'STEM Education', count: 5, percentage: 41.7 }, { option_id: 'environment', label: 'Environmental Cleanup', count: 4, percentage: 33.3 }],
  'v-008': [{ option_id: 'gingerbread', label: 'Gingerbread', count: 31, percentage: 42.5 }, { option_id: 'eggnog', label: 'Eggnog Spice', count: 18, percentage: 24.7 }, { option_id: 'cranberry', label: 'Cranberry Mint', count: 24, percentage: 32.9 }],
  'v-009': [{ option_id: 'yes', label: 'Yes', count: 45, percentage: 67.2 }, { option_id: 'no', label: 'No', count: 22, percentage: 32.8 }],
  'v-010': [{ option_id: 'modern', label: 'Modern Flat', count: 19, percentage: 61.3 }, { option_id: 'classic', label: 'Classic 3D', count: 12, percentage: 38.7 }],
}

const NAMES = ['WhaleKing', 'CryptoWhale42', 'BigFishBob', 'MegaHolder', 'WhaleWatcher', 'TopTierTom', 'ProWhale', 'WhaleMaster']

const MOCK_PROPOSALS: Proposal[] = [
  { id: 'prop-001', user_id: 'u-001', user_name: NAMES[0], user_email: 'whale1@example.com', title: 'International Shipping', description: 'Proposal to offer international shipping to Canada and UK markets. This would significantly expand our customer base and increase revenue.', proposed_vote_type: 'product', proposed_options: [{ id: 'yes', label: 'Yes' }, { id: 'no', label: 'No' }], status: 'pending', admin_notes: null, created_at: new Date(Date.now() - 2 * 86400000).toISOString() },
  { id: 'prop-002', user_id: 'u-002', user_name: NAMES[1], user_email: 'whale2@example.com', title: 'Carbon Neutral Initiative', description: 'Propose that BlakJaks commits to becoming carbon neutral by 2027. This includes offsetting shipping emissions and using sustainable packaging.', proposed_vote_type: 'corporate', proposed_options: [{ id: 'approve', label: 'Approve' }, { id: 'reject', label: 'Reject' }], status: 'pending', admin_notes: null, created_at: new Date(Date.now() - 4 * 86400000).toISOString() },
  { id: 'prop-003', user_id: 'u-003', user_name: NAMES[2], user_email: 'whale3@example.com', title: 'Spicy Flavor Collection', description: 'A new line of spicy nicotine pouches: Habanero Heat, Jalapeno Lime, and Ghost Pepper Rush.', proposed_vote_type: 'flavor', proposed_options: [{ id: 'habanero', label: 'Habanero Heat' }, { id: 'jalapeno', label: 'Jalapeno Lime' }, { id: 'ghost', label: 'Ghost Pepper Rush' }], status: 'approved', admin_notes: 'Great idea! Created vote.', created_at: new Date(Date.now() - 10 * 86400000).toISOString() },
  { id: 'prop-004', user_id: 'u-004', user_name: NAMES[3], user_email: 'whale4@example.com', title: 'Lower Tier Requirements', description: 'Reduce scan requirements for all tiers by 50% to make it easier for new users to advance.', proposed_vote_type: 'loyalty', proposed_options: null, status: 'rejected', admin_notes: 'This would devalue existing tier holders\' achievements. Not aligned with our growth model.', created_at: new Date(Date.now() - 15 * 86400000).toISOString() },
  { id: 'prop-005', user_id: 'u-005', user_name: NAMES[4], user_email: 'whale5@example.com', title: 'Monthly Community AMA', description: 'Hold monthly Ask-Me-Anything sessions with the founding team in the whale-room channel.', proposed_vote_type: 'corporate', proposed_options: [{ id: 'yes', label: 'Yes' }, { id: 'no', label: 'No' }], status: 'approved', admin_notes: 'Approved — scheduling first AMA for next month.', created_at: new Date(Date.now() - 20 * 86400000).toISOString() },
  { id: 'prop-006', user_id: 'u-006', user_name: NAMES[5], user_email: 'whale6@example.com', title: 'NFT Collection Partnership', description: 'Partner with a major NFT collection to create limited edition BlakJaks-themed NFTs for Whale tier members.', proposed_vote_type: 'corporate', proposed_options: null, status: 'changes_requested', admin_notes: 'Interesting concept but need more details on the specific NFT collection and cost implications.', created_at: new Date(Date.now() - 8 * 86400000).toISOString() },
  { id: 'prop-007', user_id: 'u-007', user_name: NAMES[6], user_email: 'whale7@example.com', title: 'Double Comp Weekend', description: 'Introduce a monthly "Double Comp Weekend" where all comp rewards are doubled for 48 hours.', proposed_vote_type: 'loyalty', proposed_options: [{ id: 'yes', label: 'Yes' }, { id: 'no', label: 'No' }], status: 'pending', admin_notes: null, created_at: new Date(Date.now() - 1 * 86400000).toISOString() },
  { id: 'prop-008', user_id: 'u-008', user_name: NAMES[7], user_email: 'whale8@example.com', title: 'Exclusive Whale Merch', description: 'Create an exclusive merchandise line only available to Whale tier members: branded jackets, hats, and accessories.', proposed_vote_type: 'product', proposed_options: [{ id: 'yes', label: 'Yes, launch merch' }, { id: 'no', label: 'No, focus on core products' }], status: 'rejected', admin_notes: 'Not in our current roadmap. Will reconsider in Q4.', created_at: new Date(Date.now() - 25 * 86400000).toISOString() },
]

/** GET /admin/governance/votes — returns all votes regardless of status (admin view). */
export async function getAllVotes(): Promise<Vote[]> {
  try {
    const { data } = await client.get('/admin/governance/votes')
    return data
  } catch {
    return [...MOCK_VOTES]
  }
}

/** GET /admin/governance/votes — filtered list used by the votes tab. */
export async function getVotes(
  status?: string,
  voteType?: string,
): Promise<Vote[]> {
  try {
    const params: Record<string, string> = {}
    if (status) params.status = status
    if (voteType) params.vote_type = voteType
    const { data } = await client.get('/admin/governance/votes', { params })
    return data
  } catch {
    let filtered = [...MOCK_VOTES]
    if (status) filtered = filtered.filter(v => v.status === status)
    if (voteType) filtered = filtered.filter(v => v.vote_type === voteType)
    return filtered
  }
}

/** GET /admin/governance/votes/{voteId}/results */
export async function getVoteResults(voteId: string): Promise<VoteResult[]> {
  try {
    const { data } = await client.get(`/admin/governance/votes/${voteId}/results`)
    return data
  } catch {
    return MOCK_RESULTS[voteId] || []
  }
}

/**
 * POST /admin/governance/votes
 * Creates a new vote. Pass either durationDays or endDate (ISO string); endDate takes precedence.
 */
export async function createVote(
  title: string,
  description: string,
  voteType: string,
  options: VoteOption[],
  durationDays = 7,
  endDate?: string,
): Promise<Vote> {
  // Compute duration from explicit end date if provided
  const computedDuration = endDate
    ? Math.max(1, Math.round((new Date(endDate).getTime() - Date.now()) / 86400000))
    : durationDays

  try {
    const body: Record<string, unknown> = {
      title,
      description,
      vote_type: voteType,
      options,
      duration_days: computedDuration,
    }
    const { data } = await client.post('/admin/governance/votes', body)
    return data
  } catch {
    const resolvedEndDate = endDate
      ? new Date(endDate).toISOString()
      : new Date(Date.now() + durationDays * 86400000).toISOString()
    return {
      id: `v-new-${Date.now()}`,
      title,
      description,
      vote_type: voteType,
      options_json: options,
      min_tier_required: voteType === 'corporate' ? 'Whale' : voteType === 'flavor' ? 'VIP' : 'High Roller',
      status: 'active',
      start_date: new Date().toISOString(),
      end_date: resolvedEndDate,
      created_by: 'Admin',
      total_ballots: 0,
      created_at: new Date().toISOString(),
    }
  }
}

/** PUT /admin/governance/votes/{voteId}/close */
export async function closeVote(voteId: string): Promise<void> {
  try {
    await client.put(`/admin/governance/votes/${voteId}/close`)
  } catch { /* mock success */ }
}

/** GET /admin/governance/proposals */
export async function getProposals(status?: string): Promise<Proposal[]> {
  try {
    const params: Record<string, string> = {}
    if (status) params.status = status
    const { data } = await client.get('/admin/governance/proposals', { params })
    return data
  } catch {
    let filtered = [...MOCK_PROPOSALS]
    if (status) filtered = filtered.filter(p => p.status === status)
    return filtered
  }
}

/** PUT /admin/governance/proposals/{proposalId}/review */
export async function reviewProposal(
  proposalId: string,
  action: 'approve' | 'reject' | 'changes_requested',
  notes?: string
): Promise<{ message: string; vote_id?: string }> {
  try {
    const { data } = await client.put(`/admin/governance/proposals/${proposalId}/review`, {
      action,
      admin_notes: notes,
    })
    return data
  } catch {
    if (action === 'approve') return { message: 'Proposal approved, vote created', vote_id: `v-new-${Date.now()}` }
    return { message: `Proposal ${action === 'reject' ? 'rejected' : 'returned for changes'}` }
  }
}
