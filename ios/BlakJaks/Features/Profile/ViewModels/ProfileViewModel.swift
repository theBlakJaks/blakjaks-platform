import Foundation
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    private let apiClient: APIClientProtocol
    init(apiClient: APIClientProtocol = MockAPIClient()) { self.apiClient = apiClient }
}
