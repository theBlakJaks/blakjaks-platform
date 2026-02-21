package com.blakjaks.app.features.shop

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.Product
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

// ─── ShopViewModel ────────────────────────────────────────────────────────────
// Manages the product catalog: loading, search filtering.
// Mirrors iOS ShopViewModel.swift — Koin DI (no Hilt).

class ShopViewModel(
    private val apiClient: ApiClientInterface
) : ViewModel() {

    // ─── Private Backing State ───────────────────────────────────────────────

    private val _products = MutableStateFlow<List<Product>>(emptyList())
    val products: StateFlow<List<Product>> = _products.asStateFlow()

    val searchQuery = MutableStateFlow("")

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // ─── Derived: filteredProducts ───────────────────────────────────────────
    // Uses combine so it reacts to both product list and search query changes.

    val filteredProducts: StateFlow<List<Product>> = combine(_products, searchQuery) { products, query ->
        val trimmed = query.trim()
        if (trimmed.isEmpty()) {
            products
        } else {
            val q = trimmed.lowercase()
            products.filter { product ->
                product.name.lowercase().contains(q) ||
                product.flavor.lowercase().contains(q)
            }
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = emptyList()
    )

    // ─── Init ────────────────────────────────────────────────────────────────

    init {
        loadProducts()
    }

    // ─── Load ────────────────────────────────────────────────────────────────

    fun loadProducts() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                _products.value = apiClient.getProducts(category = null, limit = 50, offset = 0)
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load products"
            } finally {
                _isLoading.value = false
            }
        }
    }

    // ─── Refresh — clears and reloads ────────────────────────────────────────

    fun refresh() {
        _products.value = emptyList()
        loadProducts()
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    fun clearError() {
        _error.value = null
    }
}
