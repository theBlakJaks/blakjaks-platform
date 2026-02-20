import XCTest
@testable import BlakJaks

// MARK: - ScanWalletViewModelTests
// All tests use MockAPIClient — no network required.

@MainActor
final class ScanWalletViewModelTests: XCTestCase {

    private var viewModel: ScanWalletViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ScanWalletViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - loadAll

    func testLoadAllPopulatesWallet() async {
        await viewModel.loadAll()
        XCTAssertNotNil(viewModel.wallet)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadAllPopulatesMemberCard() async {
        await viewModel.loadAll()
        XCTAssertNotNil(viewModel.memberCard)
    }

    func testLoadAllPopulatesTransactions() async {
        await viewModel.loadAll()
        XCTAssertFalse(viewModel.transactions.isEmpty)
    }

    func testLoadAllPopulatesScans() async {
        await viewModel.loadAll()
        XCTAssertFalse(viewModel.scans.isEmpty)
    }

    func testLoadAllPopulatesCompVault() async {
        await viewModel.loadAll()
        XCTAssertNotNil(viewModel.compVault)
    }

    // MARK: - Transaction filter

    func testFilterAllReturnsAllTransactions() async {
        await viewModel.loadAll()
        viewModel.txFilter = .all
        XCTAssertEqual(viewModel.filteredTransactions.count, viewModel.transactions.count)
    }

    func testFilterDepositsReturnsOnlyPositive() async {
        await viewModel.loadAll()
        viewModel.txFilter = .deposits
        XCTAssertTrue(viewModel.filteredTransactions.allSatisfy { $0.amount > 0 })
    }

    func testFilterWithdrawalsReturnsOnlyNegative() async {
        await viewModel.loadAll()
        viewModel.txFilter = .withdrawals
        XCTAssertTrue(viewModel.filteredTransactions.allSatisfy { $0.amount < 0 })
    }

    // MARK: - Wallet balance

    func testWalletHasPositiveBalance() async {
        await viewModel.loadAll()
        XCTAssertGreaterThan(viewModel.wallet?.availableBalance ?? 0, 0)
    }

    func testWalletHasLinkedBankAccount() async {
        await viewModel.loadAll()
        XCTAssertNotNil(viewModel.wallet?.linkedBankAccount)
    }

    // MARK: - CompVault

    func testCompVaultHasMilestones() async {
        await viewModel.loadAll()
        XCTAssertFalse(viewModel.compVault?.milestones.isEmpty ?? true)
    }

    func testCompVaultLifetimeCompsPositive() async {
        await viewModel.loadAll()
        XCTAssertGreaterThan(viewModel.compVault?.lifetimeComps ?? 0, 0)
    }

    // MARK: - Withdraw validation

    func testWithdrawCryptoFailsWithEmptyAmount() async {
        await viewModel.loadAll()
        viewModel.withdrawAmount  = ""
        viewModel.withdrawAddress = "0xabc"
        let result = await viewModel.withdrawCrypto()
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.error)
    }

    func testWithdrawCryptoFailsWithEmptyAddress() async {
        await viewModel.loadAll()
        viewModel.withdrawAmount  = "50.00"
        viewModel.withdrawAddress = ""
        let result = await viewModel.withdrawCrypto()
        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Refresh

    func testRefreshClearsAndReloads() async {
        await viewModel.loadAll()
        XCTAssertNotNil(viewModel.wallet)
        await viewModel.refresh()
        XCTAssertNotNil(viewModel.wallet)
    }

    // MARK: - isLoading resets

    func testLoadingIsFalseAfterLoadAll() async {
        await viewModel.loadAll()
        XCTAssertFalse(viewModel.isLoading)
    }

    func testClearError() async {
        viewModel.withdrawAmount  = ""
        viewModel.withdrawAddress = ""
        _ = await viewModel.withdrawCrypto()
        XCTAssertNotNil(viewModel.error)
        viewModel.clearError()
        XCTAssertNil(viewModel.error)
    }
}

// MARK: - PayoutChoiceTests

@MainActor
final class PayoutChoiceTests: XCTestCase {

    private var viewModel: ScanWalletViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ScanWalletViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testSubmitPayoutChoiceClearsSheet() async {
        viewModel.showPayoutChoiceSheet = true
        viewModel.pendingChoiceComp = CompEarned(
            id: "mock-uuid", amount: 100.00, status: "pending_choice", requiresPayoutChoice: true
        )
        await viewModel.submitPayoutChoice(compId: "mock-uuid", method: "crypto")
        XCTAssertFalse(viewModel.showPayoutChoiceSheet)
        XCTAssertNil(viewModel.pendingChoiceComp)
        XCTAssertNil(viewModel.error)
    }

    func testSubmitPayoutChoiceBankSucceeds() async {
        await viewModel.submitPayoutChoice(compId: "mock-uuid", method: "bank")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isSubmittingPayoutChoice)
    }

    func testSubmitPayoutChoiceLaterSucceeds() async {
        await viewModel.submitPayoutChoice(compId: "mock-uuid", method: "later")
        XCTAssertNil(viewModel.error)
    }

    func testCompBalanceFromWallet() async {
        await viewModel.loadAll()
        XCTAssertEqual(viewModel.compBalance, viewModel.wallet?.compBalance ?? 0)
        XCTAssertGreaterThan(viewModel.compBalance, 0)
    }

    func testMockScanResultHasRequiresPayoutChoice() {
        let comp = MockScans.scanResult.compEarned
        XCTAssertNotNil(comp)
        XCTAssertTrue(comp?.requiresPayoutChoice ?? false)
        XCTAssertEqual(comp?.status, "pending_choice")
    }

    func testWalletHasCompBalance() async {
        await viewModel.loadAll()
        XCTAssertNotNil(viewModel.wallet)
        XCTAssertGreaterThan(viewModel.wallet?.compBalance ?? 0, 0)
    }
}

// MARK: - ScannerViewModelTests

@MainActor
final class ScannerViewModelTests: XCTestCase {

    private var viewModel: ScannerViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ScannerViewModel(apiClient: MockAPIClient())
    }

    func testSubmitCodePopulatesScanResult() async {
        await viewModel.submitCode("ABCD-1234-EFGH")
        XCTAssertNotNil(viewModel.scanResult)
        XCTAssertNil(viewModel.error)
    }

    func testDismissResultClearsState() async {
        await viewModel.submitCode("ABCD-1234-EFGH")
        XCTAssertNotNil(viewModel.scanResult)
        viewModel.dismissResult()
        XCTAssertNil(viewModel.scanResult)
    }

    func testManualEntryWithEmptyCodeDoesNothing() async {
        viewModel.manualCode = "  "
        await viewModel.submitManualEntry()
        XCTAssertNil(viewModel.scanResult)
    }
}
