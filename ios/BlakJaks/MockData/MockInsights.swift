import Foundation

enum MockInsights {
    static let overview = InsightsOverview(
        globalScanCount: 1_487_392,
        activeMembers: 8_241,
        payoutsLast24h: 12_450.75,
        liveFeed: feedItems,
        milestoneProgress: [
            MilestoneProgress(id: "active-members", label: "10K Members", current: 8241, target: 10000, percentage: 82.4),
            MilestoneProgress(id: "payouts", label: "$1M Payouts", current: 487320, target: 1000000, percentage: 48.7)
        ]
    )

    static let feedItems: [ActivityFeedItem] = [
        ActivityFeedItem(id: 1, type: "comp_earned", description: "BJ-0892-HR earned $100 milestone comp", amount: 100, userId: nil, createdAt: "2026-02-20T12:01:00Z"),
        ActivityFeedItem(id: 2, type: "tier_upgrade", description: "BJ-1204-ST upgraded to VIP", amount: nil, userId: nil, createdAt: "2026-02-20T11:58:00Z"),
        ActivityFeedItem(id: 3, type: "new_member", description: "New member BJ-8241-ST joined", amount: nil, userId: nil, createdAt: "2026-02-20T11:55:00Z"),
        ActivityFeedItem(id: 4, type: "payout", description: "ACH payout of $250 processed for BJ-0423-VIP", amount: 250, userId: nil, createdAt: "2026-02-20T11:50:00Z")
    ]

    static let treasury = InsightsTreasury(
        onChainBalances: [
            PoolBalance(id: "member", poolType: "member_treasury", balance: 245_820.50, currency: "USDC", walletAddress: "0x1234...5678"),
            PoolBalance(id: "affiliate", poolType: "affiliate_treasury", balance: 89_450.25, currency: "USDC", walletAddress: "0xabcd...ef12"),
            PoolBalance(id: "wholesale", poolType: "wholesale_treasury", balance: 55_200.00, currency: "USDC", walletAddress: "0x7890...abcd")
        ],
        bankBalances: [
            BankBalance(id: "operating", accountName: "Operating Account", institution: "Chase Business", balance: 125_000.00, lastSyncAt: "2026-02-20T06:00:00Z"),
            BankBalance(id: "reserve", accountName: "Reserve Account", institution: "Chase Business", balance: 500_000.00, lastSyncAt: "2026-02-20T06:00:00Z"),
            BankBalance(id: "comp", accountName: "Comp Pool Account", institution: "Chase Business", balance: 85_250.75, lastSyncAt: "2026-02-20T06:00:00Z")
        ],
        dwollaPlatformBalance: DwollaBalance(available: 42_150.50, total: 44_800.00, currency: "USD"),
        sparklines: [:],
        reconciliationStatus: ReconciliationStatus(lastRunAt: "2026-02-20T05:00:00Z", status: "ok", variance: 2.15, tolerance: 10.00),
        payoutLedger: []
    )

    static let systems = InsightsSystems(
        compBudgetHealth: CompBudgetHealth(totalBudget: 500_000, usedBudget: 87_320.50, remainingBudget: 412_679.50, percentUsed: 17.46, projectedExhaustionDate: nil),
        payoutPipelineQueueDepth: 12,
        payoutPipelineSuccessRate: 99.7,
        scanVelocity: ScanVelocity(perMinute: 42.3, perHour: 2538, last60Min: []),
        polygonNodeStatus: NodeStatus(connected: true, blockNumber: 57_923_841, syncing: false, provider: "Infura"),
        tellerLastSync: "2026-02-20T06:00:00Z",
        tierDistribution: ["Standard": 5820, "VIP": 1890, "High Roller": 412, "Whale": 119]
    )

    static let comps = InsightsComps(
        tier100: CompTierStats(totalPaid: 24_800, totalRecipients: 248, averagePayout: 100, periodLabel: "All Time"),
        tier1k: CompTierStats(totalPaid: 38_000, totalRecipients: 38, averagePayout: 1000, periodLabel: "All Time"),
        tier10k: CompTierStats(totalPaid: 50_000, totalRecipients: 5, averagePayout: 10000, periodLabel: "All Time"),
        tier200kTrip: CompTierStats(totalPaid: 0, totalRecipients: 0, averagePayout: 200000, periodLabel: "Not yet triggered"),
        milestoneProgress: overview.milestoneProgress,
        guaranteedCompTotals: GuaranteedCompTotals(totalPaidThisYear: 32_500, totalRecipients: 650, nextRunDate: "2026-03-01"),
        vaultEconomy: VaultEconomy(totalInVaults: 89_450.25, avgVaultBalance: 10.85, goldChipsIssued: 34_820)
    )

    static let partners = InsightsPartners(
        affiliateActiveCount: 284,
        sunsetEngineStatus: "active",
        weeklyPool: 4_200.00,
        lifetimeMatchTotal: 18_750.50,
        permanentTierFloorCounts: ["VIP": 42, "High Roller": 8],
        wholesaleActiveAccounts: 37,
        wholesaleOrderValueThisMonth: 142_800.00
    )
}
