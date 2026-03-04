import client from './client'
import type { Vote, VoteOption, VoteResult } from '../types'

const MOCK_VOTES: Vote[] = [
  { id: 'v-001', title: 'New Summer Flavor', description: 'Vote on the next summer limited edition flavor', target_tiers: ['VIP', 'High Roller', 'Whale'], options: [{ id: 'mango', label: 'Tropical Mango' }, { id: 'watermelon', label: 'Watermelon Mint' }, { id: 'coconut', label: 'Coconut Ice' }], status: 'active', start_date: new Date(Date.now() - 5 * 86400000).toISOString(), end_date: new Date(Date.now() + 9 * 86400000).toISOString(), total_votes: 127, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 5 * 86400000).toISOString() },
  { id: 'v-002', title: 'Product Line Expansion', description: 'Should we expand into CBD pouches?', target_tiers: ['High Roller', 'Whale'], options: [{ id: 'yes', label: 'Yes, expand' }, { id: 'no', label: 'No, stay focused' }, { id: 'later', label: 'Maybe next year' }], status: 'active', start_date: new Date(Date.now() - 3 * 86400000).toISOString(), end_date: new Date(Date.now() + 11 * 86400000).toISOString(), total_votes: 42, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 3 * 86400000).toISOString() },
  { id: 'v-003', title: 'Board Seat Election', description: 'Community board representative election', target_tiers: ['Whale'], options: [{ id: 'alice', label: 'Alice W.' }, { id: 'bob', label: 'Bob K.' }, { id: 'carol', label: 'Carol M.' }], status: 'active', start_date: new Date(Date.now() - 1 * 86400000).toISOString(), end_date: new Date(Date.now() + 13 * 86400000).toISOString(), total_votes: 8, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 1 * 86400000).toISOString() },
  { id: 'v-004', title: 'Loyalty Points Multiplier', description: 'Vote on the loyalty points multiplier for Q2', target_tiers: ['High Roller', 'Whale'], options: [{ id: '2x', label: '2x Multiplier' }, { id: '3x', label: '3x Multiplier' }], status: 'closed', start_date: new Date(Date.now() - 30 * 86400000).toISOString(), end_date: new Date(Date.now() - 16 * 86400000).toISOString(), total_votes: 89, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 30 * 86400000).toISOString() },
  { id: 'v-005', title: 'Best Menthol Variant', description: 'Which menthol is your favorite?', target_tiers: ['VIP', 'High Roller', 'Whale'], options: [{ id: 'cool', label: 'Cool Menthol' }, { id: 'ice', label: 'Mint Ice' }, { id: 'pepper', label: 'Peppermint' }], status: 'closed', start_date: new Date(Date.now() - 25 * 86400000).toISOString(), end_date: new Date(Date.now() - 11 * 86400000).toISOString(), total_votes: 214, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 25 * 86400000).toISOString() },
  { id: 'v-006', title: 'Subscription Box Design', description: 'Pick the next subscription box design', target_tiers: ['High Roller', 'Whale'], options: [{ id: 'minimal', label: 'Minimalist Black' }, { id: 'colorful', label: 'Vibrant Colors' }, { id: 'retro', label: 'Retro Style' }], status: 'closed', start_date: new Date(Date.now() - 20 * 86400000).toISOString(), end_date: new Date(Date.now() - 6 * 86400000).toISOString(), total_votes: 56, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 20 * 86400000).toISOString() },
  { id: 'v-007', title: 'Charitable Donation Recipient', description: 'Where should our quarterly charitable donation go?', target_tiers: ['Whale'], options: [{ id: 'health', label: 'Public Health Fund' }, { id: 'education', label: 'STEM Education' }, { id: 'environment', label: 'Environmental Cleanup' }], status: 'closed', start_date: new Date(Date.now() - 40 * 86400000).toISOString(), end_date: new Date(Date.now() - 26 * 86400000).toISOString(), total_votes: 12, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 40 * 86400000).toISOString() },
  { id: 'v-008', title: 'Holiday Special Edition', description: 'Vote on the holiday special edition flavor', target_tiers: ['VIP', 'High Roller', 'Whale'], options: [{ id: 'gingerbread', label: 'Gingerbread' }, { id: 'eggnog', label: 'Eggnog Spice' }, { id: 'cranberry', label: 'Cranberry Mint' }], status: 'active', start_date: new Date(Date.now() - 2 * 86400000).toISOString(), end_date: new Date(Date.now() + 12 * 86400000).toISOString(), total_votes: 73, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 2 * 86400000).toISOString() },
  { id: 'v-009', title: 'Referral Bonus Increase', description: 'Should we increase referral bonuses for Q3?', target_tiers: ['High Roller', 'Whale'], options: [{ id: 'yes', label: 'Yes' }, { id: 'no', label: 'No' }], status: 'closed', start_date: new Date(Date.now() - 50 * 86400000).toISOString(), end_date: new Date(Date.now() - 36 * 86400000).toISOString(), total_votes: 67, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 50 * 86400000).toISOString() },
  { id: 'v-010', title: 'App Icon Redesign', description: 'Choose the new app icon', target_tiers: ['High Roller', 'Whale'], options: [{ id: 'modern', label: 'Modern Flat' }, { id: 'classic', label: 'Classic 3D' }], status: 'active', start_date: new Date(Date.now() - 1 * 86400000).toISOString(), end_date: new Date(Date.now() + 6 * 86400000).toISOString(), total_votes: 31, results: [], user_has_voted: false, user_selected_option: null, created_at: new Date(Date.now() - 1 * 86400000).toISOString() },
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
): Promise<Vote[]> {
  try {
    const params: Record<string, string> = {}
    if (status) params.status = status
    const { data } = await client.get('/admin/governance/votes', { params })
    return data
  } catch {
    let filtered = [...MOCK_VOTES]
    if (status) filtered = filtered.filter(v => v.status === status)
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
 * Creates a new vote with target tiers and an explicit end date.
 */
export async function createVote(
  title: string,
  description: string,
  targetTiers: string[],
  options: VoteOption[],
  endDate: string,
): Promise<Vote> {
  try {
    const body: Record<string, unknown> = {
      title,
      description,
      target_tiers: targetTiers,
      options,
      end_date: endDate,
    }
    const { data } = await client.post('/admin/governance/votes', body)
    return data
  } catch {
    return {
      id: `v-new-${Date.now()}`,
      title,
      description,
      target_tiers: targetTiers,
      options,
      status: 'active',
      start_date: new Date().toISOString(),
      end_date: endDate,
      total_votes: 0,
      results: [],
      user_has_voted: false,
      user_selected_option: null,
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
