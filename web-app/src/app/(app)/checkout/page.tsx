'use client'

import { useEffect, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { CheckCircle, AlertCircle } from 'lucide-react'
import NicotineWarningBanner from '@/components/NicotineWarningBanner'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import GoldButton from '@/components/ui/GoldButton'
import Input from '@/components/ui/Input'
import { api } from '@/lib/api'
import { formatCurrency } from '@/lib/utils'

// Authorize.net Accept.js type augmentation
declare global {
  interface Window {
    Accept?: {
      dispatchData: (
        payload: { authData: { clientKey: string; apiLoginID: string }; cardData: { cardNumber: string; month: string; year: string; cardCode: string } },
        callback: (response: { opaqueData?: { dataDescriptor: string; dataValue: string }; messages: { resultCode: string; message: Array<{ text: string }> } }) => void,
      ) => void
    }
    AgeChecker?: {
      run: (config?: Record<string, unknown>) => void
    }
  }
}

const STEPS = ['Shipping', 'Age Verification', 'Payment', 'Review & Submit'] as const
type Step = 0 | 1 | 2 | 3

interface ShippingForm {
  firstName: string
  lastName: string
  address: string
  city: string
  state: string
  zip: string
  country: string
}

interface CartItem {
  id: string
  product_name: string
  flavor: string
  price: number
  quantity: number
}

interface Cart {
  id: string
  items: CartItem[]
  subtotal: number
}

const emptyShipping: ShippingForm = {
  firstName: '',
  lastName: '',
  address: '',
  city: '',
  state: '',
  zip: '',
  country: 'US',
}

function StepIndicator({ current }: { current: Step }) {
  return (
    <div className="flex items-center justify-between mb-8">
      {STEPS.map((label, i) => {
        const done = i < current
        const active = i === current
        return (
          <div key={label} className="flex flex-1 items-center">
            <div className="flex flex-col items-center gap-1">
              <div
                className={`flex h-9 w-9 items-center justify-center rounded-full border-2 text-sm font-bold transition-all ${
                  done
                    ? 'border-[var(--color-gold)] bg-[var(--color-gold)] text-black'
                    : active
                    ? 'border-[var(--color-gold)] text-[var(--color-gold)]'
                    : 'border-[var(--color-border)] text-[var(--color-text-dim)]'
                }`}
              >
                {done ? <CheckCircle size={18} /> : i + 1}
              </div>
              <span
                className={`hidden text-xs sm:block ${
                  active ? 'font-semibold text-white' : 'text-[var(--color-text-dim)]'
                }`}
              >
                {label}
              </span>
            </div>
            {i < STEPS.length - 1 && (
              <div
                className={`mx-2 h-0.5 flex-1 transition-all ${
                  done ? 'bg-[var(--color-gold)]' : 'bg-[var(--color-border)]'
                }`}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}

export default function CheckoutPage() {
  const router = useRouter()
  const [step, setStep] = useState<Step>(0)
  const [shipping, setShipping] = useState<ShippingForm>(emptyShipping)
  const [cart, setCart] = useState<Cart | null>(null)
  const [cartLoading, setCartLoading] = useState(true)
  const [cartError, setCartError] = useState<string | null>(null)

  // Payment state
  const [cardNumber, setCardNumber] = useState('')
  const [expMonth, setExpMonth] = useState('')
  const [expYear, setExpYear] = useState('')
  const [cvv, setCvv] = useState('')
  const [tokenizing, setTokenizing] = useState(false)
  const [opaqueData, setOpaqueData] = useState<{ dataDescriptor: string; dataValue: string } | null>(null)
  const [paymentError, setPaymentError] = useState<string | null>(null)

  // Submit state
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [orderComplete, setOrderComplete] = useState<string | null>(null)

  // Age verification state
  const [ageVerified, setAgeVerified] = useState(false)

  // Load cart
  const loadCart = useCallback(async () => {
    setCartLoading(true)
    setCartError(null)
    try {
      const data = await api.shop.getCart()
      setCart(data as Cart)
    } catch (err) {
      setCartError(err instanceof Error ? err.message : 'Failed to load cart')
    } finally {
      setCartLoading(false)
    }
  }, [])

  useEffect(() => {
    loadCart()
  }, [loadCart])

  // Load Authorize.net Accept.js on mount
  useEffect(() => {
    if (document.getElementById('authorize-accept-js')) return
    const script = document.createElement('script')
    script.id = 'authorize-accept-js'
    script.src = 'https://jstest.authorize.net/v1/Accept.js'
    script.charset = 'utf-8'
    document.body.appendChild(script)
  }, [])

  // Load AgeChecker.net SDK when we reach step 1
  useEffect(() => {
    if (step !== 1) return
    if (document.getElementById('agechecker-sdk')) {
      window.AgeChecker?.run({ onVerified: () => setAgeVerified(true) })
      return
    }
    const script = document.createElement('script')
    script.id = 'agechecker-sdk'
    script.src = 'https://cdn.agechecker.net/static/popup/v1/popup.js'
    script.async = true
    script.onload = () => {
      window.AgeChecker?.run({ onVerified: () => setAgeVerified(true) })
    }
    document.body.appendChild(script)
  }, [step])

  function handleShippingSubmit(e: React.FormEvent) {
    e.preventDefault()
    setStep(1)
  }

  function handleAgeNext() {
    setStep(2)
  }

  async function handlePaymentSubmit(e: React.FormEvent) {
    e.preventDefault()
    setPaymentError(null)
    setTokenizing(true)

    if (!window.Accept) {
      setPaymentError('Payment processor not loaded. Please refresh and try again.')
      setTokenizing(false)
      return
    }

    const publicKey = process.env.NEXT_PUBLIC_AUTHORIZE_PUBLIC_KEY ?? ''
    const apiLoginID = process.env.NEXT_PUBLIC_AUTHORIZE_LOGIN_ID ?? ''

    window.Accept.dispatchData(
      {
        authData: { clientKey: publicKey, apiLoginID },
        cardData: {
          cardNumber: cardNumber.replace(/\s/g, ''),
          month: expMonth,
          year: expYear,
          cardCode: cvv,
        },
      },
      (response) => {
        setTokenizing(false)
        if (response.messages.resultCode === 'Error') {
          setPaymentError(response.messages.message.map((m) => m.text).join(' '))
          return
        }
        if (response.opaqueData) {
          setOpaqueData(response.opaqueData)
          setStep(3)
        }
      },
    )
  }

  async function handleFinalSubmit() {
    if (!opaqueData) return
    setSubmitting(true)
    setSubmitError(null)
    try {
      const order = await api.shop.createOrder({
        shipping,
        opaqueData,
      })
      setOrderComplete(order.orderNumber)
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Order submission failed')
    } finally {
      setSubmitting(false)
    }
  }

  const subtotal = cart?.items.reduce((a, i) => a + i.price * i.quantity, 0) ?? 0

  // Order complete screen
  if (orderComplete) {
    return (
      <>
        <NicotineWarningBanner />
        <div style={{ paddingTop: '20vh' }} className="flex min-h-[60vh] items-center justify-center">
          <Card className="max-w-md w-full text-center space-y-4">
            <CheckCircle size={48} className="mx-auto text-green-500" />
            <h1 className="text-2xl font-bold text-white">Order Placed!</h1>
            <p className="text-[var(--color-text-muted)]">
              Order <span className="font-mono text-[var(--color-gold)]">{orderComplete}</span> has been confirmed. We&apos;ll email you when it ships.
            </p>
            <GoldButton onClick={() => router.push('/dashboard')}>
              Back to Dashboard
            </GoldButton>
          </Card>
        </div>
      </>
    )
  }

  return (
    <>
      <NicotineWarningBanner />
      <div style={{ paddingTop: '20vh' }} className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Checkout</h1>
          <p className="mt-1 text-sm text-[var(--color-text-dim)]">Complete your purchase securely</p>
        </div>

        <StepIndicator current={step} />

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Step content */}
          <div className="lg:col-span-2">

            {/* Step 0: Shipping */}
            {step === 0 && (
              <Card>
                <h2 className="mb-6 text-lg font-semibold text-white">Shipping Address</h2>
                <form onSubmit={handleShippingSubmit} className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <Input
                      label="First Name"
                      required
                      value={shipping.firstName}
                      onChange={(e) => setShipping((s) => ({ ...s, firstName: e.target.value }))}
                    />
                    <Input
                      label="Last Name"
                      required
                      value={shipping.lastName}
                      onChange={(e) => setShipping((s) => ({ ...s, lastName: e.target.value }))}
                    />
                  </div>
                  <Input
                    label="Street Address"
                    required
                    value={shipping.address}
                    onChange={(e) => setShipping((s) => ({ ...s, address: e.target.value }))}
                  />
                  <div className="grid grid-cols-2 gap-4">
                    <Input
                      label="City"
                      required
                      value={shipping.city}
                      onChange={(e) => setShipping((s) => ({ ...s, city: e.target.value }))}
                    />
                    <Input
                      label="State"
                      required
                      value={shipping.state}
                      onChange={(e) => setShipping((s) => ({ ...s, state: e.target.value }))}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <Input
                      label="ZIP Code"
                      required
                      value={shipping.zip}
                      onChange={(e) => setShipping((s) => ({ ...s, zip: e.target.value }))}
                    />
                    <Input
                      label="Country"
                      required
                      value={shipping.country}
                      onChange={(e) => setShipping((s) => ({ ...s, country: e.target.value }))}
                    />
                  </div>
                  <div className="pt-2">
                    <GoldButton type="submit" fullWidth size="lg">
                      Continue to Age Verification
                    </GoldButton>
                  </div>
                </form>
              </Card>
            )}

            {/* Step 1: Age Verification */}
            {step === 1 && (
              <Card className="text-center space-y-6">
                <h2 className="text-lg font-semibold text-white">Age Verification</h2>
                <p className="text-[var(--color-text-muted)]">
                  Federal law requires age verification before purchasing nicotine products. Our
                  AgeChecker.net popup will verify you are 21 or older.
                </p>
                {!ageVerified ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-center">
                      <Spinner className="h-8 w-8" />
                    </div>
                    <p className="text-sm text-[var(--color-text-dim)]">
                      Age verification popup loading…
                    </p>
                    {/* Fallback manual confirm for development */}
                    <GoldButton
                      variant="ghost"
                      onClick={() => setAgeVerified(true)}
                      className="text-xs"
                    >
                      Skip (development only)
                    </GoldButton>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="flex items-center justify-center gap-2 text-green-500">
                      <CheckCircle size={24} />
                      <span className="font-semibold">Age Verified</span>
                    </div>
                    <GoldButton fullWidth size="lg" onClick={handleAgeNext}>
                      Continue to Payment
                    </GoldButton>
                  </div>
                )}
                <button
                  onClick={() => setStep(0)}
                  className="text-sm text-[var(--color-text-dim)] hover:text-white transition-colors"
                >
                  Back to Shipping
                </button>
              </Card>
            )}

            {/* Step 2: Payment */}
            {step === 2 && (
              <Card>
                <h2 className="mb-2 text-lg font-semibold text-white">Payment</h2>
                <p className="mb-6 text-xs text-[var(--color-text-dim)]">
                  Secured by Authorize.net. Card data is tokenized client-side and never touches our servers.
                </p>
                {paymentError && (
                  <div className="mb-4 flex items-start gap-2 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-400">
                    <AlertCircle size={16} className="mt-0.5 flex-shrink-0" />
                    {paymentError}
                  </div>
                )}
                <form onSubmit={handlePaymentSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-[var(--color-text-muted)] mb-1.5">
                      Card Number <span className="text-[var(--color-danger)]">*</span>
                    </label>
                    <input
                      type="text"
                      inputMode="numeric"
                      maxLength={19}
                      placeholder="1234 5678 9012 3456"
                      required
                      value={cardNumber}
                      onChange={(e) => {
                        const raw = e.target.value.replace(/\D/g, '')
                        const formatted = raw.replace(/(\d{4})(?=\d)/g, '$1 ').trim()
                        setCardNumber(formatted)
                      }}
                      className="w-full rounded-[10px] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2.5 text-sm text-[var(--color-text)] placeholder-[var(--color-text-dim)] transition-colors focus:border-[var(--color-gold)] focus:outline-none focus:ring-1 focus:ring-[var(--color-gold)]/50"
                    />
                  </div>
                  <div className="grid grid-cols-3 gap-4">
                    <Input
                      label="Exp Month"
                      placeholder="MM"
                      maxLength={2}
                      required
                      value={expMonth}
                      onChange={(e) => setExpMonth(e.target.value.replace(/\D/g, ''))}
                    />
                    <Input
                      label="Exp Year"
                      placeholder="YYYY"
                      maxLength={4}
                      required
                      value={expYear}
                      onChange={(e) => setExpYear(e.target.value.replace(/\D/g, ''))}
                    />
                    <Input
                      label="CVV"
                      placeholder="123"
                      maxLength={4}
                      required
                      value={cvv}
                      onChange={(e) => setCvv(e.target.value.replace(/\D/g, ''))}
                    />
                  </div>
                  <div className="pt-2">
                    <GoldButton type="submit" fullWidth size="lg" loading={tokenizing}>
                      {tokenizing ? 'Processing…' : 'Continue to Review'}
                    </GoldButton>
                  </div>
                </form>
                <button
                  onClick={() => setStep(1)}
                  className="mt-4 text-sm text-[var(--color-text-dim)] hover:text-white transition-colors"
                >
                  Back to Age Verification
                </button>
              </Card>
            )}

            {/* Step 3: Review & Submit */}
            {step === 3 && (
              <Card className="space-y-6">
                <h2 className="text-lg font-semibold text-white">Review Your Order</h2>

                {/* Shipping summary */}
                <div>
                  <h3 className="mb-2 text-sm font-medium text-[var(--color-text-muted)]">Shipping To</h3>
                  <p className="text-sm text-white">
                    {shipping.firstName} {shipping.lastName}
                  </p>
                  <p className="text-sm text-[var(--color-text-dim)]">
                    {shipping.address}, {shipping.city}, {shipping.state} {shipping.zip}, {shipping.country}
                  </p>
                </div>

                {/* Payment summary */}
                <div>
                  <h3 className="mb-2 text-sm font-medium text-[var(--color-text-muted)]">Payment</h3>
                  <p className="text-sm text-white">Card ending in {cardNumber.slice(-4)}</p>
                  <p className="text-xs text-green-500 flex items-center gap-1 mt-0.5">
                    <CheckCircle size={12} /> Tokenized via Authorize.net
                  </p>
                </div>

                {/* Items */}
                {cartLoading ? (
                  <Spinner className="h-6 w-6" />
                ) : cart ? (
                  <div>
                    <h3 className="mb-2 text-sm font-medium text-[var(--color-text-muted)]">Items</h3>
                    <div className="space-y-2">
                      {cart.items.map((item) => (
                        <div key={item.id} className="flex items-center justify-between text-sm">
                          <span className="text-white">
                            {item.product_name} × {item.quantity}
                          </span>
                          <span className="text-[var(--color-text-muted)]">
                            {formatCurrency(item.price * item.quantity)}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                ) : null}

                {submitError && (
                  <div className="flex items-start gap-2 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-400">
                    <AlertCircle size={16} className="mt-0.5 flex-shrink-0" />
                    {submitError}
                  </div>
                )}

                <GoldButton fullWidth size="lg" onClick={handleFinalSubmit} loading={submitting}>
                  {submitting ? 'Placing Order…' : `Place Order — ${formatCurrency(subtotal)}`}
                </GoldButton>

                <button
                  onClick={() => setStep(2)}
                  className="text-sm text-[var(--color-text-dim)] hover:text-white transition-colors"
                >
                  Back to Payment
                </button>
              </Card>
            )}
          </div>

          {/* Order summary sidebar */}
          <div>
            <Card className="space-y-4">
              <h3 className="font-semibold text-white">Order Summary</h3>
              {cartLoading ? (
                <Spinner className="h-6 w-6" />
              ) : cartError ? (
                <p className="text-sm text-[var(--color-danger)]">{cartError}</p>
              ) : cart ? (
                <>
                  <div className="space-y-2">
                    {cart.items.map((item) => (
                      <div key={item.id} className="flex items-center justify-between text-sm">
                        <span className="text-[var(--color-text-muted)]">
                          {item.product_name} × {item.quantity}
                        </span>
                        <span className="text-white">
                          {formatCurrency(item.price * item.quantity)}
                        </span>
                      </div>
                    ))}
                  </div>
                  <div className="border-t border-[var(--color-border)] pt-3">
                    <div className="flex items-center justify-between">
                      <span className="font-semibold text-white">Subtotal</span>
                      <span className="font-bold text-[var(--color-gold)]">
                        {formatCurrency(subtotal)}
                      </span>
                    </div>
                  </div>
                </>
              ) : null}
            </Card>
          </div>
        </div>
      </div>
    </>
  )
}
