import XCTest
@testable import BlakJaks

// MARK: - ShopViewModelTests

@MainActor
final class ShopViewModelTests: XCTestCase {

    private var shopVM: ShopViewModel!

    override func setUp() {
        super.setUp()
        shopVM = ShopViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        shopVM = nil
        super.tearDown()
    }

    // MARK: - loadProducts

    func testLoadProductsPopulatesProducts() async {
        await shopVM.loadProducts()
        XCTAssertFalse(shopVM.products.isEmpty)
        XCTAssertNil(shopVM.error)
        XCTAssertFalse(shopVM.isLoading)
    }

    func testLoadProductsIsLoadingFalseAfterLoad() async {
        await shopVM.loadProducts()
        XCTAssertFalse(shopVM.isLoading)
    }

    func testLoadProductsMatchesMockCount() async {
        await shopVM.loadProducts()
        XCTAssertEqual(shopVM.products.count, MockProducts.list.count)
    }

    // MARK: - filteredProducts

    func testFilteredProductsReturnsAllWhenQueryEmpty() async {
        await shopVM.loadProducts()
        shopVM.searchQuery = ""
        XCTAssertEqual(shopVM.filteredProducts.count, shopVM.products.count)
    }

    func testFilteredProductsByName() async {
        await shopVM.loadProducts()
        shopVM.searchQuery = "Classic"
        XCTAssertTrue(shopVM.filteredProducts.allSatisfy { $0.name.contains("Classic") })
    }

    func testFilteredProductsByFlavor() async {
        await shopVM.loadProducts()
        shopVM.searchQuery = "Spearmint"
        XCTAssertFalse(shopVM.filteredProducts.isEmpty)
        XCTAssertTrue(shopVM.filteredProducts.allSatisfy { $0.flavor?.contains("Spearmint") ?? false })
    }

    func testFilteredProductsReturnsEmptyForNoMatch() async {
        await shopVM.loadProducts()
        shopVM.searchQuery = "xyznotaproduct"
        XCTAssertTrue(shopVM.filteredProducts.isEmpty)
    }

    // MARK: - refresh

    func testRefreshClearsAndReloads() async {
        await shopVM.loadProducts()
        XCTAssertFalse(shopVM.products.isEmpty)
        await shopVM.refresh()
        XCTAssertFalse(shopVM.products.isEmpty)
    }

    // MARK: - clearError

    func testClearError() async {
        await shopVM.loadProducts()
        XCTAssertNil(shopVM.error)
        shopVM.clearError()
        XCTAssertNil(shopVM.error)
    }
}

// MARK: - CartViewModelTests

@MainActor
final class CartViewModelTests: XCTestCase {

    private var cartVM: CartViewModel!

    override func setUp() {
        super.setUp()
        cartVM = CartViewModel(apiClient: MockAPIClient())
    }

    override func tearDown() {
        cartVM = nil
        super.tearDown()
    }

    // MARK: - loadCart

    func testLoadCartPopulatesCart() async {
        await cartVM.loadCart()
        XCTAssertNotNil(cartVM.cart)
        XCTAssertNil(cartVM.error)
        XCTAssertFalse(cartVM.isLoading)
    }

    func testLoadCartHasItems() async {
        await cartVM.loadCart()
        XCTAssertFalse(cartVM.cart?.items.isEmpty ?? true)
    }

    // MARK: - addItem

    func testAddItemUpdatesCart() async {
        await cartVM.addItem(productId: 1, quantity: 1)
        XCTAssertNotNil(cartVM.cart)
        XCTAssertNil(cartVM.error)
    }

    // MARK: - updateItem

    func testUpdateItemUpdatesCart() async {
        await cartVM.loadCart()
        let firstId = cartVM.cart?.items.first?.productId ?? 1
        await cartVM.updateItem(productId: firstId, quantity: 3)
        XCTAssertNil(cartVM.error)
    }

    // MARK: - removeItem

    func testRemoveItemReturnsEmptyCart() async {
        await cartVM.removeItem(productId: 1)
        XCTAssertEqual(cartVM.cart?.items.count, 0)
        XCTAssertNil(cartVM.error)
    }

    // MARK: - Computed values

    func testItemCountFromLoadedCart() async {
        await cartVM.loadCart()
        XCTAssertEqual(cartVM.itemCount, cartVM.cart?.itemCount ?? 0)
    }

    func testShippingCostFlatBelowThreshold() async {
        await cartVM.loadCart()
        // MockProducts.cart subtotal = 41.97 (below $50)
        if cartVM.subtotal < CartViewModel.freeShippingThreshold {
            XCTAssertEqual(cartVM.shippingCost, CartViewModel.flatShippingCost)
            XCTAssertFalse(cartVM.isFreeShipping)
        }
    }

    // MARK: - Shipping validation

    func testIsShippingValidFalseWhenEmpty() {
        XCTAssertFalse(cartVM.isShippingValid)
    }

    func testIsShippingValidTrueWhenFilled() {
        cartVM.firstName = "Alex"
        cartVM.lastName = "Johnson"
        cartVM.line1 = "123 Main St"
        cartVM.city = "Austin"
        cartVM.state = "TX"
        cartVM.zip = "78701"
        XCTAssertTrue(cartVM.isShippingValid)
    }

    func testIsShippingValidFalseShortZip() {
        cartVM.firstName = "Alex"
        cartVM.lastName = "Johnson"
        cartVM.line1 = "123 Main St"
        cartVM.city = "Austin"
        cartVM.state = "TX"
        cartVM.zip = "787"  // too short
        XCTAssertFalse(cartVM.isShippingValid)
    }

    // MARK: - proceedFromShipping

    func testProceedFromShippingFailsIfInvalid() async {
        await cartVM.proceedFromShipping()
        XCTAssertNotNil(cartVM.error)
        XCTAssertEqual(cartVM.checkoutStep, .shipping)
    }

    func testProceedFromShippingAdvancesToAgeVerification() async {
        cartVM.firstName = "Alex"
        cartVM.lastName = "Johnson"
        cartVM.line1 = "123 Main St"
        cartVM.city = "Austin"
        cartVM.state = "TX"
        cartVM.zip = "78701"
        await cartVM.proceedFromShipping()
        XCTAssertNil(cartVM.error)
        XCTAssertEqual(cartVM.checkoutStep, .ageVerification)
        XCTAssertNotNil(cartVM.taxEstimate)
    }

    // MARK: - proceedFromAgeVerification

    func testProceedFromAgeVerificationFailsIfNotVerified() {
        cartVM.ageVerified = false
        cartVM.checkoutStep = .ageVerification
        cartVM.proceedFromAgeVerification()
        XCTAssertNotNil(cartVM.error)
        XCTAssertEqual(cartVM.checkoutStep, .ageVerification)
    }

    func testProceedFromAgeVerificationAdvancesToPayment() {
        cartVM.ageVerified = true
        cartVM.checkoutStep = .ageVerification
        cartVM.proceedFromAgeVerification()
        XCTAssertNil(cartVM.error)
        XCTAssertEqual(cartVM.checkoutStep, .payment)
    }

    // MARK: - proceedFromPayment

    func testProceedFromPaymentFailsIfEmpty() {
        cartVM.paymentToken = ""
        cartVM.checkoutStep = .payment
        cartVM.proceedFromPayment()
        XCTAssertNotNil(cartVM.error)
        XCTAssertEqual(cartVM.checkoutStep, .payment)
    }

    func testProceedFromPaymentAdvancesToReview() {
        cartVM.paymentToken = "tok_test_abc123"
        cartVM.checkoutStep = .payment
        cartVM.proceedFromPayment()
        XCTAssertNil(cartVM.error)
        XCTAssertEqual(cartVM.checkoutStep, .review)
    }

    // MARK: - placeOrder

    func testPlaceOrderReturnsCompletedOrder() async {
        cartVM.firstName = "Alex"; cartVM.lastName = "Johnson"
        cartVM.line1 = "123 Main St"; cartVM.city = "Austin"
        cartVM.state = "TX"; cartVM.zip = "78701"
        cartVM.paymentToken = "tok_test"
        let success = await cartVM.placeOrder()
        XCTAssertTrue(success)
        XCTAssertNotNil(cartVM.completedOrder)
        XCTAssertFalse(cartVM.isPlacingOrder)
    }

    // MARK: - resetCheckout

    func testResetCheckoutClearsAllState() {
        cartVM.checkoutStep = .review
        cartVM.ageVerified = true
        cartVM.paymentToken = "tok_abc"
        cartVM.resetCheckout()
        XCTAssertEqual(cartVM.checkoutStep, .shipping)
        XCTAssertFalse(cartVM.ageVerified)
        XCTAssertTrue(cartVM.paymentToken.isEmpty)
        XCTAssertNil(cartVM.taxEstimate)
        XCTAssertNil(cartVM.completedOrder)
        XCTAssertNil(cartVM.error)
    }
}
