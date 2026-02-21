package com.blakjaks.app

import com.blakjaks.app.features.shop.CartViewModel
import com.blakjaks.app.features.shop.CheckoutStep
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CartViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: CartViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = CartViewModel(apiClient = MockApiClient())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── loadCart populates cart ──────────────────────────────────────────────

    @Test
    fun `loadCart populates cart`() = runTest {
        viewModel.loadCart()
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull("Cart should be non-null after loadCart", viewModel.cart.value)
        assertTrue("Cart should have items", viewModel.cart.value!!.items.isNotEmpty())
    }

    // ─── addItem updates cart ─────────────────────────────────────────────────

    @Test
    fun `addItem updates cart`() = runTest {
        viewModel.addItem(productId = 1, quantity = 2)
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull("Cart should not be null after addItem", viewModel.cart.value)
    }

    // ─── updateItem updates cart ──────────────────────────────────────────────

    @Test
    fun `updateItem updates cart`() = runTest {
        viewModel.loadCart()
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.updateItem(productId = 1, quantity = 5)
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull("Cart should not be null after updateItem", viewModel.cart.value)
    }

    // ─── removeItem updates cart ──────────────────────────────────────────────

    @Test
    fun `removeItem updates cart`() = runTest {
        viewModel.loadCart()
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.removeItem(productId = 1)
        testDispatcher.scheduler.advanceUntilIdle()
        // MockApiClient returns empty cart on removeFromCart
        val cart = viewModel.cart.value
        assertNotNull(cart)
        assertEquals("Cart should be empty after removeItem (mock)", 0, cart!!.items.size)
    }

    // ─── itemCount returns correct count from cart ────────────────────────────

    @Test
    fun `itemCount returns correct value`() = runTest {
        viewModel.loadCart()
        testDispatcher.scheduler.advanceUntilIdle()
        // MockApiClient mockCart has itemCount = 3
        assertEquals(3, viewModel.itemCount)
    }

    // ─── shippingCost is flat rate when subtotal below threshold ──────────────

    @Test
    fun `shippingCost is flat rate when subtotal below threshold`() = runTest {
        viewModel.loadCart()
        testDispatcher.scheduler.advanceUntilIdle()
        // MockApiClient mockCart subtotal = 41.97 (below 50.0 threshold)
        val subtotal = viewModel.subtotal
        assertTrue("Subtotal should be below free shipping threshold", subtotal < CartViewModel.FREE_SHIPPING_THRESHOLD)
        assertEquals(CartViewModel.FLAT_SHIPPING_COST, viewModel.shippingCost, 0.001)
    }

    // ─── shippingCost is zero when subtotal meets threshold ───────────────────

    @Test
    fun `shippingCost is zero when subtotal meets or exceeds threshold`() = runTest {
        // Load a cart, then manually set a high subtotal via a custom mock
        val richClient = object : MockApiClient() {
            override suspend fun getCart() = com.blakjaks.app.core.network.models.Cart(
                items = emptyList(),
                subtotal = 75.0,
                itemCount = 0
            )
        }
        val richViewModel = CartViewModel(apiClient = richClient)
        richViewModel.loadCart()
        testDispatcher.scheduler.advanceUntilIdle()
        assertEquals(0.0, richViewModel.shippingCost, 0.001)
        assertTrue(richViewModel.isFreeShipping)
    }

    // ─── isShippingValid false when fields empty ──────────────────────────────

    @Test
    fun `isShippingValid false when empty`() {
        assertFalse("isShippingValid should be false with empty fields", viewModel.isShippingValid)
    }

    // ─── isShippingValid true when all fields valid ───────────────────────────

    @Test
    fun `isShippingValid true when fully filled`() {
        viewModel.firstName.value = "Alex"
        viewModel.lastName.value  = "Johnson"
        viewModel.line1.value     = "123 Main St"
        viewModel.city.value      = "Austin"
        viewModel.state.value     = "TX"
        viewModel.zip.value       = "78701"
        assertTrue("isShippingValid should be true when all required fields filled", viewModel.isShippingValid)
    }

    // ─── isShippingValid false when zip is too short ──────────────────────────

    @Test
    fun `isShippingValid false when zip too short`() {
        viewModel.firstName.value = "Alex"
        viewModel.lastName.value  = "Johnson"
        viewModel.line1.value     = "123 Main St"
        viewModel.city.value      = "Austin"
        viewModel.state.value     = "TX"
        viewModel.zip.value       = "787" // only 3 chars
        assertFalse("isShippingValid should be false when zip has fewer than 5 digits", viewModel.isShippingValid)
    }

    // ─── proceedFromShipping fails if fields invalid ──────────────────────────

    @Test
    fun `proceedFromShipping fails if shipping invalid`() = runTest {
        // All fields blank
        viewModel.proceedFromShipping()
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull("Error should be set when shipping invalid", viewModel.error.value)
        assertTrue(
            "CheckoutStep should still be Shipping",
            viewModel.checkoutStep.value is CheckoutStep.Shipping
        )
    }

    // ─── proceedFromShipping advances to AgeVerification when valid ───────────

    @Test
    fun `proceedFromShipping advances to AgeVerification when valid`() = runTest {
        viewModel.firstName.value = "Alex"
        viewModel.lastName.value  = "Johnson"
        viewModel.line1.value     = "123 Main St"
        viewModel.city.value      = "Austin"
        viewModel.state.value     = "TX"
        viewModel.zip.value       = "78701"
        viewModel.proceedFromShipping()
        testDispatcher.scheduler.advanceUntilIdle()
        assertNull("Error should be null after valid shipping proceed", viewModel.error.value)
        assertTrue(
            "CheckoutStep should advance to AgeVerification",
            viewModel.checkoutStep.value is CheckoutStep.AgeVerification
        )
        assertNotNull("Tax estimate should be populated", viewModel.taxEstimate.value)
    }

    // ─── proceedFromAgeVerification fails if not verified ─────────────────────

    @Test
    fun `proceedFromAgeVerification fails if not verified`() = runTest {
        viewModel.ageVerified.value = false
        viewModel.proceedFromAgeVerification()
        assertNotNull("Error should be set when age not verified", viewModel.error.value)
        assertTrue(
            "CheckoutStep should not advance",
            viewModel.checkoutStep.value is CheckoutStep.Shipping
        )
    }

    // ─── proceedFromAgeVerification advances to Payment when verified ─────────

    @Test
    fun `proceedFromAgeVerification advances to Payment when verified`() = runTest {
        // Manually set step to AgeVerification
        viewModel.checkoutStep.value = CheckoutStep.AgeVerification
        viewModel.ageVerified.value = true
        viewModel.proceedFromAgeVerification()
        assertNull("Error should be null after age verified", viewModel.error.value)
        assertTrue(
            "CheckoutStep should advance to Payment",
            viewModel.checkoutStep.value is CheckoutStep.Payment
        )
    }

    // ─── proceedFromPayment fails if token empty ──────────────────────────────

    @Test
    fun `proceedFromPayment fails if empty token`() = runTest {
        viewModel.checkoutStep.value = CheckoutStep.Payment
        viewModel.paymentToken.value = ""
        viewModel.proceedFromPayment()
        assertNotNull("Error should be set when payment token empty", viewModel.error.value)
        assertTrue(
            "CheckoutStep should not advance from Payment",
            viewModel.checkoutStep.value is CheckoutStep.Payment
        )
    }

    // ─── proceedFromPayment advances to Review when token present ────────────

    @Test
    fun `proceedFromPayment advances to Review when token present`() = runTest {
        viewModel.checkoutStep.value = CheckoutStep.Payment
        viewModel.paymentToken.value = "tok_test_abc123"
        viewModel.proceedFromPayment()
        assertNull("Error should be null with valid token", viewModel.error.value)
        assertTrue(
            "CheckoutStep should advance to Review",
            viewModel.checkoutStep.value is CheckoutStep.Review
        )
    }

    // ─── placeOrder returns completed order ───────────────────────────────────

    @Test
    fun `placeOrder returns completed order`() = runTest {
        viewModel.firstName.value    = "Alex"
        viewModel.lastName.value     = "Johnson"
        viewModel.line1.value        = "123 Main St"
        viewModel.city.value         = "Austin"
        viewModel.state.value        = "TX"
        viewModel.zip.value          = "78701"
        viewModel.paymentToken.value = "tok_test_abc123"
        viewModel.placeOrder()
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull("completedOrder should be non-null after placeOrder", viewModel.completedOrder.value)
        assertTrue(
            "CheckoutStep should advance to Confirmation",
            viewModel.checkoutStep.value is CheckoutStep.Confirmation
        )
    }

    // ─── resetCheckout clears all state ──────────────────────────────────────

    @Test
    fun `resetCheckout clears all state`() = runTest {
        // Set some state
        viewModel.firstName.value    = "Alex"
        viewModel.paymentToken.value = "tok_test_abc123"
        viewModel.ageVerified.value  = true
        viewModel.checkoutStep.value = CheckoutStep.Review

        // Simulate a completed order
        viewModel.placeOrder()
        testDispatcher.scheduler.advanceUntilIdle()

        // Reset
        viewModel.resetCheckout()

        assertEquals("firstName should be empty", "", viewModel.firstName.value)
        assertEquals("lastName should be empty", "", viewModel.lastName.value)
        assertEquals("line1 should be empty", "", viewModel.line1.value)
        assertEquals("city should be empty", "", viewModel.city.value)
        assertEquals("state should be empty", "", viewModel.state.value)
        assertEquals("zip should be empty", "", viewModel.zip.value)
        assertEquals("paymentToken should be empty", "", viewModel.paymentToken.value)
        assertFalse("ageVerified should be false", viewModel.ageVerified.value)
        assertNull("taxEstimate should be null", viewModel.taxEstimate.value)
        assertNull("completedOrder should be null", viewModel.completedOrder.value)
        assertNull("error should be null", viewModel.error.value)
        assertTrue(
            "CheckoutStep should reset to Shipping",
            viewModel.checkoutStep.value is CheckoutStep.Shipping
        )
    }

    // ─── clearError sets error to null ────────────────────────────────────────

    @Test
    fun `clearError sets error to null`() = runTest {
        // Trigger an error
        viewModel.proceedFromShipping() // invalid — no fields set
        assertNotNull("Error should be set", viewModel.error.value)
        viewModel.clearError()
        assertNull("Error should be null after clearError", viewModel.error.value)
    }
}
