'use client'

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { login as apiLogin, logout as apiLogout, getProfile } from './api'
import type { AffiliateMember } from './types'

// AUTH_URL mirrors the logic in api.ts — points at /api/auth, not /api/affiliate.
const AUTH_URL = (process.env.NEXT_PUBLIC_API_URL
  ? process.env.NEXT_PUBLIC_API_URL.replace(/\/api\/affiliate$/, '/api/auth')
  : 'http://localhost:8000/api/auth')

// USERS_URL points at /api/users for the /me session-restore call.
const USERS_URL = (process.env.NEXT_PUBLIC_API_URL
  ? process.env.NEXT_PUBLIC_API_URL.replace(/\/api\/affiliate$/, '/api/users')
  : 'http://localhost:8000/api/users')

interface AuthState {
  member: AffiliateMember | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthState>({ member: null, loading: true, login: async () => {}, logout: async () => {} })

// Fetch the base user record from /api/users/me to fill in fields that
// /api/affiliate/me (AffiliateOut) does not return (email, first_name, etc.).
async function fetchUserMe(token: string): Promise<{
  id: string
  email: string
  first_name: string | null
  last_name: string | null
  username: string | null
} | null> {
  try {
    const res = await fetch(`${USERS_URL}/me`, {
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    })
    if (!res.ok) return null
    return res.json()
  } catch {
    return null
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [member, setMember] = useState<AffiliateMember | null>(null)
  const [loading, setLoading] = useState(true)

  // On mount: if an access token is stored, restore the session by calling
  // /api/users/me (for user fields) and /api/affiliate/me (for affiliate fields).
  useEffect(() => {
    const token = localStorage.getItem('aff_token')
    if (!token) {
      setLoading(false)
      return
    }

    Promise.all([fetchUserMe(token), getProfile()])
      .then(([userMe, affiliateProfile]) => {
        if (!affiliateProfile) {
          localStorage.removeItem('aff_token')
          localStorage.removeItem('aff_refresh')
          return
        }
        // Merge user fields from /api/users/me into the affiliate profile.
        const merged: AffiliateMember = {
          ...affiliateProfile,
          ...(userMe
            ? {
                id: userMe.id,
                email: userMe.email,
                first_name: userMe.first_name ?? '',
                last_name_initial: userMe.last_name ? userMe.last_name.charAt(0) : '',
                username: userMe.username ?? '',
              }
            : {}),
        }
        setMember(merged)
      })
      .catch(() => {
        localStorage.removeItem('aff_token')
        localStorage.removeItem('aff_refresh')
      })
      .finally(() => setLoading(false))
  }, [])

  // login() calls POST /api/auth/login via apiLogin(), which returns AuthTokens
  // extracted from { user, tokens: { access_token, refresh_token } }.
  // We then store the tokens and restore the full member object.
  const login = async (email: string, password: string) => {
    // apiLogin already unwraps .tokens from the AuthResponse shape.
    const tokens = await apiLogin(email, password)
    localStorage.setItem('aff_token', tokens.access_token)
    localStorage.setItem('aff_refresh', tokens.refresh_token)

    const [userMe, affiliateProfile] = await Promise.all([
      fetchUserMe(tokens.access_token),
      getProfile(),
    ])

    const merged: AffiliateMember = {
      ...affiliateProfile,
      ...(userMe
        ? {
            id: userMe.id,
            email: userMe.email,
            first_name: userMe.first_name ?? '',
            last_name_initial: userMe.last_name ? userMe.last_name.charAt(0) : '',
            username: userMe.username ?? '',
          }
        : {}),
    }
    setMember(merged)
  }

  // logout() clears localStorage (no backend logout endpoint exists).
  const logout = async () => {
    await apiLogout()
    setMember(null)
  }

  return <AuthContext.Provider value={{ member, loading, login, logout }}>{children}</AuthContext.Provider>
}

export function useAuth() { return useContext(AuthContext) }
