import LocalAuthentication
import SwiftUI

// MARK: - BiometricAuthManager
// Checks device biometric capability and performs the Face ID / Touch ID prompt.
// Token storage uses the regular Keychain — Face ID is an explicit gate via
// LAContext.evaluatePolicy(), giving us full control over when the prompt fires.

final class BiometricAuthManager {

    static let shared = BiometricAuthManager()
    private init() {}

    /// Whether the device supports and has enrolled biometrics.
    var isAvailable: Bool {
        let ctx = LAContext()
        var error: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometryType: LABiometryType {
        let ctx = LAContext()
        var error: NSError?
        ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return ctx.biometryType
    }

    var symbolName: String {
        switch biometryType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "faceid"
        }
    }

    var displayName: String {
        switch biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        default:       return "Face ID"
        }
    }

    /// Shows the Face ID / Touch ID prompt.
    /// Returns true if the user authenticated successfully, false otherwise.
    func authenticate(reason: String) async -> Bool {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            return try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
