import { useCallback, useEffect, useState } from 'react'
import { Plus, Download, Trash2, Copy, Check, Filter } from 'lucide-react'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import { listQRCodes, generateBatch, invalidateCodes, PRODUCTS } from '../api/qrCodes'
import { formatDate, formatDateTime } from '../utils/formatters'
import type { QRCode } from '../types'

export default function QRCodes() {
  const [codes, setCodes] = useState<QRCode[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [productFilter, setProductFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState<Set<string>>(new Set())

  // Generate modal
  const [genOpen, setGenOpen] = useState(false)
  const [genProduct, setGenProduct] = useState(PRODUCTS[0].id)
  const [genQty, setGenQty] = useState('100')
  const [generating, setGenerating] = useState(false)

  // Invalidate confirm
  const [invalidateOpen, setInvalidateOpen] = useState(false)

  // Copied code tracking
  const [copiedId, setCopiedId] = useState<string | null>(null)

  const fetchCodes = useCallback(async () => {
    setLoading(true)
    const res = await listQRCodes(page, productFilter || undefined, statusFilter || undefined)
    setCodes(res.items)
    setTotal(res.total)
    setLoading(false)
  }, [page, productFilter, statusFilter])

  useEffect(() => { fetchCodes() }, [fetchCodes])

  const totalPages = Math.ceil(total / 50)

  const handleGenerate = async () => {
    setGenerating(true)
    try {
      const res = await generateBatch(genProduct, parseInt(genQty))
      toast.success(`Generated ${res.count} QR codes (Batch: ${res.batch_id})`)
      setGenOpen(false)
      setGenQty('100')
      fetchCodes()
    } catch {
      toast.error('Failed to generate batch')
    } finally {
      setGenerating(false)
    }
  }

  const handleInvalidate = async () => {
    try {
      const res = await invalidateCodes(Array.from(selected))
      toast.success(`Invalidated ${res.invalidated} codes`)
      setSelected(new Set())
      fetchCodes()
    } catch {
      toast.error('Failed to invalidate codes')
    }
  }

  const handleCopy = (code: string, id: string) => {
    navigator.clipboard.writeText(code)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 2000)
  }

  const handleExportCSV = () => {
    const headers = 'Code,Product,Status,Scanned By,Scanned At,Created At\n'
    const rows = codes.map(c =>
      `${c.code},${c.product_name},${c.is_scanned ? 'scanned' : 'unused'},${c.scanned_by ?? ''},${c.scanned_at ?? ''},${c.created_at}`
    ).join('\n')
    const blob = new Blob([headers + rows], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `qr-codes-${new Date().toISOString().split('T')[0]}.csv`
    a.click()
    URL.revokeObjectURL(url)
    toast.success('CSV exported')
  }

  const toggleSelect = (id: string) => {
    setSelected(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const toggleAll = () => {
    if (selected.size === codes.length) setSelected(new Set())
    else setSelected(new Set(codes.map(c => c.id)))
  }

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <button
          onClick={() => setGenOpen(true)}
          className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
        >
          <Plus size={16} /> Generate New Batch
        </button>
        <button
          onClick={handleExportCSV}
          className="flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          <Download size={16} /> Export CSV
        </button>
        {selected.size > 0 && (
          <button
            onClick={() => setInvalidateOpen(true)}
            className="flex items-center gap-1.5 rounded-lg bg-red-50 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-100"
          >
            <Trash2 size={16} /> Invalidate Selected ({selected.size})
          </button>
        )}

        <div className="ml-auto flex items-center gap-3">
          <div className="flex items-center gap-2">
            <Filter size={16} className="text-slate-400" />
            <select
              value={productFilter}
              onChange={(e) => { setProductFilter(e.target.value); setPage(1) }}
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
            >
              <option value="">All Products</option>
              {PRODUCTS.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
            className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
          >
            <option value="">All Status</option>
            <option value="unused">Unused</option>
            <option value="scanned">Scanned</option>
          </select>
        </div>
      </div>

      <p className="text-sm text-slate-500">{total} QR code{total !== 1 ? 's' : ''} found</p>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
      ) : codes.length === 0 ? (
        <EmptyState title="No QR codes" message="Generate a batch to get started." />
      ) : (
        <div className="overflow-hidden rounded-xl bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50">
                <th className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selected.size === codes.length && codes.length > 0}
                    onChange={toggleAll}
                    className="rounded border-slate-300"
                  />
                </th>
                <th className="px-4 py-3 font-medium text-slate-600">Code</th>
                <th className="px-4 py-3 font-medium text-slate-600">Product</th>
                <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                <th className="px-4 py-3 font-medium text-slate-600">Scanned By</th>
                <th className="px-4 py-3 font-medium text-slate-600">Scanned At</th>
                <th className="px-4 py-3 font-medium text-slate-600">Created</th>
              </tr>
            </thead>
            <tbody>
              {codes.map(c => (
                <tr key={c.id} className="border-b border-slate-50 hover:bg-slate-50">
                  <td className="px-4 py-3">
                    <input
                      type="checkbox"
                      checked={selected.has(c.id)}
                      onChange={() => toggleSelect(c.id)}
                      className="rounded border-slate-300"
                    />
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs text-slate-700">{c.code}</span>
                      <button
                        onClick={() => handleCopy(c.code, c.id)}
                        className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
                        title="Copy code"
                      >
                        {copiedId === c.id ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
                      </button>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-slate-700">{c.product_name}</td>
                  <td className="px-4 py-3">
                    <Badge label={c.is_scanned ? 'scanned' : 'unused'} />
                  </td>
                  <td className="px-4 py-3 text-slate-500">{c.scanned_by ?? '-'}</td>
                  <td className="px-4 py-3 text-slate-500">{c.scanned_at ? formatDateTime(c.scanned_at) : '-'}</td>
                  <td className="px-4 py-3 text-slate-500">{formatDate(c.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {totalPages > 1 && (
            <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
              <span className="text-sm text-slate-500">Page {page} of {totalPages}</span>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage(p => p - 1)}
                  disabled={page <= 1}
                  className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage(p => p + 1)}
                  disabled={page >= totalPages}
                  className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Generate Modal */}
      <Modal open={genOpen} onClose={() => setGenOpen(false)} title="Generate QR Code Batch">
        <div className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Product</label>
            <select
              value={genProduct}
              onChange={(e) => setGenProduct(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            >
              {PRODUCTS.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Quantity</label>
            <input
              type="number"
              value={genQty}
              onChange={(e) => setGenQty(e.target.value)}
              min="1"
              max="10000"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setGenOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button
              onClick={handleGenerate}
              disabled={generating || !genQty || parseInt(genQty) < 1}
              className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40"
            >
              {generating && <LoadingSpinner className="h-4 w-4" />}
              Generate
            </button>
          </div>
        </div>
      </Modal>

      {/* Invalidate Confirm */}
      <ConfirmDialog
        open={invalidateOpen}
        onClose={() => setInvalidateOpen(false)}
        onConfirm={handleInvalidate}
        title="Invalidate QR Codes"
        message={`Are you sure you want to invalidate ${selected.size} selected code${selected.size !== 1 ? 's' : ''}? This action cannot be undone.`}
        confirmLabel="Invalidate"
        variant="danger"
      />
    </div>
  )
}
