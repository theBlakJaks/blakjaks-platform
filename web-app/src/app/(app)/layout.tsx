'use client'

import { useState, useRef, useEffect } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LayoutDashboard, MessageCircle, User, Settings, LogOut, Eye, Vote, Radio } from 'lucide-react'
import Logo from '@/components/ui/Logo'
import Avatar from '@/components/ui/Avatar'
import Spinner from '@/components/ui/Spinner'
import { useAuth } from '@/lib/auth-context'
import { useUIStore } from '@/lib/store'
import { useEmoteStore } from '@/lib/emote-store'
import NotificationBell from '@/components/ui/NotificationBell'
import { useNotificationStore } from '@/lib/notification-store'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

const mainNav = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/social', label: 'Social', icon: MessageCircle },
  { href: '/governance', label: 'Governance', icon: Vote },
  { href: '/transparency', label: 'Transparency', icon: Eye },
]

const mobileNav = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/social', label: 'Social', icon: MessageCircle },
  { href: '/governance', label: 'Governance', icon: Vote },
  { href: '/profile', label: 'Profile', icon: User },
]

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { user, isLoading, logout } = useAuth()
  const pathname = usePathname()
  const { isLive, setIsLive } = useUIStore()
  const initializeEmotes = useEmoteStore(s => s.initializeEmotes)
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [])

  // Initialize 7TV emotes on mount + refresh every 30 minutes
  useEffect(() => {
    initializeEmotes()
    const interval = setInterval(initializeEmotes, 30 * 60 * 1000)
    return () => clearInterval(interval)
  }, [initializeEmotes])

  // Load notifications on mount
  const setNotifications = useNotificationStore(s => s.setNotifications)
  const setUnreadCount = useNotificationStore(s => s.setUnreadCount)
  useEffect(() => {
    api.notifications.getAll().then(({ notifications, unreadCount }) => {
      setNotifications(notifications)
      setUnreadCount(unreadCount)
    })
  }, [setNotifications, setUnreadCount])

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner className="h-10 w-10" />
      </div>
    )
  }

  if (!user) return null

  const isLivePage = pathname === '/social/live'
  const isSocialPage = pathname === '/social'
  const isFullWidth = isLivePage || isSocialPage

  return (
    <div className="min-h-screen flex flex-col">
      {/* Top Navbar */}
      <header className="sticky top-0 z-40 border-b border-[var(--color-border)] bg-[var(--color-bg)]/95 backdrop-blur-md">
        <div className={cn('mx-auto flex h-16 items-center justify-between px-4 sm:px-6 lg:px-8', !isFullWidth && 'max-w-7xl')}>
          <Link href="/dashboard">
            <Logo size="md" />
          </Link>

          {/* Desktop Nav */}
          <nav className="hidden md:flex items-center gap-6">
            {mainNav.map((item) => {
              const Icon = item.icon
              const isActive = pathname.startsWith(item.href)
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    'flex items-center gap-2 text-sm font-medium transition-colors',
                    isActive ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-muted)] hover:text-white',
                  )}
                >
                  <Icon size={18} />
                  {item.label}
                </Link>
              )
            })}
          </nav>

          {/* Right side */}
          <div className="hidden md:flex items-center gap-4">
            {/* Live toggle */}
            <button
              onClick={() => setIsLive(!isLive)}
              className={cn(
                'flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-colors',
                isLive
                  ? 'bg-red-600 text-white'
                  : 'bg-[var(--color-bg-surface)] text-[var(--color-text-muted)] hover:text-white border border-[var(--color-border)]',
              )}
            >
              <Radio size={12} className={isLive ? 'animate-pulse' : ''} />
              {isLive ? 'Live' : 'Go Live'}
            </button>
            {/* Notification bell */}
            <NotificationBell />
            {/* Profile dropdown */}
            <div className="relative" ref={dropdownRef}>
              <button onClick={() => setDropdownOpen(!dropdownOpen)} className="flex items-center gap-2">
                <Avatar name={`${user.firstName} ${user.lastName}`} tier={user.tier} size="sm" avatarUrl={user.avatarUrl} />
              </button>
              {dropdownOpen && (
                <div className="absolute right-0 top-full mt-2 w-48 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] py-1 shadow-xl">
                  <Link
                    href="/profile"
                    onClick={() => setDropdownOpen(false)}
                    className="flex items-center gap-2 px-4 py-2.5 text-sm text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] hover:text-white transition-colors"
                  >
                    <User size={16} /> Profile
                  </Link>
                  <Link
                    href="/settings"
                    onClick={() => setDropdownOpen(false)}
                    className="flex items-center gap-2 px-4 py-2.5 text-sm text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] hover:text-white transition-colors"
                  >
                    <Settings size={16} /> Settings
                  </Link>
                  <button
                    onClick={() => { setDropdownOpen(false); logout() }}
                    className="flex w-full items-center gap-2 px-4 py-2.5 text-sm text-red-400 hover:bg-[var(--color-bg-hover)] transition-colors"
                  >
                    <LogOut size={16} /> Sign Out
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className={cn('flex-1 overflow-hidden', isFullWidth ? 'pb-0' : 'pb-20 md:pb-0')}>
        {isFullWidth ? (
          <div className="h-[calc(100vh-4rem)]">
            {children}
          </div>
        ) : (
          <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
            {children}
          </div>
        )}
      </main>

      {/* Mobile Bottom Tab Bar — hidden on live stream page */}
      <nav className={cn(
        'fixed bottom-0 left-0 right-0 z-40 border-t border-[var(--color-border)] bg-[var(--color-bg)]/95 backdrop-blur-md md:hidden',
        isFullWidth && 'hidden',
      )}>
        <div className="flex items-center justify-around py-2">
          {mobileNav.map((item) => {
            const Icon = item.icon
            const isActive = pathname.startsWith(item.href)
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex flex-col items-center gap-1 px-3 py-1',
                  isActive ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-dim)]',
                )}
              >
                <Icon size={20} />
                <span className="text-[10px] font-medium">{item.label}</span>
              </Link>
            )
          })}
        </div>
      </nav>
    </div>
  )
}
