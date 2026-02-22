import SwiftUI

// MARK: - OverviewView
// Global scan counter, vitals strip, live feed, milestone progress bars.

struct OverviewView: View {
    @StateObject private var viewModel = InsightsViewModel(apiClient: MockAPIClient())

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.overview == nil {
                    LoadingView()
                } else if let overview = viewModel.overview {
                    content(overview: overview)
                } else {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No Overview Data",
                        subtitle: "Pull to refresh.",
                        actionTitle: "Retry"
                    ) { Task { await viewModel.loadOverview() } }
                }
            }
        }
        .navigationTitle("Overview")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadOverview() }
        .refreshable { await viewModel.refresh() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Content

    private func content(overview: InsightsOverview) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Hero scan counter
                GoldAccentCard {
                    VStack(spacing: Spacing.sm) {
                        Text("Total Scans")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(overview.globalScanCount.formatted(.number))
                            .font(.walletBalance)
                            .foregroundColor(.gold)
                        Text("\(overview.activeMembers.formatted(.number)) active members")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }

                // Vitals row
                HStack(spacing: Spacing.sm) {
                    vitalCard(
                        icon: "arrow.up.circle.fill",
                        label: "24h Payouts",
                        value: "$\(overview.payoutsLast24h.formatted(.number.precision(.fractionLength(2))))",
                        color: .success
                    )
                    vitalCard(
                        icon: "person.badge.plus",
                        label: "Members",
                        value: overview.activeMembers.formatted(.number),
                        color: .gold
                    )
                }

                // Milestones
                if !overview.milestoneProgress.isEmpty {
                    BlakJaksCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Milestones")
                                .font(.headline)
                                .foregroundColor(.primary)
                            ForEach(overview.milestoneProgress) { milestone in
                                milestoneRow(milestone)
                            }
                        }
                    }
                }

                // Live feed
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Live Feed")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.success)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.success)
                            }
                        }
                        ForEach(overview.liveFeed) { item in
                            feedRow(item)
                            if item.id != overview.liveFeed.last?.id {
                                Divider()
                            }
                        }
                        if overview.liveFeed.isEmpty {
                            Text("No recent activity")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Sub-views

    private func vitalCard(icon: String, label: String, value: String, color: Color) -> some View {
        BlakJaksCard {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon).font(.title3).foregroundColor(color)
                Text(value)
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .foregroundColor(.gold)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(label).font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
    }

    private func milestoneRow(_ milestone: MilestoneProgress) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(milestone.label).font(.footnote.weight(.medium))
                Spacer()
                Text("\(Int(milestone.percentage))%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.backgroundTertiary).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gold)
                        .frame(width: geo.size.width * CGFloat(min(milestone.percentage / 100, 1)), height: 6)
                }
            }
            .frame(height: 6)
            HStack {
                Text(milestone.current.formatted(.number.precision(.fractionLength(0)))).font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text(milestone.target.formatted(.number.precision(.fractionLength(0)))).font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private func feedRow(_ item: ActivityFeedItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            feedIcon(for: item.type).font(.body).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.description).font(.footnote).foregroundColor(.primary)
                Text(item.createdAt.relativeTimeString).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            if let amount = item.amount {
                Text("+$\(amount.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundColor(.success)
            }
        }
        .padding(.vertical, 2)
    }

    private func feedIcon(for type: String) -> some View {
        switch type {
        case "comp_earned":  return Image(systemName: "gift.fill").foregroundColor(.gold)
        case "tier_upgrade": return Image(systemName: "arrow.up.circle.fill").foregroundColor(.success)
        case "new_member":   return Image(systemName: "person.badge.plus").foregroundColor(.info)
        case "payout":       return Image(systemName: "dollarsign.circle.fill").foregroundColor(.success)
        default:             return Image(systemName: "circle.fill").foregroundColor(.secondary)
        }
    }
}

// MARK: - String relative time

extension String {
    var relativeTimeString: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: self) ?? ISO8601DateFormatter().date(from: self) else { return self }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { OverviewView() }
}
