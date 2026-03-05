import SwiftUI

// MARK: - SystemsView
// Displays InsightsSystems: comp budget health, payout pipeline,
// scan velocity, Polygon node status, tier distribution bar chart.

struct SystemsView: View {
    @EnvironmentObject private var vm: InsightsViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoadingSystems && vm.systems == nil {
                InsightsLoadingView()
            } else if let error = vm.errorMessage, vm.systems == nil {
                InsightsErrorView(message: error) { Task { await vm.loadSystems() } }
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .disableSwipeBack()
        .toolbar { toolbarContent }
        .task { await vm.loadSystems() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("SYSTEMS")
                    .font(BJFont.playfair(18, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .tracking(1)
                Text("INFRASTRUCTURE HEALTH")
                    .font(BJFont.eyebrow)
                    .foregroundColor(Color.goldMid)
                    .tracking(2)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                if let systems = vm.systems {
                    compBudgetSection(systems: systems)
                    payoutPipelineSection(systems: systems)
                    scanVelocitySection(systems: systems)
                    polygonNodeSection(systems: systems)
                    tierDistributionSection(systems: systems)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .refreshable { await vm.loadSystems() }
    }

    // MARK: - Comp Budget Health

    @ViewBuilder
    private func compBudgetSection(systems: InsightsSystems) -> some View {
        let budget = systems.compBudgetHealth

        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "ALLOCATION", title: "Comp Budget Health")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    // Used / Total
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Used")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Text(budget.usedBudget.compactUSDFormatted)
                                .font(BJFont.stat)
                                .foregroundColor(Color.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Total Budget")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Text(budget.totalBudget.compactUSDFormatted)
                                .font(BJFont.stat)
                                .foregroundColor(Color.textPrimary)
                        }
                    }

                    // Progress bar
                    BudgetProgressBar(percent: budget.percentUsed)

                    // Remaining
                    HStack {
                        Label {
                            Text(budget.remainingBudget.compactUSDFormatted + " remaining")
                                .font(BJFont.sora(12, weight: .medium))
                                .foregroundColor(remainingColor(budget.percentUsed))
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(remainingColor(budget.percentUsed))
                                .font(.system(size: 12))
                        }
                        Spacer()
                        Text(budget.percentUsed.percentFormatted + " used")
                            .font(BJFont.outfit(12, weight: .semibold))
                            .foregroundColor(remainingColor(budget.percentUsed))
                    }

                    // Projected exhaustion
                    if let exhaustion = budget.projectedExhaustionDate {
                        Divider().background(Color.borderSubtle)
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 12))
                                .foregroundColor(Color.warning)
                            Text("Projected exhaustion")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Spacer()
                            Text(formatDate(exhaustion))
                                .font(BJFont.sora(12, weight: .semibold))
                                .foregroundColor(Color.warning)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Payout Pipeline

    @ViewBuilder
    private func payoutPipelineSection(systems: InsightsSystems) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "PIPELINE", title: "Payout Pipeline")

            HStack(spacing: Spacing.sm) {
                // Queue depth
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.goldMid)
                        Text("\(systems.payoutPipelineQueueDepth)")
                            .font(BJFont.stat)
                            .foregroundColor(Color.textPrimary)
                        Text("Queue Depth")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }

                // Success rate
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(successRateColor(systems.payoutPipelineSuccessRate))
                        Text(systems.payoutPipelineSuccessRate.percentFormatted)
                            .font(BJFont.stat)
                            .foregroundColor(successRateColor(systems.payoutPipelineSuccessRate))
                        Text("Success Rate")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Scan Velocity

    @ViewBuilder
    private func scanVelocitySection(systems: InsightsSystems) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "ACTIVITY", title: "Scan Velocity")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    HStack(spacing: 0) {
                        VelocityStat(
                            value: formatDecimal(systems.scanVelocity.perMinute),
                            label: "Per Minute",
                            icon: "bolt.fill",
                            color: Color.goldMid
                        )
                        Divider()
                            .frame(height: 44)
                            .background(Color.borderSubtle)
                            .padding(.horizontal, Spacing.md)
                        VelocityStat(
                            value: formatDecimal(systems.scanVelocity.perHour),
                            label: "Per Hour",
                            icon: "clock.fill",
                            color: Color.textSecondary
                        )
                    }

                    // Mini sparkline
                    if !systems.scanVelocity.last60Min.isEmpty {
                        MiniSparkline(points: systems.scanVelocity.last60Min)
                            .frame(height: 40)
                    }

                    Text("Last 60 minutes")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Polygon Node Status

    @ViewBuilder
    private func polygonNodeSection(systems: InsightsSystems) -> some View {
        let node = systems.polygonNodeStatus

        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "BLOCKCHAIN", title: "Polygon Node")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    HStack {
                        // Connection indicator
                        HStack(spacing: 8) {
                            PulsingDot(isActive: node.connected)
                            Text(node.connected ? "Connected" : "Disconnected")
                                .font(BJFont.sora(14, weight: .semibold))
                                .foregroundColor(node.connected ? Color.success : Color.error)
                        }
                        Spacer()
                        // Provider badge
                        Text(node.provider)
                            .font(BJFont.micro)
                            .foregroundColor(Color.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    }

                    if let blockNumber = node.blockNumber {
                        Divider().background(Color.borderSubtle)
                        HStack {
                            Text("Block Number")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Spacer()
                            Text(formatBlockNumber(blockNumber))
                                .font(BJFont.outfit(13, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                        }
                    }

                    if node.syncing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .tint(Color.warning)
                                .scaleEffect(0.7)
                            Text("Node is syncing...")
                                .font(BJFont.caption)
                                .foregroundColor(Color.warning)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tier Distribution

    @ViewBuilder
    private func tierDistributionSection(systems: InsightsSystems) -> some View {
        guard !systems.tierDistribution.isEmpty else { return AnyView(EmptyView()) }

        let sorted = systems.tierDistribution.sorted { $0.value > $1.value }
        let total = sorted.reduce(0) { $0 + $1.value }

        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "MEMBERSHIP", title: "Tier Distribution")

                BlakJaksCard {
                    VStack(spacing: Spacing.md) {
                        // Horizontal stacked bar
                        if total > 0 {
                            StackedTierBar(tiers: sorted, total: total)
                                .frame(height: 12)
                        }

                        // Legend
                        VStack(spacing: Spacing.xs) {
                            ForEach(sorted, id: \.key) { tier, count in
                                HStack {
                                    Circle()
                                        .fill(tierColor(tier))
                                        .frame(width: 8, height: 8)
                                    Text(tier.capitalized)
                                        .font(BJFont.sora(13, weight: .medium))
                                        .foregroundColor(Color.textPrimary)
                                    Spacer()
                                    Text("\(count)")
                                        .font(BJFont.outfit(13, weight: .semibold))
                                        .foregroundColor(Color.textSecondary)
                                    if total > 0 {
                                        Text("(\(Int((Double(count) / Double(total)) * 100))%)")
                                            .font(BJFont.micro)
                                            .foregroundColor(Color.textTertiary)
                                            .frame(width: 42, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    // MARK: - Helpers

    private func remainingColor(_ pct: Double) -> Color {
        if pct >= 90 { return Color.error }
        if pct >= 70 { return Color.warning }
        return Color.success
    }

    private func successRateColor(_ rate: Double) -> Color {
        if rate >= 95 { return Color.success }
        if rate >= 80 { return Color.warning }
        return Color.error
    }

    private func formatDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func formatBlockNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func formatDate(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: iso) {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            return f.string(from: date)
        }
        return iso
    }

    private func tierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "whale":       return Color.gold
        case "high_roller", "highroller", "high roller": return Color.purple
        case "vip":         return Color.blue
        default:            return Color(UIColor.systemGray)
        }
    }
}

// MARK: - BudgetProgressBar

private struct BudgetProgressBar: View {
    let percent: Double

    var fillColor: Color {
        if percent >= 90 { return Color.error }
        if percent >= 70 { return Color.warning }
        return Color.success
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Radius.pill)
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: Radius.pill)
                    .fill(
                        LinearGradient(
                            colors: [fillColor.opacity(0.8), fillColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(percent / 100.0, 1.0)), height: 8)
                    .animation(.easeOut(duration: 0.5), value: percent)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - VelocityStat

private struct VelocityStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(value)
                .font(BJFont.stat)
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MiniSparkline

private struct MiniSparkline: View {
    let points: [SparklinePoint]

    var body: some View {
        GeometryReader { geo in
            let values = points.map { $0.value }
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let range = max(maxVal - minVal, 1)

            Path { path in
                guard points.count > 1 else { return }
                let w = geo.size.width
                let h = geo.size.height
                let step = w / CGFloat(points.count - 1)

                for (index, point) in points.enumerated() {
                    let x = CGFloat(index) * step
                    let normalised = CGFloat((point.value - minVal) / range)
                    let y = h - (normalised * h)
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.goldMid.opacity(0.6), Color.gold],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - PulsingDot

private struct PulsingDot: View {
    let isActive: Bool
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.success.opacity(0.3) : Color.error.opacity(0.3))
                .frame(width: 16, height: 16)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .opacity(pulsing ? 0 : 1)
                .animation(
                    isActive ? .easeOut(duration: 1.2).repeatForever(autoreverses: false) : .default,
                    value: pulsing
                )
            Circle()
                .fill(isActive ? Color.success : Color.error)
                .frame(width: 9, height: 9)
        }
        .onAppear { if isActive { pulsing = true } }
    }
}

// MARK: - StackedTierBar

private struct StackedTierBar: View {
    let tiers: [(key: String, value: Int)]
    let total: Int

    private let tierColors: [String: Color] = [
        "whale":       Color.gold,
        "high_roller": Color.purple,
        "highroller":  Color.purple,
        "high roller": Color.purple,
        "vip":         Color.blue,
        "standard":    Color(UIColor.systemGray)
    ]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(tiers, id: \.key) { tier, count in
                    let fraction = CGFloat(count) / CGFloat(max(total, 1))
                    let color = tierColors[tier.lowercased()] ?? Color.textTertiary
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(geo.size.width * fraction - 2, 4))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SystemsView()
            .environmentObject(InsightsViewModel())
    }
    .preferredColorScheme(.dark)
}
