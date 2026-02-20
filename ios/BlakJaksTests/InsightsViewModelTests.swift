import XCTest
@testable import BlakJaks

// MARK: - InsightsViewModelTests
// All tests use MockAPIClient — no network required.

@MainActor
final class InsightsViewModelTests: XCTestCase {

    private var viewModel: InsightsViewModel!

    override func setUp() {
        super.setUp()
        viewModel = InsightsViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Overview

    func testLoadOverviewPopulatesData() async {
        await viewModel.loadOverview()
        XCTAssertNotNil(viewModel.overview)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testOverviewHasPositiveScanCount() async {
        await viewModel.loadOverview()
        XCTAssertGreaterThan(viewModel.overview?.globalScanCount ?? 0, 0)
    }

    func testOverviewHasLiveFeedItems() async {
        await viewModel.loadOverview()
        XCTAssertFalse(viewModel.overview?.liveFeed.isEmpty ?? true)
    }

    func testOverviewHasMilestoneProgress() async {
        await viewModel.loadOverview()
        XCTAssertFalse(viewModel.overview?.milestoneProgress.isEmpty ?? true)
    }

    // MARK: - Treasury

    func testLoadTreasuryPopulatesData() async {
        await viewModel.loadTreasury()
        XCTAssertNotNil(viewModel.treasury)
        XCTAssertNil(viewModel.error)
    }

    func testTreasuryHasThreeOnChainPools() async {
        await viewModel.loadTreasury()
        XCTAssertEqual(viewModel.treasury?.onChainBalances.count, 3)
    }

    func testTreasuryHasThreeBankAccounts() async {
        await viewModel.loadTreasury()
        XCTAssertEqual(viewModel.treasury?.bankBalances.count, 3)
    }

    func testTreasuryDwollaBalanceIsPositive() async {
        await viewModel.loadTreasury()
        XCTAssertGreaterThan(viewModel.treasury?.dwollaPlatformBalance.available ?? 0, 0)
    }

    // MARK: - Systems

    func testLoadSystemsPopulatesData() async {
        await viewModel.loadSystems()
        XCTAssertNotNil(viewModel.systems)
        XCTAssertNil(viewModel.error)
    }

    func testPolygonNodeIsConnected() async {
        await viewModel.loadSystems()
        XCTAssertTrue(viewModel.systems?.polygonNodeStatus.connected ?? false)
    }

    func testTierDistributionHasFourTiers() async {
        await viewModel.loadSystems()
        XCTAssertEqual(viewModel.systems?.tierDistribution.count, 4)
    }

    // MARK: - Comps

    func testLoadCompsPopulatesData() async {
        await viewModel.loadComps()
        XCTAssertNotNil(viewModel.comps)
        XCTAssertNil(viewModel.error)
    }

    func testCompsHaveTier100Stats() async {
        await viewModel.loadComps()
        XCTAssertEqual(viewModel.comps?.tier100.averagePayout, 100)
    }

    // MARK: - Partners

    func testLoadPartnersPopulatesData() async {
        await viewModel.loadPartners()
        XCTAssertNotNil(viewModel.partners)
        XCTAssertNil(viewModel.error)
    }

    func testPartnersHasActiveAffiliates() async {
        await viewModel.loadPartners()
        XCTAssertGreaterThan(viewModel.partners?.affiliateActiveCount ?? 0, 0)
    }

    // MARK: - Caching (second load does not reset data)

    func testOverviewNotReloadedIfAlreadyPresent() async {
        await viewModel.loadOverview()
        let original = viewModel.overview?.globalScanCount
        await viewModel.loadOverview()  // should skip
        XCTAssertEqual(viewModel.overview?.globalScanCount, original)
    }

    // MARK: - Refresh clears and reloads

    func testRefreshClearsAndReloadsOverview() async {
        await viewModel.loadOverview()
        XCTAssertNotNil(viewModel.overview)
        await viewModel.refresh()
        XCTAssertNotNil(viewModel.overview)  // reloaded, not nil
    }

    // MARK: - isLoading resets

    func testLoadingIsFalseAfterOverviewLoad() async {
        await viewModel.loadOverview()
        XCTAssertFalse(viewModel.isLoading)
    }
}
