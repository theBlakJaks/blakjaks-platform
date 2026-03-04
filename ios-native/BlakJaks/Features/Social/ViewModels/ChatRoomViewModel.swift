import SwiftUI
import Combine

@MainActor
final class ChatRoomViewModel: ObservableObject {

    // MARK: - Published State

    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreHistory = true
    @Published var newMessageCount = 0
    @Published var isCatchingUp = false
    @Published var errorMessage: String?

    // Typing & Presence
    @Published var typingUsernames: [String] = []
    @Published var onlineUsers: Set<String> = []

    // Input & Composition
    @Published var inputText = ""
    @Published var isSending = false
    @Published var replyingTo: ChatMessage?
    @Published var cooldownEnd: Date?

    var cooldownActive: Bool {
        guard let end = cooldownEnd else { return false }
        return Date() < end
    }

    let channel: Channel
    private let api: APIClientProtocol
    private let engine: ChatEngine

    private var cancellables = Set<AnyCancellable>()
    private(set) var isUserAtBottom = true
    private var typingTimers: [String: DispatchWorkItem] = [:]  // userId → auto-clear timer
    private var lastTypingSent: Date = .distantPast

    // MARK: - Init

    init(channel: Channel, engine: ChatEngine, api: APIClientProtocol = APIClient.shared) {
        self.channel = channel
        self.engine = engine
        self.api = api
        subscribe()
    }

    // MARK: - Load Initial Messages

    func loadInitial() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await api.getMessages(channelId: channel.id, limit: 50, before: nil)
            messages = fetched
            hasMoreHistory = fetched.count >= 50
            // Join/resume via WebSocket for real-time
            engine.resumeChannel(channel.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Load More (Infinite Scroll)

    func loadMore() async {
        guard !isLoadingMore, hasMoreHistory, let oldest = messages.first else { return }
        isLoadingMore = true
        do {
            let older = try await api.getMessages(channelId: channel.id, limit: 50, before: oldest.id)
            if older.isEmpty {
                hasMoreHistory = false
            } else {
                messages.insert(contentsOf: older, at: 0)
                hasMoreHistory = older.count >= 50
            }
        } catch {
            // Silently fail — user can scroll up again
        }
        isLoadingMore = false
    }

    // MARK: - Send Message

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !cooldownActive else { return }

        let replyId = replyingTo?.id
        let replyPreviewText = replyingTo?.content

        inputText = ""
        replyingTo = nil
        isSending = true

        // Optimistic insert via engine queue
        let queued = engine.sendMessage(channelId: channel.id, content: text, replyToId: replyId)
        let optimistic = ChatMessage(
            id: queued.idempotencyKey,
            channelId: channel.id,
            userId: engine.userId ?? "",
            username: "",
            avatarUrl: nil,
            userTier: nil,
            content: text,
            sequence: nil,
            replyToId: replyId,
            replyPreview: replyPreviewText,
            reactions: nil,
            isPinned: false,
            isSystem: false,
            gifUrl: nil,
            originalLanguage: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            deliveryStatus: .sending,
            idempotencyKey: queued.idempotencyKey
        )
        messages.append(optimistic)
        isSending = false

        // 2s cooldown
        cooldownEnd = Date().addingTimeInterval(2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.cooldownEnd = nil
        }
    }

    // MARK: - Send GIF

    func sendGif(_ gifUrl: String) async {
        guard !cooldownActive else { return }
        isSending = true

        // Send GIF as a message with the URL as content
        let queued = engine.sendMessage(channelId: channel.id, content: gifUrl, replyToId: nil)
        let optimistic = ChatMessage(
            id: queued.idempotencyKey,
            channelId: channel.id,
            userId: engine.userId ?? "",
            username: "",
            avatarUrl: nil,
            userTier: nil,
            content: gifUrl,
            sequence: nil,
            replyToId: nil,
            replyPreview: nil,
            reactions: nil,
            isPinned: false,
            isSystem: false,
            gifUrl: gifUrl,
            originalLanguage: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            deliveryStatus: .sending,
            idempotencyKey: queued.idempotencyKey
        )
        messages.append(optimistic)
        isSending = false

        cooldownEnd = Date().addingTimeInterval(2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.cooldownEnd = nil
        }
    }

    // MARK: - Reply

    func setReply(_ message: ChatMessage) {
        replyingTo = message
    }

    func clearReply() {
        replyingTo = nil
    }

    // MARK: - Translate

    func translate(messageId: String) async -> String? {
        do {
            let result = try await api.translateMessage(messageId: messageId, targetLanguage: "en")
            return result.translatedText
        } catch {
            return nil
        }
    }

    // MARK: - Reactions

    /// Toggle reaction: add if not reacted, remove if already reacted.
    func toggleReaction(messageId: String, emoji: String) {
        guard let msg = messages.first(where: { $0.id == messageId }) else { return }
        let userId = engine.userId ?? ""
        let alreadyReacted = msg.reactionMap[emoji]?.contains(userId) ?? false
        if alreadyReacted {
            engine.removeReaction(messageId: messageId, emoji: emoji, channelId: channel.id)
        } else {
            engine.addReaction(messageId: messageId, emoji: emoji, channelId: channel.id)
        }
    }

    // MARK: - Typing

    /// Call when user types in the input field. Debounced to 3s intervals.
    func sendTypingIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastTypingSent) > 3 else { return }
        lastTypingSent = now
        engine.sendTyping(channel.id)
    }

    var currentUserId: String? { engine.userId }

    // MARK: - Scroll Tracking

    func setAtBottom(_ value: Bool) {
        isUserAtBottom = value
        if value { newMessageCount = 0 }
    }

    // MARK: - Cleanup

    func onDisappear() {
        engine.leaveChannel(channel.id)
    }

    // MARK: - Subscriptions

    private func subscribe() {
        // New messages (live + replay)
        engine.onMessage
            .filter { [weak self] in $0.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.handleIncomingMessage(payload)
            }
            .store(in: &cancellables)

        // Message confirmed (optimistic → real)
        engine.onMessageConfirmed
            .filter { [weak self] in $0.message.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] confirmed in
                self?.handleConfirmation(key: confirmed.idempotencyKey, payload: confirmed.message)
            }
            .store(in: &cancellables)

        // Message failed
        engine.onMessageFailed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] key in
                self?.handleFailure(key: key)
            }
            .store(in: &cancellables)

        // Message deleted
        engine.onMessageDeleted
            .filter { [weak self] in $0.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.messages.removeAll { $0.id == payload.messageId }
            }
            .store(in: &cancellables)

        // Reaction updates
        engine.onReactionUpdate
            .filter { [weak self] in $0.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.applyReaction(payload)
            }
            .store(in: &cancellables)

        // Catching up state
        engine.onCatchingUp
            .receive(on: DispatchQueue.main)
            .sink { [weak self] catching in
                self?.isCatchingUp = catching
            }
            .store(in: &cancellables)

        // Replay start — full resync replaces messages
        engine.onReplayStart
            .filter { [weak self] in $0.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                if payload.fullResync {
                    self?.messages.removeAll()
                }
            }
            .store(in: &cancellables)

        // Typing indicators
        engine.onTyping
            .filter { [weak self] in $0.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.handleTyping(payload)
            }
            .store(in: &cancellables)

        // Presence updates
        engine.onPresenceUpdate
            .filter { [weak self] in $0.channelId == self?.channel.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                if payload.status == "online" {
                    self?.onlineUsers.insert(payload.userId)
                } else {
                    self?.onlineUsers.remove(payload.userId)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Typing Handler

    private func handleTyping(_ payload: TypingPayload) {
        // Don't show our own typing
        guard payload.userId != engine.userId else { return }

        let userId = payload.userId
        let username = payload.username

        // Add if not present
        if !typingUsernames.contains(username) {
            typingUsernames.append(username)
        }

        // Cancel existing timer for this user
        typingTimers[userId]?.cancel()

        // Auto-remove after 4s of no typing events
        let workItem = DispatchWorkItem { [weak self] in
            self?.typingUsernames.removeAll { $0 == username }
            self?.typingTimers.removeValue(forKey: userId)
        }
        typingTimers[userId] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    // MARK: - Message Handlers

    private func handleIncomingMessage(_ payload: NewMessagePayload) {
        // Skip if we already have this message (dedup)
        guard !messages.contains(where: { $0.id == payload.id }) else { return }
        // Skip if this is a confirmation for an optimistic message
        if let key = payload.idempotencyKey, messages.contains(where: { $0.idempotencyKey == key }) { return }

        let msg = chatMessage(from: payload)
        messages.append(msg)

        if !isUserAtBottom {
            newMessageCount += 1
        }
    }

    private func handleConfirmation(key: String, payload: NewMessagePayload) {
        // Replace optimistic message with confirmed one
        if let idx = messages.firstIndex(where: { $0.idempotencyKey == key }) {
            var confirmed = chatMessage(from: payload)
            confirmed.deliveryStatus = .sent
            messages[idx] = confirmed
        }
    }

    private func handleFailure(key: String) {
        if let idx = messages.firstIndex(where: { $0.idempotencyKey == key }) {
            messages[idx].deliveryStatus = .failed
            messages[idx].idempotencyKey = key // preserve for retry
        }
    }

    private func applyReaction(_ payload: ReactionUpdatePayload) {
        guard let idx = messages.firstIndex(where: { $0.id == payload.messageId }) else { return }
        let msg = messages[idx]
        var reactionMap = msg.reactionMap
        var users = reactionMap[payload.emoji] ?? []

        if payload.action == "add" {
            if !users.contains(payload.userId) { users.append(payload.userId) }
        } else {
            users.removeAll { $0 == payload.userId }
        }

        if users.isEmpty {
            reactionMap.removeValue(forKey: payload.emoji)
        } else {
            reactionMap[payload.emoji] = users
        }

        // Convert back to [ReactionInfo]
        let newReactions = reactionMap.map { ReactionInfo(emoji: $0.key, count: $0.value.count, users: $0.value) }

        // ChatMessage has let reactions — we need to rebuild
        messages[idx] = ChatMessage(
            id: msg.id,
            channelId: msg.channelId,
            userId: msg.userId,
            username: msg.username,
            avatarUrl: msg.avatarUrl,
            userTier: msg.userTier,
            content: msg.content,
            sequence: msg.sequence,
            replyToId: msg.replyToId,
            replyPreview: msg.replyPreview,
            reactions: newReactions,
            isPinned: msg.isPinned,
            isSystem: msg.isSystem,
            gifUrl: msg.gifUrl,
            originalLanguage: msg.originalLanguage,
            createdAt: msg.createdAt,
            deliveryStatus: msg.deliveryStatus,
            idempotencyKey: msg.idempotencyKey
        )
    }

    // MARK: - Payload → Model

    private func chatMessage(from p: NewMessagePayload) -> ChatMessage {
        ChatMessage(
            id: p.id,
            channelId: p.channelId,
            userId: p.userId,
            username: p.username,
            avatarUrl: p.avatarUrl,
            userTier: nil,
            content: p.content,
            sequence: p.sequence,
            replyToId: p.replyToId,
            replyPreview: p.replyPreview,
            reactions: nil,
            isPinned: false,
            isSystem: p.isSystem,
            gifUrl: nil,
            originalLanguage: nil,
            createdAt: p.timestamp,
            deliveryStatus: nil,
            idempotencyKey: p.idempotencyKey
        )
    }
}
