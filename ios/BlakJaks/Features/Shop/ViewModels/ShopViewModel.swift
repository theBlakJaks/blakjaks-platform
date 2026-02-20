import Foundation
@MainActor
class ShopViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let apiClient: APIClientProtocol
    init(apiClient: APIClientProtocol = MockAPIClient()) { self.apiClient = apiClient }
}
