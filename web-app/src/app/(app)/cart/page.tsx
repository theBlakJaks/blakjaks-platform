'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { ShoppingBag, RefreshCw, Trash2 } from 'lucide-react'
import NicotineWarningBanner from '@/components/NicotineWarningBanner'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'
import GoldButton from '@/components/ui/GoldButton'
import QuantitySelector from '@/components/ui/QuantitySelector'
import { api } from '@/lib/api'
import { formatCurrency } from '@/lib/utils'

interface CartLineItem {
  id: string
  product_id: string
  product_name: string
  flavor: string
  price: number
  quantity: number
  image_url?: string
}

interface Cart {
  id: string
  items: CartLineItem[]
  subtotal: number
}

export default function CartPage() {
  const [cart, setCart] = useState<Cart | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [updatingItem, setUpdatingItem] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await api.shop.getCart()
      setCart(data as Cart)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load cart')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  async function handleQuantityChange(itemId: string, quantity: number) {
    if (!cart) return
    setUpdatingItem(itemId)
    // Optimistic update
    setCart((prev) =>
      prev
        ? {
            ...prev,
            items: prev.items.map((i) => (i.id === itemId ? { ...i, quantity } : i)),
            subtotal: prev.items
              .map((i) => (i.id === itemId ? quantity * i.price : i.quantity * i.price))
              .reduce((a, b) => a + b, 0),
          }
        : prev,
    )
    try {
      await api.shop.updateCartItem(itemId, quantity)
    } catch {
      load() // revert on error
    } finally {
      setUpdatingItem(null)
    }
  }

  async function handleRemove(itemId: string) {
    if (!cart) return
    setUpdatingItem(itemId)
    // Optimistic update
    setCart((prev) => {
      if (!prev) return prev
      const items = prev.items.filter((i) => i.id !== itemId)
      const subtotal = items.reduce((a, i) => a + i.quantity * i.price, 0)
      return { ...prev, items, subtotal }
    })
    try {
      await api.shop.removeCartItem(itemId)
    } catch {
      load()
    } finally {
      setUpdatingItem(null)
    }
  }

  const subtotal = cart?.items.reduce((acc, item) => acc + item.price * item.quantity, 0) ?? 0

  return (
    <>
      <NicotineWarningBanner />
      <div style={{ paddingTop: '20vh' }} className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-white">Your Cart</h1>
          <p className="mt-1 text-sm text-[var(--color-text-dim)]">
            Review your items before checkout
          </p>
        </div>

        {/* Loading */}
        {loading && (
          <div className="flex min-h-[40vh] items-center justify-center">
            <Spinner className="h-10 w-10" />
          </div>
        )}

        {/* Error */}
        {!loading && error && (
          <Card className="text-center">
            <p className="mb-4 text-[var(--color-danger)]">{error}</p>
            <GoldButton onClick={load} variant="secondary">
              <RefreshCw size={14} /> Retry
            </GoldButton>
          </Card>
        )}

        {/* Empty */}
        {!loading && !error && (!cart || cart.items.length === 0) && (
          <EmptyState
            icon={ShoppingBag}
            message="Your cart is empty."
            actionLabel="Browse Shop"
            onAction={() => window.location.assign('/shop')}
          />
        )}

        {/* Cart contents */}
        {!loading && !error && cart && cart.items.length > 0 && (
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            {/* Line items */}
            <div className="lg:col-span-2 space-y-4">
              {cart.items.map((item) => (
                <Card key={item.id} className="flex flex-col gap-4 sm:flex-row sm:items-center">
                  {/* Product image placeholder */}
                  <div className="flex h-20 w-20 flex-shrink-0 items-center justify-center rounded-xl bg-[var(--color-bg-surface)]">
                    {item.image_url ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={item.image_url}
                        alt={item.product_name}
                        className="h-full w-full rounded-xl object-cover"
                      />
                    ) : (
                      <ShoppingBag size={24} className="text-[var(--color-text-dim)]" />
                    )}
                  </div>

                  {/* Details */}
                  <div className="flex flex-1 flex-col gap-1">
                    <p className="font-semibold text-white">{item.product_name}</p>
                    {item.flavor && (
                      <p className="text-xs capitalize text-[var(--color-text-dim)]">
                        {item.flavor}
                      </p>
                    )}
                    <p className="text-sm text-[var(--color-text-muted)]">
                      {formatCurrency(item.price)} each
                    </p>
                  </div>

                  {/* Quantity + remove */}
                  <div className="flex flex-shrink-0 items-center gap-4">
                    <QuantitySelector
                      value={item.quantity}
                      onChange={(qty) => handleQuantityChange(item.id, qty)}
                      min={1}
                      max={99}
                    />
                    <span className="w-20 text-right font-semibold text-white">
                      {formatCurrency(item.price * item.quantity)}
                    </span>
                    <button
                      onClick={() => handleRemove(item.id)}
                      disabled={updatingItem === item.id}
                      className="rounded-lg p-2 text-[var(--color-danger)] transition-colors hover:bg-red-500/10 disabled:opacity-40"
                      aria-label="Remove item"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </Card>
              ))}
            </div>

            {/* Order summary */}
            <Card className="h-fit space-y-4">
              <h2 className="text-lg font-semibold text-white">Order Summary</h2>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-sm text-[var(--color-text-muted)]">
                  <span>
                    Subtotal ({cart.items.reduce((a, i) => a + i.quantity, 0)} items)
                  </span>
                  <span className="font-medium text-white">{formatCurrency(subtotal)}</span>
                </div>
                <div className="flex items-center justify-between text-sm text-[var(--color-text-muted)]">
                  <span>Shipping</span>
                  <span className="text-[var(--color-text-dim)]">Calculated at checkout</span>
                </div>
              </div>
              <div className="border-t border-[var(--color-border)] pt-4">
                <div className="mb-4 flex items-center justify-between">
                  <span className="font-semibold text-white">Subtotal</span>
                  <span className="text-lg font-bold text-[var(--color-gold)]">
                    {formatCurrency(subtotal)}
                  </span>
                </div>
                <Link href="/checkout">
                  <GoldButton fullWidth size="lg">
                    Proceed to Checkout
                  </GoldButton>
                </Link>
                <Link
                  href="/shop"
                  className="mt-3 block text-center text-sm text-[var(--color-text-muted)] hover:text-white transition-colors"
                >
                  Continue Shopping
                </Link>
              </div>
            </Card>
          </div>
        )}
      </div>
    </>
  )
}
