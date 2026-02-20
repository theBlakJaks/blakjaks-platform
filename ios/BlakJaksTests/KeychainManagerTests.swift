import XCTest
@testable import BlakJaks

// MARK: - KeychainManagerTests
// Unit tests for token storage and retrieval.
// Uses a fresh KeychainManager (not the singleton) to avoid polluting real keychain.

final class KeychainManagerTests: XCTestCase {

    private var keychain: KeychainManager!

    override func setUp() {
        super.setUp()
        keychain = KeychainManager()
        keychain.clearAll()
    }

    override func tearDown() {
        keychain.clearAll()
        keychain = nil
        super.tearDown()
    }

    func testStoreAndRetrieveAccessToken() {
        keychain.accessToken = "test_access_123"
        XCTAssertEqual(keychain.accessToken, "test_access_123")
    }

    func testStoreAndRetrieveRefreshToken() {
        keychain.refreshToken = "test_refresh_456"
        XCTAssertEqual(keychain.refreshToken, "test_refresh_456")
    }

    func testStoreTokensFromAuthTokens() {
        let tokens = AuthTokens(
            accessToken: "acc_abc",
            refreshToken: "ref_xyz",
            tokenType: "Bearer"
        )
        keychain.store(tokens: tokens)
        XCTAssertEqual(keychain.accessToken, "acc_abc")
        XCTAssertEqual(keychain.refreshToken, "ref_xyz")
    }

    func testClearAllRemovesTokens() {
        keychain.accessToken  = "acc"
        keychain.refreshToken = "ref"
        keychain.clearAll()
        XCTAssertNil(keychain.accessToken)
        XCTAssertNil(keychain.refreshToken)
    }

    func testHasCredentialsTrueWhenAccessTokenPresent() {
        keychain.accessToken = "token"
        XCTAssertTrue(keychain.hasCredentials)
    }

    func testHasCredentialsFalseWhenEmpty() {
        XCTAssertFalse(keychain.hasCredentials)
    }

    func testOverwriteAccessToken() {
        keychain.accessToken = "first"
        keychain.accessToken = "second"
        XCTAssertEqual(keychain.accessToken, "second")
    }

    func testNilAccessTokenRemovesEntry() {
        keychain.accessToken = "token"
        XCTAssertNotNil(keychain.accessToken)
        keychain.accessToken = nil
        XCTAssertNil(keychain.accessToken)
    }
}
