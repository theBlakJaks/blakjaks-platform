import SwiftUI
import Combine

@MainActor
final class ShopViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var selectedCategory: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    let categories = ["All", "Pouches", "Cigars", "Accessories", "Limited"]

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    var filteredProducts: [Product] {
        var result = products
        if let cat = selectedCategory, cat != "All" {
            result = result.filter { $0.category.lowercased() == cat.lowercased() }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await api.getProducts(category: nil, limit: 50, offset: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
