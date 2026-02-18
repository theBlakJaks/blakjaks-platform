import client from './client'
import type { User } from '../types'

interface LoginResponse {
  access_token: string
  refresh_token: string
  token_type: string
}

export async function login(email: string, password: string): Promise<LoginResponse> {
  const { data } = await client.post<LoginResponse>('/auth/login', { email, password })
  return data
}

export async function getMe(): Promise<User> {
  const { data } = await client.get<User>('/users/me')
  return data
}

export async function logout(): Promise<void> {
  localStorage.removeItem('access_token')
  localStorage.removeItem('refresh_token')
}
