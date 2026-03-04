import SwiftUI

// MARK: - TransactionsView
// Scrollable transaction history with pull-to-refresh, per-row status badges,
// and a styled empty state.

struct TransactionsView: View {

    @ObservedObject var vm: ScanWalletViewModel

    var body: some View {
        Group {
            if vm.isLoadingTransactions && vm.transactions.isEmpty {
                loadingState
            } else if vm.transactions.isEmpty {
                emptyState
            } else {
                transactionList
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - List

    private var transactionList: some View {
        LazyVStack(spacing: Spacing.xs) {
            ForEach(vm.transactions) { tx in
                TransactionRow(transaction: tx)
            }
        }
        .refreshable {
            await vm.loadTransactions(refresh: true)
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                ShimmerRow()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(Color.textTertiary)

            VStack(spacing: Spacing.xs) {
                Text("No Transactions Yet")
                    .font(BJFont.subheading)
                    .foregroundColor(Color.textSecondary)
                Text("Scan a BlakJaks QR code to start earning\nand your activity will appear here.")
                    .font(BJFont.caption)
                    .foregroundColor(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, Spacing.xxxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TransactionRow

struct TransactionRow: View {

    let transaction: Transaction

    var body: some View {
        BlakJaksCard(padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(transaction.description)
                        .font(BJFont.sora(13, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.xs) {
                        Text(formattedDate)
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)

                        statusBadge
                    }
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formattedAmount)
                        .font(BJFont.outfit(15, weight: .bold))
                        .foregroundColor(amountColor)

                    Text(transaction.currency.uppercased())
                        .font(BJFont.micro)
                        .tracking(1)
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isCredit: Bool {
        let t = transaction.type.lowercased()
        return t.contains("credit") || t.contains("earn") || t.contains("comp") || t.contains("deposit")
    }

    private var isPending: Bool {
        transaction.status.lowercased() == "pending"
    }

    private var iconName: String {
        switch transaction.status.lowercased() {
        case "pending": return "clock"
        default:
            return isCredit ? "arrow.down.circle" : "arrow.up.circle"
        }
    }

    private var iconColor: Color {
        switch transaction.status.lowercased() {
        case "pending": return .pendingAmount
        case "failed":  return .error
        default:        return isCredit ? .creditAmount : .debitAmount
        }
    }

    private var amountColor: Color {
        switch transaction.status.lowercased() {
        case "pending": return .pendingAmount
        case "failed":  return .error
        default:        return isCredit ? .creditAmount : .debitAmount
        }
    }

    private var formattedAmount: String {
        let prefix = isCredit ? "+" : "-"
        return "\(prefix)\(transaction.amount.usdFormatted)"
    }

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        let display = DateFormatter()
        display.dateFormat = "MMM d, h:mm a"
        if let date = iso.date(from: transaction.createdAt) {
            return display.string(from: date)
        }
        return transaction.createdAt
    }

    private var statusBadge: some View {
        let (label, color): (String, Color) = {
            switch transaction.status.lowercased() {
            case "processed": return ("Processed", .success)
            case "pending":   return ("Pending",   .pendingAmount)
            case "failed":    return ("Failed",    .error)
            case "cancelled": return ("Cancelled", .textTertiary)
            default:          return (transaction.status.capitalized, .textTertiary)
            }
        }()

        return Text(label)
            .font(BJFont.micro)
            .tracking(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
            .clipShape(Capsule())
    }
}

// MARK: - ShimmerRow
// Placeholder skeleton while transactions load.

private struct ShimmerRow: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        BlakJaksCard(padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(Color.bgCard)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bgCard)
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bgCard)
                        .frame(width: 80, height: 10)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bgCard)
                    .frame(width: 60, height: 14)
            }
        }
        .redacted(reason: .placeholder)
    }
}

#Preview {
    ScrollView {
        TransactionsView(vm: ScanWalletViewModel())
    }
    .background(Color.bgPrimary)
}
