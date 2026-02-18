'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { ShoppingCart, ArrowLeft, ArrowRight, CheckCircle, Package, Minus, Plus } from 'lucide-react'
import GoldButton from '@/components/GoldButton'
import Spinner from '@/components/Spinner'
import { getProducts, createOrder } from '@/lib/api'
import { formatCurrency, formatNumber } from '@/lib/utils'
import type { Product } from '@/lib/types'

type Step = 'select' | 'review' | 'confirmation'

const FLAVOR_COLORS: Record<string, string> = {
  Original: 'bg-amber-500/20 text-amber-400',
  Mint: 'bg-emerald-500/20 text-emerald-400',
  Wintergreen: 'bg-teal-500/20 text-teal-400',
  Cinnamon: 'bg-red-500/20 text-red-400',
  Coffee: 'bg-yellow-700/20 text-yellow-600',
  Citrus: 'bg-orange-500/20 text-orange-400',
  Berry: 'bg-purple-500/20 text-purple-400',
}

const QUICK_QTYS = [100, 500, 1000]

export default function PlaceOrderPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [quantities, setQuantities] = useState<Record<string, number>>({})
  const [step, setStep] = useState<Step>('select')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [orderNumber, setOrderNumber] = useState('')
  const router = useRouter()

  useEffect(() => {
    getProducts().then(setProducts).finally(() => setLoading(false))
  }, [])

  const setQty = (id: string, qty: number) => {
    setQuantities(prev => {
      const n = { ...prev }
      if (qty <= 0) delete n[id]
      else n[id] = qty
      return n
    })
  }

  const cartItems = products.filter(p => quantities[p.id] > 0).map(p => ({
    product: p,
    quantity: quantities[p.id],
    lineTotal: quantities[p.id] * p.price_per_tin,
  }))

  const totalTins = cartItems.reduce((s, i) => s + i.quantity, 0)
  const totalCost = cartItems.reduce((s, i) => s + i.lineTotal, 0)
  const chipsEarned = totalTins

  const handleSubmit = async () => {
    setSubmitting(true)
    try {
      const items = cartItems.map(i => ({ product_id: i.product.id, quantity: i.quantity }))
      const order = await createOrder(items)
      setOrderNumber(order.order_number)
      setStep('confirmation')
    } catch {
      // handled by mock
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) return <div className="flex items-center justify-center py-16"><Spinner className="h-10 w-10" /></div>

  return (
    <div className="space-y-6">
      {/* Steps indicator */}
      <div className="flex items-center gap-3">
        {(['Select Products', 'Review Order', 'Confirmation'] as const).map((label, i) => {
          const stepIdx = step === 'select' ? 0 : step === 'review' ? 1 : 2
          return (
            <div key={label} className="flex items-center gap-2">
              <div className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold ${i <= stepIdx ? 'gold-gradient text-black' : 'bg-[var(--color-border)] text-[var(--color-text-dim)]'}`}>
                {i + 1}
              </div>
              <span className={`text-sm font-medium ${i <= stepIdx ? 'text-white' : 'text-[var(--color-text-dim)]'}`}>{label}</span>
              {i < 2 && <div className="mx-2 h-px w-8 bg-[var(--color-border)]" />}
            </div>
          )
        })}
      </div>

      {/* Step 1: Select Products */}
      {step === 'select' && (
        <>
          {/* Sticky Cart Bar */}
          {totalTins > 0 && (
            <div className="sticky top-0 z-10 flex items-center justify-between rounded-2xl border border-[var(--color-gold)]/30 bg-[var(--color-bg-card)] px-6 py-4">
              <div className="flex items-center gap-4">
                <ShoppingCart size={20} className="text-[var(--color-gold)]" />
                <span className="text-sm text-white">{cartItems.length} product(s) &middot; {formatNumber(totalTins)} tins</span>
              </div>
              <div className="flex items-center gap-4">
                <span className="text-lg font-bold text-[var(--color-gold)]">{formatCurrency(totalCost)}</span>
                <GoldButton size="sm" onClick={() => setStep('review')}>
                  Review Order <ArrowRight size={14} />
                </GoldButton>
              </div>
            </div>
          )}

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {products.map(p => {
              const qty = quantities[p.id] || 0
              return (
                <div key={p.id} className={`rounded-2xl border bg-[var(--color-bg-card)] p-5 transition-all hover:-translate-y-0.5 ${qty > 0 ? 'border-[var(--color-gold)]/50' : 'border-[var(--color-border)]'} ${!p.in_stock ? 'opacity-50' : ''}`}>
                  <div className="mb-3 flex items-center justify-between">
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${FLAVOR_COLORS[p.flavor] || 'bg-zinc-500/20 text-zinc-400'}`}>{p.flavor}</span>
                    <span className="text-xs text-[var(--color-text-dim)]">{p.strength}</span>
                  </div>
                  <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-xl bg-[var(--color-gold)]/10">
                    <Package size={24} className="text-[var(--color-gold)]" />
                  </div>
                  <h3 className="text-sm font-medium text-white">{p.name}</h3>
                  <p className="mt-1 font-mono text-lg font-bold text-[var(--color-gold)]">{formatCurrency(p.price_per_tin)}<span className="text-xs font-normal text-[var(--color-text-dim)]">/tin</span></p>
                  <p className="mb-3 text-xs text-[var(--color-text-dim)]">Min: {p.min_order_qty} tins</p>

                  {p.in_stock ? (
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <button onClick={() => setQty(p.id, Math.max(0, qty - 100))} className="rounded-lg border border-[var(--color-border)] p-1.5 text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)]"><Minus size={14} /></button>
                        <input
                          type="number"
                          value={qty || ''}
                          onChange={e => setQty(p.id, parseInt(e.target.value) || 0)}
                          min={0}
                          step={100}
                          placeholder="0"
                          className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] px-3 py-1.5 text-center text-sm text-white outline-none focus:border-[var(--color-gold)]"
                        />
                        <button onClick={() => setQty(p.id, qty + 100)} className="rounded-lg border border-[var(--color-border)] p-1.5 text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)]"><Plus size={14} /></button>
                      </div>
                      <div className="flex gap-1">
                        {QUICK_QTYS.map(q => (
                          <button key={q} onClick={() => setQty(p.id, q)} className={`flex-1 rounded-lg border px-2 py-1 text-xs font-medium transition-colors ${qty === q ? 'border-[var(--color-gold)] bg-[var(--color-gold)]/10 text-[var(--color-gold)]' : 'border-[var(--color-border)] text-[var(--color-text-dim)] hover:border-[var(--color-border-light)]'}`}>
                            {q}
                          </button>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <p className="text-xs font-medium text-red-400">Out of Stock</p>
                  )}
                </div>
              )
            })}
          </div>
        </>
      )}

      {/* Step 2: Review */}
      {step === 'review' && (
        <div className="space-y-6">
          <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]">
            <div className="border-b border-[var(--color-border)] px-6 py-4">
              <h3 className="text-sm font-semibold text-white">Order Summary</h3>
            </div>
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-[var(--color-border)]">
                  <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Product</th>
                  <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Qty (tins)</th>
                  <th className="px-6 py-3 font-medium text-[var(--color-text-muted)]">Unit Price</th>
                  <th className="px-6 py-3 text-right font-medium text-[var(--color-text-muted)]">Line Total</th>
                </tr>
              </thead>
              <tbody>
                {cartItems.map(i => (
                  <tr key={i.product.id} className="border-b border-[var(--color-border)] last:border-0">
                    <td className="px-6 py-3 text-white">{i.product.name}</td>
                    <td className="px-6 py-3 font-mono text-white">{formatNumber(i.quantity)}</td>
                    <td className="px-6 py-3 font-mono text-[var(--color-text-muted)]">{formatCurrency(i.product.price_per_tin)}</td>
                    <td className="px-6 py-3 text-right font-mono font-medium text-white">{formatCurrency(i.lineTotal)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5 text-center">
              <p className="text-xs text-[var(--color-text-muted)]">Total Tins</p>
              <p className="mt-1 text-2xl font-bold text-white">{formatNumber(totalTins)}</p>
            </div>
            <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5 text-center">
              <p className="text-xs text-[var(--color-text-muted)]">Total Cost</p>
              <p className="mt-1 text-2xl font-bold text-[var(--color-gold)]">{formatCurrency(totalCost)}</p>
            </div>
            <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-5 text-center">
              <p className="text-xs text-[var(--color-text-muted)]">Chips to Earn</p>
              <p className="mt-1 text-2xl font-bold text-[var(--color-gold)]">{formatNumber(chipsEarned)}</p>
            </div>
          </div>

          <div className="flex gap-3">
            <GoldButton variant="outline" onClick={() => setStep('select')}>
              <ArrowLeft size={14} /> Back
            </GoldButton>
            <GoldButton onClick={handleSubmit} disabled={submitting}>
              {submitting ? <Spinner className="h-4 w-4" /> : 'Submit Order'}
            </GoldButton>
          </div>
        </div>
      )}

      {/* Step 3: Confirmation */}
      {step === 'confirmation' && (
        <div className="flex flex-col items-center py-12 text-center">
          <CheckCircle size={64} className="text-[var(--color-gold)]" />
          <h2 className="mt-6 text-2xl font-bold text-white">Order Placed!</h2>
          <p className="mt-2 text-[var(--color-text-muted)]">Your order <span className="font-mono text-[var(--color-gold)]">{orderNumber}</span> has been submitted.</p>
          <p className="mt-1 text-sm text-[var(--color-text-dim)]">A confirmation email will be sent to your registered email address.</p>
          <div className="mt-8 flex gap-3">
            <GoldButton variant="outline" onClick={() => router.push('/orders')}>View Orders</GoldButton>
            <GoldButton onClick={() => { setQuantities({}); setStep('select') }}>Place Another Order</GoldButton>
          </div>
        </div>
      )}
    </div>
  )
}
