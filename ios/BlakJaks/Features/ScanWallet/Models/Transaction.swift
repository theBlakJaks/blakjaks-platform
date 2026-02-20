import Foundation

struct Transaction: Codable, Identifiable {
    let id: Int
    let type: String
    let amount: Double
    let currency: String
    let status: String
    let description: String
    let createdAt: String
    let processedAt: String?
    let txHash: String?
}
