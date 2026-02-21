package com.blakjaks.app.features.shop

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.Cart
import com.blakjaks.app.core.network.models.Order
import com.blakjaks.app.core.network.models.ShippingAddress
import com.blakjaks.app.core.network.models.TaxEstimate
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// ─── CheckoutStep ─────────────────────────────────────────────────────────────

sealed class CheckoutStep {
    object Shipping : CheckoutStep()
    object AgeVerification : CheckoutStep()
    object Payment : CheckoutStep()
    object Review : CheckoutStep()
    object Confirmation : CheckoutStep()

    val title: String
        get() = when (this) {
            is Shipping        -> "Shipping"
            is AgeVerification -> "Age Verify"
            is Payment         -> "Payment"
            is Review          -> "Review"
            is Confirmation    -> "Confirmation"
        }

    val stepIndex: Int
        get() = when (this) {
            is Shipping        -> 0
            is AgeVerification -> 1
            is Payment         -> 2
            is Review          -> 3
            is Confirmation    -> 4
        }
}

// ─── CheckoutError ────────────────────────────────────────────────────────────

sealed class CheckoutError(override val message: String) : Exception(message) {
    object InvalidShippingAddress  : CheckoutError("Please fill in all required shipping fields.")
    object AgeVerificationRequired : CheckoutError("Age verification is required to purchase nicotine products.")
    object PaymentRequired         : CheckoutError("Please enter payment information.")
}

// ─── CartViewModel ────────────────────────────────────────────────────────────
// Manages cart state plus 5-step checkout flow.
// Mirrors iOS CartViewModel.swift — Koin DI (no Hilt).

class CartViewModel(
    private val apiClient: ApiClientInterface
) : ViewModel() {

    // ─── Constants ───────────────────────────────────────────────────────────

    companion object {
        val FREE_SHIPPING_THRESHOLD = 50.0
        val FLAT_SHIPPING_COST = 7.99
    }

    // ─── Cart State ──────────────────────────────────────────────────────────

    private val _cart = MutableStateFlow<Cart?>(null)
    val cart: StateFlow<Cart?> = _cart.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isPlacingOrder = MutableStateFlow(false)
    val isPlacingOrder: StateFlow<Boolean> = _isPlacingOrder.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _completedOrder = MutableStateFlow<Order?>(null)
    val completedOrder: StateFlow<Order?> = _completedOrder.asStateFlow()

    // ─── Checkout Flow State ─────────────────────────────────────────────────

    val checkoutStep = MutableStateFlow<CheckoutStep>(CheckoutStep.Shipping)

    // Step 1: Shipping Address
    val firstName    = MutableStateFlow("")
    val lastName     = MutableStateFlow("")
    val line1        = MutableStateFlow("")
    val line2        = MutableStateFlow("")
    val city         = MutableStateFlow("")
    val state        = MutableStateFlow("")
    val zip          = MutableStateFlow("")

    // Step 2: Age Verification
    val ageVerified  = MutableStateFlow(false)

    // Step 3: Payment token (Authorize.net)
    val paymentToken = MutableStateFlow("")

    // Tax estimate (fetched at end of shipping step)
    val taxEstimate  = MutableStateFlow<TaxEstimate?>(null)

    // ─── Computed Cart Values ────────────────────────────────────────────────

    val itemCount: Int
        get() = _cart.value?.itemCount ?: 0

    val subtotal: Double
        get() = _cart.value?.subtotal ?: 0.0

    val shippingCost: Double
        get() = if (subtotal >= FREE_SHIPPING_THRESHOLD) 0.0 else FLAT_SHIPPING_COST

    val isFreeShipping: Boolean
        get() = subtotal >= FREE_SHIPPING_THRESHOLD

    val total: Double
        get() = subtotal + shippingCost + (taxEstimate.value?.taxAmount ?: 0.0)

    // ─── Shipping Validation ─────────────────────────────────────────────────

    val isShippingValid: Boolean
        get() = firstName.value.isNotBlank() &&
                lastName.value.isNotBlank() &&
                line1.value.isNotBlank() &&
                city.value.isNotBlank() &&
                state.value.isNotBlank() &&
                zip.value.length == 5

    private val currentShippingAddress: ShippingAddress
        get() = ShippingAddress(
            firstName = firstName.value.trim(),
            lastName  = lastName.value.trim(),
            line1     = line1.value.trim(),
            line2     = line2.value.trim().ifEmpty { null },
            city      = city.value.trim(),
            state     = state.value.trim().uppercase(),
            zip       = zip.value.trim(),
            country   = "US"
        )

    // ─── Cart Operations ─────────────────────────────────────────────────────

    fun loadCart() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                _cart.value = apiClient.getCart()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load cart"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun addItem(productId: Int, quantity: Int) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                _cart.value = apiClient.addToCart(productId, quantity)
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to add item"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun updateItem(productId: Int, quantity: Int) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                _cart.value = apiClient.updateCartItem(productId, quantity)
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to update item"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun removeItem(productId: Int) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                _cart.value = apiClient.removeFromCart(productId)
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to remove item"
            } finally {
                _isLoading.value = false
            }
        }
    }

    // ─── Checkout Steps ──────────────────────────────────────────────────────

    fun proceedFromShipping() {
        if (!isShippingValid) {
            _error.value = CheckoutError.InvalidShippingAddress.message
            return
        }
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                taxEstimate.value = apiClient.estimateTax(currentShippingAddress)
                checkoutStep.value = CheckoutStep.AgeVerification
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to estimate tax"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun proceedFromAgeVerification() {
        if (!ageVerified.value) {
            _error.value = CheckoutError.AgeVerificationRequired.message
            return
        }
        checkoutStep.value = CheckoutStep.Payment
    }

    fun proceedFromPayment() {
        if (paymentToken.value.isBlank()) {
            _error.value = CheckoutError.PaymentRequired.message
            return
        }
        checkoutStep.value = CheckoutStep.Review
    }

    fun placeOrder(): Boolean {
        var result = false
        viewModelScope.launch {
            _isPlacingOrder.value = true
            _error.value = null
            try {
                _completedOrder.value = apiClient.createOrder(
                    shippingAddress = currentShippingAddress,
                    paymentToken = paymentToken.value
                )
                checkoutStep.value = CheckoutStep.Confirmation
                result = true
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to place order"
                result = false
            } finally {
                _isPlacingOrder.value = false
            }
        }
        return result
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    fun clearError() {
        _error.value = null
    }

    fun resetCheckout() {
        checkoutStep.value = CheckoutStep.Shipping
        ageVerified.value  = false
        paymentToken.value = ""
        taxEstimate.value  = null
        _completedOrder.value = null
        _error.value = null
        firstName.value = ""
        lastName.value  = ""
        line1.value     = ""
        line2.value     = ""
        city.value      = ""
        state.value     = ""
        zip.value       = ""
    }
}
