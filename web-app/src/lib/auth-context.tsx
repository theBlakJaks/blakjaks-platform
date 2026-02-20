'use client'

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import type { User } from './types'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

interface AuthContextType {
  user: User | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  register: (data: { email: string; password: string; username: string; firstName: string; lastName: string }) => Promise<void>
  logout: () => void
  updateUser: (partial: Partial<User>) => void
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

const publicPaths = ['/', '/about', '/transparency', '/login', '/signup', '/forgot-password']

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  // On mount: if an access token exists in localStorage, restore the session
  // by fetching GET /api/users/me. If the request fails the token is stale
  // and we clear storage so the user is redirected to login.
  /* eslint-disable react-hooks/set-state-in-effect -- reading browser API on mount is the standard SSR-safe pattern */
  useEffect(() => {
    const token = localStorage.getItem('blakjaks_token')
    if (!token) {
      setIsLoading(false)
      return
    }

    fetch(`${BASE_URL}/api/users/me`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then(async (res) => {
        if (!res.ok) {
          localStorage.removeItem('blakjaks_token')
          localStorage.removeItem('blakjaks_refresh_token')
          return
        }
        const data = await res.json()
        setUser(data as User)
      })
      .catch(() => {
        // Network error — don't clear the token; let the user stay logged in
        // on next successful request.
      })
      .finally(() => {
        setIsLoading(false)
      })
  }, [])
  /* eslint-enable react-hooks/set-state-in-effect */

  const router = useRouter()
  const pathname = usePathname()

  useEffect(() => {
    if (isLoading) return

    const isPublic = publicPaths.includes(pathname) || pathname.startsWith('/r/')
    const isAuthPage = pathname === '/login' || pathname === '/signup'

    if (!user && !isPublic) {
      router.replace('/login')
    } else if (user && isAuthPage) {
      router.replace('/dashboard')
    }
  }, [user, isLoading, pathname, router])

  const login = useCallback(async (email: string, password: string) => {
    const res = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })

    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      throw new Error(err?.detail ?? 'Invalid email or password')
    }

    const data = await res.json()
    // Backend returns: { user: {...}, tokens: { access_token, refresh_token } }
    localStorage.setItem('blakjaks_token', data.tokens.access_token)
    localStorage.setItem('blakjaks_refresh_token', data.tokens.refresh_token)
    setUser(data.user as User)
    router.replace('/dashboard')
  }, [router])

  const register = useCallback(async (formData: { email: string; password: string; username: string; firstName: string; lastName: string }) => {
    const res = await fetch(`${BASE_URL}/api/auth/signup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: formData.email,
        password: formData.password,
        username: formData.username,
        first_name: formData.firstName,
        last_name: formData.lastName,
      }),
    })

    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      throw new Error(err?.detail ?? 'Registration failed')
    }

    const data = await res.json()
    // Backend returns: { user: {...}, tokens: { access_token, refresh_token } }
    localStorage.setItem('blakjaks_token', data.tokens.access_token)
    localStorage.setItem('blakjaks_refresh_token', data.tokens.refresh_token)
    setUser(data.user as User)
    router.replace('/dashboard')
  }, [router])

  const logout = useCallback(() => {
    // Fire-and-forget — there is no /api/auth/logout endpoint on the backend
    localStorage.removeItem('blakjaks_token')
    localStorage.removeItem('blakjaks_refresh_token')
    setUser(null)
    router.replace('/login')
  }, [router])

  const updateUser = useCallback((partial: Partial<User>) => {
    setUser((prev) => prev ? { ...prev, ...partial } : null)
  }, [])

  return (
    <AuthContext.Provider value={{ user, isAuthenticated: !!user, isLoading, login, register, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
