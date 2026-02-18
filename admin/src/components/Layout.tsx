import { useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from './Sidebar'
import TopBar from './TopBar'
import { NAV_ITEMS } from '../utils/constants'

export default function Layout() {
  const [collapsed, setCollapsed] = useState(false)
  const location = useLocation()

  const currentNav = NAV_ITEMS.find((item) =>
    item.path === '/' ? location.pathname === '/' : location.pathname.startsWith(item.path)
  )
  const pageTitle = currentNav?.label || 'Dashboard'

  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed(!collapsed)} />
      <div className={`transition-all duration-300 ${collapsed ? 'ml-16' : 'ml-60'}`}>
        <TopBar title={pageTitle} />
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
