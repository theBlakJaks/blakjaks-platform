'use client'

import { create } from 'zustand'

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
