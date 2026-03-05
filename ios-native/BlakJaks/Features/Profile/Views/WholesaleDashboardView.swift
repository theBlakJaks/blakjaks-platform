import SwiftUI

// MARK: - WholesaleDashboardView

struct WholesaleDashboardView: View {

    @StateObject private var vm = WholesaleViewModel()
    @State private var showOrderForm = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoading && vm.dashboard == nil {
                LoadingView(message: "Loading wholesale data...")
            } else if let dashboard = vm.dashboard {
                mainContent(dashboard: dashboard)
            } else if let error = vm.errorMessage {
                InsightsErrorView(message: error) {
                    Task { await vm.loadAll() }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("WHOLESALE")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.gold)
            }
        }
        .disableSwipeBack()
        .task {
            await vm.loadAll()
        }
        .sheet(isPresented: $showOrderForm) {
            WholesaleOrderFormSheet(vm: vm, isPresented: $showOrderForm)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(dashboard: WholesaleDashboard) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                businessHeader(dashboard: dashboard)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)

                statsGrid(dashboard: dashboard)
                    .padding(.horizontal, Spacing.md)

                GoldButton(title: "Place New Order") {
                    showOrderForm = true
                }
                .padding(.horizontal, Spacing.md)

                ordersSection
                    .padding(.horizontal, Spacing.md)

                Spacer(minLength: Spacing.xxxl)
            }
        }
        .refreshable { await vm.loadAll() }
    }

    // MARK: - Business Header

    private func businessHeader(dashboard: WholesaleDashboard) -> some View {
        BlakJaksCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(LinearGradient.goldShimmer.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.goldMid)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(dashboard.businessName)
                        .font(BJFont.playfair(20, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    statusBadge(dashboard.status)
                }

                Spacer()
            }
        }
    }

    // MARK: - Stats Grid

    private func statsGrid(dashboard: WholesaleDashboard) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                wholesaleStat(
                    icon: "chart.bar.fill",
                    value: dashboard.totalOrderValue.usdFormatted,
                    label: "Total Orders",
                    color: Color.goldMid
                )
                wholesaleStat(
                    icon: "hexagon.fill",
                    value: "\(dashboard.totalChipsEarned)",
                    label: "Chips Earned",
                    color: Color.gold
                )
            }
            HStack(spacing: Spacing.sm) {
                wholesaleStat(
                    icon: "hexagon.fill",
                    value: "\(dashboard.chipBalance)",
                    label: "Chip Balance",
                    color: Color.goldMid
                )
                wholesaleStat(
                    icon: "clock.badge.exclamationmark.fill",
                    value: "\(dashboard.pendingOrders)",
                    label: "Pending Orders",
                    color: dashboard.pendingOrders > 0 ? Color.warning : Color.textTertiary
                )
            }
        }
    }

    private func wholesaleStat(icon: String, value: String, label: String, color: Color) -> some View {
        BlakJaksCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(value)
                    .font(BJFont.outfit(20, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Orders Section

    private var ordersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(eyebrow: "HISTORY", title: "Orders")

            if vm.orders.isEmpty {
                EmptyStateView(
                    icon: "📦",
                    title: "No Orders Yet",
                    subtitle: "Your wholesale orders will appear here."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.orders) { order in
                        WholesaleOrderRow(order: order)

                        if order.id != vm.orders.last?.id {
                            Divider()
                                .background(Color.borderSubtle)
                                .padding(.leading, Spacing.md)
                        }
                    }
                }
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.borderGold, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            }
        }
    }

    // MARK: - Status Badge

    private func statusBadge(_ status: String) -> some View {
        let color: Color = {
            switch status.lowercased() {
            case "active", "approved": return Color.success
            case "pending":            return Color.warning
            case "suspended":          return Color.error
            default:                   return Color.textTertiary
            }
        }()

        return Text(status.uppercased())
            .font(BJFont.micro)
            .tracking(1.5)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
            .clipShape(Capsule())
    }
}

// MARK: - WholesaleOrderRow

private struct WholesaleOrderRow: View {
    let order: WholesaleOrder

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Order icon
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.bgPrimary)
                    .frame(width: 40, height: 40)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.goldMid)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.xs) {
                    Text("Order #\(order.id)")
                        .font(BJFont.sora(13, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    orderStatusBadge(order.status)
                }
                Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                    .font(BJFont.caption)
                    .foregroundColor(Color.textTertiary)
                Text(formattedDate(order.createdAt))
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }

            Spacer()

            // Total + chips
            VStack(alignment: .trailing, spacing: 3) {
                Text(order.totalAmount.usdFormatted)
                    .font(BJFont.outfit(14, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                HStack(spacing: 3) {
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.goldMid)
                    Text("+\(order.chipsEarned)")
                        .font(BJFont.micro)
                        .foregroundColor(Color.goldMid)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func orderStatusBadge(_ status: String) -> some View {
        let color: Color = {
            switch status.lowercased() {
            case "completed", "delivered": return Color.success
            case "pending", "processing": return Color.warning
            case "cancelled":              return Color.error
            default:                       return Color.textTertiary
            }
        }()

        return Text(status.uppercased())
            .font(BJFont.micro)
            .tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private func formattedDate(_ iso: String) -> String {
        let fmts = [
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }()
        ]
        for fmt in fmts {
            if let date = fmt.date(from: iso) {
                let d = DateFormatter(); d.dateFormat = "MMM d, yyyy"
                return d.string(from: date)
            }
        }
        return iso
    }
}

// MARK: - WholesaleOrderFormSheet

private struct WholesaleOrderFormSheet: View {

    @ObservedObject var vm: WholesaleViewModel
    @Binding var isPresented: Bool

    @State private var orderItems: [OrderLineItem] = [OrderLineItem()]
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    struct OrderLineItem: Identifiable {
        let id = UUID()
        var productName: String = ""
        var quantity: String = ""
        var unitPrice: String = ""
        var productId: Int = 0
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.borderGold)
                    .frame(width: 40, height: 3)
                    .padding(.top, Spacing.sm)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        Text("New Wholesale Order")
                            .font(BJFont.playfair(22, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                            .padding(.top, Spacing.md)

                        // Line items
                        VStack(spacing: Spacing.sm) {
                            Text("ORDER ITEMS")
                                .font(BJFont.eyebrow)
                                .tracking(3)
                                .foregroundColor(Color.goldMid)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(Array(orderItems.enumerated()), id: \.element.id) { index, _ in
                                OrderLineItemRow(item: $orderItems[index]) {
                                    if orderItems.count > 1 {
                                        orderItems.remove(at: index)
                                    }
                                }
                            }

                            Button {
                                orderItems.append(OrderLineItem())
                            } label: {
                                Label("Add Item", systemImage: "plus.circle.fill")
                                    .font(BJFont.sora(13, weight: .semibold))
                                    .foregroundColor(Color.goldMid)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                    .background(Color.bgCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Radius.md)
                                            .stroke(Color.borderGold, style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            }
                        }

                        // Order total preview
                        let total = orderItems.compactMap { item -> Double? in
                            guard let q = Double(item.quantity), let p = Double(item.unitPrice) else { return nil }
                            return q * p
                        }.reduce(0, +)

                        if total > 0 {
                            HStack {
                                Text("Estimated Total")
                                    .font(BJFont.sora(14, weight: .semibold))
                                    .foregroundColor(Color.textSecondary)
                                Spacer()
                                Text(total.usdFormatted)
                                    .font(BJFont.outfit(18, weight: .bold))
                                    .foregroundColor(Color.gold)
                            }
                            .padding(Spacing.md)
                            .background(Color.bgCard)
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.borderGold, lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(BJFont.caption)
                                .foregroundColor(Color.error)
                                .multilineTextAlignment(.center)
                        }

                        GoldButton(
                            title: "Submit Order",
                            action: submitOrder,
                            isLoading: isSubmitting,
                            isDisabled: orderItems.allSatisfy { $0.productName.isEmpty }
                        )

                        GhostButton(title: "Cancel") {
                            isPresented = false
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
        }
    }

    private func submitOrder() {
        let items = orderItems.compactMap { item -> WholesaleOrderItem? in
            guard !item.productName.isEmpty,
                  let qty = Int(item.quantity), qty > 0,
                  let price = Double(item.unitPrice), price > 0
            else { return nil }
            return WholesaleOrderItem(
                productId: item.productId,
                productName: item.productName,
                quantity: qty,
                unitPrice: price
            )
        }
        guard !items.isEmpty else {
            errorMessage = "Please add at least one valid item."
            return
        }
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                _ = try await APIClient.shared.createWholesaleOrder(items: items)
                await vm.loadAll()
                isPresented = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - OrderLineItemRow

private struct OrderLineItemRow: View {
    @Binding var item: WholesaleOrderFormSheet.OrderLineItem
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                TextField("Product name", text: $item.productName)
                    .font(BJFont.body)
                    .foregroundColor(Color.textPrimary)
                    .tint(Color.goldMid)

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 48)
            .background(Color.bgInput)
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.borderSubtle, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            HStack(spacing: Spacing.xs) {
                HStack {
                    Text("Qty")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                    TextField("0", text: $item.quantity)
                        .font(BJFont.body)
                        .foregroundColor(Color.textPrimary)
                        .tint(Color.goldMid)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, Spacing.sm)
                .frame(height: 44)
                .background(Color.bgInput)
                .overlay(RoundedRectangle(cornerRadius: Radius.sm).stroke(Color.borderSubtle, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

                HStack {
                    Text("$")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                    TextField("0.00", text: $item.unitPrice)
                        .font(BJFont.body)
                        .foregroundColor(Color.textPrimary)
                        .tint(Color.goldMid)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, Spacing.sm)
                .frame(height: 44)
                .background(Color.bgInput)
                .overlay(RoundedRectangle(cornerRadius: Radius.sm).stroke(Color.borderSubtle, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .padding(Spacing.sm)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.borderSubtle, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

// MARK: - WholesaleViewModel

@MainActor
final class WholesaleViewModel: ObservableObject {
    @Published var dashboard: WholesaleDashboard?
    @Published var orders: [WholesaleOrder] = []
    @Published var chips: WholesaleChips?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let d = api.getWholesaleDashboard()
            async let o = api.getWholesaleOrders(limit: 25, offset: 0)
            async let c = api.getWholesaleChips()
            dashboard = try await d
            orders = (try? await o) ?? []
            chips = try? await c
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        WholesaleDashboardView()
    }
    .preferredColorScheme(.dark)
}
