'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import Logo from '@/components/Logo'
import GoldButton from '@/components/GoldButton'
import Spinner from '@/components/Spinner'
import { login } from '@/lib/api'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !password) { setError('Please fill in all fields'); return }
    setError('')
    setLoading(true)
    try {
      const tokens = await login(email, password)
      localStorage.setItem('ws_token', tokens.access_token)
      localStorage.setItem('ws_refresh', tokens.refresh_token)
      router.push('/dashboard')
    } catch {
      setError('Invalid email or password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="w-full max-w-md space-y-8 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-8">
      <div className="text-center">
        <Logo size="lg" />
        <p className="mt-3 text-sm text-[var(--color-text-muted)]">Wholesale Partner Portal</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        {error && (
          <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">{error}</div>
        )}

        <div>
          <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">Email</label>
          <input
            type="email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            placeholder="you@company.com"
            className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none placeholder:text-[var(--color-text-dim)] focus:border-[var(--color-gold)]"
          />
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">Password</label>
          <input
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="••••••••"
            className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none placeholder:text-[var(--color-text-dim)] focus:border-[var(--color-gold)]"
          />
        </div>

        <GoldButton type="submit" disabled={loading} className="w-full">
          {loading ? <Spinner className="h-4 w-4" /> : 'Sign In'}
        </GoldButton>
      </form>

      <div className="flex items-center justify-between text-sm">
        <Link href="/apply" className="text-[var(--color-gold)] hover:underline">Apply for Account</Link>
        <button className="text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)]">Forgot Password</button>
      </div>
    </div>
  )
}
