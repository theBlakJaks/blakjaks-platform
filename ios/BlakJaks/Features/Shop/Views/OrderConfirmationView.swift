import SwiftUI

// MARK: - OrderConfirmationView
// Post-checkout confirmation: order number, summary, estimated delivery, CTA buttons.

struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Spacer(minLength: Spacing.xxl)

                // Success animation
                successHeader

                // Order number card
                GoldAccentCard {
                    VStack(spacing: Spacing.sm) {
                        Text("Order #\(order.id)")
                            .font(.title2.weight(.bold))
                        Text("Placed \(formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        statusCapsule(order.status)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Layout.screenMargin)

                // Shipping address
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        rowHeader("Ships To", icon: "shippingbox")
                        Text("\(order.shippingAddress.firstName) \(order.shippingAddress.lastName)")
                            .font(.footnote.weight(.medium))
                        Text(order.shippingAddress.line1)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if let line2 = order.shippingAddress.line2 {
                            Text(line2)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Text("\(order.shippingAddress.city), \(order.shippingAddress.state) \(order.shippingAddress.zip)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if let tracking = order.trackingNumber {
                            Divider()
                            HStack {
                                Image(systemName: "location.circle")
                                    .font(.caption)
                                    .foregroundColor(.gold)
                                Text("Tracking: \(tracking)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Tracking number will be emailed once shipped.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, Layout.screenMargin)

                // Items
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        rowHeader("Items", icon: "bag")
                        ForEach(order.items) { item in
                            HStack {
                                Text(item.productName)
                                    .font(.footnote)
                                    .lineLimit(1)
                                Spacer()
                                Text("×\(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(item.lineTotal.formatted(.number.precision(.fractionLength(2))))")
                                    .font(.system(.footnote, design: .monospaced))
                            }
                        }
                    }
                }
                .padding(.horizontal, Layout.screenMargin)

                // Order totals
                BlakJaksCard {
                    VStack(spacing: Spacing.sm) {
                        totalRow("Subtotal", order.subtotal)
                        totalRow("Tax", order.taxAmount)
                        let shipping = order.total - order.subtotal - order.taxAmount
                        if shipping > 0 {
                            totalRow("Shipping", shipping)
                        } else {
                            HStack {
                                Text("Shipping").font(.footnote).foregroundColor(.secondary)
                                Spacer()
                                Text("FREE")
                                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                                    .foregroundColor(.success)
                            }
                        }
                        Divider()
                        totalRow("Total", order.total, isBold: true)
                    }
                }
                .padding(.horizontal, Layout.screenMargin)

                // CTA buttons
                VStack(spacing: Spacing.sm) {
                    if order.trackingNumber != nil {
                        Button {
                            // Track order — deep link in production polish pass
                        } label: {
                            Label("Track Order", systemImage: "location.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(Color.gold)
                                .foregroundColor(.black)
                                .cornerRadius(Layout.cardCornerRadius)
                        }
                    }

                    Button {
                        // Pop to shop root — parent NavigationStack handles this
                        dismiss()
                    } label: {
                        Text("Continue Shopping")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.backgroundSecondary)
                            .foregroundColor(.primary)
                            .cornerRadius(Layout.cardCornerRadius)
                    }
                }
                .padding(.horizontal, Layout.screenMargin)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.backgroundPrimary)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Order Confirmed")
                    .font(.headline)
            }
        }
    }

    // MARK: - Success header

    private var successHeader: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.success.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.success)
            }
            Text("Order Confirmed!")
                .font(.title2.weight(.bold))
            Text("Thank you for your order. You'll receive a confirmation email shortly.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: order.createdAt) else { return order.createdAt }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    private func statusCapsule(_ status: String) -> some View {
        Text(status.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.warning)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.warning.opacity(0.15)))
    }

    private func rowHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.gold)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private func totalRow(_ label: String, _ value: Double, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .footnote.weight(.bold) : .footnote)
                .foregroundColor(isBold ? .primary : .secondary)
            Spacer()
            Text("$\(value.formatted(.number.precision(.fractionLength(2))))")
                .font(.system(.footnote, design: .monospaced).weight(isBold ? .bold : .regular))
                .foregroundColor(isBold ? .gold : .primary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrderConfirmationView(order: MockProducts.order)
    }
}
