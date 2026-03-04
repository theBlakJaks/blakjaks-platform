import Foundation
import Alamofire

// MARK: - APIClient
// Production Alamofire session with JWT silent-refresh interceptor.

final class APIClient: APIClientProtocol {

    static let shared = APIClient()

    private let session: Session

    /// Tracks in-flight GET requests so identical calls share a single network round-trip.
    private let inflightLock = NSLock()
    private var inflightGETs: [URL: [(Result<Data, Error>) -> Void]] = [:]

    private init() {
        let interceptor = TokenRefreshInterceptor()

        // HTTP caching — 20 MB memory / 100 MB disk
        let cache = URLCache(memoryCapacity: 20_000_000, diskCapacity: 100_000_000)
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy

        session = Session(configuration: configuration, interceptor: interceptor)
    }

    // MARK: - Private helpers

    /// Shared decoder: converts snake_case JSON keys to camelCase Swift properties.
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private func baseURL(for path: String) -> URL {
        Config.apiBaseURL.appendingPathComponent(path)
    }

    private func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) async throws -> T {
        // Deduplicate identical in-flight GET requests
        if method == .get {
            let url = baseURL(for: path)
            let data = try await deduplicatedGET(url: url, parameters: parameters, encoding: encoding)
            return try APIClient.decoder.decode(T.self, from: data)
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL(for: path),
                method: method,
                parameters: parameters,
                encoding: encoding
            )
            .validate()
            .responseDecodable(of: T.self, decoder: APIClient.decoder) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response, data: response.data))
                }
            }
        }
    }

    /// Fires a GET and deduplicates identical in-flight requests by URL.
    private func deduplicatedGET(url: URL, parameters: Parameters?, encoding: ParameterEncoding) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            inflightLock.lock()
            if inflightGETs[url] != nil {
                // Already in flight — piggyback on the existing request.
                inflightGETs[url]?.append { result in
                    continuation.resume(with: result)
                }
                inflightLock.unlock()
                return
            }
            inflightGETs[url] = [{ result in continuation.resume(with: result) }]
            inflightLock.unlock()

            session.request(url, method: .get, parameters: parameters, encoding: encoding)
                .validate()
                .responseData { [weak self] response in
                    guard let self else { return }
                    self.inflightLock.lock()
                    let callbacks = self.inflightGETs.removeValue(forKey: url) ?? []
                    self.inflightLock.unlock()

                    switch response.result {
                    case .success(let data):
                        callbacks.forEach { $0(.success(data)) }
                    case .failure(let error):
                        let apiError = APIError.from(afError: error, response: response.response, data: response.data)
                        callbacks.forEach { $0(.failure(apiError)) }
                    }
                }
        }
    }

    private func requestEncodable<Body: Encodable, T: Decodable>(
        _ path: String,
        method: HTTPMethod = .post,
        body: Body
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL(for: path),
                method: method,
                parameters: body,
                encoder: JSONParameterEncoder.default
            )
            .validate()
            .responseDecodable(of: T.self, decoder: APIClient.decoder) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response, data: response.data))
                }
            }
        }
    }

    private func requestVoid(
        _ path: String,
        method: HTTPMethod = .post,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL(for: path),
                method: method,
                parameters: parameters,
                encoding: encoding
            )
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response, data: response.data))
                }
            }
        }
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthTokens {
        let body = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await requestEncodable(APIEndpoints.login, body: body)
        KeychainManager.shared.store(tokens: response.tokens)
        return response.tokens
    }

    func signup(email: String, password: String, firstName: String, lastName: String, username: String, birthdate: String, referralCode: String?) async throws -> AuthTokens {
        let body = SignupRequest(
            email: email,
            password: password,
            first_name: firstName,
            last_name: lastName,
            birthdate: birthdate,
            username: username,
            referral_code: referralCode.flatMap { $0.isEmpty ? nil : $0 }
        )
        let response: LoginResponse = try await requestEncodable(APIEndpoints.signup, body: body)
        KeychainManager.shared.store(tokens: response.tokens)
        return response.tokens
    }

    func logout() async throws {
        // Clear local credentials first — logout must work even if the network call fails.
        KeychainManager.shared.clearAll()
        try await requestVoid(APIEndpoints.logout)
    }

    func refreshToken(refreshToken: String) async throws -> AuthTokens {
        let body = TokenRefreshRequest(refresh_token: refreshToken)
        // Backend /auth/refresh only returns access_token — reconstruct AuthTokens
        // using the existing refresh token (it remains valid).
        let response: RefreshResponse = try await requestEncodable(APIEndpoints.refreshToken, body: body)
        let tokens = AuthTokens(
            accessToken:  response.accessToken,
            refreshToken: refreshToken,
            tokenType:    response.tokenType
        )
        KeychainManager.shared.store(tokens: tokens)
        return tokens
    }

    func getIntercomToken() async throws -> IntercomToken {
        try await request(APIEndpoints.intercomToken)
    }

    // MARK: - User

    func getMe() async throws -> UserProfile {
        try await request(APIEndpoints.me)
    }

    func registerPushToken(_ token: String) async throws {
        struct Body: Encodable { let token: String }
        let body = Body(token: token)
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL(for: APIEndpoints.pushToken),
                method: .post,
                parameters: body,
                encoder: JSONParameterEncoder.default
            )
            .validate()
            .response { response in
                switch response.result {
                case .success: continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response, data: response.data))
                }
            }
        }
    }

    func updateProfile(fullName: String?, bio: String?) async throws -> UserProfile {
        var params: Parameters = [:]
        if let fullName { params["full_name"] = fullName }
        if let bio { params["bio"] = bio }
        return try await request(APIEndpoints.me, method: .patch, parameters: params)
    }

    func uploadAvatar(imageData: Data, mimeType: String) async throws -> UserProfile {
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { form in
                    form.append(imageData, withName: "avatar", fileName: "avatar.jpg", mimeType: mimeType)
                },
                to: baseURL(for: APIEndpoints.avatarUpload)
            )
            .validate()
            .responseDecodable(of: UserProfile.self, decoder: APIClient.decoder) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response, data: response.data))
                }
            }
        }
    }

    func getMemberCard() async throws -> MemberCard {
        try await request(APIEndpoints.memberCard)
    }

    // MARK: - Insights

    func getInsightsOverview() async throws -> InsightsOverview {
        try await request(APIEndpoints.insightsOverview)
    }

    func getInsightsTreasury() async throws -> InsightsTreasury {
        try await request(APIEndpoints.insightsTreasury)
    }

    func getInsightsSystems() async throws -> InsightsSystems {
        try await request(APIEndpoints.insightsSystems)
    }

    func getInsightsComps() async throws -> InsightsComps {
        try await request(APIEndpoints.insightsComps)
    }

    func getInsightsPartners() async throws -> InsightsPartners {
        try await request(APIEndpoints.insightsPartners)
    }

    func getInsightsFeed(limit: Int, offset: Int) async throws -> [ActivityFeedItem] {
        try await request(APIEndpoints.insightsFeed, parameters: ["limit": limit, "offset": offset], encoding: URLEncoding.default)
    }

    // MARK: - Scan

    func submitScan(qrCode: String) async throws -> ScanResult {
        let params: Parameters = ["qr_code": qrCode]
        return try await request(APIEndpoints.scan, method: .post, parameters: params)
    }

    func getScanHistory(limit: Int, offset: Int) async throws -> [Scan] {
        try await request(APIEndpoints.scanHistory, parameters: ["limit": limit, "offset": offset], encoding: URLEncoding.default)
    }

    // MARK: - Wallet

    func getWallet() async throws -> Wallet {
        try await request(APIEndpoints.wallet)
    }

    func getTransactions(limit: Int, offset: Int, statusFilter: String? = nil) async throws -> [Transaction] {
        var params: Parameters = ["limit": limit, "offset": offset]
        if let statusFilter { params["status"] = statusFilter }
        return try await request(APIEndpoints.transactions, parameters: params, encoding: URLEncoding.default)
    }

    func getCompVault() async throws -> CompVault {
        try await request(APIEndpoints.compVault)
    }

    func withdrawCrypto(address: String, amount: Double) async throws -> WithdrawalResult {
        let params: Parameters = ["address": address, "amount": amount]
        return try await request(APIEndpoints.cryptoWithdraw, method: .post, parameters: params)
    }

    func withdrawToBank(amount: Double, fundingSourceId: String) async throws -> DwollaTransfer {
        let params: Parameters = ["amount": amount, "funding_source_id": fundingSourceId]
        return try await request(APIEndpoints.bankWithdraw, method: .post, parameters: params)
    }

    // MARK: - Dwolla ACH

    func getDwollaFundingSources() async throws -> [DwollaFundingSource] {
        try await request(APIEndpoints.dwollaFundingSources)
    }

    func createDwollaCustomer() async throws -> DwollaCustomer {
        try await request(APIEndpoints.dwollaFundingSources, method: .post)
    }

    func getPlaidLinkToken() async throws -> PlaidLinkToken {
        try await request(APIEndpoints.dwollaPlaidToken, method: .post)
    }

    func linkBankAccount(publicToken: String, accountId: String) async throws -> DwollaFundingSource {
        let params: Parameters = ["public_token": publicToken, "account_id": accountId]
        return try await request(APIEndpoints.dwollaExchangeSession, method: .post, parameters: params)
    }

    // MARK: - Shop

    func getProducts(category: String?, limit: Int, offset: Int) async throws -> [Product] {
        var params: Parameters = ["limit": limit, "offset": offset]
        if let category { params["category"] = category }
        return try await request(APIEndpoints.products, parameters: params, encoding: URLEncoding.default)
    }

    func getProduct(id: Int) async throws -> Product {
        try await request(APIEndpoints.product(id))
    }

    func getCart() async throws -> Cart {
        try await request(APIEndpoints.cart)
    }

    func addToCart(productId: Int, quantity: Int) async throws -> Cart {
        let params: Parameters = ["product_id": productId, "quantity": quantity]
        return try await request(APIEndpoints.cartItems, method: .post, parameters: params)
    }

    func updateCartItem(productId: Int, quantity: Int) async throws -> Cart {
        let params: Parameters = ["quantity": quantity]
        return try await request(APIEndpoints.cartItem(productId), method: .patch, parameters: params)
    }

    func removeFromCart(productId: Int) async throws -> Cart {
        try await request(APIEndpoints.cartItem(productId), method: .delete)
    }

    func estimateTax(shippingAddress: ShippingAddress) async throws -> TaxEstimate {
        try await requestEncodable(APIEndpoints.taxEstimate, body: shippingAddress)
    }

    func createOrder(shippingAddress: ShippingAddress, paymentToken: String) async throws -> Order {
        struct CreateOrderBody: Encodable {
            let shippingAddress: ShippingAddress
            let paymentToken: String
        }
        return try await requestEncodable(APIEndpoints.checkout, body: CreateOrderBody(shippingAddress: shippingAddress, paymentToken: paymentToken))
    }

    // MARK: - Notifications

    func getNotifications(typeFilter: String?, limit: Int, offset: Int) async throws -> [AppNotification] {
        var params: Parameters = ["limit": limit, "offset": offset]
        if let typeFilter { params["type"] = typeFilter }
        return try await request(APIEndpoints.notifications, parameters: params, encoding: URLEncoding.default)
    }

    func markNotificationRead(id: Int) async throws {
        try await requestVoid(APIEndpoints.notifications + "/\(id)/read")
    }

    func markAllNotificationsRead() async throws {
        try await requestVoid(APIEndpoints.notificationsMarkRead)
    }

    func getUnreadNotificationCount() async throws -> Int {
        struct CountResponse: Decodable { let count: Int }
        let response: CountResponse = try await request(APIEndpoints.notifications + "/unread-count")
        return response.count
    }

    // MARK: - Social

    func getChannels() async throws -> [Channel] {
        try await request(APIEndpoints.channels)
    }

    func getMessages(channelId: String, limit: Int, before: String?) async throws -> [ChatMessage] {
        var params: Parameters = ["limit": limit]
        if let before { params["before"] = before }
        return try await request(APIEndpoints.channelMessages(channelId), parameters: params, encoding: URLEncoding.default)
    }

    func sendMessage(channelId: String, content: String, mediaType: String?) async throws -> ChatMessage {
        var params: Parameters = ["content": content]
        if let mediaType { params["media_type"] = mediaType }
        return try await request(APIEndpoints.channelMessages(channelId), method: .post, parameters: params)
    }

    func translateMessage(messageId: String, targetLanguage: String) async throws -> TranslatedMessage {
        let params: Parameters = ["target_language": targetLanguage]
        return try await request(APIEndpoints.channels + "/messages/\(messageId)/translate", method: .post, parameters: params)
    }

    func addReaction(messageId: String, emoji: String) async throws {
        let params: Parameters = ["emoji": emoji]
        try await requestVoid(
            "/social/messages/\(messageId)/reactions",
            method: .post,
            parameters: params
        )
    }

    func removeReaction(messageId: String, emoji: String) async throws {
        let encoded = emoji.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? emoji
        try await requestVoid(
            "/social/messages/\(messageId)/reactions/\(encoded)",
            method: .delete
        )
    }

    func getPinnedMessages(channelId: String) async throws -> [ChatMessage] {
        try await request(APIEndpoints.channelMessages(channelId) + "/pinned")
    }

    func getLiveStreams() async throws -> [LiveStream] {
        try await request(APIEndpoints.liveStreams)
    }

    // MARK: - Giphy (backend proxy)

    func searchGifs(query: String, limit: Int = 20, offset: Int = 0) async throws -> [GiphyProxyGif] {
        let params: Parameters = ["q": query, "limit": limit, "offset": offset]
        let response: GiphyProxyResponse = try await request("/giphy/search", parameters: params, encoding: URLEncoding.default)
        return response.results
    }

    func getTrendingGifs(limit: Int = 20) async throws -> [GiphyProxyGif] {
        let params: Parameters = ["limit": limit]
        let response: GiphyProxyResponse = try await request("/giphy/trending", parameters: params, encoding: URLEncoding.default)
        return response.results
    }

    // MARK: - Saved Emotes

    func getSavedEmotes() async throws -> [SavedEmoteResponse] {
        try await request(APIEndpoints.savedEmotes)
    }

    func saveEmote(emoteId: String, emoteName: String, animated: Bool, zeroWidth: Bool) async throws -> SavedEmoteResponse {
        let body = SavedEmoteCreateRequest(emoteId: emoteId, emoteName: emoteName, animated: animated, zeroWidth: zeroWidth)
        return try await requestEncodable(APIEndpoints.savedEmotes, body: body)
    }

    func deleteSavedEmote(emoteId: String) async throws {
        try await requestVoid(APIEndpoints.savedEmote(emoteId), method: .delete)
    }

    func reorderSavedEmotes(emoteIds: [String]) async throws {
        let params: Parameters = ["emote_ids": emoteIds]
        try await requestVoid(APIEndpoints.savedEmotesReorder, method: .put, parameters: params)
    }

    // MARK: - Governance

    func getActiveVotes() async throws -> [GovernanceVote] {
        try await request(APIEndpoints.proposals)
    }

    func getVoteDetail(id: String) async throws -> GovernanceVoteDetail {
        try await request(APIEndpoints.proposals + "/\(id)")
    }

    func castBallot(voteId: String, selectedOption: String) async throws {
        let params: Parameters = ["option": selectedOption]
        try await requestVoid(APIEndpoints.vote(voteId))
    }

    // MARK: - Comp Payout

    func submitPayoutChoice(compId: String, method: String) async throws -> CompPayoutResult {
        let params: Parameters = ["comp_id": compId, "method": method]
        return try await request(APIEndpoints.compVault + "/payout", method: .post, parameters: params)
    }

    // MARK: - Wholesale

    func submitWholesaleApplication(businessName: String, contactEmail: String, estimatedMonthlyVolume: Double) async throws {
        try await requestVoid(APIEndpoints.wholesaleDashboard + "/apply")
    }

    func getWholesaleDashboard() async throws -> WholesaleDashboard {
        try await request(APIEndpoints.wholesaleDashboard)
    }

    func getWholesaleOrders(limit: Int, offset: Int) async throws -> [WholesaleOrder] {
        try await request(APIEndpoints.wholesaleDashboard + "/orders", parameters: ["limit": limit, "offset": offset], encoding: URLEncoding.default)
    }

    func createWholesaleOrder(items: [WholesaleOrderItem]) async throws -> WholesaleOrder {
        try await requestEncodable(APIEndpoints.wholesaleDashboard + "/orders", body: items)
    }

    func getWholesaleChips() async throws -> WholesaleChips {
        try await request(APIEndpoints.wholesaleDashboard + "/chips")
    }

    // MARK: - Affiliate

    func getAffiliateDashboard() async throws -> AffiliateDashboard {
        try await request(APIEndpoints.affiliateDashboard)
    }

    func getAffiliateDownline(limit: Int, offset: Int) async throws -> [AffiliateDownlineMember] {
        try await request(APIEndpoints.affiliateReferrals, parameters: ["limit": limit, "offset": offset], encoding: URLEncoding.default)
    }

    func getAffiliateChips() async throws -> AffiliateChips {
        try await request(APIEndpoints.affiliateReferrals)
    }

    func getAffiliatePayouts(limit: Int, offset: Int) async throws -> [AffiliatePayout] {
        try await request(APIEndpoints.affiliatePayouts, parameters: ["limit": limit, "offset": offset], encoding: URLEncoding.default)
    }

    func getAffiliateReferralCode() async throws -> ReferralCode {
        try await request(APIEndpoints.affiliateReferrals)
    }
}

// MARK: - GiphyProxyGif

/// Wrapper for backend Giphy proxy responses: {"results": [...], "count": N}
struct GiphyProxyResponse: Decodable {
    let results: [GiphyProxyGif]
    let count: Int
}

/// Model matching the backend Giphy proxy response shape.
/// Backend returns: id, title, url, preview_url, preview_width, preview_height, mp4_url
struct GiphyProxyGif: Decodable, Identifiable {
    let id: String
    let title: String
    let url: String
    let previewUrl: String
    let previewWidth: Int
    let previewHeight: Int
    let mp4Url: String?
}

// MARK: - TokenRefreshInterceptor

final class TokenRefreshInterceptor: RequestInterceptor {

    private let lock = NSLock()
    private var isRefreshing = false
    private var pendingRequests: [(RetryResult) -> Void] = []

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        if let token = KeychainManager.shared.accessToken {
            request.headers.add(.authorization(bearerToken: token))
        }
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401,
              request.retryCount == 0 else {
            completion(.doNotRetry)
            return
        }

        lock.lock()
        pendingRequests.append(completion)

        guard !isRefreshing else {
            lock.unlock()
            return
        }
        isRefreshing = true
        lock.unlock()

        Task { await self.performRefresh() }
    }

    private func performRefresh() async {
        guard let refreshToken = KeychainManager.shared.refreshToken else {
            resolvePending(success: false)
            return
        }
        do {
            let tokens = try await APIClient.shared.refreshToken(refreshToken: refreshToken)
            KeychainManager.shared.store(tokens: tokens)
            resolvePending(success: true)
        } catch {
            KeychainManager.shared.clearAll()
            resolvePending(success: false)
        }
    }

    private func resolvePending(success: Bool) {
        lock.lock()
        let completions = pendingRequests
        pendingRequests.removeAll()
        isRefreshing = false
        lock.unlock()
        completions.forEach { $0(success ? .retry : .doNotRetry) }
    }
}

extension APIError {
    static func from(afError: AFError, response: HTTPURLResponse?, data: Data? = nil) -> APIError {
        if let code = response?.statusCode {
            if code == 401 {
                // Try to parse {"detail": "..."} from the response body for a meaningful message
                let detail: String? = data.flatMap {
                    (try? JSONSerialization.jsonObject(with: $0) as? [String: Any])
                        .flatMap { $0["detail"] as? String }
                }
                return .unauthorized(detail: detail)
            }
            return .serverError(statusCode: code, message: afError.localizedDescription)
        }
        if case .sessionTaskFailed = afError { return .networkError(afError) }
        return .unknown
    }
}
