import { LogOut, Bell } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'

interface TopBarProps {
  title: string
}

export default function TopBar({ title }: TopBarProps) {
  const { user, logout } = useAuth()

  return (
    <header className="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-6">
      <h1 className="text-lg font-semibold text-slate-900">{title}</h1>
      <div className="flex items-center gap-4">
        <button className="relative rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600">
          <Bell size={20} />
          <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-red-500" />
        </button>
        <span className="text-sm text-slate-600">
          {user?.first_name} {user?.last_name}
        </span>
        <button
          onClick={logout}
          className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-slate-600 hover:bg-slate-100"
        >
          <LogOut size={16} />
          Logout
        </button>
      </div>
    </header>
  )
}
