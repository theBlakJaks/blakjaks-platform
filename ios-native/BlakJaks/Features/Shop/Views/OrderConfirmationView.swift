import SwiftUI

// MARK: - OrderConfirmationView
// Full-screen order success screen with order details and navigation options.

struct OrderConfirmationView: View {
    let order: Order
    @ObservedObject var cartVM: CartViewModel

    @State private var showOrderDetails = false
    @State private var checkmarkAppeared = false

    // Dismiss back to ShopView root
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // Top spacing
                    Spacer(minLength: Spacing.xxxl)

                    // Animated gold checkmark
                    confirmationHero
                        .padding(.bottom, Spacing.xl)

                    // Order confirmed heading
                    VStack(spacing: Spacing.xs) {
                        Text("Order Confirmed!")
                            .font(BJFont.playfair(28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Thank you for your purchase.")
                            .font(BJFont.sora(14, weight: .regular))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.bottom, Spacing.xl)

                    // Order details card
                    orderDetailsCard
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.lg)

                    // Delivery note
                    deliveryNote
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)

                    // Tracking number (if available)
                    if let tracking = order.trackingNumber {
                        trackingRow(tracking: tracking)
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }

                    // View order details toggle
                    viewOrderDetailsSection
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)

                    // Continue shopping CTA
                    GoldButton(title: "Continue Shopping") {
                        // Pop all the way back to root shop view
                        // NavigationStack pops automatically when we reset lastOrder
                        cartVM.lastOrder = nil
                        dismiss()
                    }
                    .padding(.horizontal, Spacing.xl)

                    Spacer(minLength: Spacing.xxxl)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                checkmarkAppeared = true
            }
        }
    }

    // MARK: - Confirmation Hero

    private var confirmationHero: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(Color.gold.opacity(0.08))
                .frame(width: 120, height: 120)
                .scaleEffect(checkmarkAppeared ? 1.0 : 0.5)
                .opacity(checkmarkAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.15), value: checkmarkAppeared)

            // Gold circle
            Circle()
                .fill(LinearGradient.goldShimmer)
                .frame(width: 90, height: 90)
                .shadow(color: Color.gold.opacity(0.4), radius: 20, y: 6)
                .scaleEffect(checkmarkAppeared ? 1.0 : 0.3)
                .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.05), value: checkmarkAppeared)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color.bgPrimary)
                .scaleEffect(checkmarkAppeared ? 1.0 : 0.1)
                .opacity(checkmarkAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3), value: checkmarkAppeared)
        }
    }

    // MARK: - Order Details Card

    private var orderDetailsCard: some View {
        VStack(spacing: 0) {
            // Order number + status row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORDER NUMBER")
                        .font(BJFont.eyebrow)
                        .tracking(2.5)
                        .foregroundColor(Color.textTertiary)
                    Text("#\(order.id)")
                        .font(BJFont.outfit(20, weight: .heavy))
                        .foregroundColor(Color.gold)
                }

                Spacer()

                StatusBadge(status: order.status)
            }
            .padding(Spacing.md)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 0.5)

            // Financial summary
            VStack(spacing: Spacing.sm) {
                ConfirmationSummaryRow(
                    label: "Subtotal",
                    value: order.subtotal.formatted(.currency(code: "USD"))
                )
                ConfirmationSummaryRow(
                    label: "Tax",
                    value: order.taxAmount.formatted(.currency(code: "USD"))
                )

                Rectangle()
                    .fill(Color.borderSubtle)
                    .frame(height: 0.5)

                HStack {
                    Text("TOTAL CHARGED")
                        .font(BJFont.sora(13, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    Text(order.total.formatted(.currency(code: "USD")))
                        .font(BJFont.outfit(20, weight: .heavy))
                        .foregroundColor(Color.gold)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    // MARK: - Delivery Note

    private var deliveryNote: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "shippingbox")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color.goldMid)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("ESTIMATED DELIVERY")
                    .font(BJFont.eyebrow)
                    .tracking(2)
                    .foregroundColor(Color.goldMid)
                Text("5–7 business days after age verification is completed.")
                    .font(BJFont.sora(12, weight: .regular))
                    .foregroundColor(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Tracking Row

    private func trackingRow(tracking: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "location.circle")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color.goldMid)

            VStack(alignment: .leading, spacing: 3) {
                Text("TRACKING NUMBER")
                    .font(BJFont.eyebrow)
                    .tracking(2)
                    .foregroundColor(Color.textTertiary)
                Text(tracking)
                    .font(BJFont.outfit(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .textSelection(.enabled)
            }

            Spacer()

            Button {
                UIPasteboard.general.string = tracking
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundColor(Color.goldMid)
                    .padding(Spacing.xs)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .padding(Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.gold.opacity(0.2), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Order Items Section

    private var viewOrderDetailsSection: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showOrderDetails.toggle()
                }
            } label: {
                HStack {
                    Text(showOrderDetails ? "Hide Order Details" : "View Order Details")
                        .font(BJFont.sora(13, weight: .semibold))
                        .foregroundColor(Color.goldMid)
                    Spacer()
                    Image(systemName: showOrderDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.goldMid)
                }
                .padding(Spacing.md)
                .background(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: showOrderDetails ? 0 : Radius.md)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: showOrderDetails ? 0 : Radius.md))
            }

            // Expanded items list
            if showOrderDetails {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.borderSubtle)
                        .frame(height: 0.5)

                    ForEach(order.items) { item in
                        HStack(spacing: Spacing.sm) {
                            Text("×\(item.quantity)")
                                .font(BJFont.outfit(12, weight: .bold))
                                .foregroundColor(Color.textTertiary)
                                .frame(width: 24)

                            Text(item.productName)
                                .font(BJFont.sora(13, weight: .regular))
                                .foregroundColor(Color.textSecondary)
                                .lineLimit(2)

                            Spacer()

                            Text(item.lineTotal.formatted(.currency(code: "USD")))
                                .font(BJFont.outfit(13, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)

                        if item.id != order.items.last?.id {
                            Rectangle()
                                .fill(Color.borderSubtle)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .background(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.borderGold.opacity(showOrderDetails ? 0 : 0), lineWidth: 0)
        )
    }
}

// MARK: - StatusBadge

private struct StatusBadge: View {
    let status: String

    private var badgeColor: Color {
        switch status.lowercased() {
        case "confirmed", "processing":  return Color.success
        case "shipped":                  return Color.info
        case "delivered":                return Color.gold
        case "cancelled":                return Color.error
        default:                         return Color.textTertiary
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)
            Text(status.capitalized)
                .font(BJFont.sora(11, weight: .semibold))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.1))
        .overlay(Capsule().stroke(badgeColor.opacity(0.3), lineWidth: 0.8))
        .clipShape(Capsule())
    }
}

// MARK: - ConfirmationSummaryRow

private struct ConfirmationSummaryRow: View {
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
    let sampleOrder = Order(
        id: 10042,
        status: "confirmed",
        items: [
            CartItem(
                id: 1, productId: 1,
                productName: "Arctic Frost Nicotine Pouches",
                imageUrl: nil, quantity: 2,
                unitPrice: 14.99, lineTotal: 29.98
            ),
            CartItem(
                id: 2, productId: 3,
                productName: "Maduro Reserve Cigar",
                imageUrl: nil, quantity: 1,
                unitPrice: 24.99, lineTotal: 24.99
            )
        ],
        shippingAddress: ShippingAddress(
            firstName: "James", lastName: "Monroe",
            line1: "1600 Pennsylvania Ave NW", line2: nil,
            city: "Washington", state: "DC", zip: "20500", country: "US"
        ),
        subtotal: 54.97,
        taxAmount: 4.95,
        total: 59.92,
        ageVerificationId: "agv_abc123",
        createdAt: "2026-02-25T14:30:00Z",
        trackingNumber: "1Z999AA10123456784"
    )
    return NavigationStack {
        OrderConfirmationView(order: sampleOrder, cartVM: CartViewModel())
    }
}
