import Foundation

// MARK: - ScanWalletViewModel
// Owns all data for the center tab: member card, wallet, transactions,
// scan history, comp vault, and Dwolla bank linking.
// Follows iOS Strategy § 7.1 ViewModel Contract.

@MainActor
final class ScanWalletViewModel: ObservableObject {

    // MARK: - Published State

    @Published var memberCard: MemberCard?
    @Published var wallet: Wallet?
    @Published var transactions: [Transaction] = []
    @Published var scans: [Scan] = []
    @Published var compVault: CompVault?
    @Published var fundingSources: [DwollaFundingSource] = []

    @Published var isLoading     = false
    @Published var isRefreshing  = false
    @Published var error: Error?

    // Withdrawal sheet
    @Published var showWithdrawSheet  = false
    @Published var withdrawAmount     = ""
    @Published var withdrawAddress    = ""
    @Published var withdrawIsLoading  = false

    // Bank link sheet
    @Published var showBankLinkSheet  = false
    @Published var plaidLinkToken: PlaidLinkToken?

    // Payout choice
    @Published var showPayoutChoiceSheet = false
    @Published var pendingChoiceComp: CompEarned? = nil
    @Published var isSubmittingPayoutChoice = false

    // Transaction filter
    @Published var txFilter: TxFilter = .all

    // MARK: - Dependencies

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Initial Load

    func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let card   = apiClient.getMemberCard()
            async let wallet = apiClient.getWallet()
            async let txs    = apiClient.getTransactions(limit: 50, offset: 0, statusFilter: nil)
            async let scans  = apiClient.getScanHistory(limit: 20, offset: 0)
            async let vault  = apiClient.getCompVault()
            let (c, w, t, s, v) = try await (card, wallet, txs, scans, vault)
            memberCard   = c
            self.wallet  = w
            transactions = t
            self.scans   = s
            compVault    = v
        } catch {
            self.error = error
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        memberCard = nil; wallet = nil; transactions = []; scans = []; compVault = nil
        await loadAll()
    }

    // MARK: - Computed

    var compBalance: Double {
        wallet?.compBalance ?? 0
    }

    // MARK: - Filtered transactions

    var filteredTransactions: [Transaction] {
        switch txFilter {
        case .all:         return transactions
        case .deposits:    return transactions.filter { $0.amount > 0 }
        case .withdrawals: return transactions.filter { $0.amount < 0 }
        }
    }

    // MARK: - Crypto Withdrawal

    func withdrawCrypto() async -> Bool {
        let amountValue = Double(withdrawAmount) ?? 0
        guard amountValue > 0, !withdrawAddress.isEmpty else {
            error = WithdrawError.invalidInput; return false
        }
        withdrawIsLoading = true
        defer { withdrawIsLoading = false }
        do {
            _ = try await apiClient.withdrawCrypto(address: withdrawAddress, amount: amountValue)
            withdrawAmount = ""; withdrawAddress = ""
            await refresh()
            return true
        } catch {
            self.error = error; return false
        }
    }

    // MARK: - Bank Withdrawal (Dwolla ACH)

    func withdrawToBank(fundingSourceId: String) async -> Bool {
        let amountValue = Double(withdrawAmount) ?? 0
        guard amountValue > 0 else {
            error = WithdrawError.invalidInput; return false
        }
        withdrawIsLoading = true
        defer { withdrawIsLoading = false }
        do {
            _ = try await apiClient.withdrawToBank(amount: amountValue, fundingSourceId: fundingSourceId)
            withdrawAmount = ""
            await refresh()
            return true
        } catch {
            self.error = error; return false
        }
    }

    // MARK: - Payout Choice

    func submitPayoutChoice(compId: String, method: String) async {
        isSubmittingPayoutChoice = true
        defer { isSubmittingPayoutChoice = false }
        do {
            _ = try await apiClient.submitPayoutChoice(compId: compId, method: method)
            showPayoutChoiceSheet = false
            pendingChoiceComp = nil
            await refresh()
        } catch {
            self.error = error
        }
    }

    // MARK: - Bank Linking (Plaid via Dwolla Exchange Session)

    func fetchPlaidLinkToken() async {
        do {
            plaidLinkToken = try await apiClient.getPlaidLinkToken()
            showBankLinkSheet = true
        } catch {
            self.error = error
        }
    }

    func completeBankLink(publicToken: String, accountId: String) async {
        do {
            let source = try await apiClient.linkBankAccount(publicToken: publicToken, accountId: accountId)
            fundingSources.append(source)
            wallet = try await apiClient.getWallet()
            showBankLinkSheet = false
        } catch {
            self.error = error
        }
    }

    func clearError() { error = nil }
}

// MARK: - TxFilter

enum TxFilter: String, CaseIterable {
    case all = "All"
    case deposits = "Deposits"
    case withdrawals = "Withdrawals"
}

// MARK: - WithdrawError

enum WithdrawError: LocalizedError {
    case invalidInput
    var errorDescription: String? { "Please enter a valid amount and destination." }
}
