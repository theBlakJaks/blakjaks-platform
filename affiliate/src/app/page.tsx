'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import NicotineWarningBanner from '@/components/NicotineWarningBanner'

export default function Home() {
  const router = useRouter()

  useEffect(() => {
    router.replace('/login')
  }, [router])

  return (
    <div style={{ paddingTop: '20vh' }}>
      <NicotineWarningBanner />
    </div>
  )
}
