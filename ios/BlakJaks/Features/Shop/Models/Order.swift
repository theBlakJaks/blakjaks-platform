import Foundation

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
