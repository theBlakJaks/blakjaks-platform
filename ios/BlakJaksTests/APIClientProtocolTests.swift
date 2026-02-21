import XCTest
@testable import BlakJaks

final class APIClientProtocolTests: XCTestCase {
    var mockClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockClient = MockAPIClient()
    }

    // MARK: - MockAPIClient implements all protocol methods

    func testMockClientLogin() async throws {
        let tokens = try await mockClient.login(email: "test@example.com", password: "password")
        XCTAssertFalse(tokens.accessToken.isEmpty)
        XCTAssertFalse(tokens.refreshToken.isEmpty)
        XCTAssertEqual(tokens.tokenType, "Bearer")
    }

    func testMockClientGetMe() async throws {
        let profile = try await mockClient.getMe()
        XCTAssertEqual(profile.id, MockUser.current.id)
        XCTAssertFalse(profile.fullName.isEmpty)
        XCTAssertFalse(profile.memberId.isEmpty)
    }

    func testMockClientInsightsOverview() async throws {
        let overview = try await mockClient.getInsightsOverview()
        XCTAssertGreaterThan(overview.globalScanCount, 0)
        XCTAssertGreaterThan(overview.activeMembers, 0)
        XCTAssertFalse(overview.liveFeed.isEmpty)
    }

    func testMockClientSubmitScan() async throws {
        let result = try await mockClient.submitScan(qrCode: "TEST-CODE-1234")
        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.usdcEarned, 0)
        XCTAssertGreaterThan(result.tierMultiplier, 0)
    }

    func testMockClientGetWallet() async throws {
        let wallet = try await mockClient.getWallet()
        XCTAssertGreaterThanOrEqual(wallet.availableBalance, 0)
    }

    func testMockClientGetProducts() async throws {
        let products = try await mockClient.getProducts(category: nil, limit: 10, offset: 0)
        XCTAssertFalse(products.isEmpty)
        XCTAssertFalse(products[0].name.isEmpty)
    }

    func testMockClientGetNotifications() async throws {
        let notifications = try await mockClient.getNotifications(typeFilter: nil, limit: 10, offset: 0)
        XCTAssertFalse(notifications.isEmpty)
    }

    func testMockClientGetChannels() async throws {
        let channels = try await mockClient.getChannels()
        XCTAssertFalse(channels.isEmpty)
    }

    func testMockClientGetActiveVotes() async throws {
        let votes = try await mockClient.getActiveVotes()
        XCTAssertFalse(votes.isEmpty)
        let vote = votes[0]
        XCTAssertFalse(vote.options.isEmpty)
    }

    func testMockClientDwollaFundingSources() async throws {
        let sources = try await mockClient.getDwollaFundingSources()
        XCTAssertFalse(sources.isEmpty)
        XCTAssertEqual(sources[0].status, "verified")
    }

    func testMockClientAffiliateDashboard() async throws {
        let dashboard = try await mockClient.getAffiliateDashboard()
        XCTAssertFalse(dashboard.referralCode.isEmpty)
        XCTAssertGreaterThan(dashboard.totalDownline, 0)
    }

    func testMockClientWithdrawToBank() async throws {
        let transfer = try await mockClient.withdrawToBank(amount: 100.00, fundingSourceId: "fs-001")
        XCTAssertFalse(transfer.transferId.isEmpty)
        XCTAssertEqual(transfer.amount, 100.00)
        XCTAssertEqual(transfer.status, "pending")
    }

    // MARK: - MockData Models

    func testMockUserHasRequiredFields() {
        let user = MockUser.current
        XCTAssertGreaterThan(user.id, 0)
        XCTAssertFalse(user.memberId.isEmpty)
        XCTAssertTrue(user.memberId.hasPrefix("BJ-"))
    }

    func testMockProductsHaveRequiredFields() {
        for product in MockProducts.list {
            XCTAssertGreaterThan(product.id, 0)
            XCTAssertFalse(product.sku.isEmpty)
            XCTAssertGreaterThan(product.price, 0)
        }
    }

    func testMockInsightsTreasuryHasThreeBalanceSources() throws {
        let treasury = MockInsights.treasury
        XCTAssertEqual(treasury.onChainBalances.count, 3, "Must have 3 on-chain pool balances")
        XCTAssertEqual(treasury.bankBalances.count, 3, "Must have 3 Teller bank balances")
        XCTAssertGreaterThan(treasury.dwollaPlatformBalance.available, 0, "Dwolla balance must be present")
    }

    func testMockScanResultHasTierProgress() throws {
        let result = MockScans.scanResult
        XCTAssertFalse(result.tierProgress.quarter.isEmpty)
        XCTAssertGreaterThan(result.tierProgress.currentCount, 0)
    }
}
