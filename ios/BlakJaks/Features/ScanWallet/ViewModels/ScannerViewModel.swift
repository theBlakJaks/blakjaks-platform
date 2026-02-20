import Foundation
// Stub — implemented in Task I4
@MainActor
class ScannerViewModel: ObservableObject {
    @Published var scanResult: ScanResult?
    @Published var isLoading = false
    @Published var error: Error?
    private let apiClient: APIClientProtocol
    init(apiClient: APIClientProtocol = MockAPIClient()) { self.apiClient = apiClient }
}
