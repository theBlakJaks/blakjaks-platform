import client from './client'

// ── Types ────────────────────────────────────────────────────────────────────

export interface NodeHealth {
  api: string
  database: string
  redis: string
  polygon_node: string
  [key: string]: string
}

export interface ScanVelocity {
  scans_per_minute: number
  history?: number[]
}

export interface TierDistribution {
  [tier: string]: number
}

export interface SystemsHealth {
  scan_velocity: ScanVelocity
  node_health: NodeHealth
  teller_sync: {
    status: string
    last_sync?: string
    accounts_synced?: number
  }
  tier_distribution: TierDistribution
}

export interface SparklinePoint {
  timestamp?: string
  value: number
}

export interface PoolBalance {
  amount: number
  trend?: number
  currency?: string
}

export interface PoolBalances {
  consumer: PoolBalance
  affiliate: PoolBalance
  wholesale: PoolBalance
  [key: string]: PoolBalance
}

export interface BlockchainHealth {
  status: string
  block_lag?: number
  last_block?: number
}

export interface TreasuryInsights {
  pool_balances: PoolBalances
  bank_balances?: {
    [account: string]: number
  }
  sparklines?: {
    [pool: string]: SparklinePoint[]
  }
  blockchain_health: BlockchainHealth
}

export interface PrizeTiers {
  '100': number
  '1000': number
  '10000': number
  '200000': number
  [key: string]: number
}

export interface CompStats {
  prize_tiers: PrizeTiers
  total_comps_paid: number
  active_members: number
}

// ── API Functions ─────────────────────────────────────────────────────────────

export async function getSystemsHealth(): Promise<SystemsHealth> {
  const res = await client.get<SystemsHealth>('/insights/systems')
  return res.data
}

export async function getTreasuryInsights(): Promise<TreasuryInsights> {
  const res = await client.get<TreasuryInsights>('/insights/treasury')
  return res.data
}

export async function getCompStats(): Promise<CompStats> {
  const res = await client.get<CompStats>('/insights/comps')
  return res.data
}
