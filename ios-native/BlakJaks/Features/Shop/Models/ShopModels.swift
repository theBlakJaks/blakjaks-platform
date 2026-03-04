import Foundation

// MARK: - Shop Domain Models
// Product, Order, and related types for the BlakJaks Shop feature.

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

struct Order: Codable, Identifiable {
    let id: Int
    let status: String
    let items: [CartItem]
    let shippingAddress: ShippingAddress
    let subtotal: Double
    let taxAmount: Double
    let total: Double
    let ageVerificationId: String?
    let createdAt: String
    let trackingNumber: String?
}
