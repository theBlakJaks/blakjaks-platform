import Foundation

// MARK: - LiveStream model
// Defined here (not in APIClientProtocol) since it's only used by Social features.

struct LiveStream: Codable, Identifiable {
    let id: Int
    let title: String
    let hlsUrl: String?
    let viewerCount: Int
    let isLive: Bool
    let hostName: String
    let thumbnailUrl: String?
}

// MARK: - MemberCard
// Already declared in APIClientProtocol — see Core/Network/APIClientProtocol.swift

// NOTE: getLiveStreams() and registerPushToken(_:) are implemented directly
// in the APIClient class body (Networking/APIClient.swift) since they need
// access to internal session state.
