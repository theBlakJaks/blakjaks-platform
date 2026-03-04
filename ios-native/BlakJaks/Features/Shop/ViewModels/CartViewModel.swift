import SwiftUI
import Combine

@MainActor
final class CartViewModel: ObservableObject {
    @Published var cart: Cart?
    @Published var taxEstimate: TaxEstimate?
    @Published var isLoading = false
    @Published var isCheckingOut = false
    @Published var errorMessage: String?
    @Published var lastOrder: Order?
    @Published var shippingAddress = ShippingAddress(
        firstName: "", lastName: "", line1: "", line2: nil,
        city: "", state: "", zip: "", country: "US"
    )

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    var itemCount: Int { cart?.itemCount ?? 0 }
    var subtotal: Double { cart?.subtotal ?? 0 }

    func loadCart() async {
        isLoading = true
        do {
            cart = try await api.getCart()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addToCart(productId: Int, quantity: Int = 1) async {
        do {
            cart = try await api.addToCart(productId: productId, quantity: quantity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateItem(productId: Int, quantity: Int) async {
        do {
            cart = try await api.updateCartItem(productId: productId, quantity: quantity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeItem(productId: Int) async {
        do {
            cart = try await api.removeFromCart(productId: productId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func estimateTax() async {
        guard !shippingAddress.zip.isEmpty else { return }
        do {
            taxEstimate = try await api.estimateTax(shippingAddress: shippingAddress)
        } catch {
            // Non-fatal — just hide tax line
        }
    }

    func checkout(paymentToken: String) async {
        isCheckingOut = true
        errorMessage = nil
        do {
            lastOrder = try await api.createOrder(shippingAddress: shippingAddress, paymentToken: paymentToken)
            cart = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isCheckingOut = false
    }
}
