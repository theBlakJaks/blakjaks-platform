import SwiftUI

// MARK: - WalletSectionView
// Shows balance breakdown, linked bank account, USDC wallet address,
// and the full list of Dwolla funding sources.

struct WalletSectionView: View {

    @ObservedObject var vm: ScanWalletViewModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            balanceCard

            if let wallet = vm.wallet {
                bankSection(wallet: wallet)
                if let address = wallet.address {
                    usdcAddressCard(address: address)
                }
            }

            if vm.fundingSources.count > 1 {
                allFundingSourcesSection
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Balance Breakdown Card

    private var balanceCard: some View {
        BlakJaksCard(padding: Spacing.lg) {
            VStack(spacing: 0) {
                HStack {
                    Text("BALANCE BREAKDOWN")
                        .font(BJFont.eyebrow)
                        .tracking(3)
                        .foregroundColor(Color.textTertiary)
                    Spacer()
                    Image(systemName: "chart.pie")
                        .font(.system(size: 14))
                        .foregroundColor(Color.goldMid)
                }

                Divider()
                    .background(Color.borderGold)
                    .padding(.vertical, Spacing.md)

                VStack(spacing: Spacing.sm) {
                    balanceRow(
                        label: "Available Balance",
                        value: vm.wallet?.availableBalance ?? 0,
                        color: Color.creditAmount,
                        isLarge: true
                    )
                    balanceRow(
                        label: "Comp Balance",
                        value: vm.wallet?.compBalance ?? 0,
                        color: Color.goldMid,
                        isLarge: false
                    )
                    balanceRow(
                        label: "Pending Balance",
                        value: vm.wallet?.pendingBalance ?? 0,
                        color: Color.pendingAmount,
                        isLarge: false
                    )

                    Divider()
                        .background(Color.borderGold)
                        .padding(.vertical, 4)

                    HStack {
                        Text("Total")
                            .font(BJFont.sora(13, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        Spacer()
                        let total = (vm.wallet?.availableBalance ?? 0)
                            + (vm.wallet?.compBalance ?? 0)
                            + (vm.wallet?.pendingBalance ?? 0)
                        Text(total.usdFormatted)
                            .font(BJFont.outfit(16, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                    }
                }

                if let currency = vm.wallet?.currency {
                    HStack {
                        Spacer()
                        Text("Currency: \(currency.uppercased())")
                            .font(BJFont.micro)
                            .tracking(1.5)
                            .foregroundColor(Color.textTertiary)
                    }
                    .padding(.top, Spacing.sm)
                }
            }
        }
    }

    private func balanceRow(label: String, value: Double, color: Color, isLarge: Bool) -> some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(isLarge ? BJFont.sora(14, weight: .semibold) : BJFont.caption)
                    .foregroundColor(isLarge ? Color.textPrimary : Color.textSecondary)
            }
            Spacer()
            Text(value.usdFormatted)
                .font(isLarge ? BJFont.outfit(18, weight: .bold) : BJFont.label)
                .foregroundColor(color)
        }
    }

    // MARK: - Bank Section

    @ViewBuilder
    private func bankSection(wallet: Wallet) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("LINKED BANK")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.textTertiary)
                .padding(.horizontal, 4)

            if let bank = wallet.linkedBankAccount {
                linkedBankCard(bank: bank)
            } else {
                noLinkCard
            }
        }
    }

    private func linkedBankCard(bank: DwollaFundingSource) -> some View {
        BlakJaksCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.goldMid.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "building.columns")
                        .font(.system(size: 20))
                        .foregroundColor(Color.goldMid)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(bank.bankName ?? bank.name)
                        .font(BJFont.sora(14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    if let last4 = bank.lastFour {
                        Text("Account ending ••••\(last4)")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }

                Spacer()

                statusBadge(bank.status)
            }
        }
    }

    private var noLinkCard: some View {
        BlakJaksCard {
            VStack(spacing: Spacing.md) {
                HStack {
                    Image(systemName: "building.columns.circle")
                        .font(.system(size: 28))
                        .foregroundColor(Color.textTertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Bank Account Linked")
                            .font(BJFont.sora(14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                        Text("Link a bank to enable ACH withdrawals")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)
                    }
                    Spacer()
                }
                GhostButton(title: "Link Bank Account") {
                    // Plaid link flow handled by parent coordinator
                }
            }
        }
    }

    // MARK: - USDC Address Card

    private func usdcAddressCard(address: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("POLYGON WALLET")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.textTertiary)
                .padding(.horizontal, 4)

            BlakJaksCard {
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.goldMid.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "bitcoinsign.circle")
                                .font(.system(size: 20))
                                .foregroundColor(Color.goldMid)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("USDC Address")
                                .font(BJFont.sora(14, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            Text(address.truncatedWalletAddress)
                                .font(BJFont.sora(11))
                                .foregroundColor(Color.textSecondary)
                                .monospaced()
                        }

                        Spacer()

                        CopyButton(text: address)
                    }

                    // Full address in a scrollable mono field
                    Text(address)
                        .font(BJFont.sora(10))
                        .foregroundColor(Color.textTertiary)
                        .monospaced()
                        .lineLimit(2)
                        .padding(Spacing.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.bgPrimary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
            }
        }
    }

    // MARK: - All Funding Sources

    private var allFundingSourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("ALL FUNDING SOURCES")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.textTertiary)
                .padding(.horizontal, 4)

            BlakJaksCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(vm.fundingSources.enumerated()), id: \.element.id) { index, source in
                        fundingSourceRow(source)
                        if index < vm.fundingSources.count - 1 {
                            Divider()
                                .background(Color.borderGold)
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
            }
        }
    }

    private func fundingSourceRow(_ source: DwollaFundingSource) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: source.type == "balance" ? "dollarsign.circle" : "building.columns")
                .font(.system(size: 16))
                .foregroundColor(Color.goldMid)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.bankName ?? source.name)
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                if let last4 = source.lastFour {
                    Text("••••\(last4)")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }

            Spacer()

            statusBadge(source.status)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Helpers

    private func statusBadge(_ status: String) -> some View {
        let color: Color = {
            switch status.lowercased() {
            case "verified":   return .success
            case "unverified": return .warning
            case "pending":    return .pendingAmount
            default:           return .textTertiary
            }
        }()
        return Text(status.uppercased())
            .font(BJFont.micro)
            .tracking(1)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
            .clipShape(Capsule())
    }
}

// MARK: - CopyButton

private struct CopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { copied = false }
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(copied ? Color.success : Color.goldMid)
                .frame(width: 36, height: 36)
                .background(Color.goldMid.opacity(0.08))
                .clipShape(Circle())
        }
    }
}

#Preview {
    ScrollView {
        WalletSectionView(vm: ScanWalletViewModel())
    }
    .background(Color.bgPrimary)
}
