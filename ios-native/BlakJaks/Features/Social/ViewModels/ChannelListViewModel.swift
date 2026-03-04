import SwiftUI
import Combine

@MainActor
final class ChannelListViewModel: ObservableObject {

    // Ordered category groupings
    @Published var channelsByCategory: [(category: String, channels: [Channel])] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Collapsed state per category
    @Published var collapsedCategories: Set<String> = []

    private let api: APIClientProtocol

    private static let categoryOrder = ["Standard", "VIP", "High Roller", "Whale"]

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadChannels() async {
        isLoading = true
        errorMessage = nil
        do {
            let channels = try await api.getChannels()
            // Group by category, ordered by categoryOrder
            var grouped: [String: [Channel]] = [:]
            for ch in channels {
                let cat = ch.category ?? "Standard"
                grouped[cat, default: []].append(ch)
            }
            channelsByCategory = Self.categoryOrder.compactMap { cat in
                guard let channels = grouped[cat], !channels.isEmpty else { return nil }
                return (category: cat, channels: channels)
            }
            // Append any categories not in the predefined order
            let knownCats = Set(Self.categoryOrder)
            for (cat, channels) in grouped where !knownCats.contains(cat) {
                channelsByCategory.append((category: cat, channels: channels))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleCategory(_ category: String) {
        if collapsedCategories.contains(category) {
            collapsedCategories.remove(category)
        } else {
            collapsedCategories.insert(category)
        }
    }

    /// Icon prefix for a channel based on its room type
    func channelPrefix(for channel: Channel) -> String {
        switch channel.roomType {
        case "announcements": return "📢"
        case "governance": return "🗳"
        default: return "#"
        }
    }

    /// Tier icon for category headers
    func categoryIcon(for category: String) -> String {
        switch category {
        case "Standard": return "♠"
        case "VIP": return "♦"
        case "High Roller": return "♥"
        case "Whale": return "♣"
        default: return "#"
        }
    }
}
