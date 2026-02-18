import { createContext, useCallback, useEffect, useState, type ReactNode } from 'react'
import { login as apiLogin, getMe, logout as apiLogout } from '../api/auth'
import type { User } from '../types'

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<string | null>
  logout: () => void
}

export const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  login: async () => null,
  logout: () => {},
})

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  const fetchUser = useCallback(async () => {
    try {
      const me = await getMe()
      if (!me.is_admin) {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        setUser(null)
        return
      }
      setUser(me)
    } catch {
      setUser(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    const token = localStorage.getItem('access_token')
    if (token) {
      fetchUser()
    } else {
      setLoading(false)
    }
  }, [fetchUser])

  const login = useCallback(async (email: string, password: string): Promise<string | null> => {
    try {
      const res = await apiLogin(email, password)
      localStorage.setItem('access_token', res.access_token)
      if (res.refresh_token) {
        localStorage.setItem('refresh_token', res.refresh_token)
      }
      const me = await getMe()
      if (!me.is_admin) {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        return 'Access denied. Admin privileges required.'
      }
      setUser(me)
      return null
    } catch {
      return 'Invalid email or password.'
    }
  }, [])

  const logout = useCallback(() => {
    apiLogout()
    setUser(null)
  }, [])

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}
