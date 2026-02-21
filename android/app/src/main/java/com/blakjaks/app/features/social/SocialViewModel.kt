package com.blakjaks.app.features.social

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.Channel
import com.blakjaks.app.core.network.models.ChatMessage
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// ─── LiveStream model (defined here pending backend model promotion to Models.kt) ───

data class LiveStream(
    val id: Int,
    val title: String,
    val host: String,
    val isLive: Boolean,
    val viewerCount: Int,
    val streamUrl: String,
    val thumbnailUrl: String?
)

// ─── Mock default live stream ─────────────────────────────────────────────────

object MockLiveStream {
    val live = LiveStream(
        id = 1,
        title = "BlakJaks Live — New Flavor Drop",
        host = "BlakJaks Official",
        isLive = true,
        viewerCount = 842,
        streamUrl = "https://stream.blakjaks.com/live/hls/main.m3u8",
        thumbnailUrl = null
    )
}

// ─── SocialViewModel ──────────────────────────────────────────────────────────

class SocialViewModel(private val apiClient: ApiClientInterface) : ViewModel() {

    // ─── Channels ────────────────────────────────────────────────────────────

    private val _channels = MutableStateFlow<List<Channel>>(emptyList())
    val channels: StateFlow<List<Channel>> = _channels.asStateFlow()

    private val _selectedChannel = MutableStateFlow<Channel?>(null)
    val selectedChannel: StateFlow<Channel?> = _selectedChannel.asStateFlow()

    private val _isLoadingChannels = MutableStateFlow(false)
    val isLoadingChannels: StateFlow<Boolean> = _isLoadingChannels.asStateFlow()

    // ─── Messages ────────────────────────────────────────────────────────────

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isLoadingMessages = MutableStateFlow(false)
    val isLoadingMessages: StateFlow<Boolean> = _isLoadingMessages.asStateFlow()

    // ─── Live Stream ─────────────────────────────────────────────────────────

    private val _currentLiveStream = MutableStateFlow<LiveStream?>(MockLiveStream.live)
    val currentLiveStream: StateFlow<LiveStream?> = _currentLiveStream.asStateFlow()

    // ─── Error ───────────────────────────────────────────────────────────────

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // ─── Rate Limit ──────────────────────────────────────────────────────────

    private val _isRateLimited = MutableStateFlow(false)
    val isRateLimited: StateFlow<Boolean> = _isRateLimited.asStateFlow()

    private val _rateLimitRemainingSeconds = MutableStateFlow(0)
    val rateLimitRemainingSeconds: StateFlow<Int> = _rateLimitRemainingSeconds.asStateFlow()

    // ─── New Message Count / Pinned ───────────────────────────────────────────

    private val _newMessageCount = MutableStateFlow(0)
    val newMessageCount: StateFlow<Int> = _newMessageCount.asStateFlow()

    private val _pinnedMessage = MutableStateFlow<ChatMessage?>(null)
    val pinnedMessage: StateFlow<ChatMessage?> = _pinnedMessage.asStateFlow()

    // ─── Draft ───────────────────────────────────────────────────────────────

    val draftMessage = MutableStateFlow("")

    // ─── Private ─────────────────────────────────────────────────────────────

    private var lastSentAt: Long? = null
    private val rateLimitDuration = 5L // seconds
    private var rateLimitJob: Job? = null

    val currentUserId: Int = 1
    val currentUserTier: String = "Standard"

    // ─── Init ─────────────────────────────────────────────────────────────────

    init {
        loadChannels()
    }

    // ─── Channel Methods ──────────────────────────────────────────────────────

    fun loadChannels() {
        viewModelScope.launch {
            _isLoadingChannels.value = true
            try {
                _channels.value = apiClient.getChannels()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load channels"
            } finally {
                _isLoadingChannels.value = false
            }
        }
    }

    fun selectChannel(channel: Channel) {
        viewModelScope.launch {
            _selectedChannel.value = channel
            _messages.value = emptyList()
            _newMessageCount.value = 0
            loadMessages()
        }
    }

    fun loadMessages(before: Int? = null) {
        val channelId = _selectedChannel.value?.id ?: return
        viewModelScope.launch {
            _isLoadingMessages.value = true
            try {
                val fetched = apiClient.getMessages(channelId, 50, before)
                if (before != null) {
                    // Prepend older messages
                    _messages.value = fetched + _messages.value
                } else {
                    _messages.value = fetched
                }
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load messages"
            } finally {
                _isLoadingMessages.value = false
            }
        }
    }

    // ─── Send Message ─────────────────────────────────────────────────────────

    fun sendMessage() {
        val trimmed = draftMessage.value.trim()
        if (trimmed.isEmpty()) return
        if (trimmed.length > 500) return
        if (_isRateLimited.value) return
        val channelId = _selectedChannel.value?.id ?: return

        viewModelScope.launch {
            try {
                val sent = apiClient.sendMessage(channelId, trimmed, null)
                _messages.value = _messages.value + sent
                draftMessage.value = ""
                lastSentAt = System.currentTimeMillis()
                if (currentUserTier.lowercase() == "standard") {
                    startRateLimitCooldown()
                }
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to send message"
            }
        }
    }

    // ─── Rate Limit Cooldown ──────────────────────────────────────────────────

    private fun startRateLimitCooldown() {
        rateLimitJob?.cancel()
        _isRateLimited.value = true
        _rateLimitRemainingSeconds.value = rateLimitDuration.toInt()

        rateLimitJob = viewModelScope.launch {
            repeat(rateLimitDuration.toInt()) {
                delay(1000L)
                _rateLimitRemainingSeconds.value--
            }
            _isRateLimited.value = false
        }
    }

    // ─── Reactions ────────────────────────────────────────────────────────────

    fun addReaction(message: ChatMessage, emoji: String) {
        viewModelScope.launch {
            try {
                apiClient.addReaction(message.id, emoji)
            } catch (_: Exception) {
                // Silently ignore reaction errors
            }
        }
    }

    fun removeReaction(message: ChatMessage, emoji: String) {
        viewModelScope.launch {
            try {
                apiClient.removeReaction(message.id, emoji)
            } catch (_: Exception) {
                // Silently ignore reaction errors
            }
        }
    }

    // ─── Translation ──────────────────────────────────────────────────────────

    suspend fun translateMessage(message: ChatMessage): String? {
        return try {
            val result = apiClient.translateMessage(message.id, "en")
            result.translatedText
        } catch (_: Exception) {
            null
        }
    }

    // ─── Socket.IO stubs (TODO: Wire to socket.io-client-java in production) ──

    fun connectSocket() {
        // TODO: Socket.IO — SocketManager + auth token handshake
    }

    fun disconnectSocket() {
        // TODO: Socket.IO — socket.disconnect()
    }

    // ─── Error ────────────────────────────────────────────────────────────────

    fun clearError() {
        _error.value = null
    }
}
