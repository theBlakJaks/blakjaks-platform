'use client'

import { useState, useRef, useCallback, type FormEvent, Suspense } from 'react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { Check, X, Loader2 } from 'lucide-react'
import Logo from '@/components/ui/Logo'
import Input from '@/components/ui/Input'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import { api } from '@/lib/api'

const US_STATES = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
  'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
  'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
]

const USERNAME_REGEX = /^[a-zA-Z_][a-zA-Z0-9_]{3,24}$/

function validateUsername(username: string): { valid: boolean; error?: string } {
  if (username.length < 4) return { valid: false, error: 'Must be at least 4 characters' }
  if (username.length > 25) return { valid: false, error: 'Must be 25 characters or less' }
  if (/^[0-9]/.test(username)) return { valid: false, error: 'Cannot start with a number' }
  if (!/^[a-zA-Z0-9_]+$/.test(username)) return { valid: false, error: 'Only letters, numbers, and underscores allowed' }
  if (!USERNAME_REGEX.test(username)) return { valid: false, error: 'Must start with a letter or underscore' }
  return { valid: true }
}

export default function SignupPage() {
  return (
    <Suspense fallback={<div className="flex min-h-[80vh] items-center justify-center"><Spinner className="h-10 w-10" /></div>}>
      <SignupForm />
    </Suspense>
  )
}

function SignupForm() {
  const searchParams = useSearchParams()
  const referralCode = searchParams.get('ref')

  const [form, setForm] = useState({
    firstName: '',
    lastName: '',
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
    dob: '',
    phone: '',
    street: '',
    city: '',
    state: '',
    zip: '',
  })
  const [agreeTerms, setAgreeTerms] = useState(false)
  const [agreePrivacy, setAgreePrivacy] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  // Username availability state
  const [usernameStatus, setUsernameStatus] = useState<'idle' | 'checking' | 'available' | 'taken' | 'invalid'>('idle')
  const [usernameMessage, setUsernameMessage] = useState('')
  const [usernameSuggestions, setUsernameSuggestions] = useState<string[]>([])
  const usernameTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  function updateField(field: string, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  function calculateAge(dob: string): number {
    const birth = new Date(dob)
    const today = new Date()
    let age = today.getFullYear() - birth.getFullYear()
    const m = today.getMonth() - birth.getMonth()
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
    return age
  }

  const checkUsername = useCallback(async (username: string) => {
    const validation = validateUsername(username)
    if (!validation.valid) {
      setUsernameStatus('invalid')
      setUsernameMessage(validation.error || 'Invalid username')
      setUsernameSuggestions([])
      return
    }

    setUsernameStatus('checking')
    setUsernameMessage('')
    setUsernameSuggestions([])
    try {
      const result = await api.users.checkUsername(username)
      if (result.available) {
        setUsernameStatus('available')
        setUsernameMessage('Username available')
      } else {
        setUsernameStatus('taken')
        setUsernameMessage(result.message)
        setUsernameSuggestions(result.suggestions || [])
      }
    } catch {
      setUsernameStatus('idle')
    }
  }, [])

  function handleUsernameChange(value: string) {
    // Auto-lowercase, strip invalid chars
    const clean = value.toLowerCase().replace(/[^a-z0-9_]/g, '')
    updateField('username', clean)

    if (usernameTimerRef.current) clearTimeout(usernameTimerRef.current)

    if (clean.length < 4) {
      setUsernameStatus(clean.length > 0 ? 'invalid' : 'idle')
      setUsernameMessage(clean.length > 0 ? 'Must be at least 4 characters' : '')
      setUsernameSuggestions([])
      return
    }

    usernameTimerRef.current = setTimeout(() => checkUsername(clean), 500)
  }

  function selectSuggestion(suggestion: string) {
    updateField('username', suggestion)
    checkUsername(suggestion)
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')

    if (!form.firstName.trim()) { setError('First name is required'); return }
    if (!form.lastName.trim()) { setError('Last name is required'); return }
    if (!form.username.trim()) { setError('Username is required'); return }
    if (usernameStatus !== 'available') { setError('Please choose an available username'); return }
    if (!form.email.trim()) { setError('Email is required'); return }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) { setError('Please enter a valid email address'); return }
    if (!form.password) { setError('Password is required'); return }
    if (form.password.length < 8) { setError('Password must be at least 8 characters'); return }
    if (form.password !== form.confirmPassword) { setError('Passwords do not match'); return }
    if (!form.dob) { setError('Date of birth is required'); return }
    if (calculateAge(form.dob) < 21) { setError('You must be at least 21 years old to create an account'); return }
    if (!form.phone.trim()) { setError('Phone number is required'); return }
    if (!form.street.trim()) { setError('Street address is required'); return }
    if (!form.city.trim()) { setError('City is required'); return }
    if (!form.state) { setError('State is required'); return }
    if (!form.zip.trim()) { setError('ZIP code is required'); return }
    if (!agreeTerms) { setError('You must agree to the Terms of Service'); return }
    if (!agreePrivacy) { setError('You must agree to the Privacy Policy'); return }

    setLoading(true)
    try {
      await api.auth.register({
        email: form.email,
        password: form.password,
        username: form.username,
        firstName: form.firstName,
        lastName: form.lastName,
      })
      setSuccess(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="flex min-h-[80vh] items-center justify-center px-4">
        <Card className="w-full max-w-md text-center">
          <div className="mb-6 flex justify-center">
            <Logo size="lg" />
          </div>
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-emerald-500/20">
            <span className="text-3xl text-emerald-400">&#10003;</span>
          </div>
          <h2 className="text-xl font-bold text-white">Check Your Email</h2>
          <p className="mt-3 text-sm text-[var(--color-text-dim)]">
            We&apos;ve sent a verification link to <strong className="text-white">{form.email}</strong>.
            Please check your inbox and click the link to verify your account.
          </p>
          <Link href="/login">
            <GoldButton variant="secondary" className="mt-6">
              Back to Sign In
            </GoldButton>
          </Link>
        </Card>
      </div>
    )
  }

  return (
    <div className="flex min-h-[80vh] items-center justify-center px-4 py-10">
      <Card className="w-full max-w-2xl">
        <div className="mb-8 flex flex-col items-center">
          <Logo size="lg" />
          <p className="mt-3 text-sm text-[var(--color-text-dim)]">
            Create your BlakJaks account
          </p>
        </div>

        {referralCode && (
          <div className="mb-6 rounded-xl border border-[var(--color-gold)]/30 bg-[var(--color-gold)]/10 px-4 py-3 text-center text-sm text-[var(--color-gold)]">
            Referred by: <strong>{referralCode}</strong>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <Input
              label="First Name"
              placeholder="John"
              value={form.firstName}
              onChange={(e) => updateField('firstName', e.target.value)}
              required
            />
            <Input
              label="Last Name"
              placeholder="Doe"
              value={form.lastName}
              onChange={(e) => updateField('lastName', e.target.value)}
              required
            />
          </div>

          {/* Username field */}
          <div className="space-y-1.5">
            <label className="block text-sm font-medium text-[var(--color-text-muted)]">
              Username<span className="ml-1 text-[var(--color-danger)]">*</span>
            </label>
            <div className="relative">
              <input
                value={form.username}
                onChange={(e) => handleUsernameChange(e.target.value)}
                maxLength={25}
                placeholder="Choose a username"
                required
                className="w-full rounded-[10px] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2.5 pr-10 text-sm text-[var(--color-text)] placeholder-[var(--color-text-dim)] transition-colors focus:border-[var(--color-gold)] focus:outline-none focus:ring-1 focus:ring-[var(--color-gold)]/50"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2">
                {usernameStatus === 'checking' && <Loader2 size={16} className="animate-spin text-[var(--color-text-dim)]" />}
                {usernameStatus === 'available' && <Check size={16} className="text-emerald-400" />}
                {(usernameStatus === 'taken' || usernameStatus === 'invalid') && <X size={16} className="text-red-400" />}
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className={`text-xs ${
                usernameStatus === 'available' ? 'text-emerald-400' :
                usernameStatus === 'taken' || usernameStatus === 'invalid' ? 'text-red-400' :
                'text-[var(--color-text-dim)]'
              }`}>
                {usernameMessage || (form.username.length === 0 ? 'Letters, numbers, and underscores only' : '')}
              </span>
              <span className="text-[10px] text-[var(--color-text-dim)]">{form.username.length}/25</span>
            </div>
            {usernameSuggestions.length > 0 && (
              <div className="flex flex-wrap gap-1.5">
                <span className="text-xs text-[var(--color-text-dim)]">Try:</span>
                {usernameSuggestions.map((s) => (
                  <button
                    key={s}
                    type="button"
                    onClick={() => selectSuggestion(s)}
                    className="rounded-full border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-2.5 py-0.5 text-xs text-[var(--color-gold)] hover:bg-[var(--color-gold)]/10 transition-colors"
                  >
                    {s}
                  </button>
                ))}
              </div>
            )}
          </div>

          <Input
            label="Email"
            type="email"
            placeholder="you@example.com"
            value={form.email}
            onChange={(e) => updateField('email', e.target.value)}
            required
          />

          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <Input
              label="Password"
              type="password"
              placeholder="Min 8 characters"
              value={form.password}
              onChange={(e) => updateField('password', e.target.value)}
              required
            />
            <Input
              label="Confirm Password"
              type="password"
              placeholder="Confirm your password"
              value={form.confirmPassword}
              onChange={(e) => updateField('confirmPassword', e.target.value)}
              required
            />
          </div>

          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
            <Input
              label="Date of Birth"
              type="date"
              value={form.dob}
              onChange={(e) => updateField('dob', e.target.value)}
              required
            />
            <Input
              label="Phone"
              type="tel"
              placeholder="+1 (555) 123-4567"
              value={form.phone}
              onChange={(e) => updateField('phone', e.target.value)}
              required
            />
          </div>

          <div className="border-t border-[var(--color-border)] pt-5">
            <p className="mb-4 text-sm font-medium text-[var(--color-text-muted)]">Address</p>
            <div className="space-y-5">
              <Input
                label="Street"
                placeholder="123 Main St"
                value={form.street}
                onChange={(e) => updateField('street', e.target.value)}
                required
              />
              <div className="grid grid-cols-2 gap-5 sm:grid-cols-3">
                <Input
                  label="City"
                  placeholder="Austin"
                  value={form.city}
                  onChange={(e) => updateField('city', e.target.value)}
                  required
                />
                <div className="space-y-1.5">
                  <label className="block text-sm font-medium text-[var(--color-text-muted)]">
                    State<span className="ml-1 text-[var(--color-danger)]">*</span>
                  </label>
                  <select
                    value={form.state}
                    onChange={(e) => updateField('state', e.target.value)}
                    required
                    className="w-full rounded-[10px] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2.5 text-sm text-[var(--color-text)] transition-colors focus:border-[var(--color-gold)] focus:outline-none focus:ring-1 focus:ring-[var(--color-gold)]/50"
                  >
                    <option value="">Select</option>
                    {US_STATES.map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
                <Input
                  label="ZIP"
                  placeholder="78701"
                  value={form.zip}
                  onChange={(e) => updateField('zip', e.target.value)}
                  required
                />
              </div>
            </div>
          </div>

          <div className="space-y-3 border-t border-[var(--color-border)] pt-5">
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={agreeTerms}
                onChange={(e) => setAgreeTerms(e.target.checked)}
                className="mt-0.5 h-4 w-4 rounded border-[var(--color-border)] bg-[var(--color-bg-surface)] accent-[var(--color-gold)]"
              />
              <span className="text-sm text-[var(--color-text-muted)]">
                I agree to the{' '}
                <span className="text-[var(--color-gold)]">Terms of Service</span>
              </span>
            </label>
            <label className="flex items-start gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={agreePrivacy}
                onChange={(e) => setAgreePrivacy(e.target.checked)}
                className="mt-0.5 h-4 w-4 rounded border-[var(--color-border)] bg-[var(--color-bg-surface)] accent-[var(--color-gold)]"
              />
              <span className="text-sm text-[var(--color-text-muted)]">
                I agree to the{' '}
                <span className="text-[var(--color-gold)]">Privacy Policy</span>
              </span>
            </label>
          </div>

          <GoldButton type="submit" fullWidth loading={loading}>
            Create Account
          </GoldButton>
        </form>

        <p className="mt-6 text-center text-sm text-[var(--color-text-dim)]">
          Already have an account?{' '}
          <Link href="/login" className="text-[var(--color-gold)] hover:underline">
            Sign In
          </Link>
        </p>
      </Card>
    </div>
  )
}
