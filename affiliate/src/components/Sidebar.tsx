'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LayoutDashboard, Link2, Users, Coins, Banknote, Settings, LogOut, ChevronLeft, ChevronRight } from 'lucide-react'
import Logo from './Logo'
import { useAuth } from '@/lib/auth-context'

const NAV_ITEMS = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { label: 'Referral Link', path: '/referral', icon: Link2 },
  { label: 'Downline', path: '/downline', icon: Users },
  { label: 'Gold Chips', path: '/chips', icon: Coins },
  { label: 'Payouts', path: '/payouts', icon: Banknote },
  { label: 'Settings', path: '/settings', icon: Settings },
]

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false)
  const pathname = usePathname()
  const { logout } = useAuth()

  const handleLogout = async () => { await logout(); window.location.href = '/login' }

  return (
    <aside className={`flex h-screen flex-col border-r border-[var(--color-border)] bg-[var(--color-bg-card)] transition-all duration-300 ${collapsed ? 'w-[72px]' : 'w-64'}`}>
      <div className="flex h-16 items-center justify-between border-b border-[var(--color-border)] px-4">
        {!collapsed && <Logo size="sm" />}
        <button onClick={() => setCollapsed(!collapsed)} className="rounded-lg p-1.5 text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] hover:text-white">
          {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
        </button>
      </div>
      <nav className="flex-1 space-y-1 p-3">
        {NAV_ITEMS.map(item => {
          const isActive = pathname === item.path || (item.path !== '/dashboard' && pathname.startsWith(item.path))
          return (
            <Link key={item.path} href={item.path} className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${isActive ? 'bg-[var(--color-gold)]/10 text-[var(--color-gold)]' : 'text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] hover:text-white'}`}>
              <item.icon size={20} />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          )
        })}
      </nav>
      <div className="border-t border-[var(--color-border)] p-3">
        <button onClick={handleLogout} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)] hover:text-red-400">
          <LogOut size={20} />{!collapsed && <span>Sign Out</span>}
        </button>
      </div>
    </aside>
  )
}
