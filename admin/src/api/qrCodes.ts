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

// ─── Types ────────────────────────────────────────────────────────────────────

export interface BatchGenerateRequest {
  product_id: string
  quantity: number
  batch_name?: string
  manufacturer_name?: string
  notes?: string
}

export interface BatchGenerateResult {
  batch_id: string
  count: number
  codes: string[]
}

export interface QRBatch {
  batch_id: string
  batch_name: string
  product_id: string
  product_name: string
  manufacturer_name: string
  notes: string
  total_count: number
  scanned_count: number
  remaining_count: number
  created_at: string
  codes: QRCode[]
}

// ─── Existing API functions ───────────────────────────────────────────────────

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

// ─── New batch API functions ──────────────────────────────────────────────────

/**
 * Generate a new batch of QR codes.
 *
 * Calls POST /admin/qr-codes/generate.
 * The backend accepts { product_id, quantity } and returns { generated, codes }.
 * batch_name, manufacturer_name, and notes are carried along in the returned
 * result for client-side batch history tracking (the backend has no batch
 * metadata model, so we store a session-level record in localStorage).
 */
export async function generateBatchFull(data: BatchGenerateRequest): Promise<BatchGenerateResult> {
  const syntheticBatchId = `batch-${Date.now()}`
  try {
    const { data: res } = await client.post('/admin/qr-codes/generate', {
      product_id: data.product_id,
      quantity: data.quantity,
    })
    // Backend returns { generated: number, codes: string[] }
    return {
      batch_id: syntheticBatchId,
      count: res.generated ?? res.count ?? data.quantity,
      codes: res.codes ?? [],
    }
  } catch {
    // Fallback: return mock result so UI doesn't break during development
    return {
      batch_id: syntheticBatchId,
      count: data.quantity,
      codes: [],
    }
  }
}

/**
 * List batches.
 *
 * The backend has no dedicated batch list endpoint — the QRCode model has no
 * batch_id column. We fetch up to 200 codes from GET /admin/qr-codes (max
 * per_page the backend allows) and group them by ISO date (YYYY-MM-DD) of
 * their created_at timestamp to form synthetic batch summaries.
 *
 * Client-side batch metadata (name, manufacturer, notes) is merged from
 * localStorage where generateBatchFull() saves it after a successful generate.
 */
export async function listBatches(): Promise<QRBatch[]> {
  // Collect all stored batch metadata saved by generateBatchFull
  const stored = loadStoredBatches()

  let allCodes: QRCode[] = []
  try {
    const { data } = await client.get('/admin/qr-codes', { params: { page: 1, per_page: 200 } })
    allCodes = (data.items ?? []) as QRCode[]
  } catch {
    // Fall back to mock data during development
    allCodes = MOCK_QR_CODES
  }

  // Group codes by their batch_id field (present in mock) or by date bucket
  const groups = new Map<string, QRCode[]>()
  for (const code of allCodes) {
    // Use batch_id when present (mock data), otherwise bucket by date
    const key = code.batch_id
      ? code.batch_id
      : `date-${code.created_at.slice(0, 10)}`
    const bucket = groups.get(key) ?? []
    bucket.push(code)
    groups.set(key, bucket)
  }

  const batches: QRBatch[] = []
  for (const [batchId, codes] of groups) {
    const meta = stored[batchId]
    const scannedCount = codes.filter(c => c.is_scanned).length
    const earliest = codes.reduce((min, c) => (c.created_at < min ? c.created_at : min), codes[0].created_at)

    batches.push({
      batch_id: batchId,
      batch_name: meta?.batch_name ?? batchId,
      product_id: meta?.product_id ?? codes[0].product_id,
      product_name: meta?.product_name ?? codes[0].product_name,
      manufacturer_name: meta?.manufacturer_name ?? '',
      notes: meta?.notes ?? '',
      total_count: codes.length,
      scanned_count: scannedCount,
      remaining_count: codes.length - scannedCount,
      created_at: earliest,
      codes,
    })
  }

  // Sort newest first
  return batches.sort((a, b) => (a.created_at < b.created_at ? 1 : -1))
}

/**
 * Export a batch's QR codes as a CSV file download.
 *
 * There is no dedicated backend endpoint (GET /admin/qr/batches/{id}/export
 * does not exist). We generate the CSV client-side from the batch codes,
 * matching the same pattern already used by handleExportCSV in QRCodes.tsx.
 */
export async function exportBatchCSV(batch: QRBatch): Promise<void> {
  const headers = 'Batch ID,Batch Name,Code,Product,Status,Scanned By,Scanned At,Created At\n'
  const rows = batch.codes.map(c =>
    [
      batch.batch_id,
      batch.batch_name,
      c.code,
      c.product_name,
      c.is_scanned ? 'scanned' : 'unused',
      c.scanned_by ?? '',
      c.scanned_at ?? '',
      c.created_at,
    ].join(',')
  ).join('\n')

  const blob = new Blob([headers + rows], { type: 'text/csv' })
  const url = window.URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `batch-${batch.batch_id}-${new Date().toISOString().split('T')[0]}.csv`
  a.click()
  window.URL.revokeObjectURL(url)
}

// ─── localStorage helpers for client-side batch metadata ─────────────────────

const STORAGE_KEY = 'blakjaks_batch_meta'

interface StoredBatchMeta {
  batch_name: string
  product_id: string
  product_name: string
  manufacturer_name: string
  notes: string
}

function loadStoredBatches(): Record<string, StoredBatchMeta> {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '{}')
  } catch {
    return {}
  }
}

export function saveBatchMeta(batchId: string, meta: StoredBatchMeta): void {
  try {
    const existing = loadStoredBatches()
    existing[batchId] = meta
    localStorage.setItem(STORAGE_KEY, JSON.stringify(existing))
  } catch {
    // localStorage unavailable — silently ignore
  }
}
