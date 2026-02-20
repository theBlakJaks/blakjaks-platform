import Foundation

// APIClient — real implementation using URLSession (Alamofire added in Task I3)
// Stub here; full implementation with JWT RequestInterceptor in Task I3.
final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let baseURL: String
    private var accessToken: String? { KeychainManager.shared.getAccessToken() }

    private init() {
        self.baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "https://api.blakjaks.com"
    }

    // MARK: - Private helpers

    private func request<T: Decodable>(_ endpoint: APIEndpoint, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw APIError.unknown
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Server error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    // MARK: - Auth (stub — full implementation in Task I3)
    func login(email: String, password: String) async throws -> AuthTokens { throw APIError.unknown }
    func signup(email: String, password: String, fullName: String, dateOfBirth: String) async throws -> AuthTokens { throw APIError.unknown }
    func logout() async throws {}
    func refreshToken(refreshToken: String) async throws -> AuthTokens { throw APIError.unknown }
    func getIntercomToken() async throws -> IntercomToken { try await request(.intercomToken) }
    func getMe() async throws -> UserProfile { try await request(.me) }
    func updateProfile(fullName: String?, bio: String?) async throws -> UserProfile { try await request(.updateProfile, method: "PATCH") }
    func uploadAvatar(imageData: Data, mimeType: String) async throws -> UserProfile { throw APIError.unknown }
    func getMemberCard() async throws -> MemberCard { try await request(.memberCard) }
    func getInsightsOverview() async throws -> InsightsOverview { try await request(.insightsOverview) }
    func getInsightsTreasury() async throws -> InsightsTreasury { try await request(.insightsTreasury) }
    func getInsightsSystems() async throws -> InsightsSystems { try await request(.insightsSystems) }
    func getInsightsComps() async throws -> InsightsComps { try await request(.insightsComps) }
    func getInsightsPartners() async throws -> InsightsPartners { try await request(.insightsPartners) }
    func getInsightsFeed(limit: Int, offset: Int) async throws -> [ActivityFeedItem] { try await request(.insightsFeed(limit: limit, offset: offset)) }
    func submitScan(qrCode: String) async throws -> ScanResult { try await request(.submitScan, method: "POST") }
    func getScanHistory(limit: Int, offset: Int) async throws -> [Scan] { try await request(.scanHistory(limit: limit, offset: offset)) }
    func getWallet() async throws -> Wallet { try await request(.wallet) }
    func getTransactions(limit: Int, offset: Int, statusFilter: String?) async throws -> [Transaction] { try await request(.transactions(limit: limit, offset: offset, status: statusFilter)) }
    func getCompVault() async throws -> CompVault { try await request(.compVault) }
    func withdrawCrypto(address: String, amount: Double) async throws -> WithdrawalResult { try await request(.withdrawCrypto, method: "POST") }
    func getDwollaFundingSources() async throws -> [DwollaFundingSource] { try await request(.dwollaFundingSources) }
    func createDwollaCustomer() async throws -> DwollaCustomer { try await request(.dwollaCreateCustomer, method: "POST") }
    func getPlaidLinkToken() async throws -> PlaidLinkToken { try await request(.plaidLinkToken, method: "POST") }
    func linkBankAccount(publicToken: String, accountId: String) async throws -> DwollaFundingSource { try await request(.linkBank, method: "POST") }
    func withdrawToBank(amount: Double, fundingSourceId: String) async throws -> DwollaTransfer { try await request(.withdrawToBank(amount: amount, fundingSourceId: fundingSourceId), method: "POST") }
    func getProducts(category: String?, limit: Int, offset: Int) async throws -> [Product] { try await request(.products(category: category, limit: limit, offset: offset)) }
    func getProduct(id: Int) async throws -> Product { try await request(.product(id: id)) }
    func getCart() async throws -> Cart { try await request(.cart) }
    func addToCart(productId: Int, quantity: Int) async throws -> Cart { try await request(.addToCart, method: "POST") }
    func updateCartItem(productId: Int, quantity: Int) async throws -> Cart { try await request(.updateCartItem, method: "PUT") }
    func removeFromCart(productId: Int) async throws -> Cart { try await request(.removeFromCart(productId: productId), method: "DELETE") }
    func estimateTax(shippingAddress: ShippingAddress) async throws -> TaxEstimate { try await request(.estimateTax, method: "POST", body: shippingAddress) }
    func createOrder(shippingAddress: ShippingAddress, paymentToken: String) async throws -> Order { try await request(.createOrder, method: "POST") }
    func getNotifications(typeFilter: String?, limit: Int, offset: Int) async throws -> [AppNotification] { try await request(.notifications(typeFilter: typeFilter, limit: limit, offset: offset)) }
    func markNotificationRead(id: Int) async throws { let _: [String: String] = try await request(.markNotificationRead(id: id), method: "POST") }
    func markAllNotificationsRead() async throws { let _: [String: String] = try await request(.markAllRead, method: "POST") }
    func getUnreadNotificationCount() async throws -> Int {
        struct CountResponse: Decodable { let count: Int }
        return try await request(.unreadCount, as: CountResponse.self).count
    }
    func getChannels() async throws -> [Channel] { try await request(.channels) }
    func getMessages(channelId: Int, limit: Int, before: Int?) async throws -> [ChatMessage] { try await request(.messages(channelId: channelId, limit: limit, before: before)) }
    func sendMessage(channelId: Int, content: String, mediaType: String?) async throws -> ChatMessage { try await request(.sendMessage(channelId: channelId), method: "POST") }
    func translateMessage(messageId: Int, targetLanguage: String) async throws -> TranslatedMessage { try await request(.translateMessage(id: messageId), method: "POST") }
    func addReaction(messageId: Int, emoji: String) async throws { let _: [String: String] = try await request(.addReaction(messageId: messageId), method: "POST") }
    func removeReaction(messageId: Int, emoji: String) async throws { let _: [String: String] = try await request(.removeReaction(messageId: messageId, emoji: emoji), method: "DELETE") }
    func getActiveVotes() async throws -> [GovernanceVote] { try await request(.activeVotes) }
    func getVoteDetail(id: Int) async throws -> GovernanceVoteDetail { try await request(.voteDetail(id: id)) }
    func castBallot(voteId: Int, selectedOption: String) async throws { let _: [String: String] = try await request(.castBallot(voteId: voteId), method: "POST") }
    func submitWholesaleApplication(businessName: String, contactEmail: String, estimatedMonthlyVolume: Double) async throws { let _: [String: String] = try await request(.wholesaleApply, method: "POST") }
    func getWholesaleDashboard() async throws -> WholesaleDashboard { try await request(.wholesaleDashboard) }
    func getWholesaleOrders(limit: Int, offset: Int) async throws -> [WholesaleOrder] { try await request(.wholesaleOrders(limit: limit, offset: offset)) }
    func createWholesaleOrder(items: [WholesaleOrderItem]) async throws -> WholesaleOrder { try await request(.createWholesaleOrder, method: "POST") }
    func getWholesaleChips() async throws -> WholesaleChips { try await request(.wholesaleChips) }
    func getAffiliateDashboard() async throws -> AffiliateDashboard { try await request(.affiliateDashboard) }
    func getAffiliateDownline(limit: Int, offset: Int) async throws -> [AffiliateDownlineMember] { try await request(.affiliateDownline(limit: limit, offset: offset)) }
    func getAffiliateChips() async throws -> AffiliateChips { try await request(.affiliateChips) }
    func getAffiliatePayouts(limit: Int, offset: Int) async throws -> [AffiliatePayout] { try await request(.affiliatePayouts(limit: limit, offset: offset)) }
    func getAffiliateReferralCode() async throws -> ReferralCode { try await request(.affiliateReferralCode) }

    // Convenience overload
    private func request<T: Decodable>(_ endpoint: APIEndpoint, method: String = "GET", body: Encodable? = nil, as type: T.Type) async throws -> T {
        try await request(endpoint, method: method, body: body)
    }
}
