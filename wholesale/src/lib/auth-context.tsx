'use client'

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { login as apiLogin, logout as apiLogout, getProfile } from './api'
import type { WholesalePartner } from './types'

interface AuthState {
  partner: WholesalePartner | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthState>({
  partner: null,
  loading: true,
  login: async () => {},
  logout: async () => {},
})

export function AuthProvider({ children }: { children: ReactNode }) {
  const [partner, setPartner] = useState<WholesalePartner | null>(null)
  const [loading, setLoading] = useState(true)

  // On mount: if a stored access token exists, restore the session by fetching
  // the wholesale account profile from GET /api/wholesale/account.
  useEffect(() => {
    const token = localStorage.getItem('ws_token')
    if (token) {
      getProfile()
        .then(setPartner)
        .catch(() => {
          // Token is invalid or expired and refresh failed — clear storage.
          localStorage.removeItem('ws_token')
          localStorage.removeItem('ws_refresh')
        })
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  /**
   * Log in with email and password.
   *
   * The backend returns { user, tokens: { access_token, refresh_token } }.
   * We store access_token as ws_token and refresh_token as ws_refresh.
   * The user object from the login response is used to seed the session;
   * we then fetch the wholesale account profile to populate partner state.
   */
  const login = async (email: string, password: string) => {
    const result = await apiLogin(email, password)
    localStorage.setItem('ws_token', result.access_token)
    localStorage.setItem('ws_refresh', result.refresh_token)
    // Fetch the wholesale account profile now that we have a valid token.
    const profile = await getProfile()
    setPartner(profile)
  }

  /**
   * Log out: clear tokens from localStorage and reset partner state.
   * apiLogout() removes ws_token and ws_refresh from localStorage.
   */
  const logout = async () => {
    await apiLogout()
    setPartner(null)
  }

  return (
    <AuthContext.Provider value={{ partner, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
