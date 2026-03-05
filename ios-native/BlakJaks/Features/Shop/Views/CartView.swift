import SwiftUI

// MARK: - CartView
// Shopping cart with item list, tax estimate, and checkout navigation.

struct CartView: View {
    @ObservedObject var cartVM: CartViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCheckout = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if cartVM.isLoading {
                LoadingView(message: "Loading your cart...")
            } else if let cart = cartVM.cart, !cart.items.isEmpty {
                filledCartView(cart: cart)
            } else {
                emptyCartView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(BJFont.sora(14, weight: .medium))
                    }
                    .foregroundColor(Color.goldMid)
                }
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("YOUR CART")
                        .font(BJFont.playfair(18, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color.textPrimary)
                    if let count = cartVM.cart?.itemCount, count > 0 {
                        Text("\(count) \(count == 1 ? "item" : "items")")
                            .font(BJFont.sora(10, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                    }
                }
            }
        }
        .disableSwipeBack()
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView(cartVM: cartVM)
        }
    }

    // MARK: - Filled Cart

    private func filledCartView(cart: Cart) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.sm) {

                    // Items
                    VStack(spacing: 0) {
                        ForEach(Array(cart.items.enumerated()), id: \.element.id) { index, item in
                            CartItemRowView(
                                item: item,
                                onIncrement: {
                                    Task { await cartVM.updateItem(productId: item.productId, quantity: item.quantity + 1) }
                                },
                                onDecrement: {
                                    if item.quantity > 1 {
                                        Task { await cartVM.updateItem(productId: item.productId, quantity: item.quantity - 1) }
                                    } else {
                                        Task { await cartVM.removeItem(productId: item.productId) }
                                    }
                                },
                                onRemove: {
                                    Task { await cartVM.removeItem(productId: item.productId) }
                                }
                            )

                            if index < cart.items.count - 1 {
                                Rectangle()
                                    .fill(Color.borderSubtle)
                                    .frame(height: 0.5)
                                    .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                    .background(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.borderGold, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Order summary card
                    orderSummaryCard(cart: cart)
                        .padding(.horizontal, Spacing.md)

                    // Error message
                    if let error = cartVM.errorMessage {
                        Text(error)
                            .font(BJFont.caption)
                            .foregroundColor(Color.error)
                            .padding(.horizontal, Spacing.xl)
                            .multilineTextAlignment(.center)
                    }

                    // Bottom padding for button
                    Spacer(minLength: 100)
                }
            }

            // Sticky checkout button
            checkoutBar
        }
    }

    private func orderSummaryCard(cart: Cart) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ORDER SUMMARY")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 0.5)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.sm) {
                // Subtotal
                SummaryRow(label: "Subtotal", value: cart.subtotal.formatted(.currency(code: "USD")))

                // Tax
                if let tax = cartVM.taxEstimate {
                    SummaryRow(
                        label: "Tax (\(String(format: "%.1f", tax.taxRate * 100))%)",
                        value: tax.taxAmount.formatted(.currency(code: "USD"))
                    )
                } else {
                    HStack {
                        Text("Tax")
                            .font(BJFont.sora(13, weight: .regular))
                            .foregroundColor(Color.textSecondary)
                        Spacer()
                        Text("Enter address to calculate")
                            .font(BJFont.sora(11, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 0.5)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

            // Total
            HStack {
                Text("TOTAL")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.textPrimary)
                Spacer()
                let total = cartVM.taxEstimate?.total ?? cart.subtotal
                Text(total.formatted(.currency(code: "USD")))
                    .font(BJFont.outfit(22, weight: .heavy))
                    .foregroundColor(Color.gold)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var checkoutBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 0.5)

            GoldButton(title: "Proceed to Checkout", action: {
                showCheckout = true
            })
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(Color.bgPrimary)
        }
    }

    // MARK: - Empty Cart

    private var emptyCartView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            EmptyStateView(
                icon: "🛍️",
                title: "Cart is Empty",
                subtitle: "Add some products from the shop to get started."
            )

            GhostButton(title: "Browse Products") {
                dismiss()
            }
            .frame(maxWidth: 220)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - CartItemRowView

struct CartItemRowView: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Product thumbnail
            itemThumbnail

            // Name + price
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.productName)
                    .font(BJFont.playfair(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)

                Text(item.unitPrice.formatted(.currency(code: "USD")) + " each")
                    .font(BJFont.sora(10, weight: .regular))
                    .foregroundColor(Color.textTertiary)

                Text(item.lineTotal.formatted(.currency(code: "USD")))
                    .font(BJFont.outfit(15, weight: .bold))
                    .foregroundColor(Color.gold)
            }

            Spacer()

            // Quantity stepper + remove
            VStack(spacing: Spacing.xs) {
                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.textTertiary)
                        .frame(width: 22, height: 22)
                        .background(Color.bgInput)
                        .clipShape(Circle())
                }

                // Stepper
                HStack(spacing: 0) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.goldMid)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(item.quantity)")
                        .font(BJFont.outfit(13, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .frame(width: 28, height: 28)
                        .multilineTextAlignment(.center)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.goldMid)
                            .frame(width: 28, height: 28)
                    }
                }
                .background(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .padding(Spacing.md)
    }

    private var itemThumbnail: some View {
        Group {
            if let urlString = item.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .stroke(Color.borderSubtle, lineWidth: 0.5)
        )
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.13), Color(white: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "shippingbox")
                .font(.system(size: 18, weight: .thin))
                .foregroundColor(Color.textTertiary)
        }
    }
}

// MARK: - SummaryRow

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(value)
                .font(BJFont.outfit(14, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        CartView(cartVM: CartViewModel())
    }
}
