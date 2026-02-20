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

// BASE_URL ends with /api/affiliate — used for all affiliate-specific paths.
// Auth endpoints live under /api/auth and are reached via AUTH_URL.
const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/affiliate'
const AUTH_URL = (process.env.NEXT_PUBLIC_API_URL
  ? process.env.NEXT_PUBLIC_API_URL.replace(/\/api\/affiliate$/, '/api/auth')
  : 'http://localhost:8000/api/auth')

// ─── Token refresh ────────────────────────────────────────────────────────────

export async function refreshToken(): Promise<string | null> {
  const refresh = typeof window !== 'undefined' ? localStorage.getItem('aff_refresh') : null
  if (!refresh) return null
  try {
    const res = await fetch(`${AUTH_URL}/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: refresh }),
    })
    if (!res.ok) return null
    const data: { access_token: string } = await res.json()
    if (typeof window !== 'undefined') {
      localStorage.setItem('aff_token', data.access_token)
    }
    return data.access_token
  } catch {
    return null
  }
}

// ─── Core fetch helper ────────────────────────────────────────────────────────

// Calls BASE_URL + path (e.g. '/me') → http://localhost:8000/api/affiliate/me
// On 401: attempts one token refresh, then retries. Redirects to /login only
// if the retry also fails.
async function apiFetch<T>(path: string, options?: RequestInit, _retry = true): Promise<T> {
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
    if (_retry) {
      const newToken = await refreshToken()
      if (newToken) {
        // Retry the original request once with the new access token
        return apiFetch<T>(path, options, false)
      }
    }
    localStorage.removeItem('aff_token')
    localStorage.removeItem('aff_refresh')
    window.location.href = '/login'
    throw new Error('Unauthorized')
  }

  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

// authFetch is the same helper but targets AUTH_URL instead of BASE_URL.
async function authFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${AUTH_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  })
  if (!res.ok) throw new Error(`API error: ${res.status}`)
  return res.json()
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

// Backend: POST /api/auth/login → { user, tokens: { access_token, refresh_token } }
// We extract and return only the tokens portion so callers receive AuthTokens.
export async function login(email: string, password: string): Promise<AuthTokens> {
  try {
    const data = await authFetch<{ user: unknown; tokens: AuthTokens }>('/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
    return data.tokens
  } catch {
    return { access_token: 'mock-jwt', refresh_token: 'mock-refresh' }
  }
}

// No logout endpoint exists on the backend; we only clear local storage.
export async function logout(): Promise<void> {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('aff_token')
    localStorage.removeItem('aff_refresh')
  }
}

// Backend: GET /api/affiliate/me → AffiliateOut
// The frontend AffiliateMember type differs from AffiliateOut, so we map fields.
export async function getProfile(): Promise<AffiliateMember> {
  try {
    const data = await apiFetch<{
      id: string
      user_id: string
      referral_code: string
      referral_link: string
      total_earnings: number
      pending_earnings: number
      downline_count: number
      total_chips: number
      vaulted_chips: number
      permanent_tier: string | null
      created_at: string
    }>('/me')
    return {
      id: data.user_id,
      email: '',            // not returned by AffiliateOut; populated by auth-context from /api/users/me
      first_name: '',       // same — populated by auth-context
      last_name_initial: '',
      username: '',
      tier: 'Member',
      permanent_tier: data.permanent_tier,
      lifetime_earnings: Number(data.total_earnings),
      pending_payout: Number(data.pending_earnings),
      referral_code: data.referral_code,
      custom_code: data.referral_code,
      wallet_address: null,
      created_at: data.created_at,
    }
  } catch {
    return MOCK_MEMBER
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
// The backend has no dedicated dashboard, earnings, or activity endpoints.
// /api/affiliate/me (AffiliateOut) provides aggregate numbers; detailed
// monthly/activity data fall back to mocks until those endpoints are built.

export async function getDashboardStats(): Promise<DashboardStats> {
  try {
    const data = await apiFetch<{
      total_earnings: number
      pending_earnings: number
      downline_count: number
    }>('/me')
    return {
      lifetime_earnings: Number(data.total_earnings),
      this_month: 0,
      last_month: 0,
      pending_payout: Number(data.pending_earnings),
      next_payout_date: '',
      downline_total: data.downline_count,
      downline_active: 0,
      conversion_rate: 0,
      total_clicks: 0,
      total_signups: data.downline_count,
    }
  } catch {
    return MOCK_DASHBOARD
  }
}

export async function getMonthlyEarnings(): Promise<MonthlyEarning[]> {
  // No backend endpoint — fall back to mock data.
  return MOCK_MONTHLY_EARNINGS
}

export async function getRecentActivity(): Promise<ActivityItem[]> {
  // No backend endpoint — fall back to mock data.
  return MOCK_ACTIVITY
}

// ─── Referral Link ────────────────────────────────────────────────────────────
// The backend embeds referral data inside /api/affiliate/me (AffiliateOut).
// There is no dedicated referral-link endpoint.

export async function getReferralLink(): Promise<ReferralLink> {
  try {
    const data = await apiFetch<{
      referral_code: string
      referral_link: string
    }>('/me')
    return {
      url: data.referral_link,
      code: data.referral_code,
      custom_code: data.referral_code,
      total_clicks: 0,
      total_signups: 0,
      conversion_rate: 0,
    }
  } catch {
    return MOCK_REFERRAL_LINK
  }
}

// Backend: PUT /api/affiliate/me/referral-code  body: { code }  → AffiliateOut
export async function updateReferralCode(code: string): Promise<ReferralLink> {
  try {
    const data = await apiFetch<{
      referral_code: string
      referral_link: string
    }>('/me/referral-code', { method: 'PUT', body: JSON.stringify({ code }) })
    return {
      url: data.referral_link,
      code: data.referral_code,
      custom_code: data.referral_code,
      total_clicks: 0,
      total_signups: 0,
      conversion_rate: 0,
    }
  } catch {
    return { ...MOCK_REFERRAL_LINK, custom_code: code, url: `https://blakjaks.com/r/${code}` }
  }
}

// ─── Downline ─────────────────────────────────────────────────────────────────
// Backend: GET /api/affiliate/me/downline?page=&per_page= → DownlineList
// Note: backend DownlineMember has user_id/username, not id/name.

export async function getDownline(params?: { tier?: string; status?: string; search?: string; sort?: string; page?: number }): Promise<{ items: DownlineMember[]; total: number }> {
  try {
    const qs = new URLSearchParams()
    if (params?.page) qs.set('page', String(params.page))
    const data = await apiFetch<{
      items: { user_id: string; username: string; tier: string | null; total_scans: number; earnings_generated: number; joined_at: string }[]
      total: number
    }>(`/me/downline?${qs}`)
    let items: DownlineMember[] = data.items.map(m => ({
      id: m.user_id,
      name: m.username,
      tier: m.tier ?? 'Member',
      total_scans: m.total_scans,
      earnings_generated: Number(m.earnings_generated),
      status: 'active' as const,
      joined_at: m.joined_at,
    }))
    // Client-side filtering/sorting for fields not supported by backend query params
    if (params?.tier && params.tier !== 'all') items = items.filter(m => m.tier === params.tier)
    if (params?.status && params.status !== 'all') items = items.filter(m => m.status === params.status)
    if (params?.search) { const q = params.search.toLowerCase(); items = items.filter(m => m.name.toLowerCase().includes(q)) }
    if (params?.sort === 'earnings') items.sort((a, b) => b.earnings_generated - a.earnings_generated)
    else if (params?.sort === 'scans') items.sort((a, b) => b.total_scans - a.total_scans)
    else items.sort((a, b) => new Date(b.joined_at).getTime() - new Date(a.joined_at).getTime())
    return { items, total: data.total }
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

// No backend endpoint for individual downline detail — fall back to mock.
export async function getDownlineDetail(id: string): Promise<DownlineDetail> {
  return getMockDownlineDetail(id)
}

// ─── Chips ────────────────────────────────────────────────────────────────────
// Backend: GET /api/affiliate/me/chips → ChipSummary
// Backend: POST /api/affiliate/me/chips/unvault  body: { chip_ids }

export async function getChipStats(): Promise<ChipStats> {
  try {
    const data = await apiFetch<{
      active_chips: number
      vaulted_chips: number
      expired_chips: number
      total_earned: number
    }>('/me/chips')
    return {
      total_earned: data.total_earned,
      in_vault: data.vaulted_chips,
      vault_bonus: 0,
      expiring_soon: data.expired_chips,
    }
  } catch {
    return MOCK_CHIP_STATS
  }
}

// No backend endpoint for vault entries listing — fall back to mock.
export async function getVaultEntries(): Promise<VaultEntry[]> {
  return MOCK_VAULT_ENTRIES
}

// No backend endpoint for chip history — fall back to mock.
export async function getChipHistory(): Promise<ChipHistoryEntry[]> {
  return MOCK_CHIP_HISTORY
}

// No backend endpoint for weekly pool — fall back to mock.
export async function getWeeklyPool(): Promise<WeeklyPoolInfo> {
  return MOCK_WEEKLY_POOL
}

// Backend: POST /api/affiliate/me/chips/unvault  body: { chip_ids: UUID[] }
// The frontend passes an amount (number); since we don't have chip IDs at this
// call site, we fall back to mock. Real callers that have chip_ids should call
// the endpoint directly.
export async function withdrawFromVault(amount: number): Promise<{ success: boolean; message: string }> {
  // amount-based withdrawal is not supported by the backend — mock only.
  return { success: true, message: `Withdrew ${amount} chips from vault` }
}

// ─── Payouts ──────────────────────────────────────────────────────────────────
// Backend: GET /api/affiliate/me/payouts?page=&per_page= → PayoutList

export async function getPayouts(): Promise<Payout[]> {
  try {
    const data = await apiFetch<{
      items: {
        id: string
        amount: number
        payout_type: string
        period_start: string
        period_end: string
        status: string
        tx_hash: string | null
        created_at: string
      }[]
    }>('/me/payouts')
    return data.items.map(p => ({
      id: p.id,
      date: p.created_at,
      amount: Number(p.amount),
      status: p.status as Payout['status'],
      tx_hash: p.tx_hash,
      earnings_count: 0,
    }))
  } catch {
    return MOCK_PAYOUTS
  }
}

// No backend endpoint for individual payout detail — fall back to mock.
export async function getPayoutDetail(id: string): Promise<PayoutDetail> {
  return getMockPayoutDetail(id)
}

// ─── Settings ─────────────────────────────────────────────────────────────────
// No settings endpoints exist on the backend yet — all fall back to mock.

export async function getSettings(): Promise<AffiliateSettings> {
  return MOCK_SETTINGS
}

export async function updateWallet(address: string): Promise<{ message: string }> {
  return { message: 'Wallet address updated' }
}

export async function updateNotifications(prefs: AffiliateSettings['notifications']): Promise<{ message: string }> {
  return { message: 'Notification preferences saved' }
}

export async function updatePayoutMode(mode: 'auto' | 'manual'): Promise<{ message: string }> {
  return { message: `Payout mode set to ${mode}` }
}

// ─── Sunset ───────────────────────────────────────────────────────────────────
// Backend: GET /api/affiliate/sunset → SunsetProgress

export async function getSunsetStatus(): Promise<SunsetStatus> {
  try {
    const data = await apiFetch<{
      current_monthly_volume: number
      rolling_3mo_avg: number
      threshold: number
      percentage: number
      is_triggered: boolean
      triggered_at: string | null
    }>('/sunset')
    return {
      monthly_volume: data.current_monthly_volume,
      rolling_3mo_avg: data.rolling_3mo_avg,
      threshold: data.threshold,
      percentage: data.percentage,
      is_triggered: data.is_triggered,
      triggered_at: data.triggered_at,
    }
  } catch {
    return MOCK_SUNSET
  }
}
