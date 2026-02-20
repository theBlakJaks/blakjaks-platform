import Foundation

// Stub — fully implemented in Task I3
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }
}
