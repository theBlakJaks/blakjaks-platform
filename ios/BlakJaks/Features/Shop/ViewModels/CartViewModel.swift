import Foundation

// MARK: - CheckoutStep

enum CheckoutStep: Int, CaseIterable {
    case shipping = 0
    case ageVerification = 1
    case payment = 2
    case review = 3

    var title: String {
        switch self {
        case .shipping:        return "Shipping"
        case .ageVerification: return "Age Verify"
        case .payment:         return "Payment"
        case .review:          return "Review"
        }
    }

    var systemIcon: String {
        switch self {
        case .shipping:        return "shippingbox"
        case .ageVerification: return "person.badge.shield.checkmark"
        case .payment:         return "creditcard"
        case .review:          return "checkmark.seal"
        }
    }
}

// MARK: - CartViewModel
// Manages cart state plus 4-step checkout flow.
// Shared between CartView and CheckoutView via @ObservedObject.

@MainActor
final class CartViewModel: ObservableObject {

    // MARK: - Cart State

    @Published var cart: Cart?
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Checkout Flow State

    @Published var checkoutStep: CheckoutStep = .shipping
    @Published var isPlacingOrder = false

    // Step 1: Shipping Address
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var line1 = ""
    @Published var line2 = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zip = ""

    // Step 2: Age Verification
    @Published var ageVerified = false
    @Published var ageVerificationId: String?

    // Step 3: Payment (stub — Braintree nonce in production)
    @Published var paymentToken = ""

    // Tax
    @Published var taxEstimate: TaxEstimate?

    // Completed order (set on success, triggers navigation to confirmation)
    @Published var completedOrder: Order?

    // MARK: - Constants

    static let freeShippingThreshold: Double = 50.0
    static let flatShippingCost: Double = 2.99

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Cart Operations

    func loadCart() async {
        isLoading = true
        error = nil
        do {
            cart = try await apiClient.getCart()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func addItem(productId: Int, quantity: Int) async {
        isLoading = true
        error = nil
        do {
            cart = try await apiClient.addToCart(productId: productId, quantity: quantity)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func updateItem(productId: Int, quantity: Int) async {
        isLoading = true
        error = nil
        do {
            cart = try await apiClient.updateCartItem(productId: productId, quantity: quantity)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func removeItem(productId: Int) async {
        isLoading = true
        error = nil
        do {
            cart = try await apiClient.removeFromCart(productId: productId)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    // MARK: - Computed Cart Values

    var itemCount: Int { cart?.itemCount ?? 0 }
    var subtotal: Double { cart?.subtotal ?? 0 }
    var shippingCost: Double { subtotal >= Self.freeShippingThreshold ? 0 : Self.flatShippingCost }
    var isFreeShipping: Bool { subtotal >= Self.freeShippingThreshold }
    var taxAmount: Double { taxEstimate?.taxAmount ?? 0 }
    var orderTotal: Double { subtotal + shippingCost + taxAmount }

    // MARK: - Shipping Validation

    var isShippingValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !line1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !state.trimmingCharacters(in: .whitespaces).isEmpty &&
        zip.trimmingCharacters(in: .whitespaces).count >= 5
    }

    var currentShippingAddress: ShippingAddress {
        ShippingAddress(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            line1: line1.trimmingCharacters(in: .whitespaces),
            line2: line2.trimmingCharacters(in: .whitespaces).isEmpty ? nil : line2.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            state: state.uppercased().trimmingCharacters(in: .whitespaces),
            zip: zip.trimmingCharacters(in: .whitespaces),
            country: "US"
        )
    }

    // MARK: - Checkout Steps

    func proceedFromShipping() async {
        guard isShippingValid else {
            error = CheckoutError.invalidShippingAddress
            return
        }
        isLoading = true
        error = nil
        do {
            taxEstimate = try await apiClient.estimateTax(shippingAddress: currentShippingAddress)
            checkoutStep = .ageVerification
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func proceedFromAgeVerification() {
        guard ageVerified else {
            error = CheckoutError.ageVerificationRequired
            return
        }
        checkoutStep = .payment
    }

    func proceedFromPayment() {
        guard !paymentToken.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = CheckoutError.paymentRequired
            return
        }
        checkoutStep = .review
    }

    func placeOrder() async -> Bool {
        isPlacingOrder = true
        error = nil
        do {
            completedOrder = try await apiClient.createOrder(
                shippingAddress: currentShippingAddress,
                paymentToken: paymentToken
            )
            isPlacingOrder = false
            return true
        } catch {
            self.error = error
            isPlacingOrder = false
            return false
        }
    }

    // MARK: - Helpers

    func clearError() { error = nil }

    func resetCheckout() {
        checkoutStep = .shipping
        ageVerified = false
        ageVerificationId = nil
        paymentToken = ""
        taxEstimate = nil
        completedOrder = nil
        error = nil
    }
}

// MARK: - CheckoutError

enum CheckoutError: LocalizedError {
    case invalidShippingAddress
    case ageVerificationRequired
    case paymentRequired

    var errorDescription: String? {
        switch self {
        case .invalidShippingAddress:  return "Please fill in all required shipping fields."
        case .ageVerificationRequired: return "Age verification is required to purchase nicotine products."
        case .paymentRequired:         return "Please enter payment information."
        }
    }
}
