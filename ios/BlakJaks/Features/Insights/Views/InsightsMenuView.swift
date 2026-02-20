import SwiftUI

// MARK: - InsightsMenuView
// 5-button animated menu — each routes to an Insights sub-page.
// The admin-only Insights tab; all data read-only for regular users.

struct InsightsMenuView: View {
    @StateObject private var viewModel = InsightsViewModel(apiClient: MockAPIClient())
    @State private var pressedTab: InsightsTab?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header stats strip
                        if let overview = viewModel.overview {
                            headerStatsView(overview: overview)
                        }

                        // 5 menu buttons
                        VStack(spacing: Spacing.sm) {
                            ForEach(InsightsTab.allCases) { tab in
                                NavigationLink {
                                    destinationView(for: tab)
                                        .environmentObject(viewModel)
                                } label: {
                                    menuButton(tab: tab)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, Layout.screenMargin)
                    }
                    .padding(.vertical, Spacing.lg)
                }
                .refreshable { await viewModel.refresh() }

                if viewModel.isLoading && viewModel.overview == nil {
                    LoadingView()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadOverview() }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }

    // MARK: - Header stats

    private func headerStatsView(overview: InsightsOverview) -> some View {
        HStack(spacing: Spacing.sm) {
            statChip(
                label: "Total Scans",
                value: overview.globalScanCount.formatted(.number),
                icon: "qrcode"
            )
            statChip(
                label: "Members",
                value: overview.activeMembers.formatted(.number),
                icon: "person.2.fill"
            )
            statChip(
                label: "24h Payouts",
                value: "$\(overview.payoutsLast24h.formatted(.number.precision(.fractionLength(0))))",
                icon: "arrow.up.circle.fill"
            )
        }
        .padding(.horizontal, Layout.screenMargin)
    }

    private func statChip(label: String, value: String, icon: String) -> some View {
        BlakJaksCard {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.gold)
                Text(value)
                    .font(.monoBody.weight(.semibold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Menu button

    private func menuButton(tab: InsightsTab) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gold.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.rawValue)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                Text(menuSubtitle(for: tab))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
    }

    private func menuSubtitle(for tab: InsightsTab) -> String {
        switch tab {
        case .overview: return "Scan counter, vitals, live feed"
        case .treasury: return "On-chain, bank, Dwolla balances"
        case .systems:  return "Budget, pipeline, node status"
        case .comps:    return "Prize tiers, vault economy"
        case .partners: return "Affiliate & wholesale metrics"
        }
    }

    // MARK: - Routing

    @ViewBuilder
    private func destinationView(for tab: InsightsTab) -> some View {
        switch tab {
        case .overview: OverviewView()
        case .treasury: TreasuryView()
        case .systems:  SystemsView()
        case .comps:    CompsView()
        case .partners: PartnersView()
        }
    }
}

// MARK: - ScaleButtonStyle

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    InsightsMenuView()
}
