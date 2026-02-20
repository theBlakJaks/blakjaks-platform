import Foundation

// MARK: - SocialViewModel

@MainActor
final class SocialViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var channels: [Channel] = []
    @Published var selectedChannel: Channel? = nil
    @Published var messages: [ChatMessage] = []
    @Published var isLoadingMessages = false
    @Published var isLoadingChannels = false
    @Published var error: Error?
    @Published var currentLiveStream: LiveStream? = MockLiveStream.live
    @Published var isRateLimited = false
    @Published var rateLimitRemainingSeconds: Int = 0
    @Published var newMessageCount = 0
    @Published var pinnedMessage: ChatMessage? = nil
    @Published var draftMessage = ""

    // MARK: - Private Properties

    private var lastSentAt: Date? = nil
    private var rateLimitTimer: Timer? = nil
    private let rateLimitDuration: TimeInterval = 5.0
    private let apiClient: APIClientProtocol
    let currentUserId: Int = 1
    let currentUserTier: String = "Standard"

    // MARK: - Init

    init(apiClient: APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Channel Methods

    func loadChannels() async {
        isLoadingChannels = true
        defer { isLoadingChannels = false }
        do {
            channels = try await apiClient.getChannels()
        } catch {
            self.error = error
        }
    }

    func selectChannel(_ channel: Channel) async {
        selectedChannel = channel
        messages = []
        newMessageCount = 0
        await loadMessages()
    }

    func loadMessages(before: Int? = nil) async {
        guard let channelId = selectedChannel?.id else { return }
        isLoadingMessages = true
        defer { isLoadingMessages = false }
        do {
            let fetched = try await apiClient.getMessages(channelId: channelId, limit: 50, before: before)
            if before != nil {
                // Prepend older messages
                messages = fetched + messages
            } else {
                messages = fetched
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Send Message

    func sendMessage() async {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= 500 else { return }
        guard !isRateLimited else { return }
        guard let channelId = selectedChannel?.id else { return }

        do {
            let sent = try await apiClient.sendMessage(channelId: channelId, content: trimmed, mediaType: nil)
            messages.append(sent)
            draftMessage = ""
            lastSentAt = Date()
            if currentUserTier.lowercased() == "standard" {
                startRateLimitCooldown()
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Rate Limit Cooldown

    private func startRateLimitCooldown() {
        isRateLimited = true
        rateLimitRemainingSeconds = 5

        rateLimitTimer?.invalidate()
        rateLimitTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                if self.rateLimitRemainingSeconds > 0 {
                    self.rateLimitRemainingSeconds -= 1
                }
                if self.rateLimitRemainingSeconds <= 0 {
                    self.isRateLimited = false
                    timer.invalidate()
                    self.rateLimitTimer = nil
                }
            }
        }
    }

    // MARK: - Reactions

    func addReaction(to message: ChatMessage, emoji: String) async {
        do {
            try await apiClient.addReaction(messageId: message.id, emoji: emoji)
        } catch {
            // Silently handle reaction errors
        }
    }

    func removeReaction(from message: ChatMessage, emoji: String) async {
        do {
            try await apiClient.removeReaction(messageId: message.id, emoji: emoji)
        } catch {
            // Silently handle reaction errors
        }
    }

    // MARK: - Translation

    func translateMessage(_ message: ChatMessage) async -> String? {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        do {
            let result = try await apiClient.translateMessage(messageId: message.id, targetLanguage: langCode)
            return result.translatedText
        } catch {
            return nil
        }
    }

    // MARK: - Error

    func clearError() {
        error = nil
    }

    // MARK: - Socket.IO (wire in production polish pass)
    // In production: import SocketIO; replace stubs with SocketManager/SocketIOClient calls

    func connectSocket() {
        // TODO: production — SocketManager + auth token
    }

    func disconnectSocket() {
        // TODO: production — socket.disconnect()
    }
}
