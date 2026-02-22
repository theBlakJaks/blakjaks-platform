import Foundation

enum MockUser {
    static let current = UserProfile(
        id: 1,
        email: "alex@example.com",
        fullName: "Alex Johnson",
        memberId: "BJ-0001-VIP",
        tier: "VIP",
        avatarUrl: nil,
        bio: "BlakJaks enthusiast since 2024.",
        walletBalance: 1250.75,
        pendingBalance: 85.00,
        goldChips: 42,
        lifetimeUsdt: 4820.50,
        scansThisQuarter: 67,
        isAffiliate: true,
        createdAt: "2024-01-15T10:00:00Z"
    )
}

// MARK: - MockData namespace

enum MockData {
    static let adminUser = UserProfile(
        id: 0,
        email: "admin@blakjaks.dev",
        fullName: "Dev Admin",
        memberId: "BJ-0000-DEV",
        tier: "Whale",
        avatarUrl: nil,
        bio: "Local development admin account.",
        walletBalance: 99999.99,
        pendingBalance: 0.00,
        goldChips: 999,
        lifetimeUsdt: 99999.99,
        scansThisQuarter: 999,
        isAffiliate: true,
        createdAt: "2024-01-01T00:00:00Z"
    )
}
