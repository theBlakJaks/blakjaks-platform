import SwiftUI

// MARK: - TreasuryView
// On-chain pool balances, bank accounts (Teller), Dwolla platform balance,
// reconciliation status, and payout ledger.

struct TreasuryView: View {
    @StateObject private var viewModel = InsightsViewModel(apiClient: MockAPIClient())

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.treasury == nil {
                    LoadingView()
                } else if let treasury = viewModel.treasury {
                    content(treasury: treasury)
                } else {
                    EmptyStateView(icon: "building.columns", title: "No Treasury Data", subtitle: "Pull to refresh.", actionTitle: "Retry") {
                        Task { await viewModel.loadTreasury() }
                    }
                }
            }
        }
        .navigationTitle("Treasury")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadTreasury() }
        .refreshable { await viewModel.refresh() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: { Text(viewModel.error?.localizedDescription ?? "") }
    }

    private func content(treasury: InsightsTreasury) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Total balance hero
                GoldAccentCard {
                    VStack(spacing: Spacing.xs) {
                        Text("Total Treasury")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        let total = treasury.onChainBalances.map(\.balance).reduce(0, +)
                            + treasury.bankBalances.map(\.balance).reduce(0, +)
                            + treasury.dwollaPlatformBalance.available
                        Text("$\(total.formatted(.number.precision(.fractionLength(2))))")
                            .font(.walletBalance)
                            .foregroundColor(.gold)
                        reconciliationBadge(status: treasury.reconciliationStatus)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }

                // On-chain pools
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        sectionHeader(icon: "link", title: "On-Chain (Polygon)")
                        ForEach(treasury.onChainBalances) { pool in
                            onChainRow(pool)
                            if pool.id != treasury.onChainBalances.last?.id { Divider() }
                        }
                    }
                }

                // Bank accounts (Teller)
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        sectionHeader(icon: "building.2.fill", title: "Bank Accounts (Teller)")
                        ForEach(treasury.bankBalances) { bank in
                            bankRow(bank)
                            if bank.id != treasury.bankBalances.last?.id { Divider() }
                        }
                    }
                }

                // Dwolla platform balance
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        sectionHeader(icon: "arrow.left.arrow.right.circle.fill", title: "Dwolla Platform Balance")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(treasury.dwollaPlatformBalance.available.formatted(.number.precision(.fractionLength(2))))")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(treasury.dwollaPlatformBalance.total.formatted(.number.precision(.fractionLength(2))))")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Reconciliation detail
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        sectionHeader(icon: "checkmark.seal.fill", title: "Reconciliation")
                        let rec = treasury.reconciliationStatus
                        HStack {
                            Text("Last run").font(.footnote).foregroundColor(.secondary)
                            Spacer()
                            Text(rec.lastRunAt.relativeTimeString).font(.footnote.weight(.medium))
                        }
                        HStack {
                            Text("Status").font(.footnote).foregroundColor(.secondary)
                            Spacer()
                            Text(rec.status.uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundColor(rec.status == "ok" ? .success : .warning)
                        }
                        HStack {
                            Text("Variance").font(.footnote).foregroundColor(.secondary)
                            Spacer()
                            Text("$\(rec.variance.formatted(.number.precision(.fractionLength(2))))")
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(rec.variance <= rec.tolerance ? .success : .warning)
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Row views

    private func onChainRow(_ pool: PoolBalance) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(poolLabel(for: pool.poolType))
                    .font(.footnote.weight(.medium))
                Text(pool.walletAddress)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text("$\(pool.balance.formatted(.number.precision(.fractionLength(2))))")
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .foregroundColor(.gold)
        }
    }

    private func bankRow(_ bank: BankBalance) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bank.accountName).font(.footnote.weight(.medium))
                Text(bank.institution).font(.caption2).foregroundColor(.secondary)
                Text("Synced \(bank.lastSyncAt.relativeTimeString)").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text("$\(bank.balance.formatted(.number.precision(.fractionLength(2))))")
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .foregroundColor(.primary)
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon).font(.footnote).foregroundColor(.gold)
            Text(title).font(.headline)
        }
    }

    private func reconciliationBadge(status: ReconciliationStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.status == "ok" ? Color.success : Color.warning)
                .frame(width: 6, height: 6)
            Text("Reconciled \(status.lastRunAt.relativeTimeString)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func poolLabel(for poolType: String) -> String {
        switch poolType {
        case "member_treasury":    return "Member Treasury"
        case "affiliate_treasury": return "Affiliate Treasury"
        case "wholesale_treasury": return "Wholesale Treasury"
        default: return poolType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

#Preview { NavigationStack { TreasuryView() } }
