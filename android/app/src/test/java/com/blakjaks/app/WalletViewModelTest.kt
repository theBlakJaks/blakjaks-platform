package com.blakjaks.app

import com.blakjaks.app.core.network.models.WalletDetail
import com.blakjaks.app.core.network.models.Transaction
import com.blakjaks.app.features.scanwallet.WalletViewModel
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class WalletViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: WalletViewModel
    private lateinit var mockApiClient: MockApiClient

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        mockApiClient = MockApiClient()
        viewModel = WalletViewModel(apiClient = mockApiClient)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── Test 1: loadWalletDetail populates walletDetail ──────────────────────

    @Test
    fun `loadWalletDetail populates walletDetail state`() = runTest {
        // init{} already calls loadWalletDetail(); advance to complete
        advanceUntilIdle()

        val wallet = viewModel.walletDetail.value
        assertNotNull("walletDetail should be non-null after loadWalletDetail", wallet)
        assertTrue(
            "compBalance should be >= 0",
            wallet!!.compBalance >= 0.0
        )
    }

    // ─── Test 2: loadTransactions populates transactions list ─────────────────

    @Test
    fun `loadTransactions populates transactions list`() = runTest {
        // init{} calls both loadWalletDetail() and loadTransactions()
        advanceUntilIdle()

        val txList = viewModel.transactions.value
        assertNotNull("transactions should not be null", txList)
        assertTrue(
            "transactions list should contain at least one item",
            txList.isNotEmpty()
        )
    }

    // ─── Test 3: requestWithdrawal clears amount and sets successMessage ───────

    @Test
    fun `requestWithdrawal with valid amount clears withdrawAmount and sets successMessage`() = runTest {
        advanceUntilIdle() // complete init loads — wallet balance is now set

        // Set a valid withdraw amount below the mock comp balance (847.50)
        viewModel.withdrawAmount.value = "50.00"

        viewModel.requestWithdrawal("crypto")
        advanceUntilIdle()

        assertEquals(
            "withdrawAmount should be cleared after successful withdrawal",
            "",
            viewModel.withdrawAmount.value
        )
        assertNotNull(
            "successMessage should be set after successful withdrawal",
            viewModel.successMessage.value
        )
        assertTrue(
            "successMessage should contain dollar amount",
            viewModel.successMessage.value!!.contains("50.00")
        )
    }

    // ─── Test 4: requestWithdrawal with zero amount sets error ────────────────

    @Test
    fun `requestWithdrawal with zero amount sets error`() = runTest {
        advanceUntilIdle() // complete init loads

        viewModel.withdrawAmount.value = "0"

        viewModel.requestWithdrawal("crypto")
        advanceUntilIdle()

        assertNotNull(
            "error should be set when withdrawal amount is zero",
            viewModel.error.value
        )
        assertTrue(
            "error message should mention valid amount",
            viewModel.error.value!!.contains("valid", ignoreCase = true)
        )
        // successMessage should NOT be set
        assertNull(
            "successMessage should remain null after invalid withdrawal",
            viewModel.successMessage.value
        )
    }

    // ─── Test 5: clearError clears the error state ────────────────────────────

    @Test
    fun `clearError clears the error state`() = runTest {
        // Force an error by supplying zero amount
        advanceUntilIdle()

        viewModel.withdrawAmount.value = "0"
        viewModel.requestWithdrawal("crypto")
        advanceUntilIdle()

        assertNotNull("error should be set before clearError", viewModel.error.value)

        viewModel.clearError()

        assertNull("error should be null after clearError", viewModel.error.value)
    }

    // ─── Test 6: clearSuccessMessage clears the success message ──────────────

    @Test
    fun `clearSuccessMessage clears the success message`() = runTest {
        advanceUntilIdle() // complete init loads — wallet balance available

        viewModel.withdrawAmount.value = "25.00"
        viewModel.requestWithdrawal("crypto")
        advanceUntilIdle()

        assertNotNull("successMessage should be set after withdrawal", viewModel.successMessage.value)

        viewModel.clearSuccessMessage()

        assertNull("successMessage should be null after clearSuccessMessage", viewModel.successMessage.value)
    }
}
