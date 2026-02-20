import Foundation
@MainActor
class CartViewModel: ObservableObject {
    @Published var cart: Cart?
    @Published var isLoading = false
    @Published var error: Error?
    private let apiClient: APIClientProtocol
    init(apiClient: APIClientProtocol = MockAPIClient()) { self.apiClient = apiClient }
}
