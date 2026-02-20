import Foundation

// MARK: - InsightsViewModel
// Manages all 5 Insights sub-pages. Loads concurrently on first appear.
// Follows iOS Strategy § 7.1 ViewModel Contract.

@MainActor
final class InsightsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var overview:  InsightsOverview?
    @Published var treasury:  InsightsTreasury?
    @Published var systems:   InsightsSystems?
    @Published var comps:     InsightsComps?
    @Published var partners:  InsightsPartners?

    @Published var feedPage:    [InsightsFeedItem] = []
    @Published var isLoading  = false
    @Published var error: Error?

    // Which sub-page is active (for lazy loading)
    @Published var activeTab: InsightsTab = .overview

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Load

    func loadActiveTab() async {
        switch activeTab {
        case .overview: await loadOverview()
        case .treasury: await loadTreasury()
        case .systems:  await loadSystems()
        case .comps:    await loadComps()
        case .partners: await loadPartners()
        }
    }

    func loadOverview() async {
        guard overview == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let ov   = apiClient.getInsightsOverview()
            async let feed = apiClient.getInsightsFeed(limit: 20, offset: 0)
            let (o, f) = try await (ov, feed)
            overview = o
            feedPage = f
        } catch {
            self.error = error
        }
    }

    func loadTreasury() async {
        guard treasury == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do { treasury = try await apiClient.getInsightsTreasury() } catch { self.error = error }
    }

    func loadSystems() async {
        guard systems == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do { systems = try await apiClient.getInsightsSystems() } catch { self.error = error }
    }

    func loadComps() async {
        guard comps == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do { comps = try await apiClient.getInsightsComps() } catch { self.error = error }
    }

    func loadPartners() async {
        guard partners == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do { partners = try await apiClient.getInsightsPartners() } catch { self.error = error }
    }

    func refresh() async {
        overview = nil; treasury = nil; systems = nil; comps = nil; partners = nil
        feedPage = []
        await loadActiveTab()
    }

    func clearError() { error = nil }
}

// MARK: - InsightsTab

enum InsightsTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case treasury = "Treasury"
    case systems  = "Systems"
    case comps    = "Comps"
    case partners = "Partners"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .treasury: return "building.columns.fill"
        case .systems:  return "cpu.fill"
        case .comps:    return "gift.fill"
        case .partners: return "person.2.fill"
        }
    }
}
