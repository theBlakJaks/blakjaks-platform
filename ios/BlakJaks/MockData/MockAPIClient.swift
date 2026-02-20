import Foundation

/// MockAPIClient — implements APIClientProtocol with hardcoded mock data.
/// Use this in SwiftUI Previews and unit tests.
/// Inject via: `FeatureViewModel(apiClient: MockAPIClient())`
final class MockAPIClient: APIClientProtocol {

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthTokens {
        return AuthTokens(accessToken: "mock-access-token", refreshToken: "mock-refresh-token", tokenType: "Bearer")
    }

    func signup(email: String, password: String, fullName: String, dateOfBirth: String) async throws -> AuthTokens {
        return AuthTokens(accessToken: "mock-access-token", refreshToken: "mock-refresh-token", tokenType: "Bearer")
    }

    func logout() async throws {}

    func refreshToken(refreshToken: String) async throws -> AuthTokens {
        return AuthTokens(accessToken: "mock-access-token-refreshed", refreshToken: refreshToken, tokenType: "Bearer")
    }

    func getIntercomToken() async throws -> IntercomToken {
        return IntercomToken(appId: "mock-app-id", userId: "1", userHash: "mock-hash")
    }

    // MARK: - User / Profile

    func getMe() async throws -> UserProfile {
        return MockUser.current
    }

    func updateProfile(fullName: String?, bio: String?) async throws -> UserProfile {
        return MockUser.current
    }

    func uploadAvatar(imageData: Data, mimeType: String) async throws -> UserProfile {
        return MockUser.current
    }

    func getMemberCard() async throws -> MemberCard {
        return MemberCard(
            memberId: "BJ-0001-VIP",
            fullName: "Alex Johnson",
            tier: "VIP",
            joinDate: "2024-01-15",
            avatarUrl: nil,
            walletBalance: 1250.75
        )
    }

    // MARK: - Insights

    func getInsightsOverview() async throws -> InsightsOverview {
        return MockInsights.overview
    }

    func getInsightsTreasury() async throws -> InsightsTreasury {
        return MockInsights.treasury
    }

    func getInsightsSystems() async throws -> InsightsSystems {
        return MockInsights.systems
    }

    func getInsightsComps() async throws -> InsightsComps {
        return MockInsights.comps
    }

    func getInsightsPartners() async throws -> InsightsPartners {
        return MockInsights.partners
    }

    func getInsightsFeed(limit: Int, offset: Int) async throws -> [ActivityFeedItem] {
        return MockInsights.feedItems
    }

    // MARK: - Scan & Wallet

    func submitScan(qrCode: String) async throws -> ScanResult {
        return MockScans.scanResult
    }

    func getScanHistory(limit: Int, offset: Int) async throws -> [Scan] {
        return MockScans.history
    }

    func getWallet() async throws -> Wallet {
        return MockTransactions.wallet
    }

    func getTransactions(limit: Int, offset: Int, statusFilter: String?) async throws -> [Transaction] {
        return MockTransactions.list
    }

    func getCompVault() async throws -> CompVault {
        return MockTransactions.compVault
    }

    func withdrawCrypto(address: String, amount: Double) async throws -> WithdrawalResult {
        return WithdrawalResult(
            txHash: "0xabc123",
            status: "pending",
            amount: amount,
            currency: "USDC"
        )
    }

    // MARK: - Dwolla

    func getDwollaFundingSources() async throws -> [DwollaFundingSource] {
        return [
            DwollaFundingSource(
                id: "mock-fs-id",
                name: "Chase Checking",
                bankName: "Chase",
                lastFour: "4242",
                type: "checking",
                status: "verified"
            )
        ]
    }

    func createDwollaCustomer() async throws -> DwollaCustomer {
        return DwollaCustomer(customerId: "mock-customer-id", status: "created")
    }

    func getPlaidLinkToken() async throws -> PlaidLinkToken {
        return PlaidLinkToken(linkToken: "mock-link-token", expiration: "2026-02-21T00:00:00Z")
    }

    func linkBankAccount(publicToken: String, accountId: String) async throws -> DwollaFundingSource {
        return DwollaFundingSource(
            id: "new-mock-fs-id",
            name: "Linked Bank",
            bankName: "Chase",
            lastFour: "5678",
            type: "checking",
            status: "verified"
        )
    }

    func withdrawToBank(amount: Double, fundingSourceId: String) async throws -> DwollaTransfer {
        return DwollaTransfer(
            transferId: "mock-transfer-id",
            status: "pending",
            amount: amount,
            estimatedArrival: "1–2 business days"
        )
    }

    // MARK: - Shop

    func getProducts(category: String?, limit: Int, offset: Int) async throws -> [Product] {
        return MockProducts.list
    }

    func getProduct(id: Int) async throws -> Product {
        return MockProducts.list[0]
    }

    func getCart() async throws -> Cart {
        return MockProducts.cart
    }

    func addToCart(productId: Int, quantity: Int) async throws -> Cart {
        return MockProducts.cart
    }

    func updateCartItem(productId: Int, quantity: Int) async throws -> Cart {
        return MockProducts.cart
    }

    func removeFromCart(productId: Int) async throws -> Cart {
        return Cart(items: [], subtotal: 0, itemCount: 0)
    }

    func estimateTax(shippingAddress: ShippingAddress) async throws -> TaxEstimate {
        return TaxEstimate(
            subtotal: 29.97,
            taxAmount: 2.70,
            taxRate: 0.09,
            total: 32.67,
            jurisdiction: "TX"
        )
    }

    func createOrder(shippingAddress: ShippingAddress, paymentToken: String) async throws -> Order {
        return MockProducts.order
    }

    // MARK: - Notifications

    func getNotifications(typeFilter: String?, limit: Int, offset: Int) async throws -> [AppNotification] {
        return [
            AppNotification(
                id: 1,
                type: "comp_earned",
                title: "Comp Earned!",
                body: "You earned $100 USDT — milestone reached.",
                isRead: false,
                createdAt: "2026-02-20T12:00:00Z",
                data: ["amount": "100"]
            ),
            AppNotification(
                id: 2,
                type: "tier_upgrade",
                title: "Tier Upgraded",
                body: "You've been upgraded to VIP tier.",
                isRead: true,
                createdAt: "2026-02-19T09:00:00Z",
                data: ["new_tier": "VIP"]
            )
        ]
    }

    func markNotificationRead(id: Int) async throws {}
    func markAllNotificationsRead() async throws {}

    func getUnreadNotificationCount() async throws -> Int {
        return 1
    }

    // MARK: - Social

    func getChannels() async throws -> [Channel] {
        return [
            Channel(id: 1, name: "General", category: "community", description: "Main community chat", memberCount: 1234, lastMessageAt: "2026-02-20T12:00:00Z"),
            Channel(id: 2, name: "Flavors", category: "governance", description: "Vote on new flavors", memberCount: 567, lastMessageAt: "2026-02-20T11:00:00Z"),
            Channel(id: 3, name: "VIP Lounge", category: "tier", description: "VIP+ exclusive chat", memberCount: 89, lastMessageAt: "2026-02-20T10:00:00Z")
        ]
    }

    func getMessages(channelId: Int, limit: Int, before: Int?) async throws -> [ChatMessage] {
        return [
            ChatMessage(id: 1, channelId: channelId, userId: 2, userFullName: "Alex J.", userAvatarUrl: nil, userTier: "VIP", content: "Welcome to BlakJaks!", mediaType: nil, mediaUrl: nil, reactionSummary: ["🔥": 3], createdAt: "2026-02-20T11:55:00Z")
        ]
    }

    func sendMessage(channelId: Int, content: String, mediaType: String?) async throws -> ChatMessage {
        return ChatMessage(id: Int.random(in: 1000...9999), channelId: channelId, userId: 1, userFullName: "You", userAvatarUrl: nil, userTier: "Standard", content: content, mediaType: mediaType, mediaUrl: nil, reactionSummary: nil, createdAt: "2026-02-20T12:01:00Z")
    }

    func translateMessage(messageId: Int, targetLanguage: String) async throws -> TranslatedMessage {
        return TranslatedMessage(translatedText: "Translated text here", sourceLanguage: "en", cached: false)
    }

    func addReaction(messageId: Int, emoji: String) async throws {}
    func removeReaction(messageId: Int, emoji: String) async throws {}

    // MARK: - Governance

    func getActiveVotes() async throws -> [GovernanceVote] {
        return [
            GovernanceVote(id: 1, title: "New Flavor: Mango Ice", description: "Should we add Mango Ice to the product line?", voteType: "flavor", tierEligibility: "vip", options: ["Yes, add it", "No thanks", "Maybe later"], status: "active", votingEndsAt: "2026-02-28T23:59:59Z", totalBallots: 45)
        ]
    }

    func getVoteDetail(id: Int) async throws -> GovernanceVoteDetail {
        let vote = GovernanceVote(id: id, title: "New Flavor: Mango Ice", description: "Should we add Mango Ice?", voteType: "flavor", tierEligibility: "vip", options: ["Yes, add it", "No thanks", "Maybe later"], status: "active", votingEndsAt: "2026-02-28T23:59:59Z", totalBallots: 45)
        return GovernanceVoteDetail(vote: vote, userBallot: nil, resultsByOption: nil)
    }

    func castBallot(voteId: Int, selectedOption: String) async throws {}

    // MARK: - Wholesale

    func submitWholesaleApplication(businessName: String, contactEmail: String, estimatedMonthlyVolume: Double) async throws {}

    func getWholesaleDashboard() async throws -> WholesaleDashboard {
        return WholesaleDashboard(businessName: "Mock Distributor LLC", status: "active", totalOrderValue: 45000, totalChipsEarned: 450, chipBalance: 120, pendingOrders: 2)
    }

    func getWholesaleOrders(limit: Int, offset: Int) async throws -> [WholesaleOrder] {
        return [
            WholesaleOrder(id: 1, items: [WholesaleOrderItem(productId: 1, productName: "BlakJaks Classic", quantity: 100, unitPrice: 12.99)], totalAmount: 1299, chipsEarned: 13, status: "fulfilled", createdAt: "2026-02-10T10:00:00Z")
        ]
    }

    func createWholesaleOrder(items: [WholesaleOrderItem]) async throws -> WholesaleOrder {
        return WholesaleOrder(id: 999, items: items, totalAmount: items.reduce(0) { $0 + $1.unitPrice * Double($1.quantity) }, chipsEarned: 10, status: "pending", createdAt: "2026-02-20T12:00:00Z")
    }

    func getWholesaleChips() async throws -> WholesaleChips {
        return WholesaleChips(balance: 120, lifetimeEarned: 450, pendingRedemption: 0)
    }

    // MARK: - Affiliate

    func getAffiliateDashboard() async throws -> AffiliateDashboard {
        return AffiliateDashboard(referralCode: "ALEX123", totalDownline: 42, activeDownline: 38, weeklyPool: 850.00, lifetimeEarnings: 4200.00, chipBalance: 210, nextPayoutDate: "2026-02-23", sunsetEngineActive: true)
    }

    func getAffiliateDownline(limit: Int, offset: Int) async throws -> [AffiliateDownlineMember] {
        return [
            AffiliateDownlineMember(id: 2, fullName: "Sam K.", tier: "VIP", joinDate: "2025-06-01", scansThisQuarter: 45, activeStatus: true),
            AffiliateDownlineMember(id: 3, fullName: "Jordan M.", tier: "Standard", joinDate: "2025-09-15", scansThisQuarter: 12, activeStatus: true)
        ]
    }

    func getAffiliateChips() async throws -> AffiliateChips {
        return AffiliateChips(balance: 210, lifetimeEarned: 780, matchBonus: 163.80)
    }

    func getAffiliatePayouts(limit: Int, offset: Int) async throws -> [AffiliatePayout] {
        return [
            AffiliatePayout(id: 1, amount: 250.00, payoutDate: "2026-02-16", status: "processed", poolShare: 0.062),
            AffiliatePayout(id: 2, amount: 180.00, payoutDate: "2026-02-09", status: "processed", poolShare: 0.048)
        ]
    }

    func getAffiliateReferralCode() async throws -> ReferralCode {
        return ReferralCode(code: "ALEX123", referralUrl: "https://blakjaks.com/ref/ALEX123", totalUses: 42)
    }
}
