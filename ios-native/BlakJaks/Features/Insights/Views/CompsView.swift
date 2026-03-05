import SwiftUI

// MARK: - CompsView
// Displays InsightsComps: tier cards, milestone progress,
// guaranteed comp totals, vault economy.

struct CompsView: View {
    @EnvironmentObject private var vm: InsightsViewModel

    private let tierColumns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoadingComps && vm.comps == nil {
                InsightsLoadingView()
            } else if let error = vm.errorMessage, vm.comps == nil {
                InsightsErrorView(message: error) { Task { await vm.loadComps() } }
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await vm.loadComps() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("COMPS")
                    .font(BJFont.playfair(18, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .tracking(1)
                Text("COMPENSATION ENGINE")
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
                if let comps = vm.comps {
                    tierCardsSection(comps: comps)
                    milestonesSection(comps: comps)
                    guaranteedCompSection(comps: comps)
                    vaultEconomySection(comps: comps)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .refreshable { await vm.loadComps() }
    }

    // MARK: - Tier Cards Grid

    @ViewBuilder
    private func tierCardsSection(comps: InsightsComps) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "REWARDS", title: "Comp Tiers")

            LazyVGrid(columns: tierColumns, spacing: Spacing.sm) {
                CompTierCard(tierName: "100 Scans", badge: "♠", stats: comps.tier100)
                CompTierCard(tierName: "1K Scans", badge: "♦", stats: comps.tier1k)
                CompTierCard(tierName: "10K Scans", badge: "♥", stats: comps.tier10k)
                CompTierCard(tierName: "200K Trip", badge: "♣", stats: comps.tier200kTrip)
            }
        }
    }

    // MARK: - Milestones Section

    @ViewBuilder
    private func milestonesSection(comps: InsightsComps) -> some View {
        guard !comps.milestoneProgress.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "TARGETS", title: "Milestone Progress")

                BlakJaksCard {
                    VStack(spacing: Spacing.md) {
                        ForEach(Array(comps.milestoneProgress.enumerated()), id: \.element.id) { index, milestone in
                            if index > 0 {
                                Divider().background(Color.borderSubtle)
                            }
                            CompMilestoneRow(milestone: milestone)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Guaranteed Comp Totals

    @ViewBuilder
    private func guaranteedCompSection(comps: InsightsComps) -> some View {
        let gc = comps.guaranteedCompTotals

        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "GUARANTEED", title: "Comp Totals")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    // Total paid this year — hero number
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Paid This Year")
                            .font(BJFont.eyebrow)
                            .foregroundColor(Color.goldMid)
                            .tracking(2)
                        Text(gc.totalPaidThisYear.usdFormatted)
                            .font(BJFont.price)
                            .foregroundColor(Color.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider().background(Color.borderSubtle)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Recipients")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Text("\(gc.totalRecipients)")
                                .font(BJFont.outfit(16, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Next Run")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Text(formatDate(gc.nextRunDate))
                                .font(BJFont.sora(13, weight: .semibold))
                                .foregroundColor(Color.goldMid)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Vault Economy

    @ViewBuilder
    private func vaultEconomySection(comps: InsightsComps) -> some View {
        let vault = comps.vaultEconomy

        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "ECOSYSTEM", title: "Vault Economy")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    // Total in vaults — hero
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total In Vaults")
                            .font(BJFont.eyebrow)
                            .foregroundColor(Color.goldMid)
                            .tracking(2)
                        Text(vault.totalInVaults.usdFormatted)
                            .font(BJFont.price)
                            .foregroundColor(Color.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider().background(Color.borderSubtle)

                    HStack {
                        VaultStatItem(
                            label: "Avg Vault Balance",
                            value: vault.avgVaultBalance.compactUSDFormatted,
                            icon: "lock.fill",
                            color: Color.goldMid
                        )
                        Divider()
                            .frame(height: 40)
                            .background(Color.borderSubtle)
                        VaultStatItem(
                            label: "Gold Chips Issued",
                            value: formatCount(vault.goldChipsIssued),
                            icon: "circle.hexagongrid.fill",
                            color: Color.gold
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: iso) {
            let f = DateFormatter()
            f.dateStyle = .medium
            return f.string(from: date)
        }
        return iso
    }

    private func formatCount(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000     { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }
}

// MARK: - CompTierCard

private struct CompTierCard: View {
    let tierName: String
    let badge: String
    let stats: CompTierStats

    var body: some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(badge)
                        .font(.system(size: 20))
                        .foregroundColor(Color.goldMid)
                    Spacer()
                }

                Text(tierName)
                    .font(BJFont.playfair(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)

                Text(stats.periodLabel)
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)

                Divider()
                    .background(Color.borderSubtle)
                    .padding(.vertical, 2)

                // Total paid
                VStack(alignment: .leading, spacing: 1) {
                    Text("Total Paid")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                    Text(stats.totalPaid.compactUSDFormatted)
                        .font(BJFont.outfit(15, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                }

                // Recipients
                VStack(alignment: .leading, spacing: 1) {
                    Text("Recipients")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                    Text("\(stats.totalRecipients)")
                        .font(BJFont.outfit(13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                }

                // Avg payout
                VStack(alignment: .leading, spacing: 1) {
                    Text("Avg Payout")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                    Text(stats.averagePayout.usdFormatted)
                        .font(BJFont.outfit(13, weight: .semibold))
                        .foregroundColor(Color.goldMid)
                }
            }
        }
    }
}

// MARK: - CompMilestoneRow

private struct CompMilestoneRow: View {
    let milestone: MilestoneProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(milestone.label)
                    .font(BJFont.sora(13, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text(milestone.percentage.percentFormatted)
                    .font(BJFont.outfit(13, weight: .bold))
                    .foregroundColor(progressColor(milestone.percentage))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 6)
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

// MARK: - VaultStatItem

private struct VaultStatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(BJFont.outfit(15, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(BJFont.micro)
                .foregroundColor(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CompsView()
            .environmentObject(InsightsViewModel())
    }
    .preferredColorScheme(.dark)
}
