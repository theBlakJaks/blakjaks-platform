import client from './client'
import type { QRCode } from '../types'

export async function generateBatch(productId: string, quantity: number): Promise<{ batch_id: string; count: number }> {
  const { data } = await client.post('/admin/qr-codes/generate', { product_id: productId, quantity })
  return data
}

export async function listQRCodes(page = 1, batchId?: string): Promise<{ items: QRCode[]; total: number }> {
  const params: Record<string, string | number> = { page, limit: 20 }
  if (batchId) params.batch_id = batchId
  const { data } = await client.get('/admin/qr-codes', { params })
  return data
}
