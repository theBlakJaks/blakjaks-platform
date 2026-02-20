import Foundation
import KeychainAccess

// Stub — implemented in Task I3 with full Alamofire interceptor integration
class KeychainManager {
    static let shared = KeychainManager()
    private let keychain = Keychain(service: "com.blakjaks.app")

    func saveAccessToken(_ token: String) throws {
        try keychain.set(token, key: "access_token")
    }

    func getAccessToken() -> String? {
        return try? keychain.get("access_token")
    }

    func saveRefreshToken(_ token: String) throws {
        try keychain.set(token, key: "refresh_token")
    }

    func getRefreshToken() -> String? {
        return try? keychain.get("refresh_token")
    }

    func clearAll() {
        try? keychain.remove("access_token")
        try? keychain.remove("refresh_token")
    }
}
