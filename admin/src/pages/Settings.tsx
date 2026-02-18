import { useCallback, useEffect, useState } from 'react'
import { Plus, Trash2, Zap, Shield, Bell, Plug } from 'lucide-react'
import toast from 'react-hot-toast'
import LoadingSpinner from '../components/LoadingSpinner'
import Modal from '../components/Modal'
import {
  getSystemSettings, updateSystemSettings, getIntegrations, testConnection,
  getSecuritySettings, addAdmin, updateSecuritySettings,
  getNotificationSettings, updateNotificationSettings,
  type SystemSettings, type IntegrationStatus, type SecuritySettings, type NotificationSetting, type CompMilestone,
} from '../api/settings'
import { formatDateTime } from '../utils/formatters'

const TABS = ['System', 'Integrations', 'Security', 'Notifications'] as const
type Tab = typeof TABS[number]

const TAB_ICONS = { System: Zap, Integrations: Plug, Security: Shield, Notifications: Bell }

const INTEGRATION_STATUS_COLORS: Record<string, string> = {
  connected: 'bg-emerald-100 text-emerald-800',
  configured: 'bg-amber-100 text-amber-800',
  not_configured: 'bg-red-100 text-red-800',
}

const SESSION_OPTIONS = [
  { value: 1, label: '1 hour' },
  { value: 4, label: '4 hours' },
  { value: 8, label: '8 hours' },
  { value: 24, label: '24 hours' },
]

export default function Settings() {
  const [tab, setTab] = useState<Tab>('System')
  const [loading, setLoading] = useState(true)

  // System
  const [system, setSystem] = useState<SystemSettings | null>(null)
  const [editMilestones, setEditMilestones] = useState<CompMilestone[]>([])
  const [newMemberEnabled, setNewMemberEnabled] = useState(true)
  const [newMemberAmount, setNewMemberAmount] = useState(5)
  const [newMemberFreq, setNewMemberFreq] = useState('monthly')

  // Integrations
  const [integrations, setIntegrations] = useState<IntegrationStatus[]>([])
  const [testing, setTesting] = useState<string | null>(null)

  // Security
  const [security, setSecurity] = useState<SecuritySettings | null>(null)
  const [addAdminOpen, setAddAdminOpen] = useState(false)
  const [adminEmail, setAdminEmail] = useState('')
  const [ipInput, setIpInput] = useState('')
  const [twoFa, setTwoFa] = useState(false)
  const [sessionTimeout, setSessionTimeout] = useState(8)

  // Notifications
  const [notifications, setNotifications] = useState<NotificationSetting[]>([])

  const fetchTab = useCallback(async () => {
    setLoading(true)
    if (tab === 'System') {
      const data = await getSystemSettings()
      setSystem(data)
      setEditMilestones([...data.comp_milestones])
      setNewMemberEnabled(data.new_member_comp.enabled)
      setNewMemberAmount(data.new_member_comp.amount)
      setNewMemberFreq(data.new_member_comp.frequency)
    } else if (tab === 'Integrations') {
      setIntegrations(await getIntegrations())
    } else if (tab === 'Security') {
      const data = await getSecuritySettings()
      setSecurity(data)
      setTwoFa(data.two_fa_enforced)
      setSessionTimeout(data.session_timeout_hours)
    } else {
      setNotifications(await getNotificationSettings())
    }
    setLoading(false)
  }, [tab])

  useEffect(() => { fetchTab() }, [fetchTab])

  // ── System handlers ──

  const handleUpdateMilestone = (idx: number, field: keyof CompMilestone, val: string) => {
    const updated = [...editMilestones]
    if (field === 'comp_type') updated[idx] = { ...updated[idx], comp_type: val }
    else updated[idx] = { ...updated[idx], [field]: parseFloat(val) || 0 }
    setEditMilestones(updated)
  }

  const handleAddMilestone = () => {
    setEditMilestones([...editMilestones, { scan_count: 0, comp_type: 'guaranteed_5', amount: 5 }])
  }

  const handleRemoveMilestone = (idx: number) => {
    setEditMilestones(editMilestones.filter((_, i) => i !== idx))
  }

  const handleSaveSystem = async () => {
    try {
      await updateSystemSettings({
        comp_milestones: editMilestones,
        new_member_comp: { enabled: newMemberEnabled, amount: newMemberAmount, frequency: newMemberFreq },
      })
      toast.success('System settings saved')
    } catch { toast.error('Failed to save') }
  }

  // ── Integration handlers ──

  const handleTestConnection = async (id: string) => {
    setTesting(id)
    try {
      const res = await testConnection(id)
      if (res.success) toast.success(res.message)
      else toast.error(res.message)
    } catch { toast.error('Connection test failed') }
    setTesting(null)
  }

  // ── Security handlers ──

  const handleAddAdmin = async () => {
    if (!adminEmail || !adminEmail.includes('@')) { toast.error('Enter a valid email'); return }
    try {
      await addAdmin(adminEmail)
      toast.success(`Admin access granted to ${adminEmail}`)
      setAdminEmail('')
      setAddAdminOpen(false)
      fetchTab()
    } catch { toast.error('Failed to add admin') }
  }

  const handleAddIp = () => {
    if (!ipInput) return
    if (security) {
      const updated = [...security.ip_whitelist, ipInput]
      setSecurity({ ...security, ip_whitelist: updated })
      setIpInput('')
    }
  }

  const handleRemoveIp = (idx: number) => {
    if (security) {
      const updated = security.ip_whitelist.filter((_, i) => i !== idx)
      setSecurity({ ...security, ip_whitelist: updated })
    }
  }

  const handleSaveSecurity = async () => {
    try {
      await updateSecuritySettings({
        ip_whitelist: security?.ip_whitelist,
        two_fa_enforced: twoFa,
        session_timeout_hours: sessionTimeout,
      })
      toast.success('Security settings saved')
    } catch { toast.error('Failed to save') }
  }

  // ── Notification handlers ──

  const handleToggleNotification = (key: string) => {
    setNotifications(notifications.map(n => n.key === key ? { ...n, enabled: !n.enabled } : n))
  }

  const handleSaveNotifications = async () => {
    try {
      await updateNotificationSettings(notifications)
      toast.success('Notification settings saved')
    } catch { toast.error('Failed to save') }
  }

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="border-b border-slate-200">
        <nav className="-mb-px flex gap-6">
          {TABS.map(t => {
            const Icon = TAB_ICONS[t]
            return (
              <button key={t} onClick={() => setTab(t)} className={`flex items-center gap-2 border-b-2 pb-3 text-sm font-medium transition-colors ${tab === t ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700'}`}>
                <Icon size={16} /> {t}
              </button>
            )
          })}
        </nav>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16"><LoadingSpinner /></div>
      ) : (
        <>
          {/* ── System Tab ── */}
          {tab === 'System' && system && (
            <div className="space-y-6">
              {/* Comp Milestones */}
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between">
                  <h3 className="text-sm font-semibold text-slate-700">Comp Milestone Thresholds</h3>
                  <button onClick={handleAddMilestone} className="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50"><Plus size={14} /> Add</button>
                </div>
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-slate-100">
                      <th className="px-3 py-2 font-medium text-slate-600">Scan Count</th>
                      <th className="px-3 py-2 font-medium text-slate-600">Comp Type</th>
                      <th className="px-3 py-2 font-medium text-slate-600">Amount ($)</th>
                      <th className="px-3 py-2 font-medium text-slate-600"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {editMilestones.map((m, i) => (
                      <tr key={i} className="border-b border-slate-50">
                        <td className="px-3 py-2"><input type="number" value={m.scan_count} onChange={e => handleUpdateMilestone(i, 'scan_count', e.target.value)} className="w-20 rounded border border-slate-200 px-2 py-1 text-sm outline-none" /></td>
                        <td className="px-3 py-2"><input type="text" value={m.comp_type} onChange={e => handleUpdateMilestone(i, 'comp_type', e.target.value)} className="w-40 rounded border border-slate-200 px-2 py-1 text-sm outline-none" /></td>
                        <td className="px-3 py-2"><input type="number" value={m.amount} onChange={e => handleUpdateMilestone(i, 'amount', e.target.value)} className="w-24 rounded border border-slate-200 px-2 py-1 text-sm outline-none" /></td>
                        <td className="px-3 py-2"><button onClick={() => handleRemoveMilestone(i)} className="rounded p-1 text-slate-400 hover:bg-red-50 hover:text-red-500"><Trash2 size={14} /></button></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Tier Requirements (read only) */}
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">Tier Requirements (Read Only)</h3>
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                  {system.tier_requirements.map(t => (
                    <div key={t.tier} className="rounded-lg bg-slate-50 p-4 text-center">
                      <p className="text-xs text-slate-500">{t.tier}</p>
                      <p className="text-lg font-bold text-slate-900">{t.min_quarterly_scans}</p>
                      <p className="text-xs text-slate-400">quarterly scans</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* New Member Comp */}
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">New Member Guaranteed Comp</h3>
                <div className="flex flex-wrap items-center gap-6">
                  <label className="flex items-center gap-3">
                    <span className="text-sm text-slate-600">Enabled</span>
                    <button onClick={() => setNewMemberEnabled(!newMemberEnabled)} className={`relative h-6 w-11 rounded-full transition-colors ${newMemberEnabled ? 'bg-indigo-600' : 'bg-slate-300'}`}>
                      <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${newMemberEnabled ? 'left-[22px]' : 'left-0.5'}`} />
                    </button>
                  </label>
                  <div>
                    <label className="mb-1 block text-xs text-slate-500">Amount ($)</label>
                    <input type="number" value={newMemberAmount} onChange={e => setNewMemberAmount(parseFloat(e.target.value) || 0)} className="w-24 rounded border border-slate-200 px-2 py-1.5 text-sm outline-none" />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs text-slate-500">Frequency</label>
                    <select value={newMemberFreq} onChange={e => setNewMemberFreq(e.target.value)} className="rounded border border-slate-200 px-3 py-1.5 text-sm outline-none">
                      <option value="monthly">Monthly</option>
                      <option value="weekly">Weekly</option>
                      <option value="one-time">One-Time</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Rate Limits */}
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">Rate Limits</h3>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div className="rounded-lg bg-slate-50 p-4">
                    <p className="text-xs text-slate-500">Scan Rate</p>
                    <p className="text-lg font-bold text-slate-900">{system.rate_limits.scan_rate_per_min} / min</p>
                  </div>
                  {Object.entries(system.rate_limits.chat_rate).map(([tier, rate]) => (
                    <div key={tier} className="rounded-lg bg-slate-50 p-4">
                      <p className="text-xs text-slate-500">Chat Rate — {tier}</p>
                      <p className="text-lg font-bold text-slate-900">{rate} / min</p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex justify-end">
                <button onClick={handleSaveSystem} className="rounded-lg bg-indigo-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Save Changes</button>
              </div>
            </div>
          )}

          {/* ── Integrations Tab ── */}
          {tab === 'Integrations' && (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {integrations.map(integration => (
                <div key={integration.id} className="rounded-xl bg-white p-6 shadow-sm">
                  <div className="mb-3 flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-slate-900">{integration.name}</h3>
                    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${INTEGRATION_STATUS_COLORS[integration.status]}`}>
                      {integration.status.replace('_', ' ')}
                    </span>
                  </div>
                  <p className="mb-3 text-xs text-slate-500">{integration.description}</p>
                  {integration.last_synced && (
                    <p className="mb-4 text-xs text-slate-400">Last synced: {formatDateTime(integration.last_synced)}</p>
                  )}
                  <button
                    onClick={() => handleTestConnection(integration.id)}
                    disabled={testing === integration.id}
                    className="flex w-full items-center justify-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-40"
                  >
                    {testing === integration.id ? <LoadingSpinner className="h-3 w-3" /> : <Zap size={12} />}
                    Test Connection
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* ── Security Tab ── */}
          {tab === 'Security' && security && (
            <div className="space-y-6">
              {/* Admin Accounts */}
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between">
                  <h3 className="text-sm font-semibold text-slate-700">Admin Accounts</h3>
                  <button onClick={() => setAddAdminOpen(true)} className="flex items-center gap-1 rounded-lg bg-indigo-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-indigo-700"><Plus size={14} /> Add Admin</button>
                </div>
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-slate-100 bg-slate-50">
                      <th className="px-4 py-3 font-medium text-slate-600">Name</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Email</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Role</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Last Login</th>
                      <th className="px-4 py-3 font-medium text-slate-600">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {security.admins.map(a => (
                      <tr key={a.id} className="border-b border-slate-50 hover:bg-slate-50">
                        <td className="px-4 py-3 font-medium text-slate-900">{a.name}</td>
                        <td className="px-4 py-3 text-slate-600">{a.email}</td>
                        <td className="px-4 py-3 text-slate-600">{a.role}</td>
                        <td className="px-4 py-3 text-slate-500">{a.last_login ? formatDateTime(a.last_login) : 'Never'}</td>
                        <td className="px-4 py-3"><span className="inline-flex items-center rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800">{a.status}</span></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* IP Whitelist */}
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h3 className="mb-4 text-sm font-semibold text-slate-700">IP Whitelist</h3>
                <div className="mb-3 flex gap-2">
                  <input type="text" value={ipInput} onChange={e => setIpInput(e.target.value)} placeholder="192.168.1.0/24" className="flex-1 rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-indigo-500" />
                  <button onClick={handleAddIp} className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">Add</button>
                </div>
                <div className="space-y-2">
                  {security.ip_whitelist.map((ip, i) => (
                    <div key={i} className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-2">
                      <span className="font-mono text-sm text-slate-700">{ip}</span>
                      <button onClick={() => handleRemoveIp(i)} className="rounded p-1 text-slate-400 hover:bg-red-50 hover:text-red-500"><Trash2 size={14} /></button>
                    </div>
                  ))}
                </div>
              </div>

              {/* 2FA & Session */}
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">2FA Enforcement</h3>
                  <label className="flex items-center gap-3">
                    <button onClick={() => setTwoFa(!twoFa)} className={`relative h-6 w-11 rounded-full transition-colors ${twoFa ? 'bg-indigo-600' : 'bg-slate-300'}`}>
                      <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${twoFa ? 'left-[22px]' : 'left-0.5'}`} />
                    </button>
                    <span className="text-sm text-slate-600">{twoFa ? 'Enforced for all admins' : 'Not enforced'}</span>
                  </label>
                </div>

                <div className="rounded-xl bg-white p-6 shadow-sm">
                  <h3 className="mb-4 text-sm font-semibold text-slate-700">Session Timeout</h3>
                  <select value={sessionTimeout} onChange={e => setSessionTimeout(parseInt(e.target.value))} className="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm outline-none">
                    {SESSION_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                  </select>
                </div>
              </div>

              <div className="flex justify-end">
                <button onClick={handleSaveSecurity} className="rounded-lg bg-indigo-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Save Changes</button>
              </div>
            </div>
          )}

          {/* ── Notifications Tab ── */}
          {tab === 'Notifications' && (
            <div className="space-y-4">
              <div className="rounded-xl bg-white shadow-sm">
                {notifications.map((n, i) => (
                  <div key={n.key} className={`flex items-center justify-between px-6 py-4 ${i > 0 ? 'border-t border-slate-100' : ''}`}>
                    <div>
                      <p className="text-sm font-medium text-slate-900">{n.label}</p>
                      <p className="text-xs text-slate-500">{n.description}</p>
                    </div>
                    <button onClick={() => handleToggleNotification(n.key)} className={`relative h-6 w-11 rounded-full transition-colors ${n.enabled ? 'bg-indigo-600' : 'bg-slate-300'}`}>
                      <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${n.enabled ? 'left-[22px]' : 'left-0.5'}`} />
                    </button>
                  </div>
                ))}
              </div>
              <div className="flex justify-end">
                <button onClick={handleSaveNotifications} className="rounded-lg bg-indigo-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Save Changes</button>
              </div>
            </div>
          )}
        </>
      )}

      {/* Add Admin Modal */}
      <Modal open={addAdminOpen} onClose={() => setAddAdminOpen(false)} title="Add Admin">
        <div className="space-y-4">
          <p className="text-sm text-slate-500">Grant admin access to an existing user by email.</p>
          <input type="email" value={adminEmail} onChange={e => setAdminEmail(e.target.value)} placeholder="user@example.com" className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500" />
          <div className="flex justify-end gap-3">
            <button onClick={() => setAddAdminOpen(false)} className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50">Cancel</button>
            <button onClick={handleAddAdmin} className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">Grant Access</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
