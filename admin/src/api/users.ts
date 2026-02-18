import client from './client'
import type { User } from '../types'

export async function getUsers(page = 1, search?: string): Promise<{ items: User[]; total: number }> {
  const params: Record<string, string | number> = { page, limit: 20 }
  if (search) params.search = search
  const { data } = await client.get('/admin/users', { params })
  return data
}

export async function getUser(userId: string): Promise<User> {
  const { data } = await client.get(`/admin/users/${userId}`)
  return data
}

export async function updateUser(userId: string, updates: Partial<User>): Promise<User> {
  const { data } = await client.put(`/admin/users/${userId}`, updates)
  return data
}

export async function suspendUser(userId: string, suspend: boolean): Promise<User> {
  const { data } = await client.put(`/admin/users/${userId}/suspend`, { is_suspended: suspend })
  return data
}
