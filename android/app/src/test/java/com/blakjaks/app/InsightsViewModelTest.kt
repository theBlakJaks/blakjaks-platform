package com.blakjaks.app

import com.blakjaks.app.features.insights.InsightsTab
import com.blakjaks.app.features.insights.InsightsViewModel
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class InsightsViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: InsightsViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        // Provide MockApiClient — no Koin needed in unit tests
        viewModel = InsightsViewModel(apiClient = MockApiClient())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── Test 1: loadOverview populates overview ──────────────────────────────

    @Test
    fun `loadOverview populates overview state`() = runTest {
        // init{} already calls loadOverview(); advance to let coroutines complete
        advanceUntilIdle()

        val overview = viewModel.overview.value
        assertNotNull("overview should be non-null after load", overview)
        assertTrue("globalScanCount should be > 0", overview!!.globalScanCount > 0)
        assertTrue("activeMembers should be > 0", overview.activeMembers > 0)
    }

    // ─── Test 2: loadTreasury populates treasury ──────────────────────────────

    @Test
    fun `loadTreasury populates treasury state`() = runTest {
        viewModel.loadTreasury()
        advanceUntilIdle()

        val treasury = viewModel.treasury.value
        assertNotNull("treasury should be non-null after load", treasury)
        assertTrue(
            "onChainBalances should not be empty",
            treasury!!.onChainBalances.isNotEmpty()
        )
        assertNotNull(
            "reconciliationStatus should be present",
            treasury.reconciliationStatus
        )
    }

    // ─── Test 3: selectTab updates selectedTab ────────────────────────────────

    @Test
    fun `selectTab updates selectedTab and triggers correct load`() = runTest {
        assertEquals(InsightsTab.OVERVIEW, viewModel.selectedTab.value)

        viewModel.selectTab(InsightsTab.TREASURY)
        advanceUntilIdle()

        assertEquals(InsightsTab.TREASURY, viewModel.selectedTab.value)
        assertNotNull("treasury should be loaded after selecting treasury tab",
            viewModel.treasury.value)

        viewModel.selectTab(InsightsTab.COMPS)
        advanceUntilIdle()

        assertEquals(InsightsTab.COMPS, viewModel.selectedTab.value)
        assertNotNull("comps should be loaded after selecting comps tab",
            viewModel.comps.value)
    }

    // ─── Test 4: clearError works ─────────────────────────────────────────────

    @Test
    fun `clearError clears error state`() = runTest {
        // Simulate an error by using a failing client
        val failingClient = object : MockApiClient() {
            override suspend fun getInsightsOverview() =
                throw RuntimeException("Test network error")
        }
        val errorVm = InsightsViewModel(apiClient = failingClient)
        advanceUntilIdle()

        // After the load fails, error should be set
        assertNotNull("error should be set after failed load", errorVm.error.value)

        errorVm.clearError()
        assertNull("error should be null after clearError", errorVm.error.value)
    }

    // ─── Test 5: activityFeed loads on init ───────────────────────────────────

    @Test
    fun `activityFeed loads during init`() = runTest {
        advanceUntilIdle()

        val feed = viewModel.activityFeed.value
        assertNotNull("activityFeed should be non-null after init", feed)
        assertTrue("activityFeed should have items", feed!!.isNotEmpty())
    }
}
