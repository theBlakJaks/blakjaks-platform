import client from './client'
import type { ChatReport } from '../types'

export async function getReports(status?: string): Promise<ChatReport[]> {
  const params: Record<string, string> = {}
  if (status) params.status = status
  const { data } = await client.get('/admin/social/reports', { params })
  return data
}

export async function deleteMessage(messageId: string): Promise<void> {
  await client.delete(`/admin/social/messages/${messageId}`)
}

export async function muteUser(userId: string, channelId: string | null, durationMinutes: number, reason: string): Promise<void> {
  await client.post('/admin/social/mute', {
    user_id: userId,
    channel_id: channelId,
    duration_minutes: durationMinutes,
    reason,
  })
}

export async function banUser(userId: string, reason: string): Promise<void> {
  await client.post('/admin/social/ban', { user_id: userId, reason })
}

export async function pinMessage(messageId: string): Promise<void> {
  await client.put(`/admin/social/messages/${messageId}/pin`)
}

export async function updateReportStatus(reportId: string, status: string): Promise<void> {
  await client.put(`/admin/social/reports/${reportId}`, { status })
}
