import SwiftUI
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var overview: InsightsOverview?
    @Published var treasury: InsightsTreasury?
    @Published var systems: InsightsSystems?
    @Published var comps: InsightsComps?
    @Published var partners: InsightsPartners?
    @Published var feed: [ActivityFeedItem] = []
    @Published var isLoadingOverview = false
    @Published var isLoadingTreasury = false
    @Published var isLoadingSystems = false
    @Published var isLoadingComps = false
    @Published var isLoadingPartners = false
    @Published var errorMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadOverview() async {
        isLoadingOverview = true
        errorMessage = nil
        do {
            overview = try await api.getInsightsOverview()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingOverview = false
    }

    func loadTreasury() async {
        isLoadingTreasury = true
        do {
            treasury = try await api.getInsightsTreasury()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingTreasury = false
    }

    func loadSystems() async {
        isLoadingSystems = true
        do {
            systems = try await api.getInsightsSystems()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingSystems = false
    }

    func loadComps() async {
        isLoadingComps = true
        do {
            comps = try await api.getInsightsComps()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingComps = false
    }

    func loadPartners() async {
        isLoadingPartners = true
        do {
            partners = try await api.getInsightsPartners()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingPartners = false
    }

    func loadFeed() async {
        do {
            feed = try await api.getInsightsFeed(limit: 30, offset: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
