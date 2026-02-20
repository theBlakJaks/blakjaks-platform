import Foundation

// MARK: - ProfileViewModel
// Manages profile, orders, and affiliate data for the Profile tab.
// Inject a custom APIClientProtocol for testing or previews.

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published State

    @Published var profile: UserProfile? = nil
    @Published var orders: [Order] = []
    @Published var affiliateDashboard: AffiliateDashboard? = nil
    @Published var affiliatePayouts: [AffiliatePayout] = []

    @Published var isLoadingProfile = false
    @Published var isLoadingOrders = false
    @Published var isUpdatingProfile = false

    @Published var error: Error? = nil
    @Published var successMessage: String? = nil

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Profile

    func loadProfile() async {
        isLoadingProfile = true
        error = nil
        do {
            profile = try await apiClient.getMe()
        } catch {
            self.error = error
        }
        isLoadingProfile = false
    }

    // MARK: - Orders
    // No getOrders() endpoint yet — stubbed with MockProducts.order duplicated.
    // Wire to real API in production polish pass.

    func loadOrders() async {
        isLoadingOrders = true
        // Simulate brief async work so callers can await correctly
        try? await Task.sleep(nanoseconds: 200_000_000)
        orders = [MockProducts.order, MockProducts.order]
        isLoadingOrders = false
    }

    // MARK: - Affiliate Dashboard

    func loadAffiliateDashboard() async {
        error = nil
        do {
            async let dashboard = apiClient.getAffiliateDashboard()
            async let payouts = apiClient.getAffiliatePayouts(limit: 25, offset: 0)
            affiliateDashboard = try await dashboard
            affiliatePayouts = try await payouts
        } catch {
            self.error = error
        }
    }

    // MARK: - Profile Updates

    func updateProfile(fullName: String, bio: String) async {
        isUpdatingProfile = true
        error = nil
        do {
            profile = try await apiClient.updateProfile(
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                bio: bio.trimmingCharacters(in: .whitespaces)
            )
            successMessage = "Profile updated."
        } catch {
            self.error = error
        }
        isUpdatingProfile = false
    }

    func uploadAvatar(imageData: Data) async {
        error = nil
        do {
            profile = try await apiClient.uploadAvatar(imageData: imageData, mimeType: "image/jpeg")
            successMessage = "Avatar updated."
        } catch {
            self.error = error
        }
    }

    // MARK: - Session

    func logout() async {
        error = nil
        do {
            try await apiClient.logout()
        } catch {
            // Swallow logout errors — clear state regardless
        }
        profile = nil
        orders = []
        affiliateDashboard = nil
        affiliatePayouts = []
    }

    // MARK: - Helpers

    func clearError() {
        error = nil
    }

    func clearSuccessMessage() {
        successMessage = nil
    }
}
