import SwiftUI

// MARK: - ProductSelectionView
// Full product detail screen with quantity selector and add-to-cart action.

struct ProductSelectionView: View {
    let product: Product
    @ObservedObject var cartVM: CartViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1
    @State private var isAdding = false
    @State private var addedFeedback = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // Hero image
                    heroImage

                    // Content
                    VStack(alignment: .leading, spacing: Spacing.lg) {

                        // Name + identifiers
                        productHeader

                        // Attribute badges
                        if product.flavor != nil || product.nicotineStrength != nil {
                            attributeBadges
                        }

                        // Divider
                        Rectangle()
                            .fill(Color.borderSubtle)
                            .frame(height: 0.5)

                        // Description
                        descriptionSection

                        // Divider
                        Rectangle()
                            .fill(Color.borderSubtle)
                            .frame(height: 0.5)

                        // Stock + quantity
                        stockAndQuantitySection

                        // Bottom padding for sticky button
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xl)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Sticky Add to Cart button
            stickyAddToCartBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.goldMid)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        ZStack(alignment: .bottom) {
            // Image or placeholder
            if let urlString = product.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                    case .failure, .empty:
                        heroPlaceholder
                    @unknown default:
                        heroPlaceholder
                    }
                }
                .frame(height: 300)
            } else {
                heroPlaceholder
            }

            // Bottom gradient overlay fading into background
            LinearGradient(
                colors: [Color.clear, Color.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        }
        .frame(height: 300)
    }

    private var heroPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.14), Color(white: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: Spacing.md) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundColor(Color.textTertiary)
                Text(product.category.uppercased())
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    // MARK: - Product Header

    private var productHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Category eyebrow
            HStack {
                Text(product.category.uppercased())
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)

                Spacer()

                Text("SKU: \(product.sku)")
                    .font(BJFont.sora(10, weight: .regular))
                    .foregroundColor(Color.textTertiary)
            }

            // Product name
            Text(product.name)
                .font(BJFont.playfair(24, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Price
            Text(product.price.formatted(.currency(code: "USD")))
                .font(BJFont.outfit(28, weight: .heavy))
                .foregroundColor(Color.gold)
        }
    }

    // MARK: - Attribute Badges

    private var attributeBadges: some View {
        HStack(spacing: Spacing.xs) {
            if let flavor = product.flavor {
                AttributeBadge(label: "FLAVOR", value: flavor, icon: "flame")
            }
            if let strength = product.nicotineStrength {
                AttributeBadge(label: "NICOTINE", value: strength, icon: "bolt")
            }
            Spacer()
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("ABOUT THIS PRODUCT")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.goldMid)

            Text(product.description)
                .font(BJFont.sora(14, weight: .regular))
                .foregroundColor(Color.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Stock & Quantity

    private var stockAndQuantitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Stock indicator
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(product.inStock ? Color.success : Color.error)
                    .frame(width: 7, height: 7)

                if product.inStock {
                    Text(product.stockCount > 10
                         ? "In Stock"
                         : "Only \(product.stockCount) left")
                        .font(BJFont.sora(12, weight: .semibold))
                        .foregroundColor(product.stockCount > 10 ? Color.success : Color.warning)
                } else {
                    Text("Out of Stock")
                        .font(BJFont.sora(12, weight: .semibold))
                        .foregroundColor(Color.error)
                }
            }

            // Quantity stepper
            if product.inStock {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("QUANTITY")
                        .font(BJFont.eyebrow)
                        .tracking(3)
                        .foregroundColor(Color.textTertiary)

                    HStack(spacing: 0) {
                        // Minus
                        Button {
                            if quantity > 1 { quantity -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(quantity > 1 ? Color.goldMid : Color.textTertiary)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(quantity <= 1)

                        Rectangle()
                            .fill(Color.borderSubtle)
                            .frame(width: 0.5, height: 24)

                        // Count
                        Text("\(quantity)")
                            .font(BJFont.outfit(18, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                            .frame(width: 56, height: 44)
                            .multilineTextAlignment(.center)

                        Rectangle()
                            .fill(Color.borderSubtle)
                            .frame(width: 0.5, height: 24)

                        // Plus
                        Button {
                            if quantity < product.stockCount { quantity += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(quantity < product.stockCount ? Color.goldMid : Color.textTertiary)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(quantity >= product.stockCount)
                    }
                    .background(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.borderGold, lineWidth: 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
            }
        }
    }

    // MARK: - Sticky Add to Cart Bar

    private var stickyAddToCartBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 0.5)

            HStack(spacing: Spacing.md) {
                // Line total
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL")
                        .font(BJFont.eyebrow)
                        .tracking(2)
                        .foregroundColor(Color.textTertiary)
                    Text((product.price * Double(quantity)).formatted(.currency(code: "USD")))
                        .font(BJFont.outfit(20, weight: .heavy))
                        .foregroundColor(Color.gold)
                }

                GoldButton(
                    title: addedFeedback ? "Added!" : "Add to Cart",
                    action: {
                        guard product.inStock && !isAdding else { return }
                        isAdding = true
                        Task {
                            await cartVM.addToCart(productId: product.id, quantity: quantity)
                            isAdding = false
                            withAnimation(.easeInOut(duration: 0.2)) { addedFeedback = true }
                            try? await Task.sleep(nanoseconds: 1_400_000_000)
                            withAnimation(.easeInOut(duration: 0.2)) { addedFeedback = false }
                        }
                    },
                    isLoading: isAdding,
                    isDisabled: !product.inStock
                )
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(
                Color.bgPrimary
                    .overlay(
                        LinearGradient(
                            colors: [Color.bgPrimary.opacity(0), Color.bgPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
    }
}

// MARK: - AttributeBadge

private struct AttributeBadge: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.goldMid)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(BJFont.micro)
                    .tracking(1)
                    .foregroundColor(Color.textTertiary)
                Text(value)
                    .font(BJFont.sora(12, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }
}

#Preview {
    let sample = Product(
        id: 1,
        name: "Arctic Frost Nicotine Pouches",
        sku: "BJ-NP-001",
        description: "Premium nicotine pouches crafted with care. Each pouch delivers a crisp, refreshing arctic mint sensation with a clean, consistent release of nicotine. Tobacco-free, discreet, and long-lasting.",
        price: 14.99,
        imageUrl: nil,
        category: "Pouches",
        flavor: "Arctic Mint",
        nicotineStrength: "6mg",
        inStock: true,
        stockCount: 48
    )
    return NavigationStack {
        ProductSelectionView(product: sample, cartVM: CartViewModel())
    }
}
