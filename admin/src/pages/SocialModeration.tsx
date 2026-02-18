import { useCallback, useEffect, useState } from 'react'
import { AlertTriangle, VolumeX, Ban, Filter } from 'lucide-react'
import toast from 'react-hot-toast'
import StatsCard from '../components/StatsCard'
import Badge from '../components/Badge'
import LoadingSpinner from '../components/LoadingSpinner'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import ConfirmDialog from '../components/ConfirmDialog'
import { getSocialStats, getReports, getModerationLog, deleteMessage, muteUser, banUser, updateReportStatus } from '../api/social'
import { formatDateTime } from '../utils/formatters'
import type { ChatReport, SocialStats, ModerationLogEntry } from '../types'

const TABS = ['Reports', 'Moderation Log'] as const
type Tab = typeof TABS[number]

const MUTE_DURATIONS = [
  { value: 60, label: '1 Hour' },
  { value: 1440, label: '24 Hours' },
  { value: 10080, label: '7 Days' },
  { value: 0, label: 'Custom' },
]

const ACTION_LABELS: Record<string, string> = {
  message_deleted: 'Message Deleted',
  user_muted: 'User Muted',
  user_banned: 'User Banned',
  message_pinned: 'Message Pinned',
}

export default function SocialModeration() {
  const [tab, setTab] = useState<Tab>('Reports')
  const [stats, setStats] = useState<SocialStats | null>(null)
  const [loading, setLoading] = useState(true)

  // Reports state
  const [reports, setReports] = useState<ChatReport[]>([])
  const [reportStatus, setReportStatus] = useState('')
  const [expandedMsg, setExpandedMsg] = useState<string | null>(null)

  // Moderation log state
  const [modLog, setModLog] = useState<ModerationLogEntry[]>([])
  const [modTotal, setModTotal] = useState(0)
  const [modPage, setModPage] = useState(1)
  const [actionFilter, setActionFilter] = useState('')

  // Action modals
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [muteOpen, setMuteOpen] = useState(false)
  const [banOpen, setBanOpen] = useState(false)
  const [activeReport, setActiveReport] = useState<ChatReport | null>(null)
  const [muteDuration, setMuteDuration] = useState(1440)
  const [customMinutes, setCustomMinutes] = useState('')
  const [muteReason, setMuteReason] = useState('')

  const fetchData = useCallback(async () => {
    setLoading(true)
    const [statsRes, reportsRes] = await Promise.all([
      getSocialStats(),
      getReports(reportStatus || undefined),
    ])
    setStats(statsRes)
    setReports(reportsRes)
    setLoading(false)
  }, [reportStatus])

  const fetchModLog = useCallback(async () => {
    const res = await getModerationLog(actionFilter || undefined, modPage)
    setModLog(res.items)
    setModTotal(res.total)
  }, [actionFilter, modPage])

  useEffect(() => { fetchData() }, [fetchData])
  useEffect(() => { if (tab === 'Moderation Log') fetchModLog() }, [tab, fetchModLog])

  const openAction = (report: ChatReport, action: 'delete' | 'mute' | 'ban') => {
    setActiveReport(report)
    if (action === 'delete') setDeleteOpen(true)
    else if (action === 'mute') { setMuteOpen(true); setMuteReason(report.reason) }
    else setBanOpen(true)
  }

  const handleDelete = async () => {
    if (!activeReport) return
    try {
      await deleteMessage(activeReport.message_id)
      await updateReportStatus(activeReport.id, 'resolved')
      toast.success('Message deleted and report resolved')
      fetchData()
    } catch { toast.error('Failed to delete message') }
  }

  const handleMute = async () => {
    if (!activeReport) return
    const minutes = muteDuration === 0 ? parseInt(customMinutes) || 60 : muteDuration
    try {
      await muteUser(activeReport.reported_user_id, null, minutes, muteReason)
      await updateReportStatus(activeReport.id, 'resolved')
      toast.success(`User muted for ${minutes >= 1440 ? `${Math.round(minutes / 1440)} day(s)` : `${minutes} min`}`)
      setMuteOpen(false)
      fetchData()
    } catch { toast.error('Failed to mute user') }
  }

  const handleBan = async () => {
    if (!activeReport) return
    try {
      await banUser(activeReport.reported_user_id, activeReport.reason)
      await updateReportStatus(activeReport.id, 'resolved')
      toast.success('User permanently banned')
      fetchData()
    } catch { toast.error('Failed to ban user') }
  }

  const handleDismiss = async (report: ChatReport) => {
    try {
      await updateReportStatus(report.id, 'dismissed')
      toast.success('Report dismissed')
      fetchData()
    } catch { toast.error('Failed to dismiss report') }
  }

  const modTotalPages = Math.ceil(modTotal / 20)

  return (
    <div className="space-y-6">
      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
          <StatsCard icon={AlertTriangle} label="Pending Reports" value={String(stats.pending_reports)} />
          <StatsCard icon={VolumeX} label="Users Muted" value={String(stats.active_mutes)} />
          <StatsCard icon={Ban} label="Users Banned" value={String(stats.banned_users)} />
        </div>
      )}

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

      {tab === 'Reports' && (
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            <Filter size={16} className="text-slate-400" />
            <select
              value={reportStatus}
              onChange={(e) => setReportStatus(e.target.value)}
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
            >
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="resolved">Resolved</option>
              <option value="dismissed">Dismissed</option>
            </select>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
          ) : reports.length === 0 ? (
            <EmptyState title="No reports" message="No reports match your filter." />
          ) : (
            <div className="overflow-hidden rounded-xl bg-white shadow-sm">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 bg-slate-50">
                    <th className="px-4 py-3 font-medium text-slate-600">Reporter</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Reported User</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Message</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Channel</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Reason</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Reported</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map(r => (
                    <tr key={r.id} className="border-b border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 text-slate-700">{r.reporter_name}</td>
                      <td className="px-4 py-3 font-medium text-slate-900">{r.reported_user_name}</td>
                      <td className="max-w-xs px-4 py-3">
                        <button
                          onClick={() => setExpandedMsg(expandedMsg === r.id ? null : r.id)}
                          className="text-left text-sm text-slate-600 hover:text-slate-900"
                        >
                          {expandedMsg === r.id ? r.message_content : r.message_content.length > 50 ? `${r.message_content.slice(0, 50)}...` : r.message_content}
                        </button>
                      </td>
                      <td className="px-4 py-3 text-slate-500">#{r.channel_name}</td>
                      <td className="px-4 py-3 text-slate-600">{r.reason}</td>
                      <td className="px-4 py-3"><Badge label={r.status} /></td>
                      <td className="px-4 py-3 text-slate-500">{formatDateTime(r.created_at)}</td>
                      <td className="px-4 py-3">
                        {r.status === 'pending' ? (
                          <select
                            defaultValue=""
                            onChange={(e) => {
                              const action = e.target.value
                              if (action === 'delete') openAction(r, 'delete')
                              else if (action === 'mute') openAction(r, 'mute')
                              else if (action === 'ban') openAction(r, 'ban')
                              else if (action === 'dismiss') handleDismiss(r)
                              e.target.value = ''
                            }}
                            className="rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-xs text-slate-700 outline-none"
                          >
                            <option value="" disabled>Resolve...</option>
                            <option value="delete">Delete Message</option>
                            <option value="mute">Mute User</option>
                            <option value="ban">Ban User</option>
                            <option value="dismiss">Dismiss</option>
                          </select>
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

      {tab === 'Moderation Log' && (
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            <Filter size={16} className="text-slate-400" />
            <select
              value={actionFilter}
              onChange={(e) => { setActionFilter(e.target.value); setModPage(1) }}
              className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 outline-none"
            >
              <option value="">All Actions</option>
              <option value="message_deleted">Message Deleted</option>
              <option value="user_muted">User Muted</option>
              <option value="user_banned">User Banned</option>
              <option value="message_pinned">Message Pinned</option>
            </select>
          </div>

          {modLog.length === 0 ? (
            <EmptyState title="No moderation actions" message="No actions match your filter." />
          ) : (
            <div className="overflow-hidden rounded-xl bg-white shadow-sm">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 bg-slate-50">
                    <th className="px-4 py-3 font-medium text-slate-600">Admin</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Action</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Target User</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Channel</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Details</th>
                    <th className="px-4 py-3 font-medium text-slate-600">Timestamp</th>
                  </tr>
                </thead>
                <tbody>
                  {modLog.map(e => (
                    <tr key={e.id} className="border-b border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 font-medium text-slate-900">{e.admin_name}</td>
                      <td className="px-4 py-3"><Badge label={ACTION_LABELS[e.action] || e.action} /></td>
                      <td className="px-4 py-3 text-slate-700">{e.target_user}</td>
                      <td className="px-4 py-3 text-slate-500">#{e.channel}</td>
                      <td className="px-4 py-3 text-slate-600">{e.details}</td>
                      <td className="px-4 py-3 text-slate-500">{formatDateTime(e.timestamp)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {modTotalPages > 1 && (
                <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
                  <span className="text-sm text-slate-500">Page {modPage} of {modTotalPages}</span>
                  <div className="flex gap-2">
                    <button onClick={() => setModPage(p => p - 1)} disabled={modPage <= 1} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Previous</button>
                    <button onClick={() => setModPage(p => p + 1)} disabled={modPage >= modTotalPages} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-40">Next</button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Delete Message Confirm */}
      <ConfirmDialog
        open={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        onConfirm={handleDelete}
        title="Delete Message"
        message={`Delete this message from ${activeReport?.reported_user_name}? This will also resolve the report.`}
        confirmLabel="Delete"
        variant="danger"
      />

      {/* Mute User Modal */}
      <Modal open={muteOpen} onClose={() => setMuteOpen(false)} title="Mute User">
        <div className="space-y-4">
          <p className="text-sm text-slate-600">
            Mute <strong>{activeReport?.reported_user_name}</strong> from all channels.
          </p>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Duration</label>
            <div className="grid grid-cols-2 gap-2">
              {MUTE_DURATIONS.map(d => (
                <button
                  key={d.value}
                  onClick={() => setMuteDuration(d.value)}
                  className={`rounded-lg border px-3 py-2 text-sm font-medium transition-colors ${
                    muteDuration === d.value ? 'border-indigo-500 bg-indigo-50 text-indigo-700' : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                  }`}
                >
                  {d.label}
                </button>
              ))}
            </div>
            {muteDuration === 0 && (
              <input
                type="number"
                value={customMinutes}
                onChange={(e) => setCustomMinutes(e.target.value)}
                placeholder="Minutes"
                className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
              />
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Reason</label>
            <input
              type="text"
              value={muteReason}
              onChange={(e) => setMuteReason(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setMuteOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button onClick={handleMute} className="rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700">Mute User</button>
          </div>
        </div>
      </Modal>

      {/* Ban User Confirm */}
      <ConfirmDialog
        open={banOpen}
        onClose={() => setBanOpen(false)}
        onConfirm={handleBan}
        title="Ban User"
        message={`This will permanently ban ${activeReport?.reported_user_name} from all channels. This action cannot be easily undone.`}
        confirmLabel="Ban User"
        variant="danger"
      />
    </div>
  )
}
