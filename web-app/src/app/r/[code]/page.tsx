'use client'

import { useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Spinner from '@/components/ui/Spinner'
import Logo from '@/components/ui/Logo'

export default function ReferralRedirect() {
  const router = useRouter()
  const params = useParams()
  const code = params.code as string

  useEffect(() => {
    if (code) {
      document.cookie = `bj_ref=${encodeURIComponent(code)};path=/;max-age=2592000`
      router.push(`/signup?ref=${encodeURIComponent(code)}`)
    }
  }, [code, router])

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6 bg-[var(--color-bg)]">
      <Logo size="lg" />
      <Spinner className="h-8 w-8" />
      <p className="text-sm text-[var(--color-text-dim)]">Redirecting...</p>
    </div>
  )
}
