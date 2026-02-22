import SwiftUI

// MARK: - SystemsView
// Comp budget health, payout pipeline, scan velocity, node status, tier distribution.

struct SystemsView: View {
    @StateObject private var viewModel = InsightsViewModel(apiClient: MockAPIClient())

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.systems == nil {
                    LoadingView()
                } else if let systems = viewModel.systems {
                    content(systems: systems)
                } else {
                    EmptyStateView(icon: "cpu", title: "No Systems Data", subtitle: "Pull to refresh.", actionTitle: "Retry") {
                        Task { await viewModel.loadSystems() }
                    }
                }
            }
        }
        .navigationTitle("Systems")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadSystems() }
        .refreshable { await viewModel.refresh() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: { Text(viewModel.error?.localizedDescription ?? "") }
    }

    private func content(systems: InsightsSystems) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Comp budget health
                GoldAccentCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill").foregroundColor(.gold)
                            Text("Comp Budget Health").font(.headline)
                            Spacer()
                            Text("\(Int(systems.compBudgetHealth.percentUsed))% used")
                                .font(.caption.weight(.bold))
                                .foregroundColor(budgetColor(pct: systems.compBudgetHealth.percentUsed))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.backgroundTertiary).frame(height: 10)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(budgetColor(pct: systems.compBudgetHealth.percentUsed))
                                    .frame(width: geo.size.width * CGFloat(systems.compBudgetHealth.percentUsed / 100), height: 10)
                            }
                        }
                        .frame(height: 10)
                        HStack {
                            Text("$\(systems.compBudgetHealth.usedBudget.formatted(.number.precision(.fractionLength(0)))) used")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("$\(systems.compBudgetHealth.remainingBudget.formatted(.number.precision(.fractionLength(0)))) remaining")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                // Pipeline + scan velocity
                HStack(spacing: Spacing.sm) {
                    BlakJaksCard {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title3).foregroundColor(.info)
                            Text("\(systems.payoutPipelineSuccessRate.formatted(.number.precision(.fractionLength(1))))%")
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundColor(.gold)
                            Text("Pipeline Success")
                                .font(.caption2).foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Text("\(systems.payoutPipelineQueueDepth) queued")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                    }
                    BlakJaksCard {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title3).foregroundColor(.gold)
                            Text("\(systems.scanVelocity.perMinute.formatted(.number.precision(.fractionLength(1))))/min")
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundColor(.gold)
                            Text("Scan Velocity")
                                .font(.caption2).foregroundColor(.secondary)
                            Text("\(systems.scanVelocity.perHour.formatted(.number.precision(.fractionLength(0))))/hr")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                    }
                }

                // Node status
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "network").font(.footnote).foregroundColor(.gold)
                            Text("Infrastructure").font(.headline)
                        }
                        systemRow(
                            label: "Polygon Node",
                            value: systems.polygonNodeStatus.provider,
                            status: systems.polygonNodeStatus.connected ? "Connected" : "Offline",
                            ok: systems.polygonNodeStatus.connected
                        )
                        if let block = systems.polygonNodeStatus.blockNumber {
                            systemRow(label: "Block Height", value: block.formatted(.number), status: nil, ok: true)
                        }
                        Divider()
                        systemRow(
                            label: "Teller Bank Sync",
                            value: systems.tellerLastSync.relativeTimeString,
                            status: "Synced",
                            ok: true
                        )
                    }
                }

                // Tier distribution
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "person.3.fill").font(.footnote).foregroundColor(.gold)
                            Text("Tier Distribution").font(.headline)
                        }
                        let tiers: [(String, Color)] = [
                            ("Standard", .tierStandard),
                            ("VIP", .tierVIP),
                            ("High Roller", .tierHighRoller),
                            ("Whale", .tierWhale)
                        ]
                        let total = systems.tierDistribution.values.reduce(0, +)
                        ForEach(tiers, id: \.0) { tierName, tierColor in
                            if let count = systems.tierDistribution[tierName] {
                                tierDistributionRow(name: tierName, count: count, total: total, color: tierColor)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
    }

    private func systemRow(label: String, value: String, status: String?, ok: Bool) -> some View {
        HStack {
            if status != nil {
                Circle()
                    .fill(ok ? Color.success : Color.failure)
                    .frame(width: 8, height: 8)
            }
            Text(label).font(.footnote).foregroundColor(.secondary)
            Spacer()
            if let status {
                Text(status)
                    .font(.caption.weight(.bold))
                    .foregroundColor(ok ? .success : .error)
            }
            Text(value)
                .font(.system(.footnote, design: .monospaced).weight(.medium))
                .foregroundColor(.primary)
        }
    }

    private func tierDistributionRow(name: String, count: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.footnote.weight(.medium))
                Spacer()
                Text("\(count.formatted(.number)) (\(total > 0 ? Int(Double(count) / Double(total) * 100) : 0)%)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.backgroundTertiary).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: total > 0 ? geo.size.width * CGFloat(count) / CGFloat(total) : 0, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private func budgetColor(pct: Double) -> Color {
        if pct < 50 { return .success }
        if pct < 75 { return .warning }
        return .error
    }
}

#Preview { NavigationStack { SystemsView() } }
