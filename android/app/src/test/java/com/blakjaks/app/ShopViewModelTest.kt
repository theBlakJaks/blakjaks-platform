package com.blakjaks.app

import com.blakjaks.app.features.shop.ShopViewModel
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ShopViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: ShopViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = ShopViewModel(apiClient = MockApiClient())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── loadProducts populates products ─────────────────────────────────────

    @Test
    fun `loadProducts populates products`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val products = viewModel.products.value
        assertTrue("Expected products to be non-empty", products.isNotEmpty())
    }

    // ─── filteredProducts with empty query returns all products ───────────────

    @Test
    fun `filteredProducts empty query returns all products`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.searchQuery.value = ""
        testDispatcher.scheduler.advanceUntilIdle()
        val allProducts = viewModel.products.value
        val filtered = viewModel.filteredProducts.value
        assertEquals("Filtered should equal all products when query is empty", allProducts.size, filtered.size)
    }

    // ─── filteredProducts with "Classic" returns matching products ────────────

    @Test
    fun `filteredProducts with Classic query returns matching products`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.searchQuery.value = "Classic"
        testDispatcher.scheduler.advanceUntilIdle()
        val filtered = viewModel.filteredProducts.value
        assertTrue("Should have at least one 'Classic' result", filtered.isNotEmpty())
        assertTrue(
            "All filtered products should contain 'classic' in name or flavor",
            filtered.all { product ->
                product.name.lowercase().contains("classic") ||
                product.flavor.lowercase().contains("classic")
            }
        )
    }

    // ─── filteredProducts with no match returns empty list ────────────────────

    @Test
    fun `filteredProducts no match returns empty list`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.searchQuery.value = "xyznonexistent999"
        testDispatcher.scheduler.advanceUntilIdle()
        val filtered = viewModel.filteredProducts.value
        assertTrue("Filtered list should be empty for unmatched query", filtered.isEmpty())
    }

    // ─── refresh clears and reloads products ─────────────────────────────────

    @Test
    fun `refresh clears and reloads products`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        // Confirm products loaded
        assertTrue(viewModel.products.value.isNotEmpty())
        // Call refresh
        viewModel.refresh()
        testDispatcher.scheduler.advanceUntilIdle()
        // Should reload
        assertTrue("Products should be reloaded after refresh", viewModel.products.value.isNotEmpty())
    }

    // ─── clearError sets error to null ────────────────────────────────────────

    @Test
    fun `clearError sets error to null`() = runTest {
        // Force an error by using a client that throws
        val failingClient = object : MockApiClient() {
            override suspend fun getProducts(
                category: String?,
                limit: Int,
                offset: Int
            ) = throw Exception("Test error")
        }
        val failingViewModel = ShopViewModel(apiClient = failingClient)
        testDispatcher.scheduler.advanceUntilIdle()
        assertNotNull("Error should be set after failed load", failingViewModel.error.value)
        failingViewModel.clearError()
        assertNull("Error should be null after clearError", failingViewModel.error.value)
    }
}
