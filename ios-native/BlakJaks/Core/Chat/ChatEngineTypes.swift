import Foundation

// MARK: - Connection & Delivery State

enum ChatConnectionState: String, Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case sessionExpired
}

enum ConnectionQuality: String, Sendable {
    case good
    case degraded
    case poor
}

enum MessageDeliveryStatus: String, Codable, Sendable {
    case sending
    case sent
    case failed
}

// MARK: - Outbound Queue

struct QueuedMessage: Codable, Identifiable {
    let idempotencyKey: String
    let channelId: String
    let content: String
    let replyToId: String?
    var status: MessageDeliveryStatus
    let queuedAt: Date

    var id: String { idempotencyKey }
}

// MARK: - Client → Server Messages

enum OutboundMessage {
    case joinChannel(channelId: String)
    case leaveChannel(channelId: String)
    case resume(channelId: String, lastSequence: Int)
    case sendMessage(channelId: String, content: String, replyToId: String?, idempotencyKey: String)
    case typing(channelId: String)
    case addReaction(messageId: String, emoji: String, channelId: String)
    case removeReaction(messageId: String, emoji: String, channelId: String)
    case deleteMessage(messageId: String, channelId: String)
    case ping
    case pong
    case ack(sequence: Int, channelId: String)

    func toJSON() -> [String: Any] {
        switch self {
        case .joinChannel(let channelId):
            return ["type": "join_channel", "channel_id": channelId]
        case .leaveChannel(let channelId):
            return ["type": "leave_channel", "channel_id": channelId]
        case .resume(let channelId, let lastSequence):
            return ["type": "resume", "channel_id": channelId, "last_sequence": lastSequence]
        case .sendMessage(let channelId, let content, let replyToId, let idempotencyKey):
            var dict: [String: Any] = [
                "type": "send_message",
                "channel_id": channelId,
                "content": content,
                "idempotency_key": idempotencyKey
            ]
            if let replyToId { dict["reply_to_id"] = replyToId }
            return dict
        case .typing(let channelId):
            return ["type": "typing", "channel_id": channelId]
        case .addReaction(let messageId, let emoji, let channelId):
            return ["type": "add_reaction", "message_id": messageId, "emoji": emoji, "channel_id": channelId]
        case .removeReaction(let messageId, let emoji, let channelId):
            return ["type": "remove_reaction", "message_id": messageId, "emoji": emoji, "channel_id": channelId]
        case .deleteMessage(let messageId, let channelId):
            return ["type": "delete_message", "message_id": messageId, "channel_id": channelId]
        case .ping:
            return ["type": "ping"]
        case .pong:
            return ["type": "pong"]
        case .ack(let sequence, let channelId):
            return ["type": "ack", "sequence": sequence, "channel_id": channelId]
        }
    }
}

// MARK: - Server → Client Messages

enum InboundMessage {
    case authSuccess(AuthSuccessPayload)
    case newMessage(NewMessagePayload)
    case messageDeleted(MessageDeletedPayload)
    case reactionUpdate(ReactionUpdatePayload)
    case typing(TypingPayload)
    case presenceUpdate(PresenceUpdatePayload)
    case streamEnded(streamId: String)
    case replayStart(ReplayStartPayload)
    case replayMessage(NewMessagePayload)
    case replayEnd(ReplayEndPayload)
    case ping
    case pong
    case error(code: String, message: String)
    case sessionExpired

    static func decode(from data: Data) -> InboundMessage? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return nil }

        switch type {
        case "auth_success":
            return .authSuccess(AuthSuccessPayload(
                sessionId: json["session_id"] as? String ?? "",
                userId: json["user_id"] as? String ?? ""
            ))

        case "new_message":
            guard let payload = NewMessagePayload(json: json) else { return nil }
            return .newMessage(payload)

        case "message_deleted":
            return .messageDeleted(MessageDeletedPayload(
                messageId: json["message_id"] as? String ?? "",
                channelId: json["channel_id"] as? String ?? "",
                deletedBy: json["deleted_by"] as? String ?? ""
            ))

        case "reaction_update":
            return .reactionUpdate(ReactionUpdatePayload(
                messageId: json["message_id"] as? String ?? "",
                channelId: json["channel_id"] as? String ?? "",
                emoji: json["emoji"] as? String ?? "",
                action: json["action"] as? String ?? "",
                userId: json["user_id"] as? String ?? ""
            ))

        case "typing":
            return .typing(TypingPayload(
                channelId: json["channel_id"] as? String ?? "",
                username: json["username"] as? String ?? "",
                userId: json["user_id"] as? String ?? ""
            ))

        case "presence_update":
            return .presenceUpdate(PresenceUpdatePayload(
                channelId: json["channel_id"] as? String ?? "",
                userId: json["user_id"] as? String ?? "",
                username: json["username"] as? String ?? "",
                status: json["status"] as? String ?? "offline"
            ))

        case "stream_ended":
            return .streamEnded(streamId: json["stream_id"] as? String ?? "")

        case "replay_start":
            return .replayStart(ReplayStartPayload(
                channelId: json["channel_id"] as? String ?? "",
                fromSequence: json["from_sequence"] as? Int ?? 0,
                toSequence: json["to_sequence"] as? Int ?? 0,
                fullResync: json["full_resync"] as? Bool ?? false,
                messageCount: json["message_count"] as? Int ?? 0
            ))

        case "replay_message":
            guard let payload = NewMessagePayload(json: json) else { return nil }
            return .replayMessage(payload)

        case "replay_end":
            return .replayEnd(ReplayEndPayload(
                channelId: json["channel_id"] as? String ?? "",
                toSequence: json["to_sequence"] as? Int ?? 0
            ))

        case "ping":
            return .ping

        case "pong":
            return .pong

        case "error":
            return .error(
                code: json["code"] as? String ?? "unknown",
                message: json["message"] as? String ?? ""
            )

        case "session_expired":
            return .sessionExpired

        default:
            return nil
        }
    }
}

// MARK: - Payload Structs

struct AuthSuccessPayload {
    let sessionId: String
    let userId: String
}

struct NewMessagePayload: Identifiable {
    let id: String
    let channelId: String
    let userId: String
    let username: String
    let avatarUrl: String?
    let content: String
    let sequence: Int
    let timestamp: String
    let replyToId: String?
    let replyPreview: String?
    let isSystem: Bool
    let idempotencyKey: String?
    let status: String?

    init?(json: [String: Any]) {
        guard let id = json["id"] as? String,
              let channelId = json["channel_id"] as? String,
              let userId = json["user_id"] as? String,
              let username = json["username"] as? String,
              let content = json["content"] as? String,
              let sequence = json["sequence"] as? Int,
              let timestamp = json["timestamp"] as? String else { return nil }

        self.id = id
        self.channelId = channelId
        self.userId = userId
        self.username = username
        self.avatarUrl = json["avatar_url"] as? String
        self.content = content
        self.sequence = sequence
        self.timestamp = timestamp
        self.replyToId = json["reply_to_id"] as? String
        self.replyPreview = json["reply_preview"] as? String
        self.isSystem = json["is_system"] as? Bool ?? false
        self.idempotencyKey = json["idempotency_key"] as? String
        self.status = json["status"] as? String
    }
}

struct MessageDeletedPayload {
    let messageId: String
    let channelId: String
    let deletedBy: String
}

struct ReactionUpdatePayload {
    let messageId: String
    let channelId: String
    let emoji: String
    let action: String  // "add" or "remove"
    let userId: String
}

struct TypingPayload {
    let channelId: String
    let username: String
    let userId: String
}

struct PresenceUpdatePayload {
    let channelId: String
    let userId: String
    let username: String
    let status: String  // "online" or "offline"
}

struct ReplayStartPayload {
    let channelId: String
    let fromSequence: Int
    let toSequence: Int
    let fullResync: Bool
    let messageCount: Int
}

struct ReplayEndPayload {
    let channelId: String
    let toSequence: Int
}
