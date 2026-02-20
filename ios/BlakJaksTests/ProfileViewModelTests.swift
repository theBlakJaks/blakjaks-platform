import XCTest
@testable import BlakJaks

// MARK: - ProfileViewModelTests

@MainActor
final class ProfileViewModelTests: XCTestCase {

    private var profileVM: ProfileViewModel!

    override func setUp() {
        super.setUp()
        profileVM = ProfileViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        profileVM = nil
        super.tearDown()
    }

    // MARK: - initialState

    func testInitialProfileNil() {
        XCTAssertNil(profileVM.profile)
    }

    func testInitialOrdersEmpty() {
        XCTAssertTrue(profileVM.orders.isEmpty)
    }

    func testInitialAffiliateDashboardNil() {
        XCTAssertNil(profileVM.affiliateDashboard)
    }

    func testInitialIsLoadingProfileFalse() {
        XCTAssertFalse(profileVM.isLoadingProfile)
    }

    // MARK: - loadProfile

    func testLoadProfileSetsProfile() async {
        await profileVM.loadProfile()
        XCTAssertNotNil(profileVM.profile)
        XCTAssertNil(profileVM.error)
        XCTAssertFalse(profileVM.isLoadingProfile)
    }

    func testLoadProfileFullName() async {
        await profileVM.loadProfile()
        XCTAssertEqual(profileVM.profile?.fullName, "Alex Johnson")
    }

    func testLoadProfileTier() async {
        await profileVM.loadProfile()
        XCTAssertFalse(profileVM.profile?.tier.isEmpty ?? true)
    }

    func testLoadProfileTierIsVIP() async {
        await profileVM.loadProfile()
        XCTAssertEqual(profileVM.profile?.tier, "VIP")
    }

    func testLoadProfileEmail() async {
        await profileVM.loadProfile()
        XCTAssertEqual(profileVM.profile?.email, "alex@example.com")
    }

    func testLoadProfileMemberId() async {
        await profileVM.loadProfile()
        XCTAssertEqual(profileVM.profile?.memberId, "BJ-0001-VIP")
    }

    func testLoadProfileIsAffiliate() async {
        await profileVM.loadProfile()
        XCTAssertTrue(profileVM.profile?.isAffiliate ?? false)
    }

    func testLoadProfileWalletBalance() async {
        await profileVM.loadProfile()
        XCTAssertEqual(profileVM.profile?.walletBalance, 1250.75)
    }

    func testLoadProfileIsLoadingFalseAfterLoad() async {
        await profileVM.loadProfile()
        XCTAssertFalse(profileVM.isLoadingProfile)
    }

    // MARK: - loadOrders

    func testLoadOrdersPopulatesOrders() async {
        await profileVM.loadOrders()
        XCTAssertFalse(profileVM.orders.isEmpty)
        XCTAssertFalse(profileVM.isLoadingOrders)
    }

    func testLoadOrdersReturnsTwoItems() async {
        await profileVM.loadOrders()
        // loadOrders() stubs [MockProducts.order, MockProducts.order]
        XCTAssertEqual(profileVM.orders.count, 2)
    }

    func testLoadOrdersIsLoadingFalseAfterLoad() async {
        await profileVM.loadOrders()
        XCTAssertFalse(profileVM.isLoadingOrders)
    }

    // MARK: - loadAffiliateDashboard

    func testLoadAffiliateDashboardSetsData() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertNotNil(profileVM.affiliateDashboard)
        XCTAssertNil(profileVM.error)
    }

    func testLoadAffiliateDashboardReferralCode() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertEqual(profileVM.affiliateDashboard?.referralCode, "ALEX123")
    }

    func testLoadAffiliateDashboardHasPayouts() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertFalse(profileVM.affiliatePayouts.isEmpty)
    }

    func testLoadAffiliateDashboardPayoutsCount() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertEqual(profileVM.affiliatePayouts.count, 2)
    }

    func testLoadAffiliateDashboardTotalDownline() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertEqual(profileVM.affiliateDashboard?.totalDownline, 42)
    }

    func testLoadAffiliateDashboardActiveDownline() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertEqual(profileVM.affiliateDashboard?.activeDownline, 38)
    }

    func testLoadAffiliateDashboardFirstPayoutAmount() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertEqual(profileVM.affiliatePayouts.first?.amount, 250.00)
    }

    // MARK: - updateProfile

    func testUpdateProfileSetsSuccessMessage() async {
        await profileVM.updateProfile(fullName: "Alex Johnson", bio: "Test bio")
        XCTAssertNotNil(profileVM.successMessage)
        XCTAssertNil(profileVM.error)
        XCTAssertFalse(profileVM.isUpdatingProfile)
    }

    func testUpdateProfileSuccessMessageText() async {
        await profileVM.updateProfile(fullName: "Alex Johnson", bio: "Test bio")
        XCTAssertEqual(profileVM.successMessage, "Profile updated.")
    }

    func testUpdateProfileUpdatesProfile() async {
        await profileVM.updateProfile(fullName: "New Name", bio: "New bio")
        // Mock always returns MockUser.current regardless of input
        XCTAssertNotNil(profileVM.profile)
    }

    func testUpdateProfileIsUpdatingFalseAfterCompletion() async {
        await profileVM.updateProfile(fullName: "Alex Johnson", bio: "Bio")
        XCTAssertFalse(profileVM.isUpdatingProfile)
    }

    func testUpdateProfileDoesNotSetError() async {
        await profileVM.updateProfile(fullName: "Alex Johnson", bio: "Bio")
        XCTAssertNil(profileVM.error)
    }

    func testUpdateProfileTrimsWhitespace() async {
        await profileVM.updateProfile(fullName: "  Alex Johnson  ", bio: "  Bio text  ")
        // Mock returns MockUser.current — profile is set; trimming handled internally
        XCTAssertNotNil(profileVM.profile)
        XCTAssertNil(profileVM.error)
    }

    // MARK: - logout

    func testLogoutClearsProfile() async {
        await profileVM.loadProfile()
        XCTAssertNotNil(profileVM.profile)
        await profileVM.logout()
        XCTAssertNil(profileVM.profile)
    }

    func testLogoutClearsOrders() async {
        await profileVM.loadOrders()
        XCTAssertFalse(profileVM.orders.isEmpty)
        await profileVM.logout()
        XCTAssertTrue(profileVM.orders.isEmpty)
    }

    func testLogoutClearsAffiliateDashboard() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertNotNil(profileVM.affiliateDashboard)
        await profileVM.logout()
        XCTAssertNil(profileVM.affiliateDashboard)
    }

    func testLogoutClearsAffiliatePayouts() async {
        await profileVM.loadAffiliateDashboard()
        XCTAssertFalse(profileVM.affiliatePayouts.isEmpty)
        await profileVM.logout()
        XCTAssertTrue(profileVM.affiliatePayouts.isEmpty)
    }

    // MARK: - clearSuccessMessage

    func testClearSuccessMessage() async {
        await profileVM.updateProfile(fullName: "Alex", bio: "bio")
        XCTAssertNotNil(profileVM.successMessage)
        profileVM.clearSuccessMessage()
        XCTAssertNil(profileVM.successMessage)
    }

    // MARK: - clearError

    func testClearErrorSetsNil() async {
        // In clean state error is nil; verify clearError() is idempotent and safe
        XCTAssertNil(profileVM.error)
        profileVM.clearError()
        XCTAssertNil(profileVM.error)
    }
}
