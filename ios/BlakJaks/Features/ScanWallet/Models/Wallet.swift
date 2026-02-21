import Foundation

struct Wallet: Codable {
    let compBalance: Double
    let availableBalance: Double
    let pendingBalance: Double
    let currency: String
    let linkedBankAccount: DwollaFundingSource?
    let address: String?        // polygon wallet address
}
