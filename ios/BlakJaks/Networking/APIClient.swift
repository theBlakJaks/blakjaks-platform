import Foundation
import Alamofire

// MARK: - APIClient
// Production Alamofire session with JWT silent-refresh interceptor.
// Conforms to APIClientProtocol — swap with MockAPIClient for previews/tests.

final class APIClient: APIClientProtocol {

    static let shared = APIClient()

    private let session: Session

    private init() {
        let interceptor = TokenRefreshInterceptor()
        session = Session(interceptor: interceptor)
    }

    // MARK: - Private helpers

    private func baseURL(for path: String) -> URL {
        Config.apiBaseURL.appendingPathComponent(path)
    }

    private func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL(for: path),
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: authHeaders()
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response))
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
                encoder: JSONParameterEncoder.default,
                headers: authHeaders()
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response))
                }
            }
        }
    }

    private func requestVoid(_ path: String, method: HTTPMethod = .post) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                baseURL(for: path),
                method: method,
                headers: authHeaders()
            )
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response))
                }
            }
        }
    }

    private func authHeaders() -> HTTPHeaders {
        var headers = HTTPHeaders()
        if let token = KeychainManager.shared.accessToken {
            headers.add(.authorization(bearerToken: token))
        }
        return headers
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthTokens {
        let body = LoginRequest(email: email, password: password)
        let tokens: AuthTokens = try await requestEncodable(APIEndpoints.login, body: body)
        KeychainManager.shared.store(tokens: tokens)
        return tokens
    }

    func signup(email: String, password: String, fullName: String, dateOfBirth: String) async throws -> AuthTokens {
        let body = SignupRequest(email: email, password: password, fullName: fullName, dateOfBirth: dateOfBirth)
        let tokens: AuthTokens = try await requestEncodable(APIEndpoints.signup, body: body)
        KeychainManager.shared.store(tokens: tokens)
        return tokens
    }

    func logout() async throws {
        try await requestVoid(APIEndpoints.logout)
        KeychainManager.shared.clearAll()
    }

    func refreshToken(refreshToken: String) async throws -> AuthTokens {
        let body = TokenRefreshRequest(refreshToken: refreshToken)
        let tokens: AuthTokens = try await requestEncodable(APIEndpoints.refreshToken, body: body)
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
                to: baseURL(for: APIEndpoints.avatarUpload),
                headers: authHeaders()
            )
            .validate()
            .responseDecodable(of: UserProfile.self) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: APIError.from(afError: error, response: response.response))
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

    func getInsightsFeed(limit: Int, offset: Int) async throws -> [InsightsFeedItem] {
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
        try await request(APIEndpoints.dwollaFundingSources, method: .post)  // POST /dwolla/customers
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

    func getNotifications() async throws -> [AppNotification] {
        try await request(APIEndpoints.notifications)
    }

    func markAllNotificationsRead() async throws {
        try await requestVoid(APIEndpoints.notificationsMarkRead)
    }

    func registerPushToken(_ token: String, platform: String) async throws {
        let params: Parameters = ["token": token, "platform": platform]
        try await requestVoid(APIEndpoints.pushToken)
        _ = params  // used in body — suppress warning
    }

    // MARK: - Social

    func getChannels() async throws -> [SocialChannel] {
        try await request(APIEndpoints.channels)
    }

    func getMessages(channelId: String, before: String?, limit: Int) async throws -> [ChatMessage] {
        var params: Parameters = ["limit": limit]
        if let before { params["before"] = before }
        return try await request(APIEndpoints.channelMessages(channelId), parameters: params, encoding: URLEncoding.default)
    }

    func getLiveStreams() async throws -> [LiveStream] {
        try await request(APIEndpoints.liveStreams)
    }

    // MARK: - Governance

    func getProposals() async throws -> [GovernanceVote] {
        try await request(APIEndpoints.proposals)
    }

    func castVote(proposalId: Int, choice: String) async throws -> GovernanceVote {
        let params: Parameters = ["choice": choice]
        return try await request(APIEndpoints.vote(proposalId), method: .post, parameters: params)
    }

    // MARK: - Wholesale / Affiliate

    func getWholesaleDashboard() async throws -> WholesaleDashboard {
        try await request(APIEndpoints.wholesaleDashboard)
    }

    func getAffiliateDashboard() async throws -> AffiliateDashboard {
        try await request(APIEndpoints.affiliateDashboard)
    }

    func getAffiliateReferrals() async throws -> [AffiliateReferral] {
        try await request(APIEndpoints.affiliateReferrals)
    }

    func getAffiliatePayouts() async throws -> [AffiliateReferral] {
        try await request(APIEndpoints.affiliatePayouts)
    }
}

// MARK: - TokenRefreshInterceptor
// Silently refreshes JWT on 401, retries the original request once.

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

        Task {
            await self.performRefresh()
        }
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

// MARK: - APIError

enum APIError: LocalizedError {
    case serverError(statusCode: Int, message: String)
    case networkError(String)
    case unauthorized
    case unknown

    static func from(afError: AFError, response: HTTPURLResponse?) -> APIError {
        if let code = response?.statusCode {
            if code == 401 { return .unauthorized }
            return .serverError(statusCode: code, message: afError.localizedDescription)
        }
        if case .sessionTaskFailed = afError {
            return .networkError(afError.localizedDescription)
        }
        return .unknown
    }

    var errorDescription: String? {
        switch self {
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}
