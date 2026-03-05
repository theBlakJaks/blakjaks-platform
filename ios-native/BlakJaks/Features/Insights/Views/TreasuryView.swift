import SwiftUI

// MARK: - TreasuryView
// Displays InsightsTreasury: on-chain balances, bank balances,
// Dwolla platform balance, reconciliation status, payout ledger.

struct TreasuryView: View {
    @EnvironmentObject private var vm: InsightsViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoadingTreasury && vm.treasury == nil {
                InsightsLoadingView()
            } else if let error = vm.errorMessage, vm.treasury == nil {
                InsightsErrorView(message: error) { Task { await vm.loadTreasury() } }
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .disableSwipeBack()
        .toolbar { toolbarContent }
        .task { await vm.loadTreasury() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("TREASURY")
                    .font(BJFont.playfair(18, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .tracking(1)
                Text("FINANCIAL INTELLIGENCE")
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
                if let treasury = vm.treasury {
                    onChainSection(treasury: treasury)
                    bankBalancesSection(treasury: treasury)
                    dwollaSection(treasury: treasury)
                    reconciliationSection(treasury: treasury)
                    payoutLedgerSection(treasury: treasury)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .refreshable { await vm.loadTreasury() }
    }

    // MARK: - On-Chain Balances

    @ViewBuilder
    private func onChainSection(treasury: InsightsTreasury) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "BLOCKCHAIN", title: "On-Chain Balances")

            VStack(spacing: Spacing.sm) {
                ForEach(treasury.onChainBalances) { pool in
                    PoolBalanceCard(pool: pool)
                }
            }
        }
    }

    // MARK: - Bank Balances

    @ViewBuilder
    private func bankBalancesSection(treasury: InsightsTreasury) -> some View {
        guard !treasury.bankBalances.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "BANKING", title: "Bank Accounts")

                BlakJaksCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(treasury.bankBalances.enumerated()), id: \.element.id) { index, bank in
                            if index > 0 {
                                Divider()
                                    .background(Color.borderSubtle)
                                    .padding(.leading, Spacing.md)
                            }
                            BankBalanceRow(bank: bank)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Dwolla Balance

    @ViewBuilder
    private func dwollaSection(treasury: InsightsTreasury) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "ACH PLATFORM", title: "Dwolla Balance")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    DwollaBalanceRow(
                        label: "Available",
                        value: treasury.dwollaPlatformBalance.available,
                        currency: treasury.dwollaPlatformBalance.currency,
                        accent: Color.success
                    )
                    Divider().background(Color.borderSubtle)
                    DwollaBalanceRow(
                        label: "Total",
                        value: treasury.dwollaPlatformBalance.total,
                        currency: treasury.dwollaPlatformBalance.currency,
                        accent: Color.textPrimary
                    )
                }
            }
        }
    }

    // MARK: - Reconciliation

    @ViewBuilder
    private func reconciliationSection(treasury: InsightsTreasury) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "AUDIT", title: "Reconciliation")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    // Status badge row
                    HStack {
                        Text("Status")
                            .font(BJFont.sora(13, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                        Spacer()
                        ReconciliationBadge(status: treasury.reconciliationStatus.status)
                    }

                    Divider().background(Color.borderSubtle)

                    // Variance row
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Variance")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Text(treasury.reconciliationStatus.variance.usdFormatted)
                                .font(BJFont.outfit(15, weight: .semibold))
                                .foregroundColor(
                                    abs(treasury.reconciliationStatus.variance) <= treasury.reconciliationStatus.tolerance
                                    ? Color.success : Color.error
                                )
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Tolerance")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                            Text(treasury.reconciliationStatus.tolerance.usdFormatted)
                                .font(BJFont.outfit(15, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                        }
                    }

                    Divider().background(Color.borderSubtle)

                    // Last run
                    HStack {
                        Text("Last Run")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)
                        Spacer()
                        Text(formatTimestamp(treasury.reconciliationStatus.lastRunAt))
                            .font(BJFont.micro)
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Payout Ledger

    @ViewBuilder
    private func payoutLedgerSection(treasury: InsightsTreasury) -> some View {
        guard !treasury.payoutLedger.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "LEDGER", title: "Recent Payouts")

                BlakJaksCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(treasury.payoutLedger.prefix(15).enumerated()), id: \.element.id) { index, entry in
                            if index > 0 {
                                Divider()
                                    .background(Color.borderSubtle)
                                    .padding(.leading, Spacing.md)
                            }
                            LedgerEntryRow(entry: entry)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Helpers

    private func formatTimestamp(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: iso) {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }
        return iso
    }
}

// MARK: - PoolBalanceCard

private struct PoolBalanceCard: View {
    let pool: PoolBalance

    var body: some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(pool.poolType.uppercased())
                        .font(BJFont.eyebrow)
                        .foregroundColor(Color.goldMid)
                        .tracking(2)
                    Spacer()
                    Text(pool.currency)
                        .font(BJFont.sora(11, weight: .semibold))
                        .foregroundColor(Color.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }

                Text(pool.balance.usdFormatted)
                    .font(BJFont.price)
                    .foregroundColor(Color.textPrimary)

                // Wallet address truncated
                HStack(spacing: 4) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary)
                    Text(truncateAddress(pool.walletAddress))
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func truncateAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        let start = address.prefix(6)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
}

// MARK: - BankBalanceRow

private struct BankBalanceRow: View {
    let bank: BankBalance

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.goldMid.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.goldMid)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(bank.accountName)
                    .font(BJFont.sora(13, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Text(bank.institution)
                    .font(BJFont.caption)
                    .foregroundColor(Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(bank.balance.usdFormatted)
                    .font(BJFont.outfit(14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text("synced")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - DwollaBalanceRow

private struct DwollaBalanceRow: View {
    let label: String
    let value: Double
    let currency: String
    let accent: Color

    var body: some View {
        HStack {
            Text(label)
                .font(BJFont.sora(13, weight: .medium))
                .foregroundColor(Color.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                Text(value.usdFormatted)
                    .font(BJFont.outfit(16, weight: .bold))
                    .foregroundColor(accent)
                Text(currency)
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
        }
    }
}

// MARK: - ReconciliationBadge

private struct ReconciliationBadge: View {
    let status: String

    private var isOk: Bool { status.lowercased() == "ok" }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isOk ? Color.success : Color.error)
                .frame(width: 7, height: 7)
            Text(status.uppercased())
                .font(BJFont.eyebrow)
                .foregroundColor(isOk ? Color.success : Color.error)
                .tracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isOk ? Color.success : Color.error).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
    }
}

// MARK: - LedgerEntryRow

private struct LedgerEntryRow: View {
    let entry: PayoutLedgerEntry

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Status dot
            Circle()
                .fill(statusColor(entry.status))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.type.capitalized)
                    .font(BJFont.sora(13, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Text("→ \(entry.recipientMemberId)")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.amount.usdFormatted)
                    .font(BJFont.outfit(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(entry.status.lowercased())
                    .font(BJFont.micro)
                    .foregroundColor(statusColor(entry.status))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "processed", "completed", "success": return Color.success
        case "pending":                            return Color.warning
        case "failed", "error":                   return Color.error
        default:                                   return Color.textTertiary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TreasuryView()
            .environmentObject(InsightsViewModel())
    }
    .preferredColorScheme(.dark)
}
