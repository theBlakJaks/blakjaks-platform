// ── Types ──

export interface CompMilestone {
  scan_count: number
  comp_type: string
  amount: number
}

export interface TierRequirement {
  tier: string
  min_quarterly_scans: number
}

export interface NewMemberComp {
  enabled: boolean
  amount: number
  frequency: string
}

export interface RateLimits {
  scan_rate_per_min: number
  chat_rate: Record<string, number>
}

export interface SystemSettings {
  comp_milestones: CompMilestone[]
  tier_requirements: TierRequirement[]
  new_member_comp: NewMemberComp
  rate_limits: RateLimits
}

export interface IntegrationStatus {
  id: string
  name: string
  description: string
  status: 'connected' | 'configured' | 'not_configured'
  last_synced: string | null
}

export interface AdminAccount {
  id: string
  email: string
  name: string
  role: string
  last_login: string | null
  status: string
}

export interface SecuritySettings {
  admins: AdminAccount[]
  ip_whitelist: string[]
  two_fa_enforced: boolean
  session_timeout_hours: number
}

export interface NotificationSetting {
  key: string
  label: string
  description: string
  enabled: boolean
}

// ── Mock Data ──

const MOCK_SYSTEM: SystemSettings = {
  comp_milestones: [
    { scan_count: 5, comp_type: 'guaranteed_5', amount: 5 },
    { scan_count: 10, comp_type: 'crypto_100', amount: 100 },
    { scan_count: 21, comp_type: 'casino_comp', amount: 250 },
    { scan_count: 50, comp_type: 'crypto_1k', amount: 1000 },
    { scan_count: 100, comp_type: 'trip', amount: 2500 },
  ],
  tier_requirements: [
    { tier: 'Standard', min_quarterly_scans: 0 },
    { tier: 'VIP', min_quarterly_scans: 7 },
    { tier: 'High Roller', min_quarterly_scans: 15 },
    { tier: 'Whale', min_quarterly_scans: 30 },
  ],
  new_member_comp: {
    enabled: true,
    amount: 5,
    frequency: 'monthly',
  },
  rate_limits: {
    scan_rate_per_min: 10,
    chat_rate: { Standard: 5, VIP: 10, 'High Roller': 20, Whale: 30 },
  },
}

const MOCK_INTEGRATIONS: IntegrationStatus[] = [
  { id: 'brevo', name: 'Brevo', description: 'Transactional & marketing email', status: 'connected', last_synced: new Date(Date.now() - 3600000).toISOString() },
  { id: 'agechecker', name: 'AgeChecker.net', description: 'Age verification service', status: 'configured', last_synced: new Date(Date.now() - 86400000).toISOString() },
  { id: 'kintsugi', name: 'Kintsugi', description: 'Sales tax calculation', status: 'configured', last_synced: new Date(Date.now() - 7200000).toISOString() },
  { id: 'infura', name: 'Infura', description: 'Polygon RPC provider (Amoy Testnet)', status: 'connected', last_synced: new Date(Date.now() - 300000).toISOString() },
  { id: 'intercom', name: 'Intercom', description: 'Customer support & messaging', status: 'connected', last_synced: new Date(Date.now() - 1800000).toISOString() },
  { id: 'oobit', name: 'Oobit', description: 'Crypto payment processing', status: 'not_configured', last_synced: null },
]

const MOCK_SECURITY: SecuritySettings = {
  admins: [
    { id: 'adm-1', email: 'josh@blakjaks.com', name: 'Josh D.', role: 'Super Admin', last_login: new Date(Date.now() - 600000).toISOString(), status: 'active' },
    { id: 'adm-2', email: 'sarah@blakjaks.com', name: 'Sarah J.', role: 'Admin', last_login: new Date(Date.now() - 86400000).toISOString(), status: 'active' },
    { id: 'adm-3', email: 'mike@blakjaks.com', name: 'Mike W.', role: 'Admin', last_login: new Date(Date.now() - 172800000).toISOString(), status: 'active' },
  ],
  ip_whitelist: ['192.168.1.0/24', '10.0.0.0/8'],
  two_fa_enforced: false,
  session_timeout_hours: 8,
}

const MOCK_NOTIFICATIONS: NotificationSetting[] = [
  { key: 'new_user', label: 'New User Signup', description: 'Get notified when a new user registers', enabled: true },
  { key: 'order_placed', label: 'Order Placed', description: 'Get notified when an order is placed', enabled: true },
  { key: 'comp_over_1000', label: 'Comp Awarded Over $1,000', description: 'Alert when a high-value comp is awarded', enabled: true },
  { key: 'failed_tx', label: 'Failed Transaction', description: 'Alert on failed blockchain transactions', enabled: true },
  { key: 'system_error', label: 'System Error', description: 'Alert on critical system errors', enabled: false },
  { key: 'weekly_summary', label: 'Weekly Summary', description: 'Receive a weekly performance digest', enabled: true },
]

// ── API Functions ──

export async function getSystemSettings(): Promise<SystemSettings> {
  return { ...MOCK_SYSTEM }
}

export async function updateSystemSettings(settings: Partial<SystemSettings>): Promise<SystemSettings> {
  Object.assign(MOCK_SYSTEM, settings)
  return { ...MOCK_SYSTEM }
}

export async function getIntegrations(): Promise<IntegrationStatus[]> {
  return [...MOCK_INTEGRATIONS]
}

export async function testConnection(integrationId: string): Promise<{ success: boolean; message: string }> {
  const integration = MOCK_INTEGRATIONS.find(i => i.id === integrationId)
  if (!integration) return { success: false, message: 'Integration not found' }
  if (integration.status === 'not_configured') {
    return { success: false, message: `${integration.name} is not configured. Add API keys first.` }
  }
  return { success: true, message: `${integration.name} connection successful` }
}

export async function getSecuritySettings(): Promise<SecuritySettings> {
  return { ...MOCK_SECURITY, admins: [...MOCK_SECURITY.admins], ip_whitelist: [...MOCK_SECURITY.ip_whitelist] }
}

export async function addAdmin(email: string): Promise<AdminAccount> {
  const newAdmin: AdminAccount = {
    id: `adm-${MOCK_SECURITY.admins.length + 1}`,
    email,
    name: email.split('@')[0],
    role: 'Admin',
    last_login: null,
    status: 'active',
  }
  MOCK_SECURITY.admins.push(newAdmin)
  return newAdmin
}

export async function updateSecuritySettings(settings: Partial<SecuritySettings>): Promise<SecuritySettings> {
  if (settings.ip_whitelist) MOCK_SECURITY.ip_whitelist = settings.ip_whitelist
  if (settings.two_fa_enforced !== undefined) MOCK_SECURITY.two_fa_enforced = settings.two_fa_enforced
  if (settings.session_timeout_hours !== undefined) MOCK_SECURITY.session_timeout_hours = settings.session_timeout_hours
  return getSecuritySettings()
}

export async function getNotificationSettings(): Promise<NotificationSetting[]> {
  return MOCK_NOTIFICATIONS.map(n => ({ ...n }))
}

export async function updateNotificationSettings(settings: NotificationSetting[]): Promise<void> {
  settings.forEach(s => {
    const idx = MOCK_NOTIFICATIONS.findIndex(n => n.key === s.key)
    if (idx >= 0) MOCK_NOTIFICATIONS[idx].enabled = s.enabled
  })
}
