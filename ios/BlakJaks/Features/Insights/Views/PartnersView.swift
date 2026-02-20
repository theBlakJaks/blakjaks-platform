import SwiftUI

// MARK: - PartnersView
// Affiliate metrics (sunset engine, weekly pool, tier floors) + wholesale stats.

struct PartnersView: View {
    @StateObject private var viewModel = InsightsViewModel(apiClient: MockAPIClient())

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.partners == nil {
                    LoadingView()
                } else if let partners = viewModel.partners {
                    content(partners: partners)
                } else {
                    EmptyStateView(icon: "person.2", title: "No Partners Data", subtitle: "Pull to refresh.", actionTitle: "Retry") {
                        Task { await viewModel.loadPartners() }
                    }
                }
            }
        }
        .navigationTitle("Partners")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadPartners() }
        .refreshable { await viewModel.refresh() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: { Text(viewModel.error?.localizedDescription ?? "") }
    }

    private func content(partners: InsightsPartners) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Affiliate overview
                GoldAccentCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "person.2.fill").font(.footnote).foregroundColor(.gold)
                            Text("Affiliate Program").font(.headline)
                        }
                        HStack(spacing: Spacing.xl) {
                            statBlock(label: "Active Affiliates", value: partners.affiliateActiveCount.formatted(.number))
                            statBlock(label: "Weekly Pool", value: "$\(partners.weeklyPool.formatted(.number.precision(.fractionLength(2))))")
                            statBlock(label: "Lifetime Match", value: "$\(partners.lifetimeMatchTotal.formatted(.number.precision(.fractionLength(0))))")
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                // Sunset engine status
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "sunset.fill").font(.footnote).foregroundColor(.gold)
                            Text("Sunset Engine").font(.headline)
                            Spacer()
                            engineStatusBadge(status: partners.sunsetEngineStatus)
                        }
                        Text("Permanently floors tier for affiliates who reach qualifying thresholds, protecting their tier status indefinitely.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !partners.permanentTierFloorCounts.isEmpty {
                            Divider()
                            Text("Permanent Floor Counts").font(.footnote.weight(.medium))
                            HStack(spacing: Spacing.lg) {
                                ForEach(Array(partners.permanentTierFloorCounts.sorted(by: { $0.key < $1.key })), id: \.key) { tier, count in
                                    VStack(spacing: 2) {
                                        Text(count.formatted(.number))
                                            .font(.title3.weight(.bold))
                                            .foregroundColor(.gold)
                                        Text(tier)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // Wholesale stats
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "shippingbox.fill").font(.footnote).foregroundColor(.gold)
                            Text("Wholesale").font(.headline)
                        }
                        HStack {
                            statBlock(
                                label: "Active Accounts",
                                value: partners.wholesaleActiveAccounts.formatted(.number)
                            )
                            Spacer()
                            statBlock(
                                label: "Orders This Month",
                                value: "$\(partners.wholesaleOrderValueThisMonth.formatted(.number.precision(.fractionLength(0))))"
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func engineStatusBadge(status: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status == "active" ? Color.success : Color.warning)
                .frame(width: 6, height: 6)
            Text(status.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(status == "active" ? .success : .warning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(status == "active" ? Color.success.opacity(0.12) : Color.warning.opacity(0.12))
        )
    }
}

#Preview { NavigationStack { PartnersView() } }
