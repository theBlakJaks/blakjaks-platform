import XCTest
@testable import BlakJaks

// MARK: - AuthViewModelTests
// Tests AuthViewModel against MockAPIClient — no network required.

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var viewModel: AuthViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel(apiClient: MockAPIClient(), keychain: KeychainManager())
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Login Success

    func testLoginSuccessReturnsTrue() async {
        viewModel.email    = "test@blakjaks.com"
        viewModel.password = "password123"

        let result = await viewModel.login()

        XCTAssertTrue(result)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Login Validation Failures

    func testLoginFailsWithEmptyEmail() async {
        viewModel.email    = ""
        viewModel.password = "password123"

        let result = await viewModel.login()

        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.error)
    }

    func testLoginFailsWithInvalidEmail() async {
        viewModel.email    = "notanemail"
        viewModel.password = "password123"

        let result = await viewModel.login()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.error?.localizedDescription, ValidationError.invalidEmail.localizedDescription)
    }

    func testLoginFailsWithShortPassword() async {
        viewModel.email    = "test@blakjaks.com"
        viewModel.password = "1234567"  // 7 chars — below 8 minimum

        let result = await viewModel.login()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.error?.localizedDescription, ValidationError.weakPassword.localizedDescription)
    }

    // MARK: - Signup Success

    func testSignupSuccessReturnsTrue() async {
        viewModel.email    = "newuser@blakjaks.com"
        viewModel.password = "securepass"
        viewModel.fullName = "Jane Doe"
        viewModel.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!

        let result = await viewModel.signup()

        XCTAssertTrue(result)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Signup Validation Failures

    func testSignupFailsWithMissingFullName() async {
        viewModel.email    = "test@blakjaks.com"
        viewModel.password = "password123"
        viewModel.fullName = "   "
        viewModel.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        let result = await viewModel.signup()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.error?.localizedDescription, ValidationError.missingFullName.localizedDescription)
    }

    func testSignupFailsWhenUnder21() async {
        viewModel.email    = "young@blakjaks.com"
        viewModel.password = "password123"
        viewModel.fullName = "Young User"
        viewModel.dateOfBirth = Calendar.current.date(byAdding: .year, value: -18, to: Date())!

        let result = await viewModel.signup()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.error?.localizedDescription, ValidationError.ageRequirement.localizedDescription)
    }

    // MARK: - Age Check

    func testIsOldEnoughWith21YearOld() {
        viewModel.dateOfBirth = Calendar.current.date(byAdding: .year, value: -21, to: Date())!
        XCTAssertTrue(viewModel.isOldEnough)
    }

    func testIsOldEnoughWith20YearOld() {
        viewModel.dateOfBirth = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
        XCTAssertFalse(viewModel.isOldEnough)
    }

    // MARK: - isLoading resets after call

    func testLoadingIsFalseAfterLoginCompletes() async {
        viewModel.email    = "test@blakjaks.com"
        viewModel.password = "password123"
        _ = await viewModel.login()
        XCTAssertFalse(viewModel.isLoading)
    }

    func testClearError() async {
        viewModel.email    = ""
        viewModel.password = "password123"
        _ = await viewModel.login()
        XCTAssertNotNil(viewModel.error)
        viewModel.clearError()
        XCTAssertNil(viewModel.error)
    }
}
