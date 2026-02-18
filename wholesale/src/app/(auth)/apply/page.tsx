'use client'

import { useState } from 'react'
import Link from 'next/link'
import { ArrowLeft, CheckCircle } from 'lucide-react'
import Logo from '@/components/Logo'
import GoldButton from '@/components/GoldButton'
import Spinner from '@/components/Spinner'
import { submitApplication } from '@/lib/api'

export default function ApplyPage() {
  const [form, setForm] = useState({
    company_name: '', contact_person: '', email: '', phone: '', business_address: '', tax_id: '',
  })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(false)
  const [submitted, setSubmitted] = useState(false)

  const update = (field: string, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }))
    if (errors[field]) setErrors(prev => { const n = { ...prev }; delete n[field]; return n })
  }

  const validate = () => {
    const errs: Record<string, string> = {}
    if (!form.company_name.trim()) errs.company_name = 'Required'
    if (!form.contact_person.trim()) errs.contact_person = 'Required'
    if (!form.email.trim() || !form.email.includes('@')) errs.email = 'Valid email required'
    if (!form.phone.trim()) errs.phone = 'Required'
    if (!form.business_address.trim()) errs.business_address = 'Required'
    if (!form.tax_id.trim()) errs.tax_id = 'Required'
    return errs
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setLoading(true)
    try {
      await submitApplication(form)
      setSubmitted(true)
    } catch {
      setErrors({ _form: 'Submission failed. Please try again.' })
    } finally {
      setLoading(false)
    }
  }

  if (submitted) {
    return (
      <div className="w-full max-w-md space-y-6 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-8 text-center">
        <CheckCircle size={48} className="mx-auto text-[var(--color-gold)]" />
        <h2 className="text-xl font-bold text-white">Application Received</h2>
        <p className="text-sm text-[var(--color-text-muted)]">
          Thank you for your interest in becoming a BlakJaks wholesale partner.
          We will review your application within 2 business days and contact you at <span className="text-white">{form.email}</span>.
        </p>
        <Link href="/login" className="inline-block text-sm text-[var(--color-gold)] hover:underline">Back to Login</Link>
      </div>
    )
  }

  const fields: { key: string; label: string; type?: string; placeholder: string }[] = [
    { key: 'company_name', label: 'Company Name', placeholder: 'Premium Smoke Shop LLC' },
    { key: 'contact_person', label: 'Contact Person', placeholder: 'John Smith' },
    { key: 'email', label: 'Email', type: 'email', placeholder: 'john@company.com' },
    { key: 'phone', label: 'Phone', type: 'tel', placeholder: '(555) 123-4567' },
    { key: 'business_address', label: 'Business Address', placeholder: '1234 Commerce Blvd, Las Vegas, NV 89101' },
    { key: 'tax_id', label: 'Tax ID / EIN', placeholder: '82-1234567' },
  ]

  return (
    <div className="w-full max-w-lg space-y-6 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-8">
      <div className="text-center">
        <Logo size="md" />
        <h2 className="mt-4 text-lg font-bold text-white">Wholesale Partner Application</h2>
        <p className="mt-1 text-sm text-[var(--color-text-muted)]">Fill out the form below to apply for a wholesale account.</p>
      </div>

      {errors._form && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">{errors._form}</div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        {fields.map(f => (
          <div key={f.key}>
            <label className="mb-1.5 block text-sm font-medium text-[var(--color-text-muted)]">{f.label}</label>
            <input
              type={f.type || 'text'}
              value={form[f.key as keyof typeof form]}
              onChange={e => update(f.key, e.target.value)}
              placeholder={f.placeholder}
              className={`w-full rounded-xl border bg-[var(--color-bg)] px-4 py-3 text-sm text-white outline-none placeholder:text-[var(--color-text-dim)] focus:border-[var(--color-gold)] ${errors[f.key] ? 'border-red-500' : 'border-[var(--color-border)]'}`}
            />
            {errors[f.key] && <p className="mt-1 text-xs text-red-400">{errors[f.key]}</p>}
          </div>
        ))}

        <GoldButton type="submit" disabled={loading} className="w-full">
          {loading ? <Spinner className="h-4 w-4" /> : 'Submit Application'}
        </GoldButton>
      </form>

      <div className="text-center">
        <Link href="/login" className="inline-flex items-center gap-1.5 text-sm text-[var(--color-text-dim)] hover:text-[var(--color-text-muted)]">
          <ArrowLeft size={14} /> Back to Login
        </Link>
      </div>
    </div>
  )
}
