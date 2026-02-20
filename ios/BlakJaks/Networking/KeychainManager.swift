import Foundation
import KeychainAccess

// MARK: - KeychainManager
// Thread-safe JWT token storage using KeychainAccess library.

final class KeychainManager {

    static let shared = KeychainManager()

    private let keychain = Keychain(service: "com.blakjaks.app")
        .accessibility(.afterFirstUnlock)

    private enum Key {
        static let accessToken  = "access_token"
        static let refreshToken = "refresh_token"
    }

    // MARK: - Access Token

    var accessToken: String? {
        get { try? keychain.get(Key.accessToken) }
        set {
            if let value = newValue {
                try? keychain.set(value, key: Key.accessToken)
            } else {
                try? keychain.remove(Key.accessToken)
            }
        }
    }

    // MARK: - Refresh Token

    var refreshToken: String? {
        get { try? keychain.get(Key.refreshToken) }
        set {
            if let value = newValue {
                try? keychain.set(value, key: Key.refreshToken)
            } else {
                try? keychain.remove(Key.refreshToken)
            }
        }
    }

    // MARK: - Helpers

    func store(tokens: AuthTokens) {
        accessToken  = tokens.accessToken
        refreshToken = tokens.refreshToken
    }

    func clearAll() {
        accessToken  = nil
        refreshToken = nil
    }

    var hasCredentials: Bool {
        accessToken != nil
    }
}
