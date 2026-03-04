import SwiftUI
import Combine

@MainActor
final class ScanWalletViewModel: ObservableObject {

    @Published var wallet: Wallet?
    @Published var transactions: [Transaction] = []
    @Published var compVault: CompVault?
    @Published var fundingSources: [DwollaFundingSource] = []
    @Published var isLoadingWallet = false
    @Published var isLoadingTransactions = false
    @Published var errorMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    // MARK: - Wallet

    func loadWallet() async {
        isLoadingWallet = true
        errorMessage = nil
        do {
            async let w = api.getWallet()
            async let fs = api.getDwollaFundingSources()
            wallet = try await w
            fundingSources = (try? await fs) ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingWallet = false
    }

    // MARK: - Transactions

    func loadTransactions(refresh: Bool = false) async {
        if refresh { transactions = [] }
        isLoadingTransactions = true
        do {
            transactions = try await api.getTransactions(limit: 50, offset: 0, statusFilter: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingTransactions = false
    }

    // MARK: - Comp Vault

    func loadCompVault() async {
        do {
            compVault = try await api.getCompVault()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Withdrawals

    func withdrawToBank(amount: Double, fundingSourceId: String) async throws -> DwollaTransfer {
        try await api.withdrawToBank(amount: amount, fundingSourceId: fundingSourceId)
    }

    func withdrawCrypto(address: String, amount: Double) async throws -> WithdrawalResult {
        try await api.withdrawCrypto(address: address, amount: amount)
    }

    // MARK: - Comp Payout

    func submitPayoutChoice(compId: String, method: String) async throws {
        _ = try await api.submitPayoutChoice(compId: compId, method: method)
    }
}
