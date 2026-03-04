import Foundation
import Combine
import UIKit
import Starscream

// MARK: - Constants

private let queueStorageKey = "com.blakjaks.chat.outboundQueue"
private let sequenceStorageKey = "com.blakjaks.chat.lastSequence"
private let maxQueueSize = 20
private let queueTTL: TimeInterval = 5 * 60 // 5 minutes
private let queueFlushDelay: TimeInterval = 0.1
private let zombieTimeout: TimeInterval = 35 // no server ping in 35s → zombie
private let dedupMaxSize = 1000
private let maxReconnectDelay: TimeInterval = 10
private let reconnectJitter: TimeInterval = 0.5
private let maxReconnectAttempts = 10
private let rapidCloseThreshold: TimeInterval = 2 // WS closes within 2s → likely auth rejection
private let confirmationTimeout: TimeInterval = 10

@MainActor
final class ChatEngine: ObservableObject {

    // MARK: - Published State

    @Published private(set) var connectionState: ChatConnectionState = .disconnected
    @Published private(set) var quality: ConnectionQuality = .good

    // MARK: - Combine Publishers (events)

    let onMessage = PassthroughSubject<NewMessagePayload, Never>()
    let onMessageDeleted = PassthroughSubject<MessageDeletedPayload, Never>()
    let onReactionUpdate = PassthroughSubject<ReactionUpdatePayload, Never>()
    let onTyping = PassthroughSubject<TypingPayload, Never>()
    let onPresenceUpdate = PassthroughSubject<PresenceUpdatePayload, Never>()
    let onMessageQueued = PassthroughSubject<QueuedMessage, Never>()
    let onMessageConfirmed = PassthroughSubject<(idempotencyKey: String, message: NewMessagePayload), Never>()
    let onMessageFailed = PassthroughSubject<String, Never>()
    let onReplayStart = PassthroughSubject<ReplayStartPayload, Never>()
    let onReplayEnd = PassthroughSubject<ReplayEndPayload, Never>()
    let onError = PassthroughSubject<(code: String, message: String), Never>()
    let onCatchingUp = PassthroughSubject<Bool, Never>()

    // MARK: - Internal State

    private var socket: WebSocket?
    private var sessionId: String?
    private(set) var userId: String?
    private var getToken: (() -> String?)?

    private var reconnectAttempts = 0
    private var rapidCloseCount = 0
    private var connectTime: Date = .distantPast
    private var reconnectWorkItem: DispatchWorkItem?
    private var zombieWorkItem: DispatchWorkItem?
    private var rttTimer: Timer?

    private var lastSequence: [String: Int] = [:]
    private var outboundQueue: [String: QueuedMessage] = [:]
    private var confirmationTimers: [String: DispatchWorkItem] = [:]

    private var replayBuffer: [String: [NewMessagePayload]] = [:]
    private var replayFullResync: [String: Bool] = [:]
    private var catchingUpChannels: Set<String> = []

    private var seenIds: [String] = []
    private var joinedChannels: Set<String> = []

    private var qualityMonitor = ConnectionQualityMonitor()
    private var pingTimestamp: Date?

    private var foregroundObserver: Any?
    private var backgroundObserver: Any?
    private var backgroundWorkItem: DispatchWorkItem?

    /// Delegate bridge (Starscream calls delegate methods off-main, we dispatch to @MainActor)
    private var delegateBridge: WebSocketDelegateBridge?

    // MARK: - Init

    init() {
        restoreQueue()
        restoreSequences()
        qualityMonitor.onChange = { [weak self] q in
            Task { @MainActor in
                self?.quality = q
                self?.startRttInterval()
            }
        }
    }

    deinit {
        if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver) }
        if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }
    }

    // MARK: - Public API

    func connect(getToken: @escaping () -> String?) {
        self.getToken = getToken
        doConnect()
        bindAppLifecycle()
    }

    func disconnect() {
        unbindAppLifecycle()
        clearReconnect()
        clearZombieTimer()
        stopRttInterval()
        socket?.disconnect()
        socket = nil
        delegateBridge = nil
        setState(.disconnected)
    }

    func joinChannel(_ channelId: String) {
        joinedChannels.insert(channelId)
        send(.joinChannel(channelId: channelId))
    }

    func leaveChannel(_ channelId: String) {
        joinedChannels.remove(channelId)
        send(.leaveChannel(channelId: channelId))
    }

    func resumeChannel(_ channelId: String) {
        let lastSeq = lastSequence[channelId] ?? 0
        joinedChannels.insert(channelId)
        send(.resume(channelId: channelId, lastSequence: lastSeq))
    }

    @discardableResult
    func sendMessage(channelId: String, content: String, replyToId: String? = nil, existingIdempotencyKey: String? = nil) -> QueuedMessage {
        let key = existingIdempotencyKey ?? UUID().uuidString
        let queued = QueuedMessage(
            idempotencyKey: key,
            channelId: channelId,
            content: content,
            replyToId: replyToId,
            status: .sending,
            queuedAt: Date()
        )

        outboundQueue[key] = queued
        persistQueue()
        onMessageQueued.send(queued)

        // 10s confirmation timeout
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, var q = self.outboundQueue[key], q.status == .sending else { return }
                q.status = .failed
                self.outboundQueue[key] = q
                self.persistQueue()
                self.onMessageFailed.send(key)
                self.confirmationTimers.removeValue(forKey: key)
            }
        }
        confirmationTimers[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + confirmationTimeout, execute: workItem)

        // Send immediately if connected
        if socket != nil {
            send(.sendMessage(channelId: channelId, content: content, replyToId: replyToId, idempotencyKey: key))
        }

        return queued
    }

    func retryMessage(_ idempotencyKey: String) {
        guard var queued = outboundQueue[idempotencyKey] else { return }
        queued.status = .sending
        outboundQueue[idempotencyKey] = queued
        persistQueue()

        // Reset confirmation timeout
        confirmationTimers[idempotencyKey]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, var q = self.outboundQueue[idempotencyKey], q.status == .sending else { return }
                q.status = .failed
                self.outboundQueue[idempotencyKey] = q
                self.persistQueue()
                self.onMessageFailed.send(idempotencyKey)
                self.confirmationTimers.removeValue(forKey: idempotencyKey)
            }
        }
        confirmationTimers[idempotencyKey] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + confirmationTimeout, execute: workItem)

        if socket != nil {
            send(.sendMessage(
                channelId: queued.channelId,
                content: queued.content,
                replyToId: queued.replyToId,
                idempotencyKey: idempotencyKey
            ))
        }
    }

    func addReaction(messageId: String, emoji: String, channelId: String) {
        send(.addReaction(messageId: messageId, emoji: emoji, channelId: channelId))
    }

    func removeReaction(messageId: String, emoji: String, channelId: String) {
        send(.removeReaction(messageId: messageId, emoji: emoji, channelId: channelId))
    }

    func sendTyping(_ channelId: String) {
        guard qualityMonitor.quality == .good else { return }
        send(.typing(channelId: channelId))
    }

    func deleteMessage(messageId: String, channelId: String) {
        send(.deleteMessage(messageId: messageId, channelId: channelId))
    }

    func getLastSequence(_ channelId: String) -> Int {
        lastSequence[channelId] ?? 0
    }

    // MARK: - Connection

    private func doConnect() {
        // Don't connect if already connecting/connected
        if socket != nil { return }

        guard let token = getToken?(), !token.isEmpty else {
            setState(.disconnected)
            return
        }

        setState(reconnectAttempts > 0 ? .reconnecting : .connecting)

        // Build WS URL: strip /api suffix (WS route is at app root), use wss scheme
        var baseString = Config.apiBaseURL.absoluteString
        if baseString.hasSuffix("/api") {
            baseString = String(baseString.dropLast(4))
        } else if baseString.hasSuffix("/api/") {
            baseString = String(baseString.dropLast(5))
        }
        if baseString.hasSuffix("/") { baseString = String(baseString.dropLast()) }
        baseString = baseString
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")

        guard let url = URL(string: "\(baseString)/social/ws?token=\(token)") else {
            print("[ChatEngine] Invalid WS URL from base: \(baseString)")
            setState(.disconnected)
            return
        }

        print("[ChatEngine] Connecting to: \(url.absoluteString.prefix(80))...")

        // Use Starscream — it does raw TCP + HTTP/1.1 Upgrade,
        // bypassing the HTTP/2 ALPN issue with GCE load balancer.
        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let ws = WebSocket(request: request, useCustomEngine: true)

        // Bridge Starscream delegate callbacks to our @MainActor methods
        let bridge = WebSocketDelegateBridge { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleStarscreamEvent(event)
            }
        }
        delegateBridge = bridge
        ws.delegate = bridge

        socket = ws
        connectTime = Date()
        ws.connect()
    }

    // MARK: - Starscream Event Handling

    private func handleStarscreamEvent(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            print("[ChatEngine] WebSocket connected (HTTP/1.1 upgrade succeeded)")
            // Auth happens via the first server message (auth_success), not here

        case .disconnected(let reason, let code):
            print("[ChatEngine] Disconnected reason=\(reason) code=\(code)")
            handleDisconnect(closeCode: Int(code))

        case .text(let text):
            guard let data = text.data(using: .utf8) else { return }
            handleInboundData(data)

        case .binary(let data):
            handleInboundData(data)

        case .cancelled:
            print("[ChatEngine] WebSocket cancelled")
            handleDisconnect(closeCode: nil)

        case .error(let error):
            print("[ChatEngine] WebSocket error: \(String(describing: error))")
            handleDisconnect(closeCode: nil)

        case .peerClosed:
            print("[ChatEngine] Peer closed connection")
            handleDisconnect(closeCode: nil)

        default:
            break
        }
    }

    // MARK: - Inbound Data Handling

    private func handleInboundData(_ data: Data) {
        guard let inbound = InboundMessage.decode(from: data) else { return }

        switch inbound {
        case .authSuccess(let payload):
            print("[ChatEngine] auth_success userId=\(payload.userId)")
            sessionId = payload.sessionId
            userId = payload.userId
            reconnectAttempts = 0
            rapidCloseCount = 0
            setState(.connected)
            resetZombieTimer()
            onConnected()

        case .newMessage(let payload):
            handleNewMessage(payload)

        case .messageDeleted(let payload):
            onMessageDeleted.send(payload)

        case .reactionUpdate(let payload):
            onReactionUpdate.send(payload)

        case .typing(let payload):
            onTyping.send(payload)

        case .presenceUpdate(let payload):
            onPresenceUpdate.send(payload)

        case .streamEnded:
            break

        case .replayStart(let payload):
            catchingUpChannels.insert(payload.channelId)
            replayBuffer[payload.channelId] = []
            replayFullResync[payload.channelId] = payload.fullResync
            onCatchingUp.send(true)
            onReplayStart.send(payload)

        case .replayMessage(let payload):
            trackSequence(channelId: payload.channelId, sequence: payload.sequence)
            ack(channelId: payload.channelId, sequence: payload.sequence)
            replayBuffer[payload.channelId]?.append(payload)
            onMessage.send(payload)

        case .replayEnd(let payload):
            onReplayEnd.send(payload)
            catchingUpChannels.remove(payload.channelId)
            if catchingUpChannels.isEmpty {
                onCatchingUp.send(false)
            }
            replayBuffer.removeValue(forKey: payload.channelId)
            replayFullResync.removeValue(forKey: payload.channelId)
            flushQueue()

        case .ping:
            send(.pong)
            resetZombieTimer()

        case .pong:
            if let ts = pingTimestamp {
                let rtt = Date().timeIntervalSince(ts) * 1000 // ms
                qualityMonitor.recordRtt(rtt)
                pingTimestamp = nil
            }

        case .error(let code, let message):
            onError.send((code: code, message: message))

        case .sessionExpired:
            setState(.sessionExpired)
            socket?.disconnect()
            socket = nil
            delegateBridge = nil
        }
    }

    // MARK: - Disconnect Handling

    private func handleDisconnect(closeCode: Int?) {
        socket = nil
        delegateBridge = nil
        clearZombieTimer()
        stopRttInterval()

        // Close code 4001: Auth failure — terminal, do not reconnect
        if closeCode == 4001 {
            setState(.sessionExpired)
            return
        }

        // If we intentionally disconnected, don't reconnect
        if connectionState == .disconnected {
            return
        }

        // Rapid-close detection: WS closes within 2s without reaching auth_success
        let wasRapidClose = Date().timeIntervalSince(connectTime) < rapidCloseThreshold
        if wasRapidClose && connectionState != .connected {
            rapidCloseCount += 1
        } else {
            rapidCloseCount = 0
        }

        print("[ChatEngine] closeCode=\(String(describing: closeCode)) rapidCloseCount=\(rapidCloseCount) reconnectAttempts=\(reconnectAttempts)")

        // Stop retrying after max attempts or repeated rapid closes
        if reconnectAttempts >= maxReconnectAttempts || rapidCloseCount >= 3 {
            print("[ChatEngine] Giving up: attempts=\(reconnectAttempts) rapidCloses=\(rapidCloseCount)")
            setState(.sessionExpired)
            return
        }

        // Schedule reconnect
        if closeCode == 4000 {
            scheduleReconnect(delay: 0) // Resumable — immediate retry
        } else {
            scheduleReconnect()
        }
    }

    private func handleNewMessage(_ msg: NewMessagePayload) {
        trackSequence(channelId: msg.channelId, sequence: msg.sequence)
        ack(channelId: msg.channelId, sequence: msg.sequence)

        // Check if this confirms an optimistic message — do this BEFORE dedup
        if let key = msg.idempotencyKey, let _ = outboundQueue[key] {
            confirmationTimers[key]?.cancel()
            confirmationTimers.removeValue(forKey: key)
            outboundQueue.removeValue(forKey: key)
            persistQueue()
            if !hasSeen(msg.id) {
                markSeen(msg.id)
                onMessageConfirmed.send((idempotencyKey: key, message: msg))
            }
            return
        }

        // Dedup
        if hasSeen(msg.id) { return }
        markSeen(msg.id)
        onMessage.send(msg)
    }

    // MARK: - Reconnect + Queue Flush

    private func onConnected() {
        for channelId in joinedChannels {
            resumeChannel(channelId)
        }
        measureRtt()
        startRttInterval()
    }

    private func flushQueue() {
        let now = Date()
        var toSend: [QueuedMessage] = []
        var toDiscard: [String] = []

        for (key, msg) in outboundQueue {
            if now.timeIntervalSince(msg.queuedAt) > queueTTL {
                toDiscard.append(key)
            } else if msg.status == .sending {
                toSend.append(msg)
            }
        }

        for key in toDiscard {
            confirmationTimers[key]?.cancel()
            confirmationTimers.removeValue(forKey: key)
            outboundQueue.removeValue(forKey: key)
            onMessageFailed.send(key)
        }

        if !toSend.isEmpty {
            flushWithDelay(toSend, index: 0)
        }

        persistQueue()
    }

    private func flushWithDelay(_ messages: [QueuedMessage], index: Int) {
        guard index < messages.count, socket != nil else { return }
        let msg = messages[index]
        send(.sendMessage(
            channelId: msg.channelId,
            content: msg.content,
            replyToId: msg.replyToId,
            idempotencyKey: msg.idempotencyKey
        ))

        if index + 1 < messages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + queueFlushDelay) { [weak self] in
                Task { @MainActor in
                    self?.flushWithDelay(messages, index: index + 1)
                }
            }
        }
    }

    private func scheduleReconnect(delay: TimeInterval? = nil) {
        clearReconnect()
        setState(.reconnecting)

        let actualDelay = delay ?? backoffDelay()
        reconnectAttempts += 1

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.reconnectWorkItem = nil
                self?.doConnect()
            }
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + actualDelay, execute: workItem)
    }

    private func backoffDelay() -> TimeInterval {
        let base = min(pow(2.0, Double(reconnectAttempts)), maxReconnectDelay)
        let jitter = Double.random(in: -reconnectJitter...reconnectJitter)
        return max(0, base + jitter)
    }

    private func clearReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
    }

    // MARK: - Zombie Detection

    private func resetZombieTimer() {
        clearZombieTimer()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.socket != nil else { return }
                // No server ping in 35s → close as zombie (4000 = resumable)
                self.socket?.disconnect(closeCode: UInt16(4000))
            }
        }
        zombieWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + zombieTimeout, execute: workItem)
    }

    private func clearZombieTimer() {
        zombieWorkItem?.cancel()
        zombieWorkItem = nil
    }

    // MARK: - RTT Measurement

    private func measureRtt() {
        guard socket != nil else { return }
        pingTimestamp = Date()
        send(.ping)
    }

    private func startRttInterval() {
        stopRttInterval()
        let interval: TimeInterval = qualityMonitor.quality == .poor ? 10 : 25
        rttTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.measureRtt()
            }
        }
    }

    private func stopRttInterval() {
        rttTimer?.invalidate()
        rttTimer = nil
    }

    // MARK: - Sequence Tracking & ACK

    private func trackSequence(channelId: String, sequence: Int) {
        let current = lastSequence[channelId] ?? 0
        if sequence > current {
            lastSequence[channelId] = sequence
            persistSequences()
        }
    }

    private func ack(channelId: String, sequence: Int) {
        send(.ack(sequence: sequence, channelId: channelId))
    }

    // MARK: - Dedup

    private func hasSeen(_ id: String) -> Bool {
        seenIds.contains(id)
    }

    private func markSeen(_ id: String) {
        seenIds.append(id)
        if seenIds.count > dedupMaxSize {
            seenIds = Array(seenIds.suffix(dedupMaxSize))
        }
    }

    // MARK: - Queue Persistence (UserDefaults)

    private func persistQueue() {
        let entries = outboundQueue.values
            .filter { $0.status == .sending }
            .suffix(maxQueueSize)
        if let data = try? JSONEncoder().encode(Array(entries)) {
            UserDefaults.standard.set(data, forKey: queueStorageKey)
        }
    }

    private func restoreQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueStorageKey),
              let entries = try? JSONDecoder().decode([QueuedMessage].self, from: data) else { return }
        let now = Date()
        for entry in entries where entry.status == .sending && now.timeIntervalSince(entry.queuedAt) < queueTTL {
            outboundQueue[entry.idempotencyKey] = entry
        }
    }

    // MARK: - Sequence Persistence

    private func persistSequences() {
        if let data = try? JSONEncoder().encode(lastSequence) {
            UserDefaults.standard.set(data, forKey: sequenceStorageKey)
        }
    }

    private func restoreSequences() {
        guard let data = UserDefaults.standard.data(forKey: sequenceStorageKey),
              let sequences = try? JSONDecoder().decode([String: Int].self, from: data) else { return }
        lastSequence = sequences
    }

    // MARK: - App Lifecycle

    private func bindAppLifecycle() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.backgroundWorkItem?.cancel()
                self.backgroundWorkItem = nil
                if self.connectionState != .connected &&
                   self.connectionState != .connecting &&
                   self.connectionState != .sessionExpired {
                    self.reconnectAttempts = 0
                    self.scheduleReconnect(delay: 0)
                }
                if self.connectionState == .connected {
                    self.measureRtt()
                }
            }
        }

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didEnterBackgroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let workItem = DispatchWorkItem { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if self.connectionState == .connected || self.connectionState == .reconnecting {
                            self.socket?.disconnect()
                            self.socket = nil
                            self.delegateBridge = nil
                            self.clearZombieTimer()
                            self.stopRttInterval()
                            self.setState(.disconnected)
                        }
                    }
                }
                self.backgroundWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: workItem)
            }
        }
    }

    private func unbindAppLifecycle() {
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
            self.foregroundObserver = nil
        }
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
            self.backgroundObserver = nil
        }
        backgroundWorkItem?.cancel()
        backgroundWorkItem = nil
    }

    // MARK: - Send Helper

    private func send(_ msg: OutboundMessage) {
        guard let ws = socket else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: msg.toJSON()),
              let text = String(data: data, encoding: .utf8) else { return }
        ws.write(string: text)
    }

    // MARK: - State Management

    private func setState(_ state: ChatConnectionState) {
        guard connectionState != state else { return }
        print("[ChatEngine] State: \(connectionState.rawValue) → \(state.rawValue)")
        connectionState = state
    }
}

// MARK: - WebSocket Delegate Bridge

/// Bridges Starscream's delegate callbacks (called on arbitrary threads)
/// to our @MainActor ChatEngine via a closure.
private final class WebSocketDelegateBridge: NSObject, Starscream.WebSocketDelegate {
    private let handler: (WebSocketEvent) -> Void

    init(handler: @escaping (WebSocketEvent) -> Void) {
        self.handler = handler
    }

    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        handler(event)
    }
}
