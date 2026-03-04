import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    let firstName: String?
    let lastName: String?
    let birthdate: String?
    let phone: String?
    let avatarUrl: String?
    let walletAddress: String?
    let referralCode: String?
    let isActive: Bool
    let isAdmin: Bool
    let tier: TierInfo?
    let createdAt: String

    var displayName: String {
        let parts = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? username : parts.joined(separator: " ")
    }
}

struct TierInfo: Codable {
    let id: String
    let name: String
}
