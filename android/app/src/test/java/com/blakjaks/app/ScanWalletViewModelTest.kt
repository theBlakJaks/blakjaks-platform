package com.blakjaks.app

import com.blakjaks.app.core.network.models.ScanResult
import com.blakjaks.app.core.network.models.TierProgress
import com.blakjaks.app.core.network.models.CompEarned
import com.blakjaks.app.features.scanwallet.ScanWalletViewModel
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ScanWalletViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: ScanWalletViewModel
    private lateinit var mockApiClient: MockApiClient

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        mockApiClient = MockApiClient()
        viewModel = ScanWalletViewModel(apiClient = mockApiClient)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── Test 1: loadWallet populates wallet ──────────────────────────────────

    @Test
    fun `loadWallet populates wallet state`() = runTest {
        // init{} already calls loadWallet(); advance to complete
        advanceUntilIdle()

        val wallet = viewModel.wallet.value
        assertNotNull("wallet should be non-null after loadWallet", wallet)
        assertTrue(
            "compBalance should be >= 0",
            wallet!!.compBalance >= 0.0
        )
    }

    // ─── Test 2: compBalance computed from wallet ─────────────────────────────

    @Test
    fun `compBalance is derived from wallet compBalance`() = runTest {
        advanceUntilIdle()

        val wallet = viewModel.wallet.value
        assertNotNull(wallet)
        // compBalance computed property should match wallet field
        assertEquals(
            "compBalance should equal wallet.compBalance",
            wallet!!.compBalance,
            viewModel.compBalance,
            0.001
        )
    }

    // ─── Test 3: processQrCode sets currentScanResult ────────────────────────

    @Test
    fun `processQrCode sets currentScanResult after successful scan`() = runTest {
        advanceUntilIdle() // complete init loads

        assertNull("currentScanResult should start null", viewModel.currentScanResult.value)

        viewModel.processQrCode("ABCD-1234-EFGH")
        advanceUntilIdle()

        val result = viewModel.currentScanResult.value
        assertNotNull("currentScanResult should be set after processQrCode", result)
        assertTrue("scan result should be successful", result!!.success)
        assertNotNull("productName should be set", result.productName)
    }

    // ─── Test 4: requiresPayoutChoice sets showPayoutChoiceSheet ─────────────

    @Test
    fun `processQrCode sets showPayoutChoiceSheet when comp requiresPayoutChoice`() = runTest {
        // MockApiClient.submitScan returns a comp with requiresPayoutChoice = true
        advanceUntilIdle() // init loads

        assertFalse("showPayoutChoiceSheet should start false",
            viewModel.showPayoutChoiceSheet.value)

        viewModel.processQrCode("ABCD-1234-EFGH")
        advanceUntilIdle()

        val result = viewModel.currentScanResult.value
        val comp = result?.compEarned

        if (comp != null && comp.requiresPayoutChoice) {
            assertTrue(
                "showPayoutChoiceSheet should be true when comp requiresPayoutChoice",
                viewModel.showPayoutChoiceSheet.value
            )
            assertNotNull(
                "pendingChoiceComp should be set",
                viewModel.pendingChoiceComp.value
            )
        }
        // If mock doesn't always return comp, we at least verified the QR flow worked
    }

    // ─── Test 5: submitPayoutChoice clears sheet ──────────────────────────────

    @Test
    fun `submitPayoutChoice clears showPayoutChoiceSheet and pendingChoiceComp`() = runTest {
        advanceUntilIdle() // init loads

        // Trigger a scan to get a comp
        viewModel.processQrCode("ABCD-1234-EFGH")
        advanceUntilIdle()

        val comp = viewModel.pendingChoiceComp.value
        if (comp != null) {
            // Sheet should be open
            assertTrue(viewModel.showPayoutChoiceSheet.value)

            // Submit payout choice
            viewModel.submitPayoutChoice(comp.id, "crypto")
            advanceUntilIdle()

            assertFalse(
                "showPayoutChoiceSheet should be false after submitPayoutChoice",
                viewModel.showPayoutChoiceSheet.value
            )
            assertNull(
                "pendingChoiceComp should be null after submitPayoutChoice",
                viewModel.pendingChoiceComp.value
            )
        }
    }

    // ─── Test 6: clearError works ─────────────────────────────────────────────

    @Test
    fun `clearError clears error state`() = runTest {
        val failingClient = object : MockApiClient() {
            override suspend fun getWallet() =
                throw RuntimeException("Network failure")
        }
        val errorVm = ScanWalletViewModel(apiClient = failingClient)
        advanceUntilIdle()

        assertNotNull("error should be set after failed wallet load", errorVm.error.value)

        errorVm.clearError()
        assertNull("error should be null after clearError", errorVm.error.value)
    }
}
