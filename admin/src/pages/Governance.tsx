import { useCallback, useEffect, useRef, useState } from 'react'
import { Plus, X, Filter, RefreshCw, Eye, XCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import { getVotes, getVoteResults, createVote, closeVote } from '../api/governance'
import { formatDate } from '../utils/formatters'
import { TIER_COLORS } from '../utils/constants'
import type { Vote, VoteResult, VoteOption } from '../types'

const BAR_COLORS = ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4']

/** Returns a datetime-local string for `now + days` days */
function defaultEndDate(days = 7): string {
  const d = new Date(Date.now() + days * 86400000)
  // datetime-local format: YYYY-MM-DDTHH:mm
  return d.toISOString().slice(0, 16)
}

let nextOptId = 3

export default function Governance() {
  // ── Votes list ───────────────────────────────────────────────────────
  const [votes, setVotes] = useState<Vote[]>([])
  const [votesLoading, setVotesLoading] = useState(true)
  const [votesError, setVotesError] = useState<string | null>(null)
  const [voteStatusFilter, setVoteStatusFilter] = useState('')

  // ── Create vote modal ────────────────────────────────────────────────
  const [createOpen, setCreateOpen] = useState(false)
  const [newTitle, setNewTitle] = useState('')
  const [newDesc, setNewDesc] = useState('')
  const [newTargetTiers, setNewTargetTiers] = useState<string[]>(['VIP', 'High Roller', 'Whale'])
  const [newOptions, setNewOptions] = useState<{ id: string; label: string }[]>([
    { id: 'opt-1', label: '' },
    { id: 'opt-2', label: '' },
  ])
  const [newEndDate, setNewEndDate] = useState(defaultEndDate(7))
  const [creating, setCreating] = useState(false)

  // ── Results modal ────────────────────────────────────────────────────
  const [resultsVote, setResultsVote] = useState<Vote | null>(null)
  const [results, setResults] = useState<VoteResult[]>([])
  const [resultsLoading, setResultsLoading] = useState(false)
  const [resultsPublished, setResultsPublished] = useState(false)
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // ── Close confirm ────────────────────────────────────────────────────
  const [closeTarget, setCloseTarget] = useState<Vote | null>(null)
  // Close from inside the results modal
  const [closeFromResults, setCloseFromResults] = useState(false)

  // ────────────────────────────────────────────────────────────────────
  // Data fetching
  // ────────────────────────────────────────────────────────────────────

  const fetchVotes = useCallback(async () => {
    setVotesLoading(true)
    setVotesError(null)
    try {
      const data = await getVotes(voteStatusFilter || undefined)
      setVotes(data)
    } catch {
      setVotesError('Failed to load votes.')
    } finally {
      setVotesLoading(false)
    }
  }, [voteStatusFilter])

  useEffect(() => { fetchVotes() }, [fetchVotes])

  // ── Results polling ──────────────────────────────────────────────────

  const fetchResults = useCallback(async (voteId: string) => {
    const data = await getVoteResults(voteId)
    setResults(data)
  }, [])

  /** Open the results modal and start polling if the vote is still active. */
  const handleViewResults = async (vote: Vote) => {
    setResultsVote(vote)
    setResultsPublished(false)
    setResultsLoading(true)
    await fetchResults(vote.id)
    setResultsLoading(false)

    // Poll every 10 s while vote is active
    if (vote.status === 'active') {
      pollRef.current = setInterval(() => fetchResults(vote.id), 10_000)
    }
  }

  /** Stop polling and close the results modal. */
  const handleCloseResultsModal = () => {
    if (pollRef.current) {
      clearInterval(pollRef.current)
      pollRef.current = null
    }
    setResultsVote(null)
    setResults([])
    setCloseFromResults(false)
  }

  // Stop polling when vote transitions to closed inside the modal
  useEffect(() => {
    if (resultsVote?.status === 'closed' && pollRef.current) {
      clearInterval(pollRef.current)
      pollRef.current = null
    }
  }, [resultsVote])

  // Clean up on unmount
  useEffect(() => () => { if (pollRef.current) clearInterval(pollRef.current) }, [])

  // ────────────────────────────────────────────────────────────────────
  // Create vote
  // ────────────────────────────────────────────────────────────────────

  const handleCreateVote = async () => {
    const validOptions = newOptions.filter(o => o.label.trim())
    if (!newTitle.trim() || !newDesc.trim() || validOptions.length < 2) {
      toast.error('Fill in all fields and provide at least 2 options')
      return
    }
    if (newTargetTiers.length === 0) {
      toast.error('Select at least one target tier')
      return
    }
    if (!newEndDate || new Date(newEndDate) <= new Date()) {
      toast.error('End date must be in the future')
      return
    }
    setCreating(true)
    try {
      const opts: VoteOption[] = validOptions.map((o, i) => ({ id: `opt-${i + 1}`, label: o.label.trim() }))
      await createVote(newTitle.trim(), newDesc.trim(), newTargetTiers, opts, new Date(newEndDate).toISOString())
      toast.success('Vote created')
      setCreateOpen(false)
      resetCreateForm()
      fetchVotes()
    } catch {
      toast.error('Failed to create vote')
    } finally {
      setCreating(false)
    }
  }

  const resetCreateForm = () => {
    setNewTitle('')
    setNewDesc('')
    setNewTargetTiers(['VIP', 'High Roller', 'Whale'])
    setNewOptions([{ id: 'opt-1', label: '' }, { id: 'opt-2', label: '' }])
    setNewEndDate(defaultEndDate(7))
    nextOptId = 3
  }

  const addOption = () =>
    setNewOptions(prev => [...prev, { id: `opt-${nextOptId++}`, label: '' }])
  const removeOption = (idx: number) =>
    setNewOptions(prev => prev.filter((_, i) => i !== idx))
  const updateOption = (idx: number, label: string) =>
    setNewOptions(prev => prev.map((o, i) => (i === idx ? { ...o, label } : o)))

  // ────────────────────────────────────────────────────────────────────
  // Close vote
  // ────────────────────────────────────────────────────────────────────

  const handleCloseVote = async () => {
    const target = closeFromResults ? resultsVote : closeTarget
    if (!target) return
    try {
      await closeVote(target.id)
      toast.success('Vote closed')
      // Update local state
      setVotes(prev => prev.map(v => v.id === target.id ? { ...v, status: 'closed' } : v))
      if (resultsVote?.id === target.id) {
        setResultsVote(prev => prev ? { ...prev, status: 'closed' } : null)
      }
      setCloseTarget(null)
      setCloseFromResults(false)
      fetchVotes()
    } catch {
      toast.error('Failed to close vote')
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────

  const daysRemaining = (endDate: string) => {
    const diff = new Date(endDate).getTime() - Date.now()
    if (diff <= 0) return 'Ended'
    const days = Math.ceil(diff / 86400000)
    return `${days} day${days !== 1 ? 's' : ''} left`
  }

  const totalResultVotes = results.reduce((s, r) => s + r.count, 0)

  // ────────────────────────────────────────────────────────────────────
  // Render
  // ────────────────────────────────────────────────────────────────────

  return (
    <div className="space-y-6">

      <div className="space-y-4">

        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={() => { resetCreateForm(); setCreateOpen(true) }}
            className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
          >
            <Plus size={16} /> Create New Vote
          </button>

          <div className="ml-auto flex items-center gap-3">
            <Filter size={16} className="text-slate-400" />
            <select
              value={voteStatusFilter}
              onChange={e => setVoteStatusFilter(e.target.value)}
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
            >
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="closed">Closed</option>
              <option value="draft">Draft</option>
            </select>
            <button
              onClick={fetchVotes}
              title="Refresh"
              className="rounded-lg border border-slate-200 bg-white p-2 text-slate-500 hover:bg-slate-50"
            >
              <RefreshCw size={15} />
            </button>
          </div>
        </div>

        {/* Error state */}
        {votesError && (
          <div className="flex items-center justify-between rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            <span>{votesError}</span>
            <button onClick={fetchVotes} className="font-medium underline hover:no-underline">Retry</button>
          </div>
        )}

        {/* Table */}
        {votesLoading ? (
          <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
        ) : votes.length === 0 ? (
          <EmptyState title="No votes" message="Create a vote to get started." />
        ) : (
          <div className="overflow-hidden rounded-xl bg-white shadow-sm">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50">
                  <th className="px-4 py-3 font-medium text-slate-600">Title</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Target Tiers</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                  <th className="px-4 py-3 font-medium text-slate-600">End Date</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Votes</th>
                  <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
                </tr>
              </thead>
              <tbody>
                {votes.map(v => (
                  <tr key={v.id} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="px-4 py-3 font-medium text-slate-900">{v.title}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        {v.target_tiers.map(tier => (
                          <span key={tier} className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${TIER_COLORS[tier] || 'bg-slate-100 text-slate-800'}`}>
                            {tier}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td className="px-4 py-3"><Badge label={v.status} /></td>
                    <td className="px-4 py-3 text-slate-500">
                      <span title={formatDate(v.end_date)}>
                        {v.status === 'active' ? daysRemaining(v.end_date) : formatDate(v.end_date)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-700">{v.total_votes}</td>
                    <td className="px-4 py-3">
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleViewResults(v)}
                          className="flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50"
                        >
                          <Eye size={13} /> Results
                        </button>
                        {v.status === 'active' && (
                          <button
                            onClick={() => { setCloseFromResults(false); setCloseTarget(v) }}
                            className="flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50"
                          >
                            <XCircle size={13} /> Close
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ── Create Vote Modal ─────────────────────────────────────────── */}
      <Modal open={createOpen} onClose={() => setCreateOpen(false)} title="Create New Vote">
        <div className="max-h-[70vh] space-y-4 overflow-y-auto pr-1">

          {/* Title */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Title</label>
            <input
              type="text"
              value={newTitle}
              onChange={e => setNewTitle(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
              placeholder="Vote title"
            />
          </div>

          {/* Description */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Description</label>
            <textarea
              value={newDesc}
              onChange={e => setNewDesc(e.target.value)}
              rows={3}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
              placeholder="Describe what this vote is about"
            />
          </div>

          {/* Target Tiers */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Target Tiers</label>
            <div className="flex flex-wrap gap-3">
              {['VIP', 'High Roller', 'Whale'].map(tier => (
                <label key={tier} className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={newTargetTiers.includes(tier)}
                    onChange={e => {
                      if (e.target.checked) setNewTargetTiers(prev => [...prev, tier])
                      else setNewTargetTiers(prev => prev.filter(t => t !== tier))
                    }}
                    className="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <span className="text-sm text-slate-700">{tier}</span>
                </label>
              ))}
            </div>
            <p className="mt-1 text-xs text-slate-500">Poll will appear in selected tier governance rooms</p>
          </div>

          {/* Options */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Options <span className="font-normal text-slate-400">(min 2)</span>
            </label>
            <div className="space-y-2">
              {newOptions.map((opt, i) => (
                <div key={opt.id} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={opt.label}
                    onChange={e => updateOption(i, e.target.value)}
                    placeholder={`Option ${i + 1}`}
                    className="flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
                  />
                  {newOptions.length > 2 && (
                    <button
                      onClick={() => removeOption(i)}
                      className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-red-500"
                    >
                      <X size={16} />
                    </button>
                  )}
                </div>
              ))}
              <button
                onClick={addOption}
                className="text-sm font-medium text-indigo-600 hover:underline"
              >
                + Add option
              </button>
            </div>
          </div>

          {/* End date/time */}
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">End Date &amp; Time</label>
            <input
              type="datetime-local"
              value={newEndDate}
              onChange={e => setNewEndDate(e.target.value)}
              min={new Date(Date.now() + 60_000).toISOString().slice(0, 16)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
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
              onClick={handleCreateVote}
              disabled={creating}
              className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40"
            >
              {creating && <LoadingSpinner className="h-4 w-4" />}
              Create Vote
            </button>
          </div>
        </div>
      </Modal>

      {/* ── Vote Results Modal ────────────────────────────────────────── */}
      <Modal
        open={!!resultsVote}
        onClose={handleCloseResultsModal}
        title={resultsVote?.title || 'Results'}
      >
        {resultsLoading ? (
          <div className="flex items-center justify-center py-8"><LoadingSpinner /></div>
        ) : resultsVote && (
          <div className="space-y-5">

            {/* Meta row */}
            <div>
              <p className="text-sm text-slate-600">{resultsVote.description}</p>
              <div className="mt-2 flex flex-wrap items-center gap-3">
                <Badge label={resultsVote.status} />
                <span className="text-sm text-slate-500">
                  {resultsVote.status === 'active'
                    ? daysRemaining(resultsVote.end_date)
                    : `Closed ${formatDate(resultsVote.end_date)}`}
                </span>
                <span className="text-sm font-medium text-slate-700">
                  {totalResultVotes} total vote{totalResultVotes !== 1 ? 's' : ''}
                </span>
                {resultsVote.status === 'active' && (
                  <span className="ml-auto flex items-center gap-1 text-xs text-slate-400">
                    <RefreshCw size={12} className="animate-spin" /> Live
                  </span>
                )}
              </div>
            </div>

            {/* CSS bar chart */}
            {results.length > 0 ? (
              <div className="space-y-3">
                {results.map((r, i) => (
                  <div key={r.option_id}>
                    <div className="mb-1 flex items-center justify-between text-sm">
                      <div className="flex items-center gap-2">
                        <span
                          className="h-2.5 w-2.5 flex-shrink-0 rounded-full"
                          style={{ backgroundColor: BAR_COLORS[i % BAR_COLORS.length] }}
                        />
                        <span className="font-medium text-slate-700">{r.label}</span>
                      </div>
                      <span className="text-slate-500">{r.count} votes ({r.percentage}%)</span>
                    </div>
                    <div className="h-6 w-full overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{
                          width: `${r.percentage}%`,
                          backgroundColor: BAR_COLORS[i % BAR_COLORS.length],
                          minWidth: r.percentage > 0 ? '4px' : '0',
                        }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-center text-sm text-slate-400">No votes cast yet.</p>
            )}

            {/* Actions row */}
            <div className="flex flex-wrap items-center gap-3 border-t border-slate-100 pt-4">

              {/* Publish Results toggle */}
              <label className="flex cursor-pointer items-center gap-2 select-none">
                <div className="relative">
                  <input
                    type="checkbox"
                    checked={resultsPublished}
                    onChange={e => setResultsPublished(e.target.checked)}
                    className="sr-only"
                  />
                  <div className={`h-5 w-9 rounded-full transition-colors ${resultsPublished ? 'bg-emerald-500' : 'bg-slate-300'}`} />
                  <div className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-transform ${resultsPublished ? 'translate-x-4' : 'translate-x-0.5'}`} />
                </div>
                <span className="text-sm font-medium text-slate-700">
                  {resultsPublished ? 'Published' : 'Publish Results'}
                </span>
              </label>

              {/* Close vote (if still active) */}
              {resultsVote.status === 'active' && (
                <button
                  onClick={() => setCloseFromResults(true)}
                  className="ml-auto flex items-center gap-1.5 rounded-lg bg-red-50 px-3 py-2 text-sm font-medium text-red-700 hover:bg-red-100"
                >
                  <XCircle size={14} /> Close Vote
                </button>
              )}
            </div>
          </div>
        )}
      </Modal>

      {/* ── Close Vote Confirm (from table row) ──────────────────────── */}
      <ConfirmDialog
        open={!!closeTarget && !closeFromResults}
        onClose={() => setCloseTarget(null)}
        onConfirm={handleCloseVote}
        title="Close Vote Early"
        message={`Are you sure you want to close "${closeTarget?.title}"? Results will be finalized and posted to #announcements.`}
        confirmLabel="Close Vote"
        variant="danger"
      />

      {/* ── Close Vote Confirm (from results modal) ───────────────────── */}
      <ConfirmDialog
        open={closeFromResults}
        onClose={() => setCloseFromResults(false)}
        onConfirm={handleCloseVote}
        title="Close Vote Early"
        message={`Are you sure you want to close "${resultsVote?.title}"? Results will be finalized and posted to #announcements.`}
        confirmLabel="Close Vote"
        variant="danger"
      />
    </div>
  )
}
