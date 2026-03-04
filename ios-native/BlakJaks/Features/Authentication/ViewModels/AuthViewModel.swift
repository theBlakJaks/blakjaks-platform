import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var username = ""
    @Published var dateOfBirth = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        email.isValidEmail
    }

    var canSignup: Bool {
        canLogin &&
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dateOfBirth.isEmpty &&
        password.count >= 8
    }

    func login(authState: AuthState, enableBiometric: Bool = false) async {
        guard canLogin else { return }
        isLoading = true
        errorMessage = nil
        do {
            _ = try await api.login(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password)

            // Fetch user so we have the ID before doing anything with biometrics
            let user = try await api.getMe()
            let newUserId = "\(user.id)"

            // If a DIFFERENT account is logging in, clear the previous account's
            // Face ID enrollment so it doesn't persist across accounts on this device.
            if let prevUserId = KeychainManager.shared.loggedInUserId,
               prevUserId != newUserId {
                KeychainManager.shared.clearBiometricToken(for: prevUserId)
            }

            KeychainManager.shared.loggedInUserId = newUserId

            // Trigger Face ID permission dialog + initial scan if user opted in
            if enableBiometric, let rt = KeychainManager.shared.refreshToken {
                let granted = await BiometricAuthManager.shared.authenticate(
                    reason: "Enable Face ID sign-in for BlakJaks"
                )
                if granted {
                    let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
                    KeychainManager.shared.storeBiometricToken(rt, for: newUserId, email: normalizedEmail)
                }
            }

            authState.didAuthenticate(user: user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func biometricLogin(authState: AuthState) async {
        isLoading = true
        errorMessage = nil

        // Step 1: We need a user ID to look up the scoped biometric token.
        // Use the last logged-in user ID stored in keychain.
        guard let userId = KeychainManager.shared.loggedInUserId else {
            errorMessage = "No biometric credentials found. Please log in with your password."
            isLoading = false
            return
        }

        guard KeychainManager.shared.isBiometricEnabled(for: userId) else {
            errorMessage = "Face ID is not set up. Please log in with your password."
            isLoading = false
            return
        }

        // Step 2: Show Face ID prompt — no keychain token access yet.
        let authenticated = await BiometricAuthManager.shared.authenticate(
            reason: "Sign in to BlakJaks"
        )
        guard authenticated else {
            isLoading = false
            return
        }

        // Step 3: Face ID passed — read the stored refresh token.
        guard let storedRefreshToken = KeychainManager.shared.getBiometricToken(for: userId) else {
            errorMessage = "No biometric credentials found. Please log in with your password."
            isLoading = false
            return
        }

        // Step 4: Exchange refresh token for a fresh access token.
        do {
            let tokens = try await api.refreshToken(refreshToken: storedRefreshToken)
            KeychainManager.shared.store(tokens: tokens)
            KeychainManager.shared.loggedInUserId = userId
            let user = try await api.getMe()
            authState.didAuthenticate(user: user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            KeychainManager.shared.clearBiometricToken(for: userId)
        }
        isLoading = false
    }

    func signup(authState: AuthState, referralCode: String = "") async {
        guard canSignup else { return }
        isLoading = true
        errorMessage = nil

        let trimmed  = fullName.trimmingCharacters(in: .whitespaces)
        let spaceIdx = trimmed.firstIndex(of: " ")
        let firstName = spaceIdx.map { String(trimmed[..<$0]) } ?? trimmed
        let lastName  = spaceIdx.map { String(trimmed[trimmed.index(after: $0)...]) } ?? ""

        do {
            _ = try await api.signup(
                email:        email.lowercased().trimmingCharacters(in: .whitespaces),
                password:     password,
                firstName:    firstName,
                lastName:     lastName,
                username:     username.trimmingCharacters(in: .whitespaces),
                birthdate:    dateOfBirth,
                referralCode: referralCode.isEmpty ? nil : referralCode
            )
            let user = try await api.getMe()
            KeychainManager.shared.loggedInUserId = "\(user.id)"
            authState.didAuthenticate(user: user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
