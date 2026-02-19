'use client'

import { useState, useEffect } from 'react'
import { Vote as VoteIcon, FileText, Info, CheckCircle, Clock, Trophy } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'
import type { Vote, Proposal, Tier } from '@/lib/types'
import Card from '@/components/ui/Card'
import Tabs from '@/components/ui/Tabs'
import GoldButton from '@/components/ui/GoldButton'
import Modal from '@/components/ui/Modal'
import TierBadge from '@/components/ui/TierBadge'
import Badge from '@/components/ui/Badge'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Spinner from '@/components/ui/Spinner'
import { toast } from '@/components/ui/Toast'

const VOTING_RULES: { category: string; tierRequired: Tier }[] = [
  { category: 'New Product Flavors', tierRequired: 'vip' },
  { category: 'New Product Ideas', tierRequired: 'high_roller' },
  { category: 'Loyalty Program Topics', tierRequired: 'high_roller' },
  { category: 'Corporate Governance', tierRequired: 'whale' },
]

const TABS = [
  { id: 'active', label: 'Active Votes' },
  { id: 'past', label: 'Past Votes' },
  { id: 'proposals', label: 'Submit Proposal' },
]

function getCountdown(deadline: string): string {
  const diff = new Date(deadline).getTime() - Date.now()
  if (diff <= 0) return 'Voting ended'
  const days = Math.floor(diff / 86400000)
  const hours = Math.floor((diff % 86400000) / 3600000)
  const mins = Math.floor((diff % 3600000) / 60000)
  if (days > 0) return `${days}d ${hours}h remaining`
  if (hours > 0) return `${hours}h ${mins}m remaining`
  return `${mins}m remaining`
}

export default function GovernancePage() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState('active')
  const [votes, setVotes] = useState<Vote[]>([])
  const [proposals, setProposals] = useState<Proposal[]>([])
  const [loading, setLoading] = useState(true)
  const [voteModalOpen, setVoteModalOpen] = useState(false)
  const [selectedVote, setSelectedVote] = useState<Vote | null>(null)
  const [selectedOption, setSelectedOption] = useState<string>('')
  const [castingVote, setCastingVote] = useState(false)

  // Proposal form
  const [proposalTitle, setProposalTitle] = useState('')
  const [proposalDescription, setProposalDescription] = useState('')
  const [submittingProposal, setSubmittingProposal] = useState(false)
  const [proposalSubmitted, setProposalSubmitted] = useState(false)

  // Info tooltip
  const [showRules, setShowRules] = useState(false)

  const userTier = user?.tier || 'standard'
  const isWhale = userTier === 'whale'

  useEffect(() => {
    api.governance.getVotes().then(({ votes: v, proposals: p }) => {
      setVotes(v)
      setProposals(p)
      setLoading(false)
    })
  }, [])

  const activeVotes = votes.filter(v => v.status === 'active')
  const pastVotes = votes.filter(v => v.status === 'closed')

  const openVoteModal = (vote: Vote) => {
    setSelectedVote(vote)
    setSelectedOption(vote.userVote || '')
    setVoteModalOpen(true)
  }

  const handleCastVote = async () => {
    if (!selectedVote || !selectedOption) return
    setCastingVote(true)
    await api.governance.castVote(selectedVote.id, selectedOption)

    setVotes(prev => prev.map(v => {
      if (v.id !== selectedVote.id) return v
      const opts = v.options.map(o => {
        if (o.id === selectedOption && !v.userVote) return { ...o, votes: o.votes + 1 }
        if (o.id === v.userVote && v.userVote !== selectedOption) return { ...o, votes: o.votes - 1 }
        if (o.id === selectedOption && v.userVote && v.userVote !== selectedOption) return { ...o, votes: o.votes + 1 }
        return o
      })
      return {
        ...v,
        options: opts,
        userVote: selectedOption,
        totalVotes: v.userVote ? v.totalVotes : v.totalVotes + 1,
      }
    }))

    setCastingVote(false)
    setVoteModalOpen(false)
    toast('success', 'Your vote has been recorded!')
  }

  const handleSubmitProposal = async () => {
    if (!proposalTitle.trim() || !proposalDescription.trim()) return
    setSubmittingProposal(true)
    await api.governance.submitProposal({ title: proposalTitle, description: proposalDescription })
    setSubmittingProposal(false)
    setProposalSubmitted(true)
    setProposalTitle('')
    setProposalDescription('')
    toast('success', 'Proposal submitted for admin review')
  }

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Governance</h1>
          <p className="text-sm text-[var(--color-text-muted)]">Vote on proposals and shape the future of BlakJaks</p>
        </div>
        <div className="relative">
          <button
            onMouseEnter={() => setShowRules(true)}
            onMouseLeave={() => setShowRules(false)}
            className="flex items-center gap-1.5 text-sm text-[var(--color-text-muted)] hover:text-white transition-colors"
          >
            <Info size={16} />
            Voting Eligibility
          </button>
          {showRules && (
            <div className="absolute right-0 top-8 z-50 w-72 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-4 shadow-xl">
              <h4 className="text-sm font-semibold text-white mb-3">Voting Eligibility by Tier</h4>
              <div className="space-y-2">
                {VOTING_RULES.map(rule => (
                  <div key={rule.category} className="flex items-center justify-between">
                    <span className="text-xs text-[var(--color-text-muted)]">{rule.category}</span>
                    <TierBadge tier={rule.tierRequired} size="sm" />
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      <Tabs tabs={TABS} activeTab={activeTab} onChange={setActiveTab} />

      {/* Active Votes */}
      {activeTab === 'active' && (
        <div className="space-y-4">
          {activeVotes.length === 0 ? (
            <Card>
              <div className="py-8 text-center text-[var(--color-text-dim)]">No active votes at this time</div>
            </Card>
          ) : (
            activeVotes.map(vote => {
              const maxVotes = Math.max(...vote.options.map(o => o.votes), 1)
              return (
                <Card key={vote.id}>
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="text-lg font-semibold text-white">{vote.title}</h3>
                      <p className="text-sm text-[var(--color-text-muted)] mt-1">{vote.description}</p>
                    </div>
                    <div className="flex items-center gap-1.5 text-xs text-[var(--color-text-dim)] shrink-0 ml-4">
                      <Clock size={14} />
                      {getCountdown(vote.deadline)}
                    </div>
                  </div>

                  <div className="space-y-3 mb-4">
                    {vote.options.map(opt => {
                      const pct = vote.totalVotes > 0 ? (opt.votes / vote.totalVotes) * 100 : 0
                      return (
                        <div key={opt.id}>
                          <div className="flex items-center justify-between text-sm mb-1">
                            <span className="text-[var(--color-text)]">{opt.label}</span>
                            <span className="text-[var(--color-text-dim)]">{opt.votes.toLocaleString()} ({pct.toFixed(1)}%)</span>
                          </div>
                          <div className="h-2 overflow-hidden rounded-full bg-[var(--color-border)]">
                            <div
                              className={`h-full rounded-full transition-all duration-500 ${opt.votes === maxVotes ? 'gold-gradient' : 'bg-[var(--color-text-dim)]/30'}`}
                              style={{ width: `${pct}%` }}
                            />
                          </div>
                        </div>
                      )
                    })}
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="text-sm">
                      {vote.userVote ? (
                        <span className="flex items-center gap-1.5 text-emerald-400">
                          <CheckCircle size={14} />
                          You voted: {vote.options.find(o => o.id === vote.userVote)?.label}
                        </span>
                      ) : (
                        <span className="text-[var(--color-text-dim)]">You haven&apos;t voted</span>
                      )}
                    </div>
                    <GoldButton size="sm" onClick={() => openVoteModal(vote)}>
                      {vote.userVote ? 'Change Vote' : 'Vote'}
                    </GoldButton>
                  </div>

                  <div className="mt-3 text-xs text-[var(--color-text-dim)]">
                    {vote.totalVotes.toLocaleString()} total votes
                  </div>
                </Card>
              )
            })
          )}
        </div>
      )}

      {/* Past Votes */}
      {activeTab === 'past' && (
        <div className="space-y-4">
          {pastVotes.length === 0 ? (
            <Card>
              <div className="py-8 text-center text-[var(--color-text-dim)]">No past votes</div>
            </Card>
          ) : (
            pastVotes.map(vote => {
              const maxVotes = Math.max(...vote.options.map(o => o.votes))
              const winner = vote.options.find(o => o.votes === maxVotes)

              return (
                <Card key={vote.id}>
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="text-lg font-semibold text-white">{vote.title}</h3>
                      <p className="text-sm text-[var(--color-text-muted)] mt-1">{vote.description}</p>
                    </div>
                    <Badge status="completed" />
                  </div>

                  <div className="space-y-3 mb-4">
                    {vote.options.map(opt => {
                      const pct = vote.totalVotes > 0 ? (opt.votes / vote.totalVotes) * 100 : 0
                      const isWinner = opt.id === winner?.id

                      return (
                        <div key={opt.id}>
                          <div className="flex items-center justify-between text-sm mb-1">
                            <span className={`flex items-center gap-1.5 ${isWinner ? 'text-[var(--color-gold)] font-medium' : 'text-[var(--color-text)]'}`}>
                              {isWinner && <Trophy size={14} />}
                              {opt.label}
                            </span>
                            <span className="text-[var(--color-text-dim)]">{opt.votes.toLocaleString()} ({pct.toFixed(1)}%)</span>
                          </div>
                          <div className="h-2 overflow-hidden rounded-full bg-[var(--color-border)]">
                            <div
                              className={`h-full rounded-full transition-all duration-500 ${isWinner ? 'gold-gradient' : 'bg-[var(--color-text-dim)]/30'}`}
                              style={{ width: `${pct}%` }}
                            />
                          </div>
                        </div>
                      )
                    })}
                  </div>

                  <div className="flex items-center justify-between text-sm">
                    {vote.userVote ? (
                      <span className="flex items-center gap-1.5 text-[var(--color-text-muted)]">
                        <CheckCircle size={14} />
                        You voted: {vote.options.find(o => o.id === vote.userVote)?.label}
                      </span>
                    ) : (
                      <span className="text-[var(--color-text-dim)]">You did not vote</span>
                    )}
                    <span className="text-xs text-[var(--color-text-dim)]">{vote.totalVotes.toLocaleString()} total votes</span>
                  </div>
                </Card>
              )
            })
          )}
        </div>
      )}

      {/* Submit Proposal */}
      {activeTab === 'proposals' && (
        <div className="space-y-6">
          {isWhale ? (
            <Card>
              {proposalSubmitted ? (
                <div className="py-8 text-center">
                  <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-emerald-500/10">
                    <CheckCircle size={28} className="text-emerald-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-white mb-2">Proposal Submitted</h3>
                  <p className="text-sm text-[var(--color-text-muted)]">Your proposal has been submitted for admin review.</p>
                  <GoldButton variant="secondary" size="sm" className="mt-4" onClick={() => setProposalSubmitted(false)}>
                    Submit Another
                  </GoldButton>
                </div>
              ) : (
                <>
                  <h3 className="text-lg font-semibold text-white mb-4">Submit a Governance Proposal</h3>
                  <div className="space-y-4">
                    <Input
                      label="Proposal Title"
                      required
                      placeholder="e.g. Add subscription option for monthly auto-shipments"
                      value={proposalTitle}
                      onChange={e => setProposalTitle(e.target.value)}
                    />
                    <Textarea
                      label="Description"
                      required
                      placeholder="Describe your proposal in detail. Include the problem it solves and the expected benefits."
                      value={proposalDescription}
                      onChange={e => setProposalDescription(e.target.value)}
                      rows={6}
                    />
                    <GoldButton
                      onClick={handleSubmitProposal}
                      loading={submittingProposal}
                      disabled={!proposalTitle.trim() || !proposalDescription.trim()}
                    >
                      <FileText size={16} />
                      Submit Proposal
                    </GoldButton>
                  </div>
                </>
              )}
            </Card>
          ) : (
            <Card>
              <div className="py-8 text-center">
                <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-[var(--color-bg-surface)]">
                  <VoteIcon size={28} className="text-[var(--color-text-dim)]" />
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">Whale Tier Required</h3>
                <p className="text-sm text-[var(--color-text-muted)] mb-3">
                  Only Whale tier members can submit governance proposals.
                </p>
                <div className="inline-flex items-center gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-3">
                  <div>
                    <span className="text-xs text-[var(--color-text-dim)]">Your current tier</span>
                    <div className="mt-1"><TierBadge tier={userTier} /></div>
                  </div>
                  <div className="h-8 w-px bg-[var(--color-border)]" />
                  <div>
                    <span className="text-xs text-[var(--color-text-dim)]">Required tier</span>
                    <div className="mt-1"><TierBadge tier="whale" /></div>
                  </div>
                </div>
              </div>
            </Card>
          )}

          {/* Existing Proposals */}
          {proposals.length > 0 && (
            <div>
              <h3 className="text-lg font-semibold text-white mb-4">Recent Proposals</h3>
              <div className="space-y-3">
                {proposals.map(prop => (
                  <Card key={prop.id}>
                    <div className="flex items-start justify-between">
                      <div>
                        <h4 className="text-sm font-semibold text-white">{prop.title}</h4>
                        <p className="text-xs text-[var(--color-text-muted)] mt-1">{prop.description}</p>
                        <p className="text-xs text-[var(--color-text-dim)] mt-2">
                          Submitted by {prop.submittedBy}
                        </p>
                      </div>
                      <Badge status={prop.status} />
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Vote Modal */}
      <Modal open={voteModalOpen} onClose={() => setVoteModalOpen(false)} title={selectedVote?.title}>
        {selectedVote && (
          <div className="space-y-4">
            <p className="text-sm text-[var(--color-text-muted)]">{selectedVote.description}</p>

            <div className="space-y-2">
              {selectedVote.options.map(opt => (
                <label
                  key={opt.id}
                  className={`flex items-center gap-3 rounded-xl border px-4 py-3 cursor-pointer transition-colors ${
                    selectedOption === opt.id
                      ? 'border-[var(--color-gold)] bg-[var(--color-gold)]/5'
                      : 'border-[var(--color-border)] hover:border-[var(--color-border-light)]'
                  }`}
                >
                  <input
                    type="radio"
                    name="vote-option"
                    value={opt.id}
                    checked={selectedOption === opt.id}
                    onChange={() => setSelectedOption(opt.id)}
                    className="h-4 w-4 accent-[var(--color-gold)]"
                  />
                  <span className="text-sm text-[var(--color-text)]">{opt.label}</span>
                </label>
              ))}
            </div>

            <div className="flex items-center justify-between text-xs text-[var(--color-text-dim)]">
              <span>{getCountdown(selectedVote.deadline)}</span>
              <span>{selectedVote.totalVotes.toLocaleString()} votes cast</span>
            </div>

            <GoldButton
              fullWidth
              onClick={handleCastVote}
              loading={castingVote}
              disabled={!selectedOption}
            >
              <VoteIcon size={16} />
              Cast Vote
            </GoldButton>
          </div>
        )}
      </Modal>
    </div>
  )
}
