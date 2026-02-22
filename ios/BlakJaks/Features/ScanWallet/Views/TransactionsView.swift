import SwiftUI

// MARK: - TransactionsView
// Filterable transaction list: All / Deposits / Withdrawals.
// Color-coded amounts, pending state, PolygonScan link for on-chain txs.

struct TransactionsView: View {
    @ObservedObject var viewModel: ScanWalletViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section header + filter
            HStack {
                Text("Transactions")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.gold)
                Spacer()
            }
            .padding(.horizontal, Layout.screenMargin)

            // Filter tabs
            HStack(spacing: 0) {
                ForEach(TxFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, Layout.screenMargin)

            // List
            if viewModel.filteredTransactions.isEmpty {
                EmptyStateView(
                    icon: "dollarsign.circle",
                    title: "No Transactions",
                    subtitle: "Earn your first USDC by scanning a BlakJaks product.",
                    actionTitle: nil
                )
                .padding(.horizontal, Layout.screenMargin)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.filteredTransactions) { tx in
                        transactionRow(tx)
                        if tx.id != viewModel.filteredTransactions.last?.id {
                            Divider().padding(.horizontal, Layout.screenMargin)
                        }
                    }
                }
                .background(Color.backgroundSecondary)
                .cornerRadius(Layout.cardCornerRadius)
                .padding(.horizontal, Layout.screenMargin)
            }
        }
    }

    // MARK: - Filter tab

    private func filterTab(_ filter: TxFilter) -> some View {
        Button {
            viewModel.txFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.footnote.weight(.semibold))
                .foregroundColor(viewModel.txFilter == filter ? Color.backgroundPrimary : .secondary)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.sm)
                        .fill(viewModel.txFilter == filter ? Color.gold : Color.clear)
                )
        }
        .animation(.spring(response: 0.2), value: viewModel.txFilter)
    }

    // MARK: - Transaction row

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: Spacing.md) {
            // Type icon
            ZStack {
                Circle()
                    .fill(txIconBackground(tx))
                    .frame(width: 40, height: 40)
                Image(systemName: txIcon(tx))
                    .font(.callout.weight(.medium))
                    .foregroundColor(txIconColor(tx))
            }

            // Description + date
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(tx.description)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(tx.createdAt.relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount + status
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(formattedAmount(tx))
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundColor(amountColor(tx))
                statusBadge(tx)
            }
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.vertical, Spacing.md)
        .opacity(tx.status == "pending" ? 0.65 : 1.0)
        .overlay(alignment: .bottomTrailing) {
            if let txHash = tx.txHash {
                Link(destination: polygonScanURL(txHash)) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, Layout.screenMargin)
                .padding(.bottom, Spacing.xs)
            }
        }
    }

    // MARK: - Helpers

    private func txIcon(_ tx: Transaction) -> String {
        switch tx.type {
        case "comp_earned", "guaranteed_comp": return "gift.fill"
        case "scan_earn":                      return "qrcode"
        case "bank_withdrawal":                return "building.2.fill"
        case "crypto_withdrawal":              return "arrow.up.circle.fill"
        default:                               return "dollarsign.circle.fill"
        }
    }

    private func txIconBackground(_ tx: Transaction) -> Color {
        tx.amount >= 0
            ? Color.success.opacity(0.12)
            : Color.failure.opacity(0.12)
    }

    private func txIconColor(_ tx: Transaction) -> Color {
        switch tx.type {
        case "comp_earned", "guaranteed_comp": return .gold
        case "scan_earn":                      return .success
        default: return tx.amount >= 0 ? .success : .error
        }
    }

    private func amountColor(_ tx: Transaction) -> Color {
        if tx.status == "pending" { return .secondary }
        return tx.amount >= 0 ? .success : .error
    }

    private func formattedAmount(_ tx: Transaction) -> String {
        let sign = tx.amount >= 0 ? "+" : ""
        let abs = abs(tx.amount)
        return "\(sign)$\(abs.formatted(.number.precision(.fractionLength(2))))"
    }

    @ViewBuilder
    private func statusBadge(_ tx: Transaction) -> some View {
        if tx.status == "pending" {
            Text("PENDING")
                .font(.caption2.weight(.bold))
                .foregroundColor(.warning)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xs)
                .background(Capsule().fill(Color.warning.opacity(0.15)))
        } else {
            Text("")
                .font(.caption2)
                .foregroundColor(.clear)
        }
    }

    private func polygonScanURL(_ hash: String) -> URL {
        URL(string: "https://polygonscan.com/tx/\(hash)") ?? URL(string: "https://polygonscan.com")!
    }
}
