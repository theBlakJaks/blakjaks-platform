import Foundation
// Stub — implemented in Task I4
@MainActor
class InsightsViewModel: ObservableObject {
    @Published var overview: InsightsOverview?
    @Published var isLoading = false
    @Published var error: Error?
    private let apiClient: APIClientProtocol
    init(apiClient: APIClientProtocol = MockAPIClient()) { self.apiClient = apiClient }
    func loadOverview() async {
        isLoading = true; defer { isLoading = false }
        do { overview = try await apiClient.getInsightsOverview() } catch { self.error = error }
    }
}
