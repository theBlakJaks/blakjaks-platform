import Foundation

// MARK: - SocketEvent

enum SocketEvent: String {
    case newMessage = "new_message"
    case messageReaction = "message_reaction"
    case pinMessage = "pin_message"
    case systemEvent = "system_event"
    case viewerCount = "viewer_count"
}

// MARK: - WebSocketManager
// Wraps Socket.IO-Client-Swift (declared as SPM dependency in project.yml).
// Real wiring happens in production polish pass.
// import SocketIO will be added when the SPM package resolves.

@MainActor
final class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false

    var onNewMessage: ((ChatMessage) -> Void)?
    var onSystemEvent: ((String) -> Void)?
    var onViewerCountUpdate: ((Int) -> Void)?

    private init() {}

    func connect(channelId: Int, authToken: String) {
        // TODO: production
        // import SocketIO
        // let manager = SocketManager(socketURL: URL(string: AppConfig.wsBaseURL)!, config: [.log(false), .compress])
        // socket = manager.defaultSocket
        // socket.on(SocketEvent.newMessage.rawValue) { ... }
        // socket.connect()
    }

    func disconnect() {
        isConnected = false
    }

    func emit(event: SocketEvent, data: [String: Any]) {
        // TODO: production — socket.emit(event.rawValue, with: [data])
    }
}
