import SwiftUI

// MARK: - ProductCardView
// Compact two-column grid card for the shop product listing.

struct ProductCardView: View {
    let product: Product
    let onAddToCart: () -> Void

    @State private var isAdding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image area
            productImageArea
                .frame(height: 140)
                .clipped()

            // Details
            VStack(alignment: .leading, spacing: Spacing.xxs) {

                // Product name
                Text(product.name)
                    .font(BJFont.playfair(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.sm)

                // Flavor / nicotine row
                Group {
                    if let flavor = product.flavor, let strength = product.nicotineStrength {
                        Text("\(flavor) · \(strength)")
                            .font(BJFont.sora(10, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                            .lineLimit(1)
                    } else if let flavor = product.flavor {
                        Text(flavor)
                            .font(BJFont.sora(10, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                            .lineLimit(1)
                    } else if let strength = product.nicotineStrength {
                        Text(strength)
                            .font(BJFont.sora(10, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 2)

                // Price
                Text(product.price.formatted(.currency(code: "USD")))
                    .font(BJFont.outfit(16, weight: .bold))
                    .foregroundColor(Color.gold)
                    .padding(.top, Spacing.xxs)

                // Add to cart button
                Button {
                    guard product.inStock && !isAdding else { return }
                    isAdding = true
                    onAddToCart()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAdding = false
                    }
                } label: {
                    ZStack {
                        if isAdding {
                            ProgressView()
                                .tint(Color.bgPrimary)
                                .scaleEffect(0.75)
                        } else {
                            Text(product.inStock ? "ADD TO CART" : "OUT OF STOCK")
                                .font(BJFont.sora(10, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(product.inStock ? Color.bgPrimary : Color.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(
                        product.inStock
                            ? LinearGradient.goldShimmer
                            : LinearGradient(colors: [Color.bgCard], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(product.inStock ? Color.clear : Color.borderSubtle, lineWidth: 1)
                    )
                }
                .disabled(!product.inStock || isAdding)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.sm)
            }
            .padding(.horizontal, Spacing.sm)
        }
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    // MARK: - Image Area

    private var productImageArea: some View {
        ZStack(alignment: .topLeading) {
            // Background / image
            if let urlString = product.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderGradient
                    case .empty:
                        placeholderGradient
                            .overlay(
                                ProgressView().tint(Color.goldMid)
                            )
                    @unknown default:
                        placeholderGradient
                    }
                }
            } else {
                placeholderGradient
            }

            // Out of stock overlay
            if !product.inStock {
                ZStack {
                    Color.black.opacity(0.65)

                    Text("OUT OF STOCK")
                        .font(BJFont.sora(9, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color.textSecondary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }
            }

            // Category badge top-left
            Text(product.category.uppercased())
                .font(BJFont.micro)
                .tracking(1)
                .foregroundColor(Color.bgPrimary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 3)
                .background(LinearGradient.goldShimmer)
                .clipShape(Capsule())
                .padding(Spacing.xs)
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                Color(white: 0.12),
                Color(white: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "shippingbox")
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(Color.textTertiary)
        )
    }
}

#Preview {
    let sample = Product(
        id: 1,
        name: "Arctic Frost Nicotine Pouches",
        sku: "BJ-NP-001",
        description: "Premium nicotine pouches with crisp arctic mint flavor.",
        price: 14.99,
        imageUrl: nil,
        category: "Pouches",
        flavor: "Arctic Mint",
        nicotineStrength: "6mg",
        inStock: true,
        stockCount: 48
    )
    return HStack {
        ProductCardView(product: sample, onAddToCart: {})
        ProductCardView(
            product: Product(
                id: 2,
                name: "Maduro Reserve Cigar",
                sku: "BJ-CIG-002",
                description: "Full-bodied maduro with rich cocoa notes.",
                price: 24.99,
                imageUrl: nil,
                category: "Cigars",
                flavor: "Maduro",
                nicotineStrength: nil,
                inStock: false,
                stockCount: 0
            ),
            onAddToCart: {}
        )
    }
    .padding()
    .background(Color.bgPrimary)
}
