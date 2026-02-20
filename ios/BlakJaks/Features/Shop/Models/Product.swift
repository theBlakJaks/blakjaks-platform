import Foundation

struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let sku: String
    let description: String
    let price: Double
    let imageUrl: String?
    let category: String
    let flavor: String?
    let nicotineStrength: String?
    let inStock: Bool
    let stockCount: Int
}
