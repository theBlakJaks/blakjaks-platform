import Foundation

// MARK: - API Response Models

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

// Login/signup API returns { user: {...}, tokens: {...} }
struct LoginResponse: Codable {
    let user: UserProfile
    let tokens: AuthTokens
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let first_name: String
    let last_name: String
    let birthdate: String
    let username: String
    let referral_code: String?
}

struct TokenRefreshRequest: Codable {
    let refresh_token: String
}

// /auth/refresh only returns a new access_token, not a new refresh_token
struct RefreshResponse: Codable {
    let accessToken: String
    let tokenType: String
}

// MARK: - APIClientProtocol

protocol APIClientProtocol {

    // Auth
    func login(email: String, password: String) async throws -> AuthTokens
    func signup(email: String, password: String, firstName: String, lastName: String, username: String, birthdate: String, referralCode: String?) async throws -> AuthTokens
    func logout() async throws
    func refreshToken(refreshToken: String) async throws -> AuthTokens
    func getIntercomToken() async throws -> IntercomToken

    // User / Profile
    func getMe() async throws -> UserProfile
    func updateProfile(fullName: String?, bio: String?) async throws -> UserProfile
    func uploadAvatar(imageData: Data, mimeType: String) async throws -> UserProfile
    func getMemberCard() async throws -> MemberCard

    // Insights
    func getInsightsOverview() async throws -> InsightsOverview
    func getInsightsTreasury() async throws -> InsightsTreasury
    func getInsightsSystems() async throws -> InsightsSystems
    func getInsightsComps() async throws -> InsightsComps
    func getInsightsPartners() async throws -> InsightsPartners
    func getInsightsFeed(limit: Int, offset: Int) async throws -> [ActivityFeedItem]

    // Scan & Wallet
    func submitScan(qrCode: String) async throws -> ScanResult
    func getScanHistory(limit: Int, offset: Int) async throws -> [Scan]
    func getWallet() async throws -> Wallet
    func getTransactions(limit: Int, offset: Int, statusFilter: String?) async throws -> [Transaction]
    func getCompVault() async throws -> CompVault
    func withdrawCrypto(address: String, amount: Double) async throws -> WithdrawalResult
    func submitPayoutChoice(compId: String, method: String) async throws -> CompPayoutResult

    // Dwolla ACH
    func getDwollaFundingSources() async throws -> [DwollaFundingSource]
    func createDwollaCustomer() async throws -> DwollaCustomer
    func getPlaidLinkToken() async throws -> PlaidLinkToken
    func linkBankAccount(publicToken: String, accountId: String) async throws -> DwollaFundingSource
    func withdrawToBank(amount: Double, fundingSourceId: String) async throws -> DwollaTransfer

    // Shop
    func getProducts(category: String?, limit: Int, offset: Int) async throws -> [Product]
    func getProduct(id: Int) async throws -> Product
    func getCart() async throws -> Cart
    func addToCart(productId: Int, quantity: Int) async throws -> Cart
    func updateCartItem(productId: Int, quantity: Int) async throws -> Cart
    func removeFromCart(productId: Int) async throws -> Cart
    func estimateTax(shippingAddress: ShippingAddress) async throws -> TaxEstimate
    func createOrder(shippingAddress: ShippingAddress, paymentToken: String) async throws -> Order

    // Notifications
    func getNotifications(typeFilter: String?, limit: Int, offset: Int) async throws -> [AppNotification]
    func markNotificationRead(id: Int) async throws
    func markAllNotificationsRead() async throws
    func getUnreadNotificationCount() async throws -> Int

    // Social
    func getChannels() async throws -> [Channel]
    func getLiveStreams() async throws -> [LiveStream]
    func getMessages(channelId: String, limit: Int, before: String?) async throws -> [ChatMessage]
    func sendMessage(channelId: String, content: String, mediaType: String?) async throws -> ChatMessage
    func translateMessage(messageId: String, targetLanguage: String) async throws -> TranslatedMessage
    func addReaction(messageId: String, emoji: String) async throws
    func removeReaction(messageId: String, emoji: String) async throws
    func getPinnedMessages(channelId: String) async throws -> [ChatMessage]

    // Governance
    func getActiveVotes() async throws -> [GovernanceVote]
    func getVoteDetail(id: String) async throws -> GovernanceVoteDetail
    func castBallot(voteId: String, selectedOption: String) async throws

    // Wholesale
    func submitWholesaleApplication(businessName: String, contactEmail: String, estimatedMonthlyVolume: Double) async throws
    func getWholesaleDashboard() async throws -> WholesaleDashboard
    func getWholesaleOrders(limit: Int, offset: Int) async throws -> [WholesaleOrder]
    func createWholesaleOrder(items: [WholesaleOrderItem]) async throws -> WholesaleOrder
    func getWholesaleChips() async throws -> WholesaleChips

    // Affiliate
    func getAffiliateDashboard() async throws -> AffiliateDashboard
    func getAffiliateDownline(limit: Int, offset: Int) async throws -> [AffiliateDownlineMember]
    func getAffiliateChips() async throws -> AffiliateChips
    func getAffiliatePayouts(limit: Int, offset: Int) async throws -> [AffiliatePayout]
    func getAffiliateReferralCode() async throws -> ReferralCode
}

// MARK: - Shared Model Types

struct IntercomToken: Codable {
    let appId: String
    let userId: String
    let userHash: String
}

struct MemberCard: Codable {
    let memberId: String
    let fullName: String
    let tier: String
    let joinDate: String
    let avatarUrl: String?
    let walletBalance: Double
}

struct ActivityFeedItem: Codable, Identifiable {
    let id: Int
    let type: String
    let description: String
    let amount: Double?
    let userId: Int?
    let createdAt: String
}

struct DwollaFundingSource: Codable, Identifiable {
    let id: String
    let name: String
    let bankName: String?
    let lastFour: String?
    let type: String
    let status: String
}

struct DwollaCustomer: Codable {
    let customerId: String
    let status: String
}

struct PlaidLinkToken: Codable {
    let linkToken: String
    let expiration: String
}

struct DwollaTransfer: Codable {
    let transferId: String
    let status: String
    let amount: Double
    let estimatedArrival: String
}

struct WithdrawalResult: Codable {
    let txHash: String
    let status: String
    let amount: Double
    let currency: String
}

struct ShippingAddress: Codable {
    let firstName: String
    let lastName: String
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let zip: String
    let country: String
}

struct TaxEstimate: Codable {
    let subtotal: Double
    let taxAmount: Double
    let taxRate: Double
    let total: Double
    let jurisdiction: String
}

struct Cart: Codable {
    let items: [CartItem]
    let subtotal: Double
    let itemCount: Int
}

struct CartItem: Codable, Identifiable {
    let id: Int
    let productId: Int
    let productName: String
    let imageUrl: String?
    let quantity: Int
    let unitPrice: Double
    let lineTotal: Double
}

struct AppNotification: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: String
    let data: [String: String]?
}

struct Channel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let tierRequired: String?
    let locked: Bool?
    let viewOnly: Bool?
    let roomType: String?
    let unreadCount: Int?
    let memberCount: Int?

    /// Whether this channel is locked for the current user.
    var isLocked: Bool { locked ?? (tierRequired != nil) }
    /// Whether this channel is view-only.
    var isViewOnly: Bool { viewOnly ?? false }
}

struct ReactionInfo: Codable, Hashable {
    let emoji: String
    let count: Int
    let users: [String]
}

struct ChatMessage: Codable, Identifiable, Hashable {
    let id: String
    let channelId: String
    let userId: String
    let username: String
    let avatarUrl: String?
    let userTier: String?
    let content: String
    let sequence: Int?
    let replyToId: String?
    let replyPreview: String?
    let reactions: [ReactionInfo]?
    let isPinned: Bool?
    let isSystem: Bool?
    let gifUrl: String?
    let originalLanguage: String?
    let createdAt: String
    var deliveryStatus: MessageDeliveryStatus?
    var idempotencyKey: String?

    /// Convenience: convert reactions array to dictionary {emoji: [usernames]}
    var reactionMap: [String: [String]] {
        guard let reactions else { return [:] }
        var map: [String: [String]] = [:]
        for r in reactions {
            map[r.emoji] = r.users
        }
        return map
    }
}

struct TranslatedMessage: Codable {
    let translatedText: String
    let sourceLang: String?
    let targetLang: String?
    let originalText: String?
}

struct GovernanceVote: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let voteType: String
    let tierEligibility: String
    let options: [String]
    let status: String
    let votingEndsAt: String
    let totalBallots: Int
}

struct GovernanceVoteDetail: Codable {
    let vote: GovernanceVote
    let userBallot: String?
    let resultsByOption: [String: Int]?
}

struct WholesaleDashboard: Codable {
    let businessName: String
    let status: String
    let totalOrderValue: Double
    let totalChipsEarned: Int
    let chipBalance: Int
    let pendingOrders: Int
}

struct WholesaleOrder: Codable, Identifiable {
    let id: Int
    let items: [WholesaleOrderItem]
    let totalAmount: Double
    let chipsEarned: Int
    let status: String
    let createdAt: String
}

struct WholesaleOrderItem: Codable {
    let productId: Int
    let productName: String
    let quantity: Int
    let unitPrice: Double
}

struct WholesaleChips: Codable {
    let balance: Int
    let lifetimeEarned: Int
    let pendingRedemption: Int
}

struct AffiliateDashboard: Codable {
    let referralCode: String
    let totalDownline: Int
    let activeDownline: Int
    let weeklyPool: Double
    let lifetimeEarnings: Double
    let chipBalance: Int
    let nextPayoutDate: String
    let sunsetEngineActive: Bool
}

struct AffiliateDownlineMember: Codable, Identifiable {
    let id: Int
    let fullName: String
    let tier: String
    let joinDate: String
    let scansThisQuarter: Int
    let activeStatus: Bool
}

struct AffiliateChips: Codable {
    let balance: Int
    let lifetimeEarned: Int
    let matchBonus: Double
}

struct AffiliatePayout: Codable, Identifiable {
    let id: Int
    let amount: Double
    let payoutDate: String
    let status: String
    let poolShare: Double
}

struct ReferralCode: Codable {
    let code: String
    let referralUrl: String
    let totalUses: Int
}

struct CompPayoutResult: Codable {
    let compId: String
    let method: String
    let status: String
    let amount: Double
}
