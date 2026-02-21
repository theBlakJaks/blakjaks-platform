package com.blakjaks.app

import com.blakjaks.app.features.social.SocialViewModel
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
class SocialViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var viewModel: SocialViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = SocialViewModel(apiClient = MockApiClient())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // ─── 1. loadChannels populates channels ───────────────────────────────────

    @Test
    fun `loadChannels populates channels`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val channels = viewModel.channels.value
        assertTrue("Expected channels to be non-empty after init", channels.isNotEmpty())
    }

    // ─── 2. selectChannel loads messages ─────────────────────────────────────

    @Test
    fun `selectChannel loads messages for selected channel`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val channel = viewModel.channels.value.first()
        viewModel.selectChannel(channel)
        testDispatcher.scheduler.advanceUntilIdle()
        assertEquals("Selected channel should match", channel.id, viewModel.selectedChannel.value?.id)
        assertTrue("Messages should be loaded after selectChannel", viewModel.messages.value.isNotEmpty())
    }

    // ─── 3. sendMessage appends message to list ────────────────────────────────

    @Test
    fun `sendMessage appends sent message to messages list`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val channel = viewModel.channels.value.first()
        viewModel.selectChannel(channel)
        testDispatcher.scheduler.advanceUntilIdle()

        val countBefore = viewModel.messages.value.size
        viewModel.draftMessage.value = "Hello BlakJaks!"
        viewModel.sendMessage()
        testDispatcher.scheduler.advanceUntilIdle()

        val countAfter = viewModel.messages.value.size
        assertTrue("Messages list should grow after sendMessage", countAfter > countBefore)
    }

    // ─── 4. sendMessage with empty draft does nothing ──────────────────────────

    @Test
    fun `sendMessage with empty draft does nothing`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val channel = viewModel.channels.value.first()
        viewModel.selectChannel(channel)
        testDispatcher.scheduler.advanceUntilIdle()

        val countBefore = viewModel.messages.value.size
        viewModel.draftMessage.value = "   " // whitespace only
        viewModel.sendMessage()
        testDispatcher.scheduler.advanceUntilIdle()

        assertEquals("Message count should not change for blank draft", countBefore, viewModel.messages.value.size)
    }

    // ─── 5. sendMessage over 500 chars is blocked ─────────────────────────────

    @Test
    fun `sendMessage with draft over 500 chars is blocked`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val channel = viewModel.channels.value.first()
        viewModel.selectChannel(channel)
        testDispatcher.scheduler.advanceUntilIdle()

        val countBefore = viewModel.messages.value.size
        viewModel.draftMessage.value = "A".repeat(501)
        viewModel.sendMessage()
        testDispatcher.scheduler.advanceUntilIdle()

        assertEquals("Message count should not change for oversized draft", countBefore, viewModel.messages.value.size)
    }

    // ─── 6. Standard tier triggers rate limit cooldown ────────────────────────

    @Test
    fun `standard tier sendMessage triggers rate limit cooldown`() = runTest {
        testDispatcher.scheduler.advanceUntilIdle()
        val channel = viewModel.channels.value.first()
        viewModel.selectChannel(channel)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.draftMessage.value = "First message"
        viewModel.sendMessage()
        testDispatcher.scheduler.advanceUntilIdle()

        // currentUserTier is "Standard" so rate limit should be active immediately after send
        assertTrue("Rate limit should be active after standard tier send", viewModel.isRateLimited.value)
        assertTrue("Remaining seconds should be positive", viewModel.rateLimitRemainingSeconds.value > 0)
    }

    // ─── 7. clearError sets error to null ─────────────────────────────────────

    @Test
    fun `clearError resets error to null`() = runTest {
        val failingClient = object : MockApiClient() {
            override suspend fun getChannels() = throw Exception("Test channel load error")
        }
        val failingViewModel = SocialViewModel(apiClient = failingClient)
        testDispatcher.scheduler.advanceUntilIdle()

        assertNotNull("Error should be set after failed getChannels", failingViewModel.error.value)
        failingViewModel.clearError()
        assertNull("Error should be null after clearError", failingViewModel.error.value)
    }
}
