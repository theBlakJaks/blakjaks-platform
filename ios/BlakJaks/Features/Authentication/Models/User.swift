import Foundation

struct UserProfile: Codable, Identifiable {
    let id: Int
    let email: String
    let fullName: String
    let memberId: String
    let tier: String
    let avatarUrl: String?
    let bio: String?
    let walletBalance: Double
    let pendingBalance: Double
    let goldChips: Int
    let lifetimeUsdt: Double
    let scansThisQuarter: Int
    let isAffiliate: Bool
    let createdAt: String
}
