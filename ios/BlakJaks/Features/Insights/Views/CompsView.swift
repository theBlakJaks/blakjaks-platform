import SwiftUI

// MARK: - CompsView
// Prize tiers ($100/$1K/$10K/$200K trip), milestones, guaranteed comps, vault economy.

struct CompsView: View {
    @StateObject private var viewModel = InsightsViewModel(apiClient: MockAPIClient())

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.comps == nil {
                    LoadingView()
                } else if let comps = viewModel.comps {
                    content(comps: comps)
                } else {
                    EmptyStateView(icon: "gift", title: "No Comps Data", subtitle: "Pull to refresh.", actionTitle: "Retry") {
                        Task { await viewModel.loadComps() }
                    }
                }
            }
        }
        .navigationTitle("Comps")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadComps() }
        .refreshable { await viewModel.refresh() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: { Text(viewModel.error?.localizedDescription ?? "") }
    }

    private func content(comps: InsightsComps) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Prize tier cards
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "gift.fill").font(.footnote).foregroundColor(.gold)
                            Text("Prize Tiers").font(.headline)
                        }
                        compTierRow(label: "$100 Milestone", stats: comps.tier100, color: .tierStandard)
                        Divider()
                        compTierRow(label: "$1,000 Milestone", stats: comps.tier1k, color: .tierVIP)
                        Divider()
                        compTierRow(label: "$10,000 Milestone", stats: comps.tier10k, color: .tierHighRoller)
                        Divider()
                        compTierRow(label: "$200K Vegas Trip", stats: comps.tier200kTrip, color: .tierWhale)
                    }
                }

                // Milestones progress
                if !comps.milestoneProgress.isEmpty {
                    BlakJaksCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "flag.fill").font(.footnote).foregroundColor(.gold)
                                Text("Platform Milestones").font(.headline)
                            }
                            ForEach(comps.milestoneProgress) { milestone in
                                milestoneRow(milestone)
                            }
                        }
                    }
                }

                // Guaranteed comps
                GoldAccentCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "shield.checkered").font(.footnote).foregroundColor(.gold)
                            Text("Guaranteed Comps").font(.headline)
                        }
                        HStack {
                            statItem(label: "Paid This Year", value: "$\(comps.guaranteedCompTotals.totalPaidThisYear.formatted(.number.precision(.fractionLength(0))))")
                            Spacer()
                            statItem(label: "Recipients", value: comps.guaranteedCompTotals.totalRecipients.formatted(.number))
                            Spacer()
                            statItem(label: "Next Run", value: comps.guaranteedCompTotals.nextRunDate)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                // Vault economy
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "vault.fill").font(.footnote).foregroundColor(.gold)
                            Text("Vault Economy").font(.headline)
                        }
                        HStack {
                            statItem(label: "Total in Vaults", value: "$\(comps.vaultEconomy.totalInVaults.formatted(.number.precision(.fractionLength(2))))")
                            Spacer()
                            statItem(label: "Avg Vault", value: "$\(comps.vaultEconomy.avgVaultBalance.formatted(.number.precision(.fractionLength(2))))")
                            Spacer()
                            statItem(label: "Gold Chips", value: comps.vaultEconomy.goldChipsIssued.formatted(.number))
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
    }

    private func compTierRow(label: String, stats: CompTierStats, color: Color) -> some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label).font(.footnote.weight(.medium))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(stats.totalPaid.formatted(.number.precision(.fractionLength(0)))) paid")
                    .font(.system(.footnote, design: .monospaced).weight(.semibold))
                    .foregroundColor(stats.totalRecipients > 0 ? .success : .secondary)
                Text("\(stats.totalRecipients) recipients")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
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
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.footnote.weight(.semibold)).foregroundColor(.primary)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }
}

#Preview { NavigationStack { CompsView() } }
