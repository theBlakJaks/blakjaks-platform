'use client'

import { useEffect, useState, useCallback } from 'react'
import { ShoppingCart, Package, RefreshCw } from 'lucide-react'
import Card from '@/components/ui/Card'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'
import GoldButton from '@/components/ui/GoldButton'
import Badge from '@/components/ui/Badge'
import { api } from '@/lib/api'
import { formatCurrency } from '@/lib/utils'

interface Product {
  id: string
  name: string
  flavor: string
  strength: string
  price: number
  description: string
  image_url?: string
  in_stock: boolean
  category?: string
}

function ProductCardSkeleton() {
  return (
    <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-4 animate-pulse">
      <div className="mb-4 h-40 rounded-xl bg-[var(--color-bg-surface)]" />
      <div className="mb-2 h-4 w-3/4 rounded bg-[var(--color-bg-surface)]" />
      <div className="mb-3 h-3 w-1/2 rounded bg-[var(--color-bg-surface)]" />
      <div className="flex items-center justify-between">
        <div className="h-5 w-16 rounded bg-[var(--color-bg-surface)]" />
        <div className="h-8 w-24 rounded-xl bg-[var(--color-bg-surface)]" />
      </div>
    </div>
  )
}

export default function ShopPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeFilter, setActiveFilter] = useState<string>('all')
  const [addingToCart, setAddingToCart] = useState<string | null>(null)
  const [cartSuccess, setCartSuccess] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await api.shop.getProducts()
      setProducts((data.products ?? []) as Product[])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load products')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const flavors = ['all', ...Array.from(new Set(products.map((p) => p.flavor).filter(Boolean)))]

  const filtered =
    activeFilter === 'all' ? products : products.filter((p) => p.flavor === activeFilter)

  async function handleAddToCart(productId: string) {
    setAddingToCart(productId)
    try {
      await api.shop.addToCart(productId, 1)
      setCartSuccess(productId)
      setTimeout(() => setCartSuccess(null), 2000)
    } catch {
      // silent — could show a toast
    } finally {
      setAddingToCart(null)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">Shop</h1>
        <p className="mt-1 text-sm text-[var(--color-text-dim)]">
          Browse our premium nicotine pouch collection
        </p>
      </div>

      {/* Flavor filter bar */}
      {!loading && !error && products.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {flavors.map((flavor) => (
            <button
              key={flavor}
              onClick={() => setActiveFilter(flavor)}
              className={`rounded-full px-4 py-1.5 text-sm font-medium capitalize transition-all ${
                activeFilter === flavor
                  ? 'gold-gradient text-black'
                  : 'border border-[var(--color-border)] text-[var(--color-text-muted)] hover:border-[var(--color-gold)] hover:text-white'
              }`}
            >
              {flavor === 'all' ? 'All Flavors' : flavor}
            </button>
          ))}
        </div>
      )}

      {/* Loading skeleton */}
      {loading && (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <ProductCardSkeleton key={i} />
          ))}
        </div>
      )}

      {/* Error state */}
      {!loading && error && (
        <Card className="text-center">
          <p className="mb-4 text-[var(--color-danger)]">{error}</p>
          <GoldButton onClick={load} variant="secondary">
            <RefreshCw size={14} /> Retry
          </GoldButton>
        </Card>
      )}

      {/* Empty state */}
      {!loading && !error && filtered.length === 0 && (
        <EmptyState
          icon={Package}
          message={
            activeFilter === 'all'
              ? 'No products available right now.'
              : `No products found for "${activeFilter}".`
          }
          actionLabel={activeFilter !== 'all' ? 'Show All' : undefined}
          onAction={activeFilter !== 'all' ? () => setActiveFilter('all') : undefined}
        />
      )}

      {/* Product grid */}
      {!loading && !error && filtered.length > 0 && (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {filtered.map((product) => (
            <Card key={product.id} className="flex flex-col">
              {/* Image placeholder */}
              <div className="mb-4 flex h-40 items-center justify-center rounded-xl bg-[var(--color-bg-surface)]">
                {product.image_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={product.image_url}
                    alt={product.name}
                    className="h-full w-full rounded-xl object-cover"
                  />
                ) : (
                  <Package size={40} className="text-[var(--color-text-dim)]" />
                )}
              </div>

              {/* Info */}
              <div className="flex flex-1 flex-col">
                <h3 className="mb-1 font-semibold text-white">{product.name}</h3>
                <div className="mb-2 flex flex-wrap gap-1.5">
                  {product.flavor && <Badge status={product.flavor} />}
                  {product.strength && (
                    <span className="inline-flex items-center rounded-full border border-[var(--color-border)] px-2.5 py-0.5 text-xs font-medium text-[var(--color-text-muted)] capitalize">
                      {product.strength}
                    </span>
                  )}
                </div>
                {product.description && (
                  <p className="mb-3 text-xs text-[var(--color-text-dim)] line-clamp-2">
                    {product.description}
                  </p>
                )}

                {/* Price + CTA */}
                <div className="mt-auto flex items-center justify-between">
                  <span className="text-lg font-bold text-[var(--color-gold)]">
                    {formatCurrency(product.price)}
                  </span>
                  {product.in_stock !== false ? (
                    <GoldButton
                      size="sm"
                      loading={addingToCart === product.id}
                      onClick={() => handleAddToCart(product.id)}
                    >
                      {cartSuccess === product.id ? (
                        'Added!'
                      ) : (
                        <>
                          <ShoppingCart size={14} /> Add to Cart
                        </>
                      )}
                    </GoldButton>
                  ) : (
                    <span className="rounded-lg border border-[var(--color-border)] px-3 py-1.5 text-xs text-[var(--color-text-dim)]">
                      Out of Stock
                    </span>
                  )}
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
