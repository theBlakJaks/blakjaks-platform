import SwiftUI

// MARK: - ProductSelectionView
// Full product detail: hero image, strength indicator, flavor badge,
// quantity stepper, add-to-cart CTA with inline confirmation toast.

struct ProductSelectionView: View {
    let product: Product
    @ObservedObject var cartVM: CartViewModel

    @State private var quantity = 1
    @State private var showAddedToast = false

    private let maxQuantity = 10
    private let strengths = ["4mg", "6mg", "8mg", "12mg"]

    var body: some View {
        ZStack(alignment: .top) {
            scrollContent
                .padding(.top, UIScreen.main.bounds.height * 0.20)
            NicotineWarningBanner()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(product.name)
                    .font(.headline)
            }
        }
        .overlay(alignment: .bottom) {
            addedToast
        }
        .alert("Error", isPresented: Binding(get: { cartVM.error != nil }, set: { _ in cartVM.clearError() })) {
            Button("OK", role: .cancel) { cartVM.clearError() }
        } message: {
            Text(cartVM.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                heroSection

                VStack(alignment: .leading, spacing: Spacing.md) {
                    productInfoCard
                    if product.nicotineStrength != nil {
                        strengthSection
                    }
                    descriptionSection
                }
                .padding(.horizontal, Layout.screenMargin)

                addToCartSection
                    .padding(.horizontal, Layout.screenMargin)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.backgroundPrimary)
    }

    // MARK: - Hero section

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gold.opacity(0.18), Color.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            VStack(spacing: Spacing.sm) {
                Text("♠")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(product.inStock ? .gold : Color.secondary.opacity(0.5))
                if !product.inStock {
                    Text("OUT OF STOCK")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.warning)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.warning.opacity(0.15)))
                }
            }
        }
    }

    // MARK: - Product info card

    private var productInfoCard: some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.title3.weight(.bold))
                        if let flavor = product.flavor {
                            HStack(spacing: 4) {
                                Image(systemName: "wind")
                                    .font(.caption)
                                    .foregroundColor(.gold)
                                Text(flavor)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Text("$\(product.price.formatted(.number.precision(.fractionLength(2))))")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.gold)
                }
                Divider()
                HStack(spacing: Spacing.lg) {
                    if let strength = product.nicotineStrength {
                        metaLabel("Nicotine", strength)
                    }
                    metaLabel("SKU", product.sku)
                    metaLabel("Type", product.category.capitalized)
                }
            }
        }
    }

    private func metaLabel(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote.weight(.medium))
        }
    }

    // MARK: - Strength section

    private var strengthSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Nicotine Strength")
                .font(.headline)
            HStack(spacing: Spacing.sm) {
                ForEach(strengths, id: \.self) { level in
                    let isThis = product.nicotineStrength == level
                    Text(level)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(isThis ? .black : .secondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isThis ? Color.gold : Color.backgroundTertiary)
                        )
                }
                Spacer()
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("About")
                .font(.headline)
            Text(product.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Add to cart

    private var addToCartSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Quantity")
                    .font(.headline)
                Spacer()
                quantityStepper
            }

            let lineTotal = product.price * Double(quantity)
            Button {
                Task { await addToCart() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    if cartVM.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "bag.badge.plus")
                        Text(product.inStock
                             ? "Add to Cart — $\(lineTotal.formatted(.number.precision(.fractionLength(2))))"
                             : "Out of Stock")
                        .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(product.inStock ? Color.gold : Color.backgroundTertiary)
                .foregroundColor(product.inStock ? .black : .secondary)
                .cornerRadius(Layout.cardCornerRadius)
            }
            .disabled(!product.inStock || cartVM.isLoading)
        }
    }

    private var quantityStepper: some View {
        HStack(spacing: 0) {
            Button {
                if quantity > 1 { quantity -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.backgroundTertiary)
            }
            .disabled(quantity <= 1)

            Text("\(quantity)")
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .frame(width: 44, height: 40)
                .background(Color.backgroundSecondary)

            Button {
                if quantity < maxQuantity { quantity += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.backgroundTertiary)
            }
            .disabled(quantity >= maxQuantity)
        }
        .cornerRadius(8)
        .foregroundColor(.primary)
    }

    // MARK: - Added toast

    private var addedToast: some View {
        Group {
            if showAddedToast {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text("\(quantity == 1 ? "1 item" : "\(quantity) items") added to cart!")
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.backgroundSecondary)
                .cornerRadius(Layout.cardCornerRadius)
                .shadow(color: .black.opacity(0.2), radius: 8)
                .padding(.bottom, Spacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showAddedToast)
    }

    // MARK: - Actions

    @MainActor
    private func addToCart() async {
        await cartVM.addItem(productId: product.id, quantity: quantity)
        guard cartVM.error == nil else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showAddedToast = true }
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        withAnimation { showAddedToast = false }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProductSelectionView(
            product: MockProducts.list[0],
            cartVM: CartViewModel()
        )
    }
}
