import { useCallback, useEffect, useState } from 'react'
import { Plus, Radio, ExternalLink } from 'lucide-react'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import {
  listStreams,
  createStream,
  startStream,
  endStream,
  deleteStream,
} from '../api/streams'
import { formatDateTime } from '../utils/formatters'
import type { Stream } from '../api/streams'

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const TIER_OPTIONS = [
  { value: '', label: 'All Members' },
  { value: 'VIP', label: 'VIP+' },
  { value: 'High Roller', label: 'High Roller+' },
  { value: 'Whale', label: 'Whale' },
]

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function statusBadgeClass(status: Stream['status']): string {
  switch (status) {
    case 'live':
      return 'bg-green-100 text-green-800'
    case 'scheduled':
      return 'bg-amber-100 text-amber-800'
    case 'ended':
      return 'bg-slate-100 text-slate-600'
    case 'cancelled':
      return 'bg-red-100 text-red-700'
    default:
      return 'bg-slate-100 text-slate-600'
  }
}

function StatusBadge({ status }: { status: Stream['status'] }) {
  if (status === 'live') {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
        <span className="relative flex h-2 w-2">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-green-400 opacity-75" />
          <span className="relative inline-flex h-2 w-2 rounded-full bg-green-500" />
        </span>
        LIVE
      </span>
    )
  }
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusBadgeClass(status)}`}
    >
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  )
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export default function LiveStreams() {
  const [streams, setStreams] = useState<Stream[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Create form state
  const [createOpen, setCreateOpen] = useState(false)
  const [formTitle, setFormTitle] = useState('')
  const [formDesc, setFormDesc] = useState('')
  const [formScheduledAt, setFormScheduledAt] = useState('')
  const [formTier, setFormTier] = useState('')
  const [formStreamYardId, setFormStreamYardId] = useState('')
  const [creating, setCreating] = useState(false)

  // Go Live confirm
  const [goLiveTarget, setGoLiveTarget] = useState<Stream | null>(null)
  const [goingLive, setGoingLive] = useState(false)

  // End Stream confirm
  const [endTarget, setEndTarget] = useState<Stream | null>(null)
  const [ending, setEnding] = useState(false)

  // Delete confirm
  const [deleteTarget, setDeleteTarget] = useState<Stream | null>(null)
  const [deleting, setDeleting] = useState(false)

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  const fetchStreams = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await listStreams()
      setStreams(data)
    } catch {
      setError('Failed to load streams. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchStreams()
  }, [fetchStreams])

  // ---------------------------------------------------------------------------
  // Live stream viewer count banner
  // ---------------------------------------------------------------------------

  const liveStreams = streams.filter((s) => s.status === 'live')
  const totalViewers = liveStreams.reduce((sum, s) => sum + (s.viewer_count ?? 0), 0)

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  const resetCreateForm = () => {
    setFormTitle('')
    setFormDesc('')
    setFormScheduledAt('')
    setFormTier('')
    setFormStreamYardId('')
  }

  const handleCreate = async () => {
    if (!formTitle.trim()) {
      toast.error('Stream title is required')
      return
    }
    setCreating(true)
    try {
      await createStream({
        title: formTitle.trim(),
        description: formDesc.trim() || undefined,
        scheduled_at: formScheduledAt || undefined,
        tier_restriction: formTier || undefined,
        stream_key: formStreamYardId.trim() || undefined,
      })
      toast.success('Stream created')
      setCreateOpen(false)
      resetCreateForm()
      fetchStreams()
    } catch {
      toast.error('Failed to create stream')
    } finally {
      setCreating(false)
    }
  }

  const handleGoLive = async () => {
    if (!goLiveTarget) return
    setGoingLive(true)
    try {
      await startStream(goLiveTarget.id)
      toast.success(`"${goLiveTarget.title}" is now live`)
      setGoLiveTarget(null)
      fetchStreams()
    } catch {
      toast.error('Failed to go live')
    } finally {
      setGoingLive(false)
    }
  }

  const handleEndStream = async () => {
    if (!endTarget) return
    setEnding(true)
    try {
      await endStream(endTarget.id)
      toast.success(`"${endTarget.title}" has ended`)
      setEndTarget(null)
      fetchStreams()
    } catch {
      toast.error('Failed to end stream')
    } finally {
      setEnding(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await deleteStream(deleteTarget.id)
      toast.success('Stream deleted')
      setDeleteTarget(null)
      fetchStreams()
    } catch {
      toast.error('Failed to delete stream')
    } finally {
      setDeleting(false)
    }
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex-1">
          <h1 className="text-xl font-semibold text-slate-900">Live Streams</h1>
          <p className="mt-0.5 text-sm text-slate-500">
            Manage scheduled, live, and past streams.
          </p>
        </div>
        <button
          onClick={() => {
            resetCreateForm()
            setCreateOpen(true)
          }}
          className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
        >
          <Plus size={16} /> Schedule Stream
        </button>
      </div>

      {/* Live viewer count banner */}
      {liveStreams.length > 0 && (
        <div className="flex items-center gap-3 rounded-xl border border-green-200 bg-green-50 px-4 py-3">
          <span className="relative flex h-3 w-3">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-green-400 opacity-75" />
            <span className="relative inline-flex h-3 w-3 rounded-full bg-green-500" />
          </span>
          <span className="text-sm font-medium text-green-800">
            {liveStreams.length} stream{liveStreams.length !== 1 ? 's' : ''} live
            now
          </span>
          <span className="ml-auto flex items-center gap-1.5 text-sm text-green-700">
            <Radio size={14} />
            {totalViewers} viewer{totalViewers !== 1 ? 's' : ''}
          </span>
        </div>
      )}

      {/* Streams table */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <LoadingSpinner />
        </div>
      ) : error ? (
        <div className="rounded-xl border border-red-200 bg-red-50 p-6 text-center">
          <p className="mb-3 text-sm text-red-700">{error}</p>
          <button
            onClick={fetchStreams}
            className="rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-100"
          >
            Retry
          </button>
        </div>
      ) : streams.length === 0 ? (
        <EmptyState
          title="No streams yet"
          message="Schedule a stream to get started."
        />
      ) : (
        <div className="overflow-hidden rounded-xl bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50">
                <th className="px-4 py-3 font-medium text-slate-600">Title</th>
                <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                <th className="px-4 py-3 font-medium text-slate-600">
                  Scheduled Date
                </th>
                <th className="px-4 py-3 font-medium text-slate-600">
                  StreamYard ID
                </th>
                <th className="px-4 py-3 font-medium text-slate-600">
                  Tier
                </th>
                <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {streams.map((stream) => (
                <tr
                  key={stream.id}
                  className="border-b border-slate-50 hover:bg-slate-50"
                >
                  {/* Title */}
                  <td className="px-4 py-3">
                    <span className="font-medium text-slate-900">
                      {stream.title}
                    </span>
                    {stream.description && (
                      <p className="mt-0.5 max-w-xs truncate text-xs text-slate-500">
                        {stream.description}
                      </p>
                    )}
                  </td>

                  {/* Status */}
                  <td className="px-4 py-3">
                    <StatusBadge status={stream.status} />
                    {stream.status === 'live' && stream.viewer_count != null && (
                      <p className="mt-0.5 text-xs text-slate-500">
                        {stream.viewer_count} watching
                      </p>
                    )}
                  </td>

                  {/* Scheduled date */}
                  <td className="px-4 py-3 text-slate-600">
                    {stream.scheduled_at
                      ? formatDateTime(stream.scheduled_at)
                      : '-'}
                  </td>

                  {/* StreamYard ID */}
                  <td className="px-4 py-3">
                    {stream.stream_key ? (
                      <code className="rounded bg-slate-100 px-1.5 py-0.5 text-xs text-slate-700">
                        {stream.stream_key}
                      </code>
                    ) : (
                      <span className="text-slate-400">-</span>
                    )}
                  </td>

                  {/* Tier restriction */}
                  <td className="px-4 py-3">
                    {stream.tier_restriction ? (
                      <Badge label={stream.tier_restriction} variant="tier" />
                    ) : (
                      <span className="text-xs text-slate-400">All</span>
                    )}
                  </td>

                  {/* Actions */}
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-2">
                      {stream.status === 'scheduled' && (
                        <button
                          onClick={() => setGoLiveTarget(stream)}
                          className="rounded-lg bg-green-600 px-2.5 py-1.5 text-xs font-medium text-white hover:bg-green-700"
                        >
                          Go Live
                        </button>
                      )}
                      {stream.status === 'live' && (
                        <button
                          onClick={() => setEndTarget(stream)}
                          className="rounded-lg bg-red-600 px-2.5 py-1.5 text-xs font-medium text-white hover:bg-red-700"
                        >
                          End Stream
                        </button>
                      )}
                      {stream.status === 'ended' && stream.vod_url && (
                        <a
                          href={stream.vod_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50"
                        >
                          View VOD <ExternalLink size={12} />
                        </a>
                      )}
                      <button
                        onClick={() => setDeleteTarget(stream)}
                        className="rounded-lg px-2.5 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ------------------------------------------------------------------ */}
      {/* Create Stream Modal                                                 */}
      {/* ------------------------------------------------------------------ */}
      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Schedule New Stream"
      >
        <div className="max-h-[70vh] space-y-4 overflow-y-auto">
          {/* Title */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Title <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={formTitle}
              onChange={(e) => setFormTitle(e.target.value)}
              placeholder="Stream title"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>

          {/* Description */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Description
            </label>
            <textarea
              value={formDesc}
              onChange={(e) => setFormDesc(e.target.value)}
              rows={3}
              placeholder="What is this stream about?"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>

          {/* Scheduled date/time */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Scheduled Date &amp; Time
            </label>
            <input
              type="datetime-local"
              value={formScheduledAt}
              onChange={(e) => setFormScheduledAt(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>

          {/* Tier restriction */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Tier Restriction
            </label>
            <select
              value={formTier}
              onChange={(e) => setFormTier(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            >
              {TIER_OPTIONS.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </div>

          {/* StreamYard Broadcast ID */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              StreamYard Broadcast ID
            </label>
            <input
              type="text"
              value={formStreamYardId}
              onChange={(e) => setFormStreamYardId(e.target.value)}
              placeholder="sy-xxxxxxxx"
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-mono outline-none focus:border-indigo-500"
            />
            <p className="mt-1 text-xs text-slate-500">
              Leave blank to auto-generate a stream key.
            </p>
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-3 pt-1">
            <button
              onClick={() => setCreateOpen(false)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              onClick={handleCreate}
              disabled={creating}
              className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40"
            >
              {creating && <LoadingSpinner className="h-4 w-4" />}
              Schedule Stream
            </button>
          </div>
        </div>
      </Modal>

      {/* ------------------------------------------------------------------ */}
      {/* Go Live Confirm                                                     */}
      {/* ------------------------------------------------------------------ */}
      <ConfirmDialog
        open={!!goLiveTarget && !goingLive}
        onClose={() => setGoLiveTarget(null)}
        onConfirm={handleGoLive}
        title="Go Live"
        message={`Start broadcasting "${goLiveTarget?.title}" now? The stream will be marked as live and visible to members.`}
        confirmLabel="Go Live"
        variant="primary"
      />

      {/* ------------------------------------------------------------------ */}
      {/* End Stream Confirm                                                  */}
      {/* ------------------------------------------------------------------ */}
      <ConfirmDialog
        open={!!endTarget && !ending}
        onClose={() => setEndTarget(null)}
        onConfirm={handleEndStream}
        title="End Stream"
        message={`End "${endTarget?.title}"? The stream will be marked as ended and a VOD link can be added later.`}
        confirmLabel="End Stream"
        variant="danger"
      />

      {/* ------------------------------------------------------------------ */}
      {/* Delete Confirm                                                      */}
      {/* ------------------------------------------------------------------ */}
      <ConfirmDialog
        open={!!deleteTarget && !deleting}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete}
        title="Delete Stream"
        message={`Permanently delete "${deleteTarget?.title}"? This action cannot be undone.`}
        confirmLabel="Delete"
        variant="danger"
      />
    </div>
  )
}
