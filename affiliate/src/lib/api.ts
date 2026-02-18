import {
  MOCK_MEMBER, MOCK_DASHBOARD, MOCK_MONTHLY_EARNINGS, MOCK_ACTIVITY,
  MOCK_REFERRAL_LINK, MOCK_DOWNLINE, getMockDownlineDetail,
  MOCK_CHIP_STATS, MOCK_VAULT_ENTRIES, MOCK_CHIP_HISTORY, MOCK_WEEKLY_POOL,
  MOCK_PAYOUTS, getMockPayoutDetail, MOCK_SETTINGS, MOCK_SUNSET,
} from './mock-data'
import type {
  AffiliateMember, AuthTokens, DashboardStats, MonthlyEarning, ActivityItem,
  ReferralLink, DownlineMember, DownlineDetail, ChipStats, VaultEntry,
  ChipHistoryEntry, WeeklyPoolInfo, Payout, PayoutDetail, AffiliateSettings, SunsetStatus,
} from './types'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/affiliate'

async function apiFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const token = typeof window !== 'undefined' ? localStorage.getItem('aff_token') : null
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options?.headers,
    },
  })
  if (res.status === 401 && typeof window !== 'undefined') {
    localStorage.removeItem('aff_token')
    localStorage.removeItem('aff_refresh')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

// Auth
export async function login(email: string, password: string): Promise<AuthTokens> {
  try { return await apiFetch('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }) }
  catch { return { access_token: 'mock-jwt', refresh_token: 'mock-refresh' } }
}

export async function logout(): Promise<void> {
  try { await apiFetch('/auth/logout', { method: 'POST' }) } catch {}
  if (typeof window !== 'undefined') { localStorage.removeItem('aff_token'); localStorage.removeItem('aff_refresh') }
}

export async function getProfile(): Promise<AffiliateMember> {
  try { return await apiFetch('/profile') } catch { return MOCK_MEMBER }
}

// Dashboard
export async function getDashboardStats(): Promise<DashboardStats> {
  try { return await apiFetch('/dashboard') } catch { return MOCK_DASHBOARD }
}
export async function getMonthlyEarnings(): Promise<MonthlyEarning[]> {
  try { return await apiFetch('/dashboard/earnings') } catch { return MOCK_MONTHLY_EARNINGS }
}
export async function getRecentActivity(): Promise<ActivityItem[]> {
  try { return await apiFetch('/dashboard/activity') } catch { return MOCK_ACTIVITY }
}

// Referral Link
export async function getReferralLink(): Promise<ReferralLink> {
  try { return await apiFetch('/referral-link') } catch { return MOCK_REFERRAL_LINK }
}
export async function updateReferralCode(code: string): Promise<ReferralLink> {
  try { return await apiFetch('/referral-link', { method: 'PUT', body: JSON.stringify({ custom_code: code }) }) }
  catch { return { ...MOCK_REFERRAL_LINK, custom_code: code, url: `https://blakjaks.com/r/${code}` } }
}

// Downline
export async function getDownline(params?: { tier?: string; status?: string; search?: string; sort?: string; page?: number }): Promise<{ items: DownlineMember[]; total: number }> {
  try {
    const qs = new URLSearchParams()
    if (params?.tier) qs.set('tier', params.tier)
    if (params?.status) qs.set('status', params.status)
    if (params?.search) qs.set('search', params.search)
    if (params?.sort) qs.set('sort', params.sort)
    if (params?.page) qs.set('page', String(params.page))
    return await apiFetch(`/downline?${qs}`)
  } catch {
    let filtered = [...MOCK_DOWNLINE]
    if (params?.tier && params.tier !== 'all') filtered = filtered.filter(m => m.tier === params.tier)
    if (params?.status && params.status !== 'all') filtered = filtered.filter(m => m.status === params.status)
    if (params?.search) { const q = params.search.toLowerCase(); filtered = filtered.filter(m => m.name.toLowerCase().includes(q)) }
    if (params?.sort === 'earnings') filtered.sort((a, b) => b.earnings_generated - a.earnings_generated)
    else if (params?.sort === 'scans') filtered.sort((a, b) => b.total_scans - a.total_scans)
    else filtered.sort((a, b) => new Date(b.joined_at).getTime() - new Date(a.joined_at).getTime())
    const page = params?.page || 1
    const start = (page - 1) * 20
    return { items: filtered.slice(start, start + 20), total: filtered.length }
  }
}
export async function getDownlineDetail(id: string): Promise<DownlineDetail> {
  try { return await apiFetch(`/downline/${id}`) } catch { return getMockDownlineDetail(id) }
}

// Chips
export async function getChipStats(): Promise<ChipStats> {
  try { return await apiFetch('/chips') } catch { return MOCK_CHIP_STATS }
}
export async function getVaultEntries(): Promise<VaultEntry[]> {
  try { return await apiFetch('/chips/vault') } catch { return MOCK_VAULT_ENTRIES }
}
export async function getChipHistory(): Promise<ChipHistoryEntry[]> {
  try { return await apiFetch('/chips/history') } catch { return MOCK_CHIP_HISTORY }
}
export async function getWeeklyPool(): Promise<WeeklyPoolInfo> {
  try { return await apiFetch('/chips/pool') } catch { return MOCK_WEEKLY_POOL }
}
export async function withdrawFromVault(amount: number): Promise<{ success: boolean; message: string }> {
  try { return await apiFetch('/chips/vault/withdraw', { method: 'POST', body: JSON.stringify({ amount }) }) }
  catch { return { success: true, message: `Withdrew ${amount} chips from vault` } }
}

// Payouts
export async function getPayouts(): Promise<Payout[]> {
  try { return await apiFetch('/payouts') } catch { return MOCK_PAYOUTS }
}
export async function getPayoutDetail(id: string): Promise<PayoutDetail> {
  try { return await apiFetch(`/payouts/${id}`) } catch { return getMockPayoutDetail(id) }
}

// Settings
export async function getSettings(): Promise<AffiliateSettings> {
  try { return await apiFetch('/settings') } catch { return MOCK_SETTINGS }
}
export async function updateWallet(address: string): Promise<{ message: string }> {
  try { return await apiFetch('/settings/wallet', { method: 'PUT', body: JSON.stringify({ wallet_address: address }) }) }
  catch { return { message: 'Wallet address updated' } }
}
export async function updateNotifications(prefs: AffiliateSettings['notifications']): Promise<{ message: string }> {
  try { return await apiFetch('/settings/notifications', { method: 'PUT', body: JSON.stringify(prefs) }) }
  catch { return { message: 'Notification preferences saved' } }
}
export async function updatePayoutMode(mode: 'auto' | 'manual'): Promise<{ message: string }> {
  try { return await apiFetch('/settings/payout-mode', { method: 'PUT', body: JSON.stringify({ mode }) }) }
  catch { return { message: `Payout mode set to ${mode}` } }
}
export async function getSunsetStatus(): Promise<SunsetStatus> {
  try { return await apiFetch('/settings/sunset') } catch { return MOCK_SUNSET }
}
