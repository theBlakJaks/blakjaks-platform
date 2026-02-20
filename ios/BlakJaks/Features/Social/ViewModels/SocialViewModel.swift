import Foundation
@MainActor
class SocialViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    private let apiClient: APIClientProtocol
    init(apiClient: APIClientProtocol = MockAPIClient()) { self.apiClient = apiClient }
}
