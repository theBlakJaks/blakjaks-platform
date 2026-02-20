import SwiftUI

// MARK: - OrderHistoryView
// Displays the user's order history. Tapping a row shows an order detail sheet.

struct OrderHistoryView: View {
    @StateObject private var profileVM = ProfileViewModel()
    @State private var selectedOrder: Order? = nil

    var body: some View {
        Group {
            if profileVM.isLoadingOrders {
                ProgressView("Loading orders…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundPrimary)
            } else if profileVM.orders.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: "No Orders Yet",
                    subtitle: "Your orders will appear here after your first purchase."
                )
                .background(Color.backgroundPrimary)
            } else {
                List(profileVM.orders) { order in
                    Button {
                        selectedOrder = order
                    } label: {
                        orderRow(order: order)
                    }
                    .listRowBackground(Color.backgroundSecondary)
                    .listRowSeparatorTint(Color(.separator).opacity(0.4))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.backgroundPrimary)
            }
        }
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await profileVM.loadOrders() }
        .sheet(item: $selectedOrder) { order in
            OrderDetailView(order: order)
        }
    }

    // MARK: - Order Row

    private func orderRow(order: Order) -> some View {
        HStack(spacing: Spacing.md) {
            // Order icon
            Image(systemName: "shippingbox")
                .font(.system(size: 22))
                .foregroundColor(.gold)
                .frame(width: 36)

            // Order info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Order #\(order.id)")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(formatOrderDate(order.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)

                orderStatusCapsule(status: order.status)
            }

            Spacer()

            // Total
            Text(order.total.formatted(.currency(code: "USD")))
                .font(.body.weight(.bold))
                .foregroundColor(.gold)
                .fontDesign(.monospaced)
        }
        .padding(.vertical, Spacing.xs)
    }

    private func orderStatusCapsule(status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status.lowercased() {
            case "processing":  return ("Processing", .warning)
            case "shipped":     return ("Shipped", .info)
            case "delivered":   return ("Delivered", .success)
            case "cancelled":   return ("Cancelled", .failure)
            default:            return (status.capitalized, .secondary)
            }
        }()

        return Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(color)
            .cornerRadius(6)
    }

    // MARK: - Helpers

    private func formatOrderDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: isoString) {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .none
            return fmt.string(from: date)
        }
        return isoString
    }
}

// MARK: - OrderDetailView

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // Status header
                    GoldAccentCard {
                        VStack(spacing: Spacing.sm) {
                            Text("Order #\(order.id)")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack {
                                Text(formatDate(order.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                statusLabel(order.status)
                            }

                            if let tracking = order.trackingNumber {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "shippingbox")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Tracking: \(tracking)")
                                        .font(.caption.monospaced())
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // Items
                    BlakJaksCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Items")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(order.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.productName)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text("Qty: \(item.quantity) × \(item.unitPrice.formatted(.currency(code: "USD")))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(item.lineTotal.formatted(.currency(code: "USD")))
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }

                    // Totals
                    BlakJaksCard {
                        VStack(spacing: Spacing.sm) {
                            totalRow(label: "Subtotal", value: order.subtotal.formatted(.currency(code: "USD")))
                            totalRow(label: "Tax", value: order.taxAmount.formatted(.currency(code: "USD")))
                            Divider()
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(order.total.formatted(.currency(code: "USD")))
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.gold)
                            }
                        }
                    }

                    // Shipping address
                    BlakJaksCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Shipping Address")
                                .font(.headline)
                                .foregroundColor(.primary)

                            let addr = order.shippingAddress
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(addr.firstName) \(addr.lastName)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(addr.line1)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                if let line2 = addr.line2, !line2.isEmpty {
                                    Text(line2)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                Text("\(addr.city), \(addr.state) \(addr.zip)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text(addr.country)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, Layout.screenMargin)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Order Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Helpers

    private func totalRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    private func statusLabel(_ status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status.lowercased() {
            case "processing":  return ("Processing", .warning)
            case "shipped":     return ("Shipped", .info)
            case "delivered":   return ("Delivered", .success)
            case "cancelled":   return ("Cancelled", .failure)
            default:            return (status.capitalized, .secondary)
            }
        }()

        return Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(color)
            .cornerRadius(6)
    }

    private func formatDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: isoString) {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            return fmt.string(from: date)
        }
        return isoString
    }
}

// MARK: - Preview

#Preview("Order History") {
    NavigationStack {
        OrderHistoryView()
    }
}

#Preview("Order Detail") {
    OrderDetailView(order: MockProducts.order)
}
