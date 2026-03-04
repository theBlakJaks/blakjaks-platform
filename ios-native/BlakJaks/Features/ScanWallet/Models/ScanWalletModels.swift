import Foundation

// MARK: - Wallet

struct Wallet: Codable {
    let compBalance: Double
    let availableBalance: Double
    let pendingBalance: Double
    let currency: String
    let linkedBankAccount: DwollaFundingSource?
    let address: String?
}

// MARK: - Scan

struct Scan: Codable, Identifiable {
    let id: Int
    let qrCode: String
    let productName: String
    let productSku: String
    let usdcEarned: Double
    let tierMultiplier: Double
    let tier: String
    let createdAt: String
}

// MARK: - ScanResult

struct ScanResult: Codable, Equatable {
    let success: Bool
    let productName: String
    let usdcEarned: Double
    let tierMultiplier: Double
    let tierProgress: TierProgress
    let compEarned: CompEarned?
    let milestoneHit: Bool
    let walletBalance: Double
    let globalScanCount: Int
}

struct TierProgress: Codable, Equatable {
    let quarter: String
    let currentCount: Int
    let nextTier: String?
    let scansRequired: Int?
}

struct CompEarned: Codable, Equatable {
    let id: String
    let amount: Double
    let status: String
    let requiresPayoutChoice: Bool
}

// MARK: - CompVault

struct CompVault: Codable {
    let availableBalance: Double
    let lifetimeComps: Double
    let goldChips: Int
    let milestones: [CompMilestone]
    let guaranteedComps: [GuaranteedComp]
}

struct CompMilestone: Codable, Identifiable {
    let id: String
    let threshold: Double
    let label: String
    let achieved: Bool
    let achievedAt: String?
}

struct GuaranteedComp: Codable, Identifiable {
    let id: Int
    let amount: Double
    let month: String
    let status: String
    let paidAt: String?
}

// MARK: - Transaction

struct Transaction: Codable, Identifiable {
    let id: Int
    let type: String
    let amount: Double
    let currency: String
    let status: String
    let description: String
    let createdAt: String
    let processedAt: String?
    let txHash: String?
}
