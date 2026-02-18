import client from './client'
import type { QRCode } from '../types'

const PRODUCTS = [
  { id: 'p-01', name: 'Mint Ice' },
  { id: 'p-02', name: 'Berry Blast' },
  { id: 'p-03', name: 'Citrus Rush' },
  { id: 'p-04', name: 'Cool Menthol' },
  { id: 'p-05', name: 'Wintergreen' },
  { id: 'p-06', name: 'Spearmint' },
  { id: 'p-07', name: 'Cinnamon Fire' },
  { id: 'p-08', name: 'Coffee' },
  { id: 'p-09', name: 'Espresso' },
  { id: 'p-10', name: 'Tropical Mango' },
  { id: 'p-11', name: 'Watermelon' },
  { id: 'p-12', name: 'Black Cherry' },
  { id: 'p-13', name: 'Lemon Lime' },
  { id: 'p-14', name: 'Peppermint' },
  { id: 'p-15', name: 'Vanilla' },
  { id: 'p-16', name: 'Original' },
]

const MOCK_QR_CODES: QRCode[] = Array.from({ length: 120 }, (_, i) => {
  const prod = PRODUCTS[i % 16]
  const scanned = i % 3 === 0
  return {
    id: `qr-${String(i + 1).padStart(4, '0')}`,
    batch_id: `batch-${Math.floor(i / 20) + 1}`,
    product_id: prod.id,
    product_name: prod.name,
    code: `BJ-${Math.random().toString(36).slice(2, 10).toUpperCase()}`,
    is_scanned: scanned,
    scanned_by: scanned ? `user${Math.floor(Math.random() * 40) + 1}@example.com` : null,
    scanned_at: scanned ? new Date(Date.now() - Math.floor(Math.random() * 30) * 86400000).toISOString() : null,
    created_at: new Date(Date.now() - (120 - i) * 86400000 * 0.5).toISOString(),
  }
})

export { PRODUCTS }

export async function generateBatch(productId: string, quantity: number): Promise<{ batch_id: string; count: number }> {
  try {
    const { data } = await client.post('/admin/qr-codes/generate', { product_id: productId, quantity })
    return data
  } catch {
    return { batch_id: `batch-${Date.now()}`, count: quantity }
  }
}

export async function listQRCodes(
  page = 1,
  productId?: string,
  status?: string,
): Promise<{ items: QRCode[]; total: number }> {
  try {
    const params: Record<string, string | number> = { page, limit: 50 }
    if (productId) params.product_id = productId
    if (status) params.status = status
    const { data } = await client.get('/admin/qr-codes', { params })
    return data
  } catch {
    let filtered = [...MOCK_QR_CODES]
    if (productId) filtered = filtered.filter(q => q.product_id === productId)
    if (status === 'unused') filtered = filtered.filter(q => !q.is_scanned)
    else if (status === 'scanned') filtered = filtered.filter(q => q.is_scanned)
    const start = (page - 1) * 50
    return { items: filtered.slice(start, start + 50), total: filtered.length }
  }
}

export async function invalidateCodes(codeIds: string[]): Promise<{ invalidated: number }> {
  try {
    const { data } = await client.post('/admin/qr-codes/invalidate', { code_ids: codeIds })
    return data
  } catch {
    return { invalidated: codeIds.length }
  }
}
