import SwiftUI

// MARK: - ShopView
// Product catalog: 2-column flavor grid, search bar, cart badge.
// FDA nicotine warning banner (20% screen top, never dismissible).

struct ShopView: View {
    @StateObject private var shopVM = ShopViewModel()
    @StateObject private var cartVM = CartViewModel()
    @State private var showCart = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                scrollContent
                    .padding(.top, UIScreen.main.bounds.height * 0.20)
                NicotineWarningBanner()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shop")
                        .font(.system(.title3, design: .serif))
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    cartBadgeButton
                }
            }
            .task {
                async let p: () = shopVM.loadProducts()
                async let c: () = cartVM.loadCart()
                _ = await (p, c)
            }
            .sheet(isPresented: $showCart) {
                CartView(cartVM: cartVM)
            }
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                searchBar

                if shopVM.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xxl)
                } else if let error = shopVM.error {
                    ErrorView(error: error) {
                        await shopVM.loadProducts()
                    }
                    .padding(.horizontal, Spacing.lg)
                } else if shopVM.filteredProducts.isEmpty {
                    EmptyStateView(
                        icon: "bag",
                        title: "No Products",
                        subtitle: "Check back soon for new BlakJaks products."
                    )
                    .padding(.horizontal, Spacing.lg)
                } else {
                    productGrid
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.backgroundPrimary)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: Spacing.xxl)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search products...", text: $shopVM.searchQuery)
                .font(.body)
            if !shopVM.searchQuery.isEmpty {
                Button {
                    shopVM.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Product grid (2-column)

    private var productGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Layout.gridGutter),
                GridItem(.flexible(), spacing: Layout.gridGutter)
            ],
            spacing: Layout.gridGutter
        ) {
            ForEach(shopVM.filteredProducts) { product in
                NavigationLink {
                    ProductSelectionView(product: product, cartVM: cartVM)
                } label: {
                    ProductFlavorCard(product: product)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Cart badge button

    private var cartBadgeButton: some View {
        Button {
            showCart = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bag")
                    .font(.body)
                    .foregroundColor(.primary)
                if cartVM.itemCount > 0 {
                    Text("\(cartVM.itemCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.black)
                        .padding(Spacing.xs)
                        .background(Circle().fill(Color.gold))
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
}

// MARK: - ProductFlavorCard

struct ProductFlavorCard: View {
    let product: Product

    var body: some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: 0) {
                // Image placeholder — 1:1 aspect ratio
                ZStack {
                    RoundedRectangle(cornerRadius: Spacing.md)
                        .fill(
                            product.inStock
                            ? LinearGradient(
                                colors: [Color.gold.opacity(0.25), Color.backgroundTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.backgroundTertiary, Color.backgroundTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                        )
                        .aspectRatio(1, contentMode: .fit)
                    VStack(spacing: Spacing.xs) {
                        Text("♠")
                            .font(.system(.largeTitle, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(product.inStock ? .gold : .secondary)
                        if !product.inStock {
                            Text("OUT OF STOCK")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.backgroundTertiary))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if let flavor = product.flavor {
                        Text(flavor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    HStack {
                        Text("$\(product.price.formatted(.number.precision(.fractionLength(2))))")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                        Spacer()
                        if let strength = product.nicotineStrength {
                            Text(strength)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.backgroundTertiary))
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            }
        }
        .opacity(product.inStock ? 1.0 : 0.55)
    }
}

// MARK: - Preview

#Preview {
    ShopView()
}
