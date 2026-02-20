import Foundation
import LocalAuthentication

// MARK: - AuthViewModel
// Follows iOS Strategy § 7.1 ViewModel Contract.
// All auth state flows through this single object.

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State

    @Published var isLoading = false
    @Published var error: Error?

    // Input fields (two-way bound from views)
    @Published var email    = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var dateOfBirth: Date = Calendar.current.date(
        byAdding: .year, value: -21, to: Date()
    ) ?? Date()

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol
    private let keychain: KeychainManager

    init(
        apiClient: APIClientProtocol = APIClient.shared,
        keychain: KeychainManager   = .shared
    ) {
        self.apiClient = apiClient
        self.keychain  = keychain
    }

    // MARK: - Login

    func login() async -> Bool {
        guard validate(for: .login) else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await apiClient.login(email: email, password: password)
            return true
        } catch {
            self.error = error
            return false
        }
    }

    // MARK: - Signup

    func signup() async -> Bool {
        guard validate(for: .signup) else { return false }
        isLoading = true
        defer { isLoading = false }
        let dobString = ISO8601DateFormatter().string(from: dateOfBirth)
        do {
            _ = try await apiClient.signup(
                email: email,
                password: password,
                fullName: fullName,
                dateOfBirth: dobString
            )
            return true
        } catch {
            self.error = error
            return false
        }
    }

    // MARK: - Logout

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        try? await apiClient.logout()  // Best-effort: always clear local state
        keychain.clearAll()
    }

    // MARK: - Biometric Login

    func loginWithBiometrics() async -> Bool {
        let context = LAContext()
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            self.error = authError
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to BlakJaks"
            )
            if success {
                // Credentials already in Keychain from previous login — just validate they're present
                return keychain.hasCredentials
            }
            return false
        } catch {
            self.error = error
            return false
        }
    }

    // MARK: - Biometric Enrollment

    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    var biometricLabel: String {
        switch biometricType {
        case .faceID:   return "Face ID"
        case .touchID:  return "Touch ID"
        case .opticID:  return "Optic ID"
        default:        return "Biometrics"
        }
    }

    // MARK: - Validation

    enum ValidationContext { case login, signup }

    private func validate(for context: ValidationContext) -> Bool {
        guard !email.isEmpty, email.contains("@") else {
            self.error = ValidationError.invalidEmail
            return false
        }
        guard password.count >= 8 else {
            self.error = ValidationError.weakPassword
            return false
        }
        if context == .signup {
            guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
                self.error = ValidationError.missingFullName
                return false
            }
            guard isOldEnough else {
                self.error = ValidationError.ageRequirement
                return false
            }
        }
        return true
    }

    var isOldEnough: Bool {
        guard let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year else {
            return false
        }
        return age >= 21
    }

    func clearError() { error = nil }
}

// MARK: - ValidationError

enum ValidationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case missingFullName
    case ageRequirement

    var errorDescription: String? {
        switch self {
        case .invalidEmail:    return "Please enter a valid email address."
        case .weakPassword:    return "Password must be at least 8 characters."
        case .missingFullName: return "Please enter your full name."
        case .ageRequirement:  return "You must be 21 or older to create an account."
        }
    }
}
