'use client'

import { create } from 'zustand'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

interface UIStore {
  sidebarCollapsed: boolean
  mobileMenuOpen: boolean
  activeChannel: string | null
  preferredLanguage: string
  isLive: boolean
  toggleSidebar: () => void
  setMobileMenuOpen: (open: boolean) => void
  setActiveChannel: (channelId: string | null) => void
  setPreferredLanguage: (lang: string) => void
  setIsLive: (live: boolean) => void
}

function getStoredLanguage(): string {
  if (typeof window === 'undefined') return 'en'
  return localStorage.getItem('blakjaks_preferred_language') || 'en'
}

export const useUIStore = create<UIStore>((set) => ({
  sidebarCollapsed: false,
  mobileMenuOpen: false,
  activeChannel: null,
  preferredLanguage: getStoredLanguage(),
  isLive: false,
  toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
  setMobileMenuOpen: (open) => set({ mobileMenuOpen: open }),
  setActiveChannel: (channelId) => set({ activeChannel: channelId }),
  setPreferredLanguage: (lang) => {
    if (typeof window !== 'undefined') localStorage.setItem('blakjaks_preferred_language', lang)
    set({ preferredLanguage: lang })
  },
  setIsLive: (live) => set({ isLive: live }),
}))

/**
 * Refresh the access token using the stored refresh token.
 * POSTs to POST /api/auth/refresh with the current refresh token.
 * On success: updates blakjaks_token in localStorage, returns the new access token.
 * On failure: clears both tokens, returns null.
 */
export async function refreshToken(): Promise<string | null> {
  if (typeof window === 'undefined') return null

  const storedRefreshToken = localStorage.getItem('blakjaks_refresh_token')
  if (!storedRefreshToken) return null

  try {
    const res = await fetch(`${BASE_URL}/api/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: storedRefreshToken }),
    })

    if (!res.ok) {
      // Refresh token is invalid or expired — clear everything
      localStorage.removeItem('blakjaks_token')
      localStorage.removeItem('blakjaks_refresh_token')
      return null
    }

    const data = await res.json()
    const newAccessToken: string = data.access_token
    localStorage.setItem('blakjaks_token', newAccessToken)
    return newAccessToken
  } catch {
    return null
  }
}
