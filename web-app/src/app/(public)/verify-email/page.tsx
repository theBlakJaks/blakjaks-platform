'use client'

import { useState, useEffect, Suspense } from 'react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { Check, X, Loader2, Mail } from 'lucide-react'
import Logo from '@/components/ui/Logo'
import Card from '@/components/ui/Card'
import GoldButton from '@/components/ui/GoldButton'
import Spinner from '@/components/ui/Spinner'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={<div className="flex min-h-[80vh] items-center justify-center"><Spinner className="h-10 w-10" /></div>}>
      <VerifyEmailContent />
    </Suspense>
  )
}

function VerifyEmailContent() {
  const searchParams = useSearchParams()
  const token = searchParams.get('token')

  const [status, setStatus] = useState<'verifying' | 'success' | 'error' | 'no-token'>('verifying')
  const [message, setMessage] = useState('')
  const [resendEmail, setResendEmail] = useState('')
  const [resending, setResending] = useState(false)
  const [resendMessage, setResendMessage] = useState('')

  useEffect(() => {
    if (!token) {
      setStatus('no-token')
      return
    }

    async function verify() {
      try {
        const res = await fetch(`${BASE_URL}/api/auth/verify-email`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token }),
        })
        const data = await res.json()
        if (res.ok) {
          setStatus('success')
          setMessage(data.message)
        } else {
          setStatus('error')
          setMessage(data.detail || 'Verification failed')
        }
      } catch {
        setStatus('error')
        setMessage('Unable to verify. Please try again.')
      }
    }

    verify()
  }, [token])

  async function handleResend() {
    if (!resendEmail.trim()) return
    setResending(true)
    setResendMessage('')
    try {
      const res = await fetch(`${BASE_URL}/api/auth/resend-verification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: resendEmail }),
      })
      const data = await res.json()
      setResendMessage(data.message || 'Verification email sent')
    } catch {
      setResendMessage('Failed to resend. Please try again.')
    } finally {
      setResending(false)
    }
  }

  return (
    <div className="flex min-h-[80vh] items-center justify-center px-4">
      <Card className="w-full max-w-md text-center">
        <div className="mb-6 flex justify-center">
          <Logo size="lg" />
        </div>

        {status === 'verifying' && (
          <>
            <Loader2 className="mx-auto mb-4 h-12 w-12 animate-spin text-[var(--color-gold)]" />
            <h2 className="text-xl font-bold text-white">Verifying your email...</h2>
          </>
        )}

        {status === 'success' && (
          <>
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-emerald-500/20">
              <Check className="h-8 w-8 text-emerald-400" />
            </div>
            <h2 className="text-xl font-bold text-white">Email Verified!</h2>
            <p className="mt-3 text-sm text-[var(--color-text-dim)]">{message}</p>
            <Link href="/login">
              <GoldButton className="mt-6">Sign In</GoldButton>
            </Link>
          </>
        )}

        {status === 'error' && (
          <>
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-red-500/20">
              <X className="h-8 w-8 text-red-400" />
            </div>
            <h2 className="text-xl font-bold text-white">Verification Failed</h2>
            <p className="mt-3 text-sm text-[var(--color-text-dim)]">{message}</p>

            <div className="mt-6 space-y-3">
              <p className="text-sm text-[var(--color-text-dim)]">Enter your email to resend the verification link:</p>
              <input
                type="email"
                value={resendEmail}
                onChange={(e) => setResendEmail(e.target.value)}
                placeholder="you@example.com"
                className="w-full rounded-[10px] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2.5 text-sm text-[var(--color-text)] placeholder-[var(--color-text-dim)] focus:border-[var(--color-gold)] focus:outline-none"
              />
              <GoldButton onClick={handleResend} loading={resending} fullWidth variant="secondary">
                Resend Verification Email
              </GoldButton>
              {resendMessage && (
                <p className="text-xs text-emerald-400">{resendMessage}</p>
              )}
            </div>
          </>
        )}

        {status === 'no-token' && (
          <>
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-[var(--color-gold)]/20">
              <Mail className="h-8 w-8 text-[var(--color-gold)]" />
            </div>
            <h2 className="text-xl font-bold text-white">Check Your Email</h2>
            <p className="mt-3 text-sm text-[var(--color-text-dim)]">
              Click the verification link we sent to your email address.
            </p>
            <Link href="/login">
              <GoldButton variant="secondary" className="mt-6">Back to Sign In</GoldButton>
            </Link>
          </>
        )}
      </Card>
    </div>
  )
}
