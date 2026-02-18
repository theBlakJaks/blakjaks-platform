import { useCallback, useEffect, useState } from 'react'
import { Plus, X, Filter } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import toast from 'react-hot-toast'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import { getVotes, getVoteResults, createVote, closeVote, getProposals, reviewProposal } from '../api/governance'
import { formatDate } from '../utils/formatters'
import { VOTE_TYPE_COLORS, VOTE_TYPE_MIN_TIER } from '../utils/constants'
import type { Vote, VoteResult, Proposal, VoteOption } from '../types'

const TABS = ['Votes', 'Proposals'] as const
type Tab = typeof TABS[number]

const BAR_COLORS = ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4']
const VOTE_TYPES = [
  { value: 'flavor', label: 'Flavor (VIP+)' },
  { value: 'product', label: 'Product (HR+)' },
  { value: 'loyalty', label: 'Loyalty (HR+)' },
  { value: 'corporate', label: 'Corporate (Whale only)' },
]

export default function Governance() {
  const [tab, setTab] = useState<Tab>('Votes')

  // Votes
  const [votes, setVotes] = useState<Vote[]>([])
  const [votesLoading, setVotesLoading] = useState(true)
  const [voteStatusFilter, setVoteStatusFilter] = useState('')
  const [voteTypeFilter, setVoteTypeFilter] = useState('')

  // Create vote modal
  const [createOpen, setCreateOpen] = useState(false)
  const [newTitle, setNewTitle] = useState('')
  const [newDesc, setNewDesc] = useState('')
  const [newType, setNewType] = useState('flavor')
  const [newOptions, setNewOptions] = useState<{ id: string; label: string }[]>([{ id: 'opt-1', label: '' }, { id: 'opt-2', label: '' }])
  const [newDuration, setNewDuration] = useState('7')
  const [creating, setCreating] = useState(false)

  // Results modal
  const [resultsVote, setResultsVote] = useState<Vote | null>(null)
  const [results, setResults] = useState<VoteResult[]>([])
  const [resultsLoading, setResultsLoading] = useState(false)

  // Close confirm
  const [closeTarget, setCloseTarget] = useState<Vote | null>(null)

  // Proposals
  const [proposals, setProposals] = useState<Proposal[]>([])
  const [proposalsLoading, setProposalsLoading] = useState(true)
  const [proposalStatusFilter, setProposalStatusFilter] = useState('')
  const [expandedProp, setExpandedProp] = useState<string | null>(null)

  // Review modal
  const [reviewTarget, setReviewTarget] = useState<Proposal | null>(null)
  const [reviewNotes, setReviewNotes] = useState('')
  const [reviewing, setReviewing] = useState(false)

  const fetchVotes = useCallback(async () => {
    setVotesLoading(true)
    const data = await getVotes(voteStatusFilter || undefined, voteTypeFilter || undefined)
    setVotes(data)
    setVotesLoading(false)
  }, [voteStatusFilter, voteTypeFilter])

  const fetchProposals = useCallback(async () => {
    setProposalsLoading(true)
    const data = await getProposals(proposalStatusFilter || undefined)
    setProposals(data)
    setProposalsLoading(false)
  }, [proposalStatusFilter])

  useEffect(() => { fetchVotes() }, [fetchVotes])
  useEffect(() => { if (tab === 'Proposals') fetchProposals() }, [tab, fetchProposals])

  const handleViewResults = async (vote: Vote) => {
    setResultsVote(vote)
    setResultsLoading(true)
    const data = await getVoteResults(vote.id)
    setResults(data)
    setResultsLoading(false)
  }

  const handleCreateVote = async () => {
    const validOptions = newOptions.filter(o => o.label.trim())
    if (!newTitle || !newDesc || validOptions.length < 2) {
      toast.error('Fill in all fields and at least 2 options')
      return
    }
    setCreating(true)
    try {
      const opts: VoteOption[] = validOptions.map((o, i) => ({ id: `opt-${i + 1}`, label: o.label.trim() }))
      await createVote(newTitle, newDesc, newType, opts, parseInt(newDuration))
      toast.success('Vote created')
      setCreateOpen(false)
      resetCreateForm()
      fetchVotes()
    } catch { toast.error('Failed to create vote') }
    finally { setCreating(false) }
  }

  const resetCreateForm = () => {
    setNewTitle(''); setNewDesc(''); setNewType('flavor')
    setNewOptions([{ id: 'opt-1', label: '' }, { id: 'opt-2', label: '' }])
    setNewDuration('7')
  }

  const handleCloseVote = async () => {
    if (!closeTarget) return
    try {
      await closeVote(closeTarget.id)
      toast.success('Vote closed')
      setCloseTarget(null)
      fetchVotes()
    } catch { toast.error('Failed to close vote') }
  }

  const handleReview = async (action: 'approve' | 'reject' | 'changes_requested') => {
    if (!reviewTarget) return
    if ((action === 'reject' || action === 'changes_requested') && !reviewNotes.trim()) {
      toast.error('Notes required for reject/changes requested')
      return
    }
    setReviewing(true)
    try {
      const res = await reviewProposal(reviewTarget.id, action, reviewNotes || undefined)
      toast.success(res.message)
      setReviewTarget(null)
      setReviewNotes('')
      fetchProposals()
    } catch { toast.error('Failed to review proposal') }
    finally { setReviewing(false) }
  }

  const addOption = () => setNewOptions(prev => [...prev, { id: `opt-${prev.length + 1}`, label: '' }])
  const removeOption = (idx: number) => setNewOptions(prev => prev.filter((_, i) => i !== idx))
  const updateOption = (idx: number, label: string) => setNewOptions(prev => prev.map((o, i) => i === idx ? { ...o, label } : o))

  const daysRemaining = (endDate: string) => {
    const diff = new Date(endDate).getTime() - Date.now()
    if (diff <= 0) return 'Ended'
    const days = Math.ceil(diff / 86400000)
    return `${days} day${days !== 1 ? 's' : ''} left`
  }

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="border-b border-slate-200">
        <nav className="-mb-px flex gap-6">
          {TABS.map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`border-b-2 pb-3 text-sm font-medium transition-colors ${
                tab === t ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700'
              }`}
            >
              {t}
            </button>
          ))}
        </nav>
      </div>

      {/* Votes Tab */}
      {tab === 'Votes' && (
        <div className="space-y-4">
          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={() => { resetCreateForm(); setCreateOpen(true) }}
              className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              <Plus size={16} /> Create New Vote
            </button>
            <div className="ml-auto flex items-center gap-3">
              <Filter size={16} className="text-slate-400" />
              <select value={voteStatusFilter} onChange={(e) => setVoteStatusFilter(e.target.value)} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
                <option value="">All Status</option>
                <option value="active">Active</option>
                <option value="closed">Closed</option>
                <option value="draft">Draft</option>
              </select>
              <select value={voteTypeFilter} onChange={(e) => setVoteTypeFilter(e.target.value)} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
                <option value="">All Types</option>
                {VOTE_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
              </select>
            </div>
          </div>

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
                    <th className="px-4 py-3 font-medium text-slate-600">Type</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Votes</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Eligible</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Start</th>
                    <th className="px-4 py-3 font-medium text-slate-600">End</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {votes.map(v => (
                    <tr key={v.id} className="border-b border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 font-medium text-slate-900">{v.title}</td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${VOTE_TYPE_COLORS[v.vote_type] || 'bg-slate-100 text-slate-800'}`}>
                          {v.vote_type}
                        </span>
                      </td>
                      <td className="px-4 py-3"><Badge label={v.status} /></td>
                      <td className="px-4 py-3 text-slate-700">{v.total_ballots}</td>
                      <td className="px-4 py-3"><Badge label={v.min_tier_required} variant="tier" /></td>
                      <td className="px-4 py-3 text-slate-500">{formatDate(v.start_date)}</td>
                      <td className="px-4 py-3 text-slate-500">{formatDate(v.end_date)}</td>
                      <td className="px-4 py-3">
                        <div className="flex gap-2">
                          <button onClick={() => handleViewResults(v)} className="rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50">Results</button>
                          {v.status === 'active' && (
                            <button onClick={() => setCloseTarget(v)} className="rounded-lg px-2.5 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50">Close</button>
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
      )}

      {/* Proposals Tab */}
      {tab === 'Proposals' && (
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            <Filter size={16} className="text-slate-400" />
            <select value={proposalStatusFilter} onChange={(e) => setProposalStatusFilter(e.target.value)} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none">
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
              <option value="changes_requested">Changes Requested</option>
            </select>
          </div>

          {proposalsLoading ? (
            <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
          ) : proposals.length === 0 ? (
            <EmptyState title="No proposals" message="No proposals match your filter." />
          ) : (
            <div className="overflow-hidden rounded-xl bg-white shadow-sm">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 bg-slate-50">
                    <th className="px-4 py-3 font-medium text-slate-600">Submitted By</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Title</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Description</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Type</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Submitted</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {proposals.map(p => (
                    <tr key={p.id} className="border-b border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-slate-900">{p.user_name}</span>
                          <Badge label="Whale" variant="tier" />
                        </div>
                      </td>
                      <td className="px-4 py-3 font-medium text-slate-900">{p.title}</td>
                      <td className="max-w-xs px-4 py-3">
                        <button
                          onClick={() => setExpandedProp(expandedProp === p.id ? null : p.id)}
                          className="text-left text-sm text-slate-600 hover:text-slate-900"
                        >
                          {expandedProp === p.id ? p.description : p.description.length > 60 ? `${p.description.slice(0, 60)}...` : p.description}
                        </button>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${VOTE_TYPE_COLORS[p.proposed_vote_type] || 'bg-slate-100 text-slate-800'}`}>
                          {p.proposed_vote_type}
                        </span>
                      </td>
                      <td className="px-4 py-3"><Badge label={p.status} /></td>
                      <td className="px-4 py-3 text-slate-500">{formatDate(p.created_at)}</td>
                      <td className="px-4 py-3">
                        {(p.status === 'pending' || p.status === 'changes_requested') ? (
                          <button onClick={() => { setReviewTarget(p); setReviewNotes('') }} className="rounded-lg px-2.5 py-1.5 text-xs font-medium text-indigo-600 hover:bg-indigo-50">Review</button>
                        ) : (
                          <span className="text-xs text-slate-400">-</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Create Vote Modal */}
      <Modal open={createOpen} onClose={() => setCreateOpen(false)} title="Create New Vote">
        <div className="max-h-[70vh] space-y-4 overflow-y-auto">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Title</label>
            <input type="text" value={newTitle} onChange={(e) => setNewTitle(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500" placeholder="Vote title" />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Description</label>
            <textarea value={newDesc} onChange={(e) => setNewDesc(e.target.value)} rows={3} className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500" placeholder="Describe what this vote is about" />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Vote Type</label>
            <select value={newType} onChange={(e) => setNewType(e.target.value)} className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500">
              {VOTE_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
            <p className="mt-1 text-xs text-slate-500">Eligible: {VOTE_TYPE_MIN_TIER[newType]}+ tier members</p>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Options</label>
            <div className="space-y-2">
              {newOptions.map((opt, i) => (
                <div key={opt.id} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={opt.label}
                    onChange={(e) => updateOption(i, e.target.value)}
                    placeholder={`Option ${i + 1}`}
                    className="flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-indigo-500"
                  />
                  {newOptions.length > 2 && (
                    <button onClick={() => removeOption(i)} className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-red-500"><X size={16} /></button>
                  )}
                </div>
              ))}
              <button onClick={addOption} className="text-sm font-medium text-indigo-600 hover:underline">+ Add option</button>
            </div>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Duration (days)</label>
            <input type="number" value={newDuration} onChange={(e) => setNewDuration(e.target.value)} min="1" max="90" className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500" />
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setCreateOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button onClick={handleCreateVote} disabled={creating} className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-40">
              {creating && <LoadingSpinner className="h-4 w-4" />} Create Vote
            </button>
          </div>
        </div>
      </Modal>

      {/* Vote Results Modal */}
      <Modal open={!!resultsVote} onClose={() => setResultsVote(null)} title={resultsVote?.title || 'Results'}>
        {resultsLoading ? (
          <div className="flex items-center justify-center py-8"><LoadingSpinner /></div>
        ) : resultsVote && (
          <div className="space-y-4">
            <p className="text-sm text-slate-600">{resultsVote.description}</p>
            <div className="flex items-center gap-3">
              <Badge label={resultsVote.status} />
              <span className="text-sm text-slate-500">
                {resultsVote.status === 'active' ? daysRemaining(resultsVote.end_date) : `Closed ${formatDate(resultsVote.end_date)}`}
              </span>
              <span className="text-sm font-medium text-slate-700">{resultsVote.total_ballots} total votes</span>
            </div>
            {results.length > 0 && (
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={results} layout="vertical" margin={{ left: 80 }}>
                  <XAxis type="number" domain={[0, 100]} tickFormatter={(v: number) => `${v}%`} tick={{ fontSize: 12 }} stroke="#94a3b8" />
                  <YAxis type="category" dataKey="label" tick={{ fontSize: 12 }} stroke="#94a3b8" width={80} />
                  <Tooltip formatter={(v) => `${v}%`} contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0' }} />
                  <Bar dataKey="percentage" radius={[0, 4, 4, 0]}>
                    {results.map((_, i) => <Cell key={i} fill={BAR_COLORS[i % BAR_COLORS.length]} />)}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
            <div className="space-y-1">
              {results.map((r, i) => (
                <div key={r.option_id} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <span className="h-3 w-3 rounded-full" style={{ backgroundColor: BAR_COLORS[i % BAR_COLORS.length] }} />
                    <span className="text-slate-700">{r.label}</span>
                  </div>
                  <span className="text-slate-600">{r.count} votes ({r.percentage}%)</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </Modal>

      {/* Close Vote Confirm */}
      <ConfirmDialog
        open={!!closeTarget}
        onClose={() => setCloseTarget(null)}
        onConfirm={handleCloseVote}
        title="Close Vote Early"
        message={`Are you sure you want to close "${closeTarget?.title}"? Results will be finalized and posted to #announcements.`}
        confirmLabel="Close Vote"
        variant="danger"
      />

      {/* Review Proposal Modal */}
      <Modal open={!!reviewTarget} onClose={() => setReviewTarget(null)} title="Review Proposal">
        {reviewTarget && (
          <div className="space-y-4">
            <div>
              <div className="flex items-center gap-2">
                <span className="font-medium text-slate-900">{reviewTarget.user_name}</span>
                <Badge label="Whale" variant="tier" />
              </div>
              <p className="mt-1 text-xs text-slate-500">{reviewTarget.user_email}</p>
            </div>
            <div>
              <h4 className="font-medium text-slate-900">{reviewTarget.title}</h4>
              <p className="mt-1 text-sm text-slate-600">{reviewTarget.description}</p>
            </div>
            <div className="flex gap-2">
              <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${VOTE_TYPE_COLORS[reviewTarget.proposed_vote_type] || 'bg-slate-100 text-slate-800'}`}>
                {reviewTarget.proposed_vote_type}
              </span>
              {reviewTarget.proposed_options && (
                <span className="text-xs text-slate-500">{reviewTarget.proposed_options.length} options proposed</span>
              )}
            </div>
            {reviewTarget.proposed_options && (
              <div className="rounded-lg bg-slate-50 p-3">
                <p className="mb-1 text-xs font-medium text-slate-500">Proposed Options:</p>
                <ul className="space-y-1">
                  {reviewTarget.proposed_options.map(o => (
                    <li key={o.id} className="text-sm text-slate-700">- {o.label}</li>
                  ))}
                </ul>
              </div>
            )}
            {reviewTarget.admin_notes && (
              <div className="rounded-lg border border-orange-200 bg-orange-50 p-3">
                <p className="text-xs font-medium text-orange-700">Previous Admin Notes:</p>
                <p className="mt-1 text-sm text-orange-800">{reviewTarget.admin_notes}</p>
              </div>
            )}
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Admin Notes</label>
              <textarea
                value={reviewNotes}
                onChange={(e) => setReviewNotes(e.target.value)}
                rows={3}
                placeholder="Required for reject/changes requested"
                className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
              />
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => setReviewTarget(null)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
              <button
                onClick={() => handleReview('changes_requested')}
                disabled={reviewing}
                className="rounded-lg bg-orange-50 px-4 py-2 text-sm font-medium text-orange-700 hover:bg-orange-100 disabled:opacity-40"
              >
                Request Changes
              </button>
              <button
                onClick={() => handleReview('reject')}
                disabled={reviewing}
                className="rounded-lg bg-red-50 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-100 disabled:opacity-40"
              >
                Reject
              </button>
              <button
                onClick={() => handleReview('approve')}
                disabled={reviewing}
                className="flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-40"
              >
                {reviewing && <LoadingSpinner className="h-4 w-4" />} Approve
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
