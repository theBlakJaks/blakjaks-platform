'use client'

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import type { User } from './types'
import { currentUser } from './mock-data'

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
  const [user, setUser] = useState<User | null>(() => {
    if (typeof window !== 'undefined' && localStorage.getItem('bj_token')) return currentUser
    return null
  })
  const isLoading = false
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

  const login = useCallback(async (email: string, _password: string) => {
    await new Promise((r) => setTimeout(r, 400))
    if (!email) throw new Error('Email is required')
    localStorage.setItem('bj_token', 'mock_jwt_token')
    setUser(currentUser)
    router.replace('/dashboard')
  }, [router])

  const register = useCallback(async (_data: { email: string; password: string; username: string; firstName: string; lastName: string }) => {
    await new Promise((r) => setTimeout(r, 500))
    localStorage.setItem('bj_token', 'mock_jwt_token')
    setUser(currentUser)
    router.replace('/dashboard')
  }, [router])

  const logout = useCallback(() => {
    localStorage.removeItem('bj_token')
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
