import SwiftUI
import Combine

@MainActor
final class GovernanceViewModel: ObservableObject {
    @Published var detail: GovernanceVoteDetail?
    @Published var selectedOption: String?
    @Published var isLoading = false
    @Published var isCasting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadDetail(voteId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            detail = try await api.getVoteDetail(id: voteId)
            selectedOption = detail?.userBallot
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func castBallot(voteId: String) async {
        guard let option = selectedOption else { return }
        isCasting = true
        errorMessage = nil
        do {
            try await api.castBallot(voteId: voteId, selectedOption: option)
            successMessage = "Your vote has been recorded."
            // Reload to get updated results
            detail = try? await api.getVoteDetail(id: voteId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isCasting = false
    }
}
