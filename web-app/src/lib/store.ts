'use client'

import { create } from 'zustand'

interface UIStore {
  sidebarCollapsed: boolean
  mobileMenuOpen: boolean
  activeChannel: string | null
  toggleSidebar: () => void
  setMobileMenuOpen: (open: boolean) => void
  setActiveChannel: (channelId: string | null) => void
}

export const useUIStore = create<UIStore>((set) => ({
  sidebarCollapsed: false,
  mobileMenuOpen: false,
  activeChannel: null,
  toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
  setMobileMenuOpen: (open) => set({ mobileMenuOpen: open }),
  setActiveChannel: (channelId) => set({ activeChannel: channelId }),
}))
