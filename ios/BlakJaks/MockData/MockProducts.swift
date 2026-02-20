import Foundation

enum MockProducts {
    static let list: [Product] = [
        Product(id: 1, name: "BlakJaks Classic", sku: "BJC-001", description: "Our flagship nicotine pouch — smooth, bold, and balanced.", price: 12.99, imageUrl: nil, category: "pouches", flavor: "Classic Mint", nicotineStrength: "6mg", inStock: true, stockCount: 500),
        Product(id: 2, name: "BlakJaks Gold", sku: "BJG-001", description: "Premium gold-tier blend with enhanced nicotine delivery.", price: 15.99, imageUrl: nil, category: "pouches", flavor: "Spearmint", nicotineStrength: "8mg", inStock: true, stockCount: 250),
        Product(id: 3, name: "BlakJaks Frost", sku: "BJF-001", description: "Ice-cold menthol blast for maximum freshness.", price: 12.99, imageUrl: nil, category: "pouches", flavor: "Arctic Frost", nicotineStrength: "4mg", inStock: true, stockCount: 180),
        Product(id: 4, name: "BlakJaks Citrus", sku: "BJCT-001", description: "Bright citrus notes with a clean finish.", price: 12.99, imageUrl: nil, category: "pouches", flavor: "Blood Orange", nicotineStrength: "6mg", inStock: false, stockCount: 0)
    ]

    static let cart = Cart(
        items: [
            CartItem(id: 1, productId: 1, productName: "BlakJaks Classic", imageUrl: nil, quantity: 2, unitPrice: 12.99, lineTotal: 25.98),
            CartItem(id: 2, productId: 2, productName: "BlakJaks Gold", imageUrl: nil, quantity: 1, unitPrice: 15.99, lineTotal: 15.99)
        ],
        subtotal: 41.97,
        itemCount: 3
    )

    static let order = Order(
        id: 1001,
        status: "processing",
        items: cart.items,
        shippingAddress: ShippingAddress(firstName: "Alex", lastName: "Johnson", line1: "123 Main St", line2: nil, city: "Austin", state: "TX", zip: "78701", country: "US"),
        subtotal: 41.97,
        taxAmount: 3.78,
        total: 45.75,
        ageVerificationId: "age-verified-uuid",
        createdAt: "2026-02-20T12:00:00Z",
        trackingNumber: nil
    )
}
