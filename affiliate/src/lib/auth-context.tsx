'use client'

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { login as apiLogin, logout as apiLogout, getProfile } from './api'
import type { AffiliateMember } from './types'

interface AuthState {
  member: AffiliateMember | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthState>({ member: null, loading: true, login: async () => {}, logout: async () => {} })

export function AuthProvider({ children }: { children: ReactNode }) {
  const [member, setMember] = useState<AffiliateMember | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const token = localStorage.getItem('aff_token')
    if (token) {
      getProfile().then(setMember).catch(() => { localStorage.removeItem('aff_token'); localStorage.removeItem('aff_refresh') }).finally(() => setLoading(false))
    } else { setLoading(false) }
  }, [])

  const login = async (email: string, password: string) => {
    const tokens = await apiLogin(email, password)
    localStorage.setItem('aff_token', tokens.access_token)
    localStorage.setItem('aff_refresh', tokens.refresh_token)
    setMember(await getProfile())
  }

  const logout = async () => { await apiLogout(); setMember(null) }

  return <AuthContext.Provider value={{ member, loading, login, logout }}>{children}</AuthContext.Provider>
}

export function useAuth() { return useContext(AuthContext) }
