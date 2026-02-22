import SwiftUI

// MARK: - CartView
// Cart items list with inline quantity controls, pricing summary, checkout CTA.
// Presented as a sheet from ShopView. Pushes to CheckoutView via NavigationStack.

struct CartView: View {
    @ObservedObject var cartVM: CartViewModel
    @State private var showCheckout = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                contentView
                    .padding(.top, UIScreen.main.bounds.height * 0.20)
                NicotineWarningBanner()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Cart")
                        .font(.system(.title3, design: .serif))
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.primary)
                }
            }
            .navigationDestination(isPresented: $showCheckout) {
                CheckoutView(cartVM: cartVM)
            }
            .alert("Error", isPresented: Binding(
                get: { cartVM.error != nil },
                set: { _ in cartVM.clearError() }
            )) {
                Button("OK", role: .cancel) { cartVM.clearError() }
            } message: {
                Text(cartVM.error?.localizedDescription ?? "")
            }
        }
    }

    // MARK: - Content routing

    @ViewBuilder
    private var contentView: some View {
        if cartVM.isLoading {
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let cart = cartVM.cart, !cart.items.isEmpty {
            cartContent(cart: cart)
        } else {
            emptyCartView
        }
    }

    // MARK: - Cart content

    private func cartContent(cart: Cart) -> some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                itemsList(cart: cart)
                pricingSummary
            }
            .padding(.top, Spacing.md)
            // Bottom padding to clear the fixed checkout button
            .padding(.bottom, Layout.buttonHeight + Spacing.xxl)
        }
        .background(Color.backgroundPrimary)
        .safeAreaInset(edge: .bottom) {
            checkoutButton
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.backgroundPrimary)
        }
    }

    // MARK: - Items list

    private func itemsList(cart: Cart) -> some View {
        VStack(spacing: 0) {
            ForEach(cart.items) { item in
                cartItemRow(item)
                if item.id != cart.items.last?.id {
                    Divider().padding(.horizontal, Spacing.lg)
                }
            }
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
        .padding(.horizontal, Spacing.lg)
    }

    private func cartItemRow(_ item: CartItem) -> some View {
        HStack(spacing: Spacing.md) {
            // Product icon
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.sm)
                    .fill(Color.gold.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text("♠")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.gold)
            }

            // Name + price per unit
            VStack(alignment: .leading, spacing: 2) {
                Text(item.productName)
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
                Text("$\(item.unitPrice.formatted(.number.precision(.fractionLength(2)))) each")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Line total + quantity controls
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("$\(item.lineTotal.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(.footnote, design: .monospaced).weight(.semibold))

                HStack(spacing: 0) {
                    Button {
                        Task {
                            if item.quantity > 1 {
                                await cartVM.updateItem(productId: item.productId, quantity: item.quantity - 1)
                            } else {
                                await cartVM.removeItem(productId: item.productId)
                            }
                        }
                    } label: {
                        Image(systemName: item.quantity > 1 ? "minus" : "trash")
                            .font(.caption.weight(.semibold))
                            .frame(width: 28, height: 28)
                            .background(Color.backgroundTertiary)
                    }

                    Text("\(item.quantity)")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .frame(width: 28, height: 28)
                        .background(Color.backgroundSecondary)

                    Button {
                        Task { await cartVM.updateItem(productId: item.productId, quantity: item.quantity + 1) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.semibold))
                            .frame(width: 28, height: 28)
                            .background(Color.backgroundTertiary)
                    }
                }
                .cornerRadius(Spacing.xs)
                .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Pricing summary

    private var pricingSummary: some View {
        BlakJaksCard {
            VStack(spacing: Spacing.sm) {
                priceRow("Subtotal", cartVM.subtotal)
                if cartVM.isFreeShipping {
                    priceRow("Shipping", 0, freeLabel: "FREE")
                } else {
                    priceRow("Shipping", cartVM.shippingCost)
                    Text("Free shipping on orders $\(Int(CartViewModel.freeShippingThreshold))+")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if cartVM.taxAmount > 0 {
                    priceRow("Tax", cartVM.taxAmount)
                }
                Divider()
                priceRow("Total", cartVM.orderTotal, isBold: true, goldValue: true)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func priceRow(
        _ label: String, _ value: Double,
        isBold: Bool = false, goldValue: Bool = false,
        freeLabel: String? = nil
    ) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .footnote.weight(.bold) : .footnote)
                .foregroundColor(isBold ? .primary : .secondary)
            Spacer()
            if let free = freeLabel {
                Text(free)
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundColor(.success)
            } else {
                Text("$\(value.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(.footnote, design: .monospaced).weight(isBold ? .bold : .regular))
                    .foregroundColor(goldValue ? .gold : .primary)
            }
        }
    }

    // MARK: - Checkout button

    private var checkoutButton: some View {
        GoldButton("Proceed to Checkout") {
            cartVM.resetCheckout()
            showCheckout = true
        }
    }

    // MARK: - Empty state

    private var emptyCartView: some View {
        EmptyStateView(
            icon: "bag",
            title: "Your Cart is Empty",
            subtitle: "Browse the shop and add BlakJaks products to get started."
        )
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    CartView(cartVM: {
        let vm = CartViewModel()
        return vm
    }())
}
