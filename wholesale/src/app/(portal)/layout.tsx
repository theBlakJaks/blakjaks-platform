'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { AuthProvider, useAuth } from '@/lib/auth-context'
import Sidebar from '@/components/Sidebar'
import TopBar from '@/components/TopBar'
import Spinner from '@/components/Spinner'

function PortalShell({ children }: { children: React.ReactNode }) {
  const { partner, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !partner) {
      router.push('/login')
    }
  }, [loading, partner, router])

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-[var(--color-bg)]">
        <Spinner className="h-10 w-10" />
      </div>
    )
  }

  if (!partner) return null

  return (
    <div className="flex h-screen overflow-hidden bg-[var(--color-bg)]">
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <TopBar />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}

export default function PortalLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <PortalShell>{children}</PortalShell>
    </AuthProvider>
  )
}
