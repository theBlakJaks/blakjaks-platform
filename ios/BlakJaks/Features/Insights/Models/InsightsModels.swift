import Foundation

struct InsightsOverview: Codable {
    let globalScanCount: Int
    let activeMembers: Int
    let payoutsLast24h: Double
    let liveFeed: [ActivityFeedItem]
    let milestoneProgress: [MilestoneProgress]
}

struct MilestoneProgress: Codable, Identifiable {
    let id: String
    let label: String
    let current: Double
    let target: Double
    let percentage: Double
}

struct InsightsTreasury: Codable {
    let onChainBalances: [PoolBalance]
    let bankBalances: [BankBalance]
    let dwollaPlatformBalance: DwollaBalance
    let sparklines: [String: [SparklinePoint]]
    let reconciliationStatus: ReconciliationStatus
    let payoutLedger: [PayoutLedgerEntry]
}

struct PoolBalance: Codable, Identifiable {
    let id: String
    let poolType: String
    let balance: Double
    let currency: String
    let walletAddress: String
}

struct BankBalance: Codable, Identifiable {
    let id: String
    let accountName: String
    let institution: String
    let balance: Double
    let lastSyncAt: String
}

struct DwollaBalance: Codable {
    let available: Double
    let total: Double
    let currency: String
}

struct SparklinePoint: Codable {
    let timestamp: String
    let value: Double
}

struct ReconciliationStatus: Codable {
    let lastRunAt: String
    let status: String
    let variance: Double
    let tolerance: Double
}

struct PayoutLedgerEntry: Codable, Identifiable {
    let id: Int
    let amount: Double
    let type: String
    let recipientMemberId: String
    let status: String
    let createdAt: String
}

struct InsightsSystems: Codable {
    let compBudgetHealth: CompBudgetHealth
    let payoutPipelineQueueDepth: Int
    let payoutPipelineSuccessRate: Double
    let scanVelocity: ScanVelocity
    let polygonNodeStatus: NodeStatus
    let tellerLastSync: String
    let tierDistribution: [String: Int]
}

struct CompBudgetHealth: Codable {
    let totalBudget: Double
    let usedBudget: Double
    let remainingBudget: Double
    let percentUsed: Double
    let projectedExhaustionDate: String?
}

struct ScanVelocity: Codable {
    let perMinute: Double
    let perHour: Double
    let last60Min: [SparklinePoint]
}

struct NodeStatus: Codable {
    let connected: Bool
    let blockNumber: Int?
    let syncing: Bool
    let provider: String
}

struct InsightsComps: Codable {
    let tier100: CompTierStats
    let tier1k: CompTierStats
    let tier10k: CompTierStats
    let tier200kTrip: CompTierStats
    let milestoneProgress: [MilestoneProgress]
    let guaranteedCompTotals: GuaranteedCompTotals
    let vaultEconomy: VaultEconomy
}

struct CompTierStats: Codable {
    let totalPaid: Double
    let totalRecipients: Int
    let averagePayout: Double
    let periodLabel: String
}

struct GuaranteedCompTotals: Codable {
    let totalPaidThisYear: Double
    let totalRecipients: Int
    let nextRunDate: String
}

struct VaultEconomy: Codable {
    let totalInVaults: Double
    let avgVaultBalance: Double
    let goldChipsIssued: Int
}

struct InsightsPartners: Codable {
    let affiliateActiveCount: Int
    let sunsetEngineStatus: String
    let weeklyPool: Double
    let lifetimeMatchTotal: Double
    let permanentTierFloorCounts: [String: Int]
    let wholesaleActiveAccounts: Int
    let wholesaleOrderValueThisMonth: Double
}
