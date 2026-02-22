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
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(profileVM.orders) { order in
                            Button {
                                selectedOrder = order
                            } label: {
                                orderRow(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
                .background(Color.backgroundPrimary)
            }
        }
        // "Orders" header in New York serif via large display mode + toolbar title view
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Orders")
                    .font(.system(.title, design: .serif))
                    .foregroundColor(.primary)
            }
        }
        .task { await profileVM.loadOrders() }
        .sheet(item: $selectedOrder) { order in
            OrderDetailView(order: order)
        }
    }

    // MARK: - Order Row

    private func orderRow(order: Order) -> some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Order number — footnote, secondary, monospaced
                        Text("Order #\(order.id)")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)

                        // Items summary — body, primary
                        Text(order.items.map { $0.productName }.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Total — headline, monospaced, gold
                    Text(order.total.formatted(.currency(code: "USD")))
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.gold)
                }

                HStack(spacing: Spacing.sm) {
                    // Date — caption, secondary
                    Text(formatOrderDate(order.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Status badge — colored pill
                    orderStatusCapsule(status: order.status)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func orderStatusCapsule(status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status.lowercased() {
            case "pending":     return ("Pending", .warning)
            case "processing":  return ("Processing", .warning)
            case "shipped":     return ("Shipped", .info)
            case "delivered",
                 "fulfilled":   return ("Fulfilled", .success)
            case "cancelled":   return ("Cancelled", .error)
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
            case "pending":     return ("Pending", .warning)
            case "processing":  return ("Processing", .warning)
            case "shipped":     return ("Shipped", .info)
            case "delivered",
                 "fulfilled":   return ("Fulfilled", .success)
            case "cancelled":   return ("Cancelled", .error)
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
