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

  useEffect(() => {
    const token = localStorage.getItem('ws_token')
    if (token) {
      getProfile()
        .then(setPartner)
        .catch(() => {
          localStorage.removeItem('ws_token')
          localStorage.removeItem('ws_refresh')
        })
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  const login = async (email: string, password: string) => {
    const tokens = await apiLogin(email, password)
    localStorage.setItem('ws_token', tokens.access_token)
    localStorage.setItem('ws_refresh', tokens.refresh_token)
    const profile = await getProfile()
    setPartner(profile)
  }

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
