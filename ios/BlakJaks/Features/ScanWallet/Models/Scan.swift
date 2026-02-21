import Foundation

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

struct ScanResult: Codable {
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

struct TierProgress: Codable {
    let quarter: String
    let currentCount: Int
    let nextTier: String?
    let scansRequired: Int?
}

struct CompEarned: Codable {
    let id: String
    let amount: Double
    let status: String
    let requiresPayoutChoice: Bool
}

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
