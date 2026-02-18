import client from './client'
import type { ChatReport, SocialStats, ModerationLogEntry } from '../types'

const CHANNELS = ['general-chat', 'vip-chat', 'high-roller-chat', 'comp-claims', 'wallet-talk', 'proposals', 'voting', 'introductions']
const NAMES = ['James S.', 'Sarah J.', 'Mike W.', 'Lisa B.', 'Alex J.', 'Emma G.', 'Dave M.', 'Nina D.']
const REASONS = ['Spam', 'Harassment', 'Inappropriate content', 'Scam attempt', 'Off-topic trolling', 'Threatening behavior']
const MESSAGES = [
  'Buy cheap crypto now!!! Visit scam.com',
  'You\'re all losers, this platform sucks',
  'I can hack your wallet, DM me for details',
  'CAPS LOCK SPAM MESSAGE REPEATED 50 TIMES',
  'Hey @everyone check out my totally legit investment opportunity',
  'Sending threatening messages to other users',
  'Posted NSFW content in general chat',
  'Impersonating an admin and asking for passwords',
]

const MOCK_REPORTS: ChatReport[] = Array.from({ length: 25 }, (_, i) => ({
  id: `rpt-${String(i + 1).padStart(3, '0')}`,
  reporter_id: `u-${String((i % 8) + 1).padStart(3, '0')}`,
  reporter_name: NAMES[i % 8],
  reporter_email: `user${(i % 8) + 1}@example.com`,
  reported_user_id: `u-${String((i % 8) + 9).padStart(3, '0')}`,
  reported_user_name: NAMES[(i + 3) % 8],
  reported_user_email: `user${(i % 8) + 9}@example.com`,
  message_id: `msg-${i}`,
  message_content: MESSAGES[i % 8],
  channel_name: CHANNELS[i % 8],
  reason: REASONS[i % 6],
  status: i < 8 ? 'pending' : i < 18 ? 'resolved' : 'dismissed',
  created_at: new Date(Date.now() - (25 - i) * 86400000 * 0.8).toISOString(),
}))

const ACTIONS = ['message_deleted', 'user_muted', 'user_banned', 'message_pinned']
const MOCK_MOD_LOG: ModerationLogEntry[] = Array.from({ length: 30 }, (_, i) => ({
  id: `mod-${String(i + 1).padStart(3, '0')}`,
  admin_name: i % 2 === 0 ? 'Admin Josh' : 'Admin Sarah',
  action: ACTIONS[i % 4],
  target_user: NAMES[(i + 1) % 8],
  channel: CHANNELS[i % 8],
  details: [
    'Deleted spam message',
    'Muted for 24 hours — repeated spam',
    'Permanent ban — threatening behavior',
    'Pinned announcement message',
    'Deleted inappropriate content',
    'Muted for 1 hour — off-topic trolling',
  ][i % 6],
  timestamp: new Date(Date.now() - (30 - i) * 86400000 * 0.6).toISOString(),
}))

export async function getSocialStats(): Promise<SocialStats> {
  try {
    const { data } = await client.get('/admin/social/stats')
    return data
  } catch {
    return {
      pending_reports: MOCK_REPORTS.filter(r => r.status === 'pending').length,
      active_mutes: 4,
      banned_users: 2,
    }
  }
}

export async function getReports(status?: string): Promise<ChatReport[]> {
  try {
    const params: Record<string, string> = {}
    if (status) params.status = status
    const { data } = await client.get('/admin/social/reports', { params })
    return data
  } catch {
    let filtered = [...MOCK_REPORTS]
    if (status) filtered = filtered.filter(r => r.status === status)
    return filtered
  }
}

export async function getModerationLog(
  action?: string,
  page = 1,
): Promise<{ items: ModerationLogEntry[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 20 }
    if (action) params.action = action
    const { data } = await client.get('/admin/social/moderation-log', { params })
    return data
  } catch {
    let filtered = [...MOCK_MOD_LOG]
    if (action) filtered = filtered.filter(e => e.action === action)
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}

export async function deleteMessage(messageId: string): Promise<void> {
  try {
    await client.delete(`/admin/social/messages/${messageId}`)
  } catch { /* mock success */ }
}

export async function muteUser(userId: string, channelId: string | null, durationMinutes: number, reason: string): Promise<void> {
  try {
    await client.post('/admin/social/mute', {
      user_id: userId,
      channel_id: channelId,
      duration_minutes: durationMinutes,
      reason,
    })
  } catch { /* mock success */ }
}

export async function banUser(userId: string, reason: string): Promise<void> {
  try {
    await client.post('/admin/social/ban', { user_id: userId, reason })
  } catch { /* mock success */ }
}

export async function pinMessage(messageId: string): Promise<void> {
  try {
    await client.put(`/admin/social/messages/${messageId}/pin`)
  } catch { /* mock success */ }
}

export async function updateReportStatus(reportId: string, status: string): Promise<void> {
  try {
    await client.put(`/admin/social/reports/${reportId}`, { status })
  } catch { /* mock success */ }
}
