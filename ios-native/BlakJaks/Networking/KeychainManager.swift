import Foundation
import KeychainAccess

// MARK: - KeychainManager
// Thread-safe JWT token storage using KeychainAccess library.

final class KeychainManager {

    static let shared = KeychainManager()

    // Standard keychain — accessible after first unlock
    private let keychain = Keychain(service: "com.blakjaks.app")
        .accessibility(.afterFirstUnlock)

    private enum Key {
        static let accessToken  = "access_token"
        static let refreshToken = "refresh_token"
        static let loggedInUser = "logged_in_user_id"
        // Biometric keys are user-scoped by ID.
        // Email is stored alongside the token so LoginView can compare the typed
        // email against the enrolled account without waiting for a server round-trip.
        static func biometricFlag(for userId: String)  -> String { "faceid_enabled_\(userId)" }
        static func biometricToken(for userId: String) -> String { "faceid_rt_\(userId)" }
        static func biometricEmail(for userId: String) -> String { "faceid_email_\(userId)" }
    }

    // MARK: Standard tokens

    var accessToken: String? {
        get { try? keychain.get(Key.accessToken) }
        set {
            if let value = newValue { try? keychain.set(value, key: Key.accessToken) }
            else { try? keychain.remove(Key.accessToken) }
        }
    }

    var refreshToken: String? {
        get { try? keychain.get(Key.refreshToken) }
        set {
            if let value = newValue { try? keychain.set(value, key: Key.refreshToken) }
            else { try? keychain.remove(Key.refreshToken) }
        }
    }

    /// The user ID of whoever is currently (or was last) logged in.
    var loggedInUserId: String? {
        get { try? keychain.get(Key.loggedInUser) }
        set {
            if let value = newValue { try? keychain.set(value, key: Key.loggedInUser) }
            else { try? keychain.remove(Key.loggedInUser) }
        }
    }

    func store(tokens: AuthTokens) {
        accessToken  = tokens.accessToken
        refreshToken = tokens.refreshToken
    }

    func clearAll() {
        accessToken  = nil
        refreshToken = nil
        // Do NOT clear biometric enrollment here — if the same user logs back in
        // their Face ID should still work. Enrollment is cleared only on explicit
        // sign-out or when the user disables it.
    }

    var hasCredentials: Bool { accessToken != nil }

    // MARK: Biometric enrollment (user-scoped)
    // Keys are namespaced by user ID so different accounts on the same device
    // each have independent Face ID enrollment. The flag key is a fast plaintext
    // check safe to call during SwiftUI rendering — it never touches the token.

    func isBiometricEnabled(for userId: String) -> Bool {
        (try? keychain.get(Key.biometricFlag(for: userId))) == "1"
    }

    func storeBiometricToken(_ token: String, for userId: String, email: String) {
        try? keychain.set(token, key: Key.biometricToken(for: userId))
        try? keychain.set("1",   key: Key.biometricFlag(for: userId))
        try? keychain.set(email, key: Key.biometricEmail(for: userId))
    }

    func getBiometricToken(for userId: String) -> String? {
        try? keychain.get(Key.biometricToken(for: userId))
    }

    /// The email address of the account enrolled for Face ID on this device.
    func enrolledEmail(for userId: String) -> String? {
        try? keychain.get(Key.biometricEmail(for: userId))
    }

    func clearBiometricToken(for userId: String) {
        try? keychain.remove(Key.biometricToken(for: userId))
        try? keychain.remove(Key.biometricFlag(for: userId))
        try? keychain.remove(Key.biometricEmail(for: userId))
    }
}
