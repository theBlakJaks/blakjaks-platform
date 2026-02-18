import { NavLink } from 'react-router-dom'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { NAV_ITEMS } from '../utils/constants'

interface SidebarProps {
  collapsed: boolean
  onToggle: () => void
}

export default function Sidebar({ collapsed, onToggle }: SidebarProps) {
  return (
    <aside
      className={`fixed left-0 top-0 z-30 flex h-screen flex-col bg-slate-900 text-white transition-all duration-300 ${
        collapsed ? 'w-16' : 'w-60'
      }`}
    >
      <div className="flex h-16 items-center justify-between px-4">
        {!collapsed && <span className="text-lg font-bold tracking-wide">BlakJaks</span>}
        <button
          onClick={onToggle}
          className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white"
        >
          {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
        </button>
      </div>

      <nav className="mt-2 flex-1 space-y-1 px-2">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-indigo-600 text-white'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`
            }
          >
            <item.icon size={20} />
            {!collapsed && <span>{item.label}</span>}
          </NavLink>
        ))}
      </nav>

      <div className="border-t border-slate-800 px-4 py-3">
        {!collapsed && (
          <p className="text-xs text-slate-500">Admin Portal v1.0</p>
        )}
      </div>
    </aside>
  )
}
