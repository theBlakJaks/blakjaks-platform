'use client'

import { useState, type FormEvent } from 'react'
import Link from 'next/link'
import Logo from '@/components/ui/Logo'
import Input from '@/components/ui/Input'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'
import { useAuth } from '@/lib/auth-context'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

export default function LoginPage() {
  const { login } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [needsVerification, setNeedsVerification] = useState(false)
  const [resending, setResending] = useState(false)
  const [resendMessage, setResendMessage] = useState('')

  async function handleResendVerification() {
    setResending(true)
    setResendMessage('')
    try {
      const res = await fetch(`${BASE_URL}/api/auth/resend-verification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      })
      const data = await res.json()
      setResendMessage(data.message || 'Verification email sent')
    } catch {
      setResendMessage('Failed to resend. Please try again.')
    } finally {
      setResending(false)
    }
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')
    setNeedsVerification(false)
    setResendMessage('')

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
      const msg = err instanceof Error ? err.message : 'Login failed. Please try again.'
      if (msg.toLowerCase().includes('verify your email')) {
        setNeedsVerification(true)
      }
      setError(msg)
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
              <p>{error}</p>
              {needsVerification && (
                <div className="mt-3 border-t border-red-500/20 pt-3">
                  <button
                    type="button"
                    onClick={handleResendVerification}
                    disabled={resending}
                    className="text-[var(--color-gold)] hover:underline disabled:opacity-50"
                  >
                    {resending ? 'Sending...' : 'Resend verification email'}
                  </button>
                  {resendMessage && (
                    <p className="mt-1 text-xs text-emerald-400">{resendMessage}</p>
                  )}
                </div>
              )}
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
