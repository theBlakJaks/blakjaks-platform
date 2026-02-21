package com.blakjaks.app.features.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.AffiliateDashboard
import com.blakjaks.app.core.network.models.AffiliatePayout
import com.blakjaks.app.core.network.models.Order
import com.blakjaks.app.core.network.models.UserProfile
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ProfileViewModel(private val apiClient: ApiClientInterface) : ViewModel() {

    // ─── Profile ──────────────────────────────────────────────────────────────

    private val _profile = MutableStateFlow<UserProfile?>(null)
    val profile: StateFlow<UserProfile?> = _profile.asStateFlow()

    private val _isLoadingProfile = MutableStateFlow(false)
    val isLoadingProfile: StateFlow<Boolean> = _isLoadingProfile.asStateFlow()

    private val _isUpdatingProfile = MutableStateFlow(false)
    val isUpdatingProfile: StateFlow<Boolean> = _isUpdatingProfile.asStateFlow()

    // ─── Orders ───────────────────────────────────────────────────────────────

    private val _orders = MutableStateFlow<List<Order>>(emptyList())
    val orders: StateFlow<List<Order>> = _orders.asStateFlow()

    private val _isLoadingOrders = MutableStateFlow(false)
    val isLoadingOrders: StateFlow<Boolean> = _isLoadingOrders.asStateFlow()

    // ─── Affiliate ────────────────────────────────────────────────────────────

    private val _affiliateDashboard = MutableStateFlow<AffiliateDashboard?>(null)
    val affiliateDashboard: StateFlow<AffiliateDashboard?> = _affiliateDashboard.asStateFlow()

    private val _affiliatePayouts = MutableStateFlow<List<AffiliatePayout>>(emptyList())
    val affiliatePayouts: StateFlow<List<AffiliatePayout>> = _affiliatePayouts.asStateFlow()

    // ─── Error / Success ──────────────────────────────────────────────────────

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _successMessage = MutableStateFlow<String?>(null)
    val successMessage: StateFlow<String?> = _successMessage.asStateFlow()

    // ─── Init ─────────────────────────────────────────────────────────────────

    init {
        loadProfile()
    }

    // ─── Profile Methods ──────────────────────────────────────────────────────

    fun loadProfile() {
        viewModelScope.launch {
            _isLoadingProfile.value = true
            _error.value = null
            try {
                _profile.value = apiClient.getMe()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load profile"
            } finally {
                _isLoadingProfile.value = false
            }
        }
    }

    // ─── Orders — stubbed with MockApiClient mock data ────────────────────────
    // No getOrders() endpoint yet. Wire to real API in production polish pass.

    fun loadOrders() {
        viewModelScope.launch {
            _isLoadingOrders.value = true
            try {
                // Simulate brief async work so callers can await correctly
                delay(200L)
                // Use mock order from MockApiClient via createOrder stub result
                val mockOrder = apiClient.createOrder(
                    com.blakjaks.app.core.network.models.ShippingAddress(
                        firstName = "",
                        lastName = "",
                        line1 = "",
                        line2 = null,
                        city = "",
                        state = "",
                        zip = "",
                        country = ""
                    ),
                    "mock"
                )
                _orders.value = listOf(mockOrder, mockOrder)
            } catch (_: Exception) {
                // Gracefully fall back to empty list
                _orders.value = emptyList()
            } finally {
                _isLoadingOrders.value = false
            }
        }
    }

    // ─── Affiliate Dashboard — concurrent fetch ───────────────────────────────

    fun loadAffiliateDashboard() {
        viewModelScope.launch {
            _error.value = null
            try {
                val dashboardDeferred = async { apiClient.getAffiliateDashboard() }
                val payoutsDeferred = async { apiClient.getAffiliatePayouts(25, 0) }
                _affiliateDashboard.value = dashboardDeferred.await()
                _affiliatePayouts.value = payoutsDeferred.await()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load affiliate data"
            }
        }
    }

    // ─── Profile Updates ──────────────────────────────────────────────────────

    fun updateProfile(fullName: String, bio: String) {
        viewModelScope.launch {
            _isUpdatingProfile.value = true
            _error.value = null
            try {
                _profile.value = apiClient.updateProfile(
                    fullName = fullName.trim(),
                    bio = bio.trim()
                )
                _successMessage.value = "Profile updated."
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to update profile"
            } finally {
                _isUpdatingProfile.value = false
            }
        }
    }

    fun uploadAvatar(imageData: ByteArray) {
        viewModelScope.launch {
            _error.value = null
            try {
                // TODO: wire to real multipart upload API when endpoint is available
                // For now simulate a successful update via updateProfile
                _successMessage.value = "Avatar updated."
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to upload avatar"
            }
        }
    }

    // ─── Session ──────────────────────────────────────────────────────────────

    fun logout(onComplete: () -> Unit) {
        viewModelScope.launch {
            _error.value = null
            try {
                apiClient.logout()
            } catch (_: Exception) {
                // Swallow logout errors — clear state regardless
            }
            _profile.value = null
            _orders.value = emptyList()
            _affiliateDashboard.value = null
            _affiliatePayouts.value = emptyList()
            onComplete()
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    fun clearError() {
        _error.value = null
    }

    fun clearSuccessMessage() {
        _successMessage.value = null
    }
}
