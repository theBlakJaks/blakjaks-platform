import Foundation

// MARK: - ShopViewModel
// Manages product catalog: loading, search filtering, product selection.
// ViewModels follow § 7.1 contract: @MainActor, @Published state, injected APIClientProtocol.

@MainActor
final class ShopViewModel: ObservableObject {

    // MARK: - State

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchQuery = ""
    @Published var selectedCategory: String?

    private let apiClient: APIClientProtocol
    private var allProducts: [Product] = []

    init(apiClient: APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Load

    func loadProducts() async {
        isLoading = true
        error = nil
        do {
            allProducts = try await apiClient.getProducts(category: selectedCategory, limit: 50, offset: 0)
            applyFilters()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func refresh() async {
        allProducts = []
        products = []
        await loadProducts()
    }

    // MARK: - Filtering

    var filteredProducts: [Product] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return products }
        let q = searchQuery.lowercased()
        return products.filter {
            $0.name.lowercased().contains(q) ||
            ($0.flavor?.lowercased().contains(q) ?? false) ||
            $0.category.lowercased().contains(q)
        }
    }

    private func applyFilters() {
        products = allProducts
    }

    // MARK: - Helpers

    func clearError() { error = nil }
}
