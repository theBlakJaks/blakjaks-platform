'use client'

import { useState, type FormEvent } from 'react'
import Link from 'next/link'
import Logo from '@/components/ui/Logo'
import Input from '@/components/ui/Input'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'
import { useAuth } from '@/lib/auth-context'

export default function LoginPage() {
  const { login } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')

    if (!email.trim()) {
      setError('Email is required')
      return
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError('Please enter a valid email address')
      return
    }
    if (!password) {
      setError('Password is required')
      return
    }

    setLoading(true)
    try {
      await login(email, password)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-[80vh] items-center justify-center px-4">
      <Card className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center">
          <Logo size="lg" />
          <p className="mt-3 text-sm text-[var(--color-text-dim)]">
            Sign in to your account
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">
              {error}
            </div>
          )}

          <Input
            label="Email"
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <Input
            label="Password"
            type="password"
            placeholder="Enter your password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          <div className="flex justify-end">
            <Link
              href="/forgot-password"
              className="text-sm text-[var(--color-gold)] hover:underline"
            >
              Forgot Password?
            </Link>
          </div>

          <GoldButton type="submit" fullWidth loading={loading}>
            Sign In
          </GoldButton>
        </form>

        <p className="mt-6 text-center text-sm text-[var(--color-text-dim)]">
          Don&apos;t have an account?{' '}
          <Link href="/signup" className="text-[var(--color-gold)] hover:underline">
            Create Account
          </Link>
        </p>
      </Card>
    </div>
  )
}
