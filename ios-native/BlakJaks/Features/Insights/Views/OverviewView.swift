import SwiftUI

// MARK: - OverviewView
// Displays InsightsOverview: stat grid, milestone progress bars, activity feed.

struct OverviewView: View {
    @EnvironmentObject private var vm: InsightsViewModel

    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoadingOverview && vm.overview == nil {
                InsightsLoadingView()
            } else if let error = vm.errorMessage, vm.overview == nil {
                InsightsErrorView(message: error) { Task { await vm.loadOverview() } }
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .disableSwipeBack()
        .toolbar { toolbarContent }
        .task { await vm.loadOverview() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("OVERVIEW")
                    .font(BJFont.playfair(18, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .tracking(1)
                Text("CLUB INTELLIGENCE")
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
                if let overview = vm.overview {
                    statGrid(overview: overview)
                    milestonesSection(overview: overview)
                    activityFeedSection(overview: overview)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .refreshable { await vm.loadOverview() }
    }

    // MARK: - Stat Grid

    @ViewBuilder
    private func statGrid(overview: InsightsOverview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "AT A GLANCE", title: "Global Stats")

            LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
                StatCard(
                    icon: "qrcode.viewfinder",
                    label: "Global Scans",
                    value: formatCount(overview.globalScanCount),
                    accent: Color.goldMid
                )
                StatCard(
                    icon: "person.fill.checkmark",
                    label: "Active Members",
                    value: formatCount(overview.activeMembers),
                    accent: Color.goldMid
                )
                // 24h payouts spans full width
                StatCard(
                    icon: "dollarsign.circle.fill",
                    label: "24h Payouts",
                    value: overview.payoutsLast24h.usdFormatted,
                    accent: Color.success,
                    isWide: true
                )
            }
        }
    }

    // MARK: - Milestones Section

    @ViewBuilder
    private func milestonesSection(overview: InsightsOverview) -> some View {
        guard !overview.milestoneProgress.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "PROGRESS", title: "Milestones")

                BlakJaksCard {
                    VStack(spacing: Spacing.md) {
                        ForEach(Array(overview.milestoneProgress.enumerated()), id: \.element.id) { index, milestone in
                            if index > 0 {
                                Divider()
                                    .background(Color.borderSubtle)
                            }
                            MilestoneRow(milestone: milestone)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Activity Feed Section

    @ViewBuilder
    private func activityFeedSection(overview: InsightsOverview) -> some View {
        guard !overview.liveFeed.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "LIVE", title: "Activity Feed")

                BlakJaksCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(overview.liveFeed.prefix(20).enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                                    .background(Color.borderSubtle)
                                    .padding(.leading, 56)
                            }
                            FeedItemRow(item: item)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Helpers

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color
    var isWide: Bool = false

    var body: some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accent)
                    Spacer()
                }
                Text(value)
                    .font(isWide ? BJFont.price : BJFont.stat)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(BJFont.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .gridCellColumns(isWide ? 2 : 1)
    }
}

// MARK: - MilestoneRow

private struct MilestoneRow: View {
    let milestone: MilestoneProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(milestone.label)
                    .font(BJFont.sora(13, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text(milestone.percentage.percentFormatted)
                    .font(BJFont.outfit(13, weight: .semibold))
                    .foregroundColor(progressColor(milestone.percentage))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .fill(
                            LinearGradient(
                                colors: [Color.goldMid, Color.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(min(milestone.percentage / 100, 1.0)),
                            height: 6
                        )
                        .animation(.easeOut(duration: 0.6), value: milestone.percentage)
                }
            }
            .frame(height: 6)

            // Current / Target
            HStack {
                Text(milestone.current.compactUSDFormatted)
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
                Spacer()
                Text("of \(milestone.target.compactUSDFormatted)")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
        }
    }

    private func progressColor(_ pct: Double) -> Color {
        if pct >= 90 { return Color.success }
        if pct >= 60 { return Color.goldMid }
        return Color.textSecondary
    }
}

// MARK: - FeedItemRow

private struct FeedItemRow: View {
    let item: ActivityFeedItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon bubble
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconForeground)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(relativeTime(item.createdAt))
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                    if let amount = item.amount {
                        Text("•")
                            .font(BJFont.micro)
                            .foregroundColor(Color.textTertiary)
                        Text(amount.usdFormatted)
                            .font(BJFont.outfit(11, weight: .semibold))
                            .foregroundColor(Color.goldMid)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var iconName: String {
        switch item.type {
        case "scan":      return "qrcode.viewfinder"
        case "payout":    return "dollarsign.circle.fill"
        case "comp":      return "gift.fill"
        case "milestone": return "flag.fill"
        case "join":      return "person.fill.badge.plus"
        case "withdraw":  return "arrow.up.circle.fill"
        case "deposit":   return "arrow.down.circle.fill"
        default:          return "circle.fill"
        }
    }

    private var iconBackground: Color {
        switch item.type {
        case "scan":      return Color.goldMid.opacity(0.12)
        case "payout":    return Color.success.opacity(0.12)
        case "comp":      return Color.gold.opacity(0.12)
        case "milestone": return Color.info.opacity(0.12)
        case "join":      return Color.goldMid.opacity(0.12)
        case "withdraw":  return Color.error.opacity(0.12)
        case "deposit":   return Color.success.opacity(0.12)
        default:          return Color.white.opacity(0.06)
        }
    }

    private var iconForeground: Color {
        switch item.type {
        case "scan":      return Color.goldMid
        case "payout":    return Color.success
        case "comp":      return Color.gold
        case "milestone": return Color.info
        case "join":      return Color.goldMid
        case "withdraw":  return Color.error
        case "deposit":   return Color.success
        default:          return Color.textTertiary
        }
    }

    private func relativeTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let d = formatter.date(from: iso) else { return iso }
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OverviewView()
            .environmentObject(InsightsViewModel())
    }
    .preferredColorScheme(.dark)
}
