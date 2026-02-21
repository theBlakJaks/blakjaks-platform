import Foundation

// MARK: - LiveStream

struct LiveStream: Identifiable, Codable {
    let id: Int
    let title: String
    let hlsUrl: String?   // nil = offline
    let viewerCount: Int
    let isLive: Bool
    let hostName: String
    let thumbnailUrl: String?
}

// MARK: - MockLiveStream

enum MockLiveStream {
    static let live = LiveStream(
        id: 1,
        title: "BlakJaks Community Stream",
        hlsUrl: nil,
        viewerCount: 143,
        isLive: false,
        hostName: "BlakJaks HQ",
        thumbnailUrl: nil
    )
}
