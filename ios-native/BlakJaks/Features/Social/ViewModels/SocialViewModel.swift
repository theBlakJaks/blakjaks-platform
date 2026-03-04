import SwiftUI
import Combine

@MainActor
final class SocialViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var liveStreams: [LiveStream] = []
    @Published var proposals: [GovernanceVote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var onlineCount: Int = 0

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        async let ch = api.getChannels()
        async let ls = api.getLiveStreams()
        async let gv = api.getActiveVotes()
        do {
            channels = (try? await ch) ?? []
            liveStreams = (try? await ls) ?? []
            proposals = (try? await gv) ?? []
            onlineCount = Int.random(in: 120...380) // real-time via socket — placeholder count
        }
        isLoading = false
    }
}
