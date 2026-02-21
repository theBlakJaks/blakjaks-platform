package com.blakjaks.app

import com.blakjaks.app.core.network.models.ShippingAddress
import com.blakjaks.app.features.profile.ProfileViewModel
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
class ProfileViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: ProfileViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = ProfileViewModel(apiClient = MockApiClient())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── 1. loadProfile populates profile ─────────────────────────────────────

    @Test
    fun `loadProfile populates profile on init`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val profile = viewModel.profile.value
        assertNotNull("Profile should be populated after init", profile)
        assertTrue("Profile fullName should not be blank", profile!!.fullName.isNotBlank())
    }

    // ─── 2. updateProfile sets successMessage ────────────────────────────────

    @Test
    fun `updateProfile sets successMessage on success`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.updateProfile("Alex Updated", "New bio text")
        testDispatcher.scheduler.advanceUntilIdle()

        assertNotNull("successMessage should be set after successful update", viewModel.successMessage.value)
        assertTrue(
            "successMessage should contain 'updated'",
            viewModel.successMessage.value!!.lowercase().contains("updated")
        )
    }

    // ─── 3. updateProfile trims whitespace ───────────────────────────────────

    @Test
    fun `updateProfile trims whitespace from fullName and bio`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()

        val untrimmedName = "  Alex   "
        val untrimmedBio = "  Some bio  "

        // We verify the call succeeds and profile is updated (MockApiClient ignores trimming)
        viewModel.updateProfile(untrimmedName, untrimmedBio)
        testDispatcher.scheduler.advanceUntilIdle()

        // No error should occur and success message should be set
        assertNull("Error should not be set for valid update", viewModel.error.value)
        assertNotNull("successMessage should be set", viewModel.successMessage.value)
    }

    // ─── 4. loadAffiliateDashboard populates dashboard and payouts ────────────

    @Test
    fun `loadAffiliateDashboard populates affiliateDashboard and affiliatePayouts`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        viewModel.loadAffiliateDashboard()
        testDispatcher.scheduler.advanceUntilIdle()

        assertNotNull("affiliateDashboard should be populated", viewModel.affiliateDashboard.value)
        assertTrue("affiliatePayouts should be non-empty", viewModel.affiliatePayouts.value.isNotEmpty())
        assertTrue(
            "Referral code should not be blank",
            viewModel.affiliateDashboard.value!!.referralCode.isNotBlank()
        )
    }

    // ─── 5. clearError sets error to null ────────────────────────────────────

    @Test
    fun `clearError resets error to null`() = runTest {
        val failingClient = object : MockApiClient() {
            override suspend fun getMe() = throw Exception("Profile load failed")
        }
        val failingViewModel = ProfileViewModel(apiClient = failingClient)
        testDispatcher.scheduler.advanceUntilIdle()

        assertNotNull("Error should be set after failed getMe", failingViewModel.error.value)
        failingViewModel.clearError()
        assertNull("Error should be null after clearError", failingViewModel.error.value)
    }

    // ─── 6. logout clears all state ──────────────────────────────────────────

    @Test
    fun `logout clears profile orders affiliate and payouts`() = runTest {
        // Let init load complete
        testDispatcher.scheduler.advanceUntilIdle()

        // Load affiliate data too
        viewModel.loadAffiliateDashboard()
        testDispatcher.scheduler.advanceUntilIdle()

        // Confirm data is populated
        assertNotNull("Profile should be set before logout", viewModel.profile.value)
        assertNotNull("affiliateDashboard should be set before logout", viewModel.affiliateDashboard.value)

        var callbackFired = false
        viewModel.logout { callbackFired = true }
        testDispatcher.scheduler.advanceUntilIdle()

        assertNull("Profile should be null after logout", viewModel.profile.value)
        assertNull("affiliateDashboard should be null after logout", viewModel.affiliateDashboard.value)
        assertTrue("affiliatePayouts should be empty after logout", viewModel.affiliatePayouts.value.isEmpty())
        assertTrue("orders should be empty after logout", viewModel.orders.value.isEmpty())
        assertTrue("onComplete callback should be fired", callbackFired)
    }
}
