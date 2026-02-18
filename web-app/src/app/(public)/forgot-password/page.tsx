'use client'

import { useState, type FormEvent } from 'react'
import Link from 'next/link'
import Logo from '@/components/ui/Logo'
import Input from '@/components/ui/Input'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'
import { api } from '@/lib/api'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')

    if (!email.trim()) { setError('Email is required'); return }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { setError('Please enter a valid email address'); return }

    setLoading(true)
    try {
      await api.auth.forgotPassword(email)
      setSuccess(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.')
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
            Reset your password
          </p>
        </div>

        {success ? (
          <div className="text-center">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-emerald-500/20">
              <span className="text-3xl text-emerald-400">&#10003;</span>
            </div>
            <h2 className="text-lg font-bold text-white">Check Your Email</h2>
            <p className="mt-3 text-sm text-[var(--color-text-dim)]">
              If an account exists with <strong className="text-white">{email}</strong>,
              you&apos;ll receive an email with reset instructions.
            </p>
            <Link href="/login">
              <GoldButton variant="secondary" className="mt-6">
                Back to Sign In
              </GoldButton>
            </Link>
          </div>
        ) : (
          <>
            <form onSubmit={handleSubmit} className="space-y-5">
              {error && (
                <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">
                  {error}
                </div>
              )}

              <p className="text-sm text-[var(--color-text-muted)]">
                Enter your email address and we&apos;ll send you a link to reset your password.
              </p>

              <Input
                label="Email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />

              <GoldButton type="submit" fullWidth loading={loading}>
                Send Reset Link
              </GoldButton>
            </form>

            <p className="mt-6 text-center text-sm text-[var(--color-text-dim)]">
              Remember your password?{' '}
              <Link href="/login" className="text-[var(--color-gold)] hover:underline">
                Back to Sign In
              </Link>
            </p>
          </>
        )}
      </Card>
    </div>
  )
}
