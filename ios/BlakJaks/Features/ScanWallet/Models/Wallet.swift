import Foundation

struct Wallet: Codable {
    let availableBalance: Double
    let pendingBalance: Double
    let currency: String
    let linkedBankAccount: DwollaFundingSource?
}
