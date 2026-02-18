'use client'

import { useState } from 'react'
import Card from '@/components/ui/Card'
import Input from '@/components/ui/Input'
import GoldButton from '@/components/ui/GoldButton'
import Tabs from '@/components/ui/Tabs'
import Select from '@/components/ui/Select'
import Spinner from '@/components/ui/Spinner'
import { useAuth } from '@/lib/auth-context'
import { api } from '@/lib/api'

const settingsTabs = [
  { id: 'account', label: 'Account' },
  { id: 'security', label: 'Security' },
  { id: 'notifications', label: 'Notifications' },
  { id: 'language', label: 'Language' },
]

const LANGUAGES = [
  { value: 'en', label: 'English' },
  { value: 'es', label: 'Spanish' },
  { value: 'fr', label: 'French' },
  { value: 'pt', label: 'Portuguese' },
  { value: 'ja', label: 'Japanese' },
  { value: 'ko', label: 'Korean' },
  { value: 'zh', label: 'Chinese' },
  { value: 'de', label: 'German' },
]

const NOTIFICATION_CATEGORIES = [
  { key: 'compAwards', label: 'Comp Awards' },
  { key: 'orderUpdates', label: 'Order Updates' },
  { key: 'socialMentions', label: 'Social Mentions' },
  { key: 'tierChanges', label: 'Tier Changes' },
  { key: 'governanceVotes', label: 'Governance Votes' },
]

const CHANNELS = ['push', 'email', 'sms'] as const

interface NotificationState {
  [key: string]: { push: boolean; email: boolean; sms: boolean }
}

function Toggle({ enabled, onChange }: { enabled: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!enabled)}
      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
        enabled ? 'bg-[var(--color-gold)]' : 'bg-[var(--color-border-light)]'
      }`}
    >
      <span
        className={`inline-block h-4 w-4 rounded-full bg-white transition-transform ${
          enabled ? 'translate-x-6' : 'translate-x-1'
        }`}
      />
    </button>
  )
}

export default function SettingsPage() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState('account')

  // Account state
  const [accountForm, setAccountForm] = useState({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    username: user?.username || '',
    email: user?.email || '',
    phone: user?.phone || '',
  })
  const [accountSaving, setAccountSaving] = useState(false)
  const [accountSuccess, setAccountSuccess] = useState(false)

  // Security state
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  })
  const [passwordSaving, setPasswordSaving] = useState(false)
  const [passwordSuccess, setPasswordSuccess] = useState(false)
  const [passwordError, setPasswordError] = useState('')
  const [twoFAEnabled, setTwoFAEnabled] = useState(false)
  const [twoFASaving, setTwoFASaving] = useState(false)

  // Notification state
  const [notifications, setNotifications] = useState<NotificationState>(
    Object.fromEntries(
      NOTIFICATION_CATEGORIES.map((cat) => [cat.key, { push: true, email: true, sms: false }])
    )
  )
  const [notifSaving, setNotifSaving] = useState(false)
  const [notifSuccess, setNotifSuccess] = useState(false)

  // Language state
  const [language, setLanguage] = useState('en')

  // Mock sessions
  const sessions = [
    { id: 's1', device: 'Chrome on macOS', lastActive: '2 minutes ago', current: true },
    { id: 's2', device: 'Safari on iPhone', lastActive: '1 hour ago', current: false },
    { id: 's3', device: 'Firefox on Windows', lastActive: '3 days ago', current: false },
  ]

  if (!user) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Spinner className="h-10 w-10" />
      </div>
    )
  }

  async function handleAccountSave() {
    setAccountSaving(true)
    setAccountSuccess(false)
    try {
      await api.settings.updateProfile(accountForm)
      setAccountSuccess(true)
      setTimeout(() => setAccountSuccess(false), 3000)
    } finally {
      setAccountSaving(false)
    }
  }

  async function handlePasswordSave() {
    setPasswordSaving(true)
    setPasswordError('')
    setPasswordSuccess(false)

    if (!passwordForm.currentPassword) { setPasswordError('Current password is required'); setPasswordSaving(false); return }
    if (!passwordForm.newPassword) { setPasswordError('New password is required'); setPasswordSaving(false); return }
    if (passwordForm.newPassword.length < 8) { setPasswordError('Password must be at least 8 characters'); setPasswordSaving(false); return }
    if (passwordForm.newPassword !== passwordForm.confirmPassword) { setPasswordError('Passwords do not match'); setPasswordSaving(false); return }

    try {
      await api.settings.updatePassword({
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
      })
      setPasswordSuccess(true)
      setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' })
      setTimeout(() => setPasswordSuccess(false), 3000)
    } catch {
      setPasswordError('Failed to update password')
    } finally {
      setPasswordSaving(false)
    }
  }

  async function handleToggle2FA() {
    setTwoFASaving(true)
    try {
      const result = await api.settings.update2FA({ enabled: !twoFAEnabled })
      setTwoFAEnabled(result.enabled)
    } finally {
      setTwoFASaving(false)
    }
  }

  async function handleNotifSave() {
    setNotifSaving(true)
    setNotifSuccess(false)
    try {
      const flat: Record<string, boolean> = {}
      for (const [key, val] of Object.entries(notifications)) {
        for (const ch of CHANNELS) {
          flat[`${key}_${ch}`] = val[ch]
        }
      }
      await api.settings.updateNotifications(flat)
      setNotifSuccess(true)
      setTimeout(() => setNotifSuccess(false), 3000)
    } finally {
      setNotifSaving(false)
    }
  }

  function updateNotification(category: string, channel: typeof CHANNELS[number], value: boolean) {
    setNotifications((prev) => ({
      ...prev,
      [category]: { ...prev[category], [channel]: value },
    }))
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Settings</h1>

      <Tabs tabs={settingsTabs} activeTab={activeTab} onChange={setActiveTab} />

      {/* Account Tab */}
      {activeTab === 'account' && (
        <Card>
          <h2 className="mb-6 text-lg font-semibold text-white">Account Information</h2>
          <div className="space-y-5 max-w-lg">
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
              <Input
                label="First Name"
                value={accountForm.firstName}
                onChange={(e) => setAccountForm((p) => ({ ...p, firstName: e.target.value }))}
              />
              <Input
                label="Last Name"
                value={accountForm.lastName}
                onChange={(e) => setAccountForm((p) => ({ ...p, lastName: e.target.value }))}
              />
            </div>
            <Input
              label="Username"
              value={accountForm.username}
              onChange={(e) => setAccountForm((p) => ({ ...p, username: e.target.value }))}
            />
            <Input
              label="Email"
              type="email"
              value={accountForm.email}
              onChange={(e) => setAccountForm((p) => ({ ...p, email: e.target.value }))}
            />
            <Input
              label="Phone"
              type="tel"
              value={accountForm.phone}
              onChange={(e) => setAccountForm((p) => ({ ...p, phone: e.target.value }))}
            />
            <div className="flex items-center gap-3">
              <GoldButton onClick={handleAccountSave} loading={accountSaving}>
                Save Changes
              </GoldButton>
              {accountSuccess && (
                <span className="text-sm text-emerald-400">Changes saved!</span>
              )}
            </div>
          </div>
        </Card>
      )}

      {/* Security Tab */}
      {activeTab === 'security' && (
        <div className="space-y-6">
          <Card>
            <h2 className="mb-6 text-lg font-semibold text-white">Change Password</h2>
            <div className="space-y-5 max-w-lg">
              {passwordError && (
                <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">
                  {passwordError}
                </div>
              )}
              <Input
                label="Current Password"
                type="password"
                value={passwordForm.currentPassword}
                onChange={(e) => setPasswordForm((p) => ({ ...p, currentPassword: e.target.value }))}
              />
              <Input
                label="New Password"
                type="password"
                placeholder="Min 8 characters"
                value={passwordForm.newPassword}
                onChange={(e) => setPasswordForm((p) => ({ ...p, newPassword: e.target.value }))}
              />
              <Input
                label="Confirm New Password"
                type="password"
                value={passwordForm.confirmPassword}
                onChange={(e) => setPasswordForm((p) => ({ ...p, confirmPassword: e.target.value }))}
              />
              <div className="flex items-center gap-3">
                <GoldButton onClick={handlePasswordSave} loading={passwordSaving}>
                  Update Password
                </GoldButton>
                {passwordSuccess && (
                  <span className="text-sm text-emerald-400">Password updated!</span>
                )}
              </div>
            </div>
          </Card>

          <Card>
            <h2 className="mb-4 text-lg font-semibold text-white">Two-Factor Authentication</h2>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[var(--color-text)]">
                  {twoFAEnabled ? '2FA is enabled' : '2FA is disabled'}
                </p>
                <p className="text-xs text-[var(--color-text-dim)]">
                  Use an authenticator app (TOTP) for additional security
                </p>
              </div>
              <GoldButton
                variant={twoFAEnabled ? 'danger' : 'secondary'}
                size="sm"
                onClick={handleToggle2FA}
                loading={twoFASaving}
              >
                {twoFAEnabled ? 'Disable' : 'Enable'}
              </GoldButton>
            </div>
          </Card>

          <Card>
            <h2 className="mb-4 text-lg font-semibold text-white">Active Sessions</h2>
            <div className="space-y-3">
              {sessions.map((session) => (
                <div key={session.id} className="flex items-center justify-between rounded-lg border border-[var(--color-border)]/50 px-4 py-3">
                  <div>
                    <p className="text-sm text-[var(--color-text)]">
                      {session.device}
                      {session.current && (
                        <span className="ml-2 rounded-full bg-emerald-500/20 px-2 py-0.5 text-xs text-emerald-400">Current</span>
                      )}
                    </p>
                    <p className="text-xs text-[var(--color-text-dim)]">Last active: {session.lastActive}</p>
                  </div>
                  {!session.current && (
                    <GoldButton variant="danger" size="sm">
                      Revoke
                    </GoldButton>
                  )}
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}

      {/* Notifications Tab */}
      {activeTab === 'notifications' && (
        <Card>
          <h2 className="mb-6 text-lg font-semibold text-white">Notification Preferences</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--color-border)]">
                  <th className="px-3 py-2.5 text-left text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">Category</th>
                  {CHANNELS.map((ch) => (
                    <th key={ch} className="px-3 py-2.5 text-center text-xs font-medium uppercase tracking-wider text-[var(--color-text-dim)]">{ch}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {NOTIFICATION_CATEGORIES.map((cat) => (
                  <tr key={cat.key} className="border-b border-[var(--color-border)]/50">
                    <td className="px-3 py-3 text-sm text-[var(--color-text)]">{cat.label}</td>
                    {CHANNELS.map((ch) => (
                      <td key={ch} className="px-3 py-3 text-center">
                        <Toggle
                          enabled={notifications[cat.key]?.[ch] ?? false}
                          onChange={(v) => updateNotification(cat.key, ch, v)}
                        />
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="mt-6 flex items-center gap-3">
            <GoldButton onClick={handleNotifSave} loading={notifSaving}>
              Save Preferences
            </GoldButton>
            {notifSuccess && (
              <span className="text-sm text-emerald-400">Preferences saved!</span>
            )}
          </div>
        </Card>
      )}

      {/* Language Tab */}
      {activeTab === 'language' && (
        <Card>
          <h2 className="mb-6 text-lg font-semibold text-white">Language Preferences</h2>
          <div className="max-w-sm space-y-4">
            <Select
              label="Preferred Language"
              options={LANGUAGES}
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
            />
            <p className="text-xs text-[var(--color-text-dim)]">
              This sets your default translation language for the Social Hub. Messages from other languages will be auto-translated to your selected language.
            </p>
            <GoldButton>Save Language</GoldButton>
          </div>
        </Card>
      )}
    </div>
  )
}
