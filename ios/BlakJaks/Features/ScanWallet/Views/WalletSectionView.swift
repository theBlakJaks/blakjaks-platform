import SwiftUI

// MARK: - WalletSectionView
// Balance card, wallet address (truncated + copy), Send/Receive actions,
// linked bank account status, and withdrawal sheets.

struct WalletSectionView: View {
    @ObservedObject var viewModel: ScanWalletViewModel
    @State private var showCryptoWithdraw = false
    @State private var showBankWithdraw   = false
    @State private var showReceiveQR      = false
    @State private var addressCopied      = false

    // Mock wallet address (Web3Auth provides this; using stub for now)
    private let walletAddress = "0x3f2A9c8B1D7e4F0a5C6E2d8B9A1F3c7E4D2b0A8F"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("Wallet")

            if let wallet = viewModel.wallet {
                walletContent(wallet: wallet)
            } else {
                walletPlaceholder
            }
        }
        .padding(.horizontal, Layout.screenMargin)
        .sheet(isPresented: $showCryptoWithdraw) {
            cryptoWithdrawSheet
        }
        .sheet(isPresented: $showBankWithdraw) {
            bankWithdrawSheet
        }
        .sheet(isPresented: $showReceiveQR) {
            receiveSheet
        }
    }

    // MARK: - Wallet content

    private func walletContent(wallet: Wallet) -> some View {
        VStack(spacing: Spacing.md) {
            // Balance card
            GoldAccentCard {
                VStack(spacing: Spacing.sm) {
                    Text("Available Balance")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Text("$\(wallet.availableBalance.formatted(.number.precision(.fractionLength(2))))")
                        .font(.walletBalance)
                        .foregroundColor(.gold)
                    if wallet.pendingBalance > 0 {
                        Text("+$\(wallet.pendingBalance.formatted(.number.precision(.fractionLength(2)))) pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("USDT · Polygon")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.top, 2)

                    // Action buttons
                    HStack(spacing: Spacing.sm) {
                        actionButton(icon: "arrow.up.circle.fill", label: "Send") {
                            showCryptoWithdraw = true
                        }
                        actionButton(icon: "arrow.down.circle.fill", label: "Receive") {
                            showReceiveQR = true
                        }
                        if wallet.linkedBankAccount != nil {
                            actionButton(icon: "building.2.fill", label: "To Bank") {
                                showBankWithdraw = true
                            }
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
            }

            // Wallet address
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wallet Address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(truncatedAddress(walletAddress))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = walletAddress
                    addressCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { addressCopied = false }
                } label: {
                    Image(systemName: addressCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(addressCopied ? .success : .gold)
                        .animation(.spring(), value: addressCopied)
                }
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)
            .cornerRadius(Layout.cardCornerRadius)

            // Linked bank account
            if let bank = wallet.linkedBankAccount {
                linkedBankRow(bank: bank)
            } else {
                linkBankButton
            }
        }
    }

    // MARK: - Bank views

    private func linkedBankRow(bank: DwollaFundingSource) -> some View {
        HStack {
            Image(systemName: "building.2.fill")
                .foregroundColor(.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(bank.name)
                    .font(.footnote.weight(.medium))
                if let last4 = bank.lastFour {
                    Text("••\(last4) · \(bank.type.capitalized)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(bank.status.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(.success)
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
    }

    private var linkBankButton: some View {
        Button {
            Task { await viewModel.fetchPlaidLinkToken() }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill").foregroundColor(.gold)
                Text("Link Bank Account")
                    .font(.body.weight(.medium))
                    .foregroundColor(.gold)
                Spacer()
                Text("Instant ACH via Dwolla")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)
            .cornerRadius(Layout.cardCornerRadius)
        }
    }

    // MARK: - Withdraw sheets

    private var cryptoWithdrawSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Amount (USDT)")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $viewModel.withdrawAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(.title3, design: .monospaced))
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(Layout.buttonCornerRadius)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Destination Address")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                    TextField("0x...", text: $viewModel.withdrawAddress)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(Layout.buttonCornerRadius)
                }
                GoldButton("Withdraw USDT", isLoading: viewModel.withdrawIsLoading) {
                    let success = await viewModel.withdrawCrypto()
                    if success { showCryptoWithdraw = false }
                }
                Spacer()
            }
            .padding(Layout.screenMargin)
            .navigationTitle("Send USDT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCryptoWithdraw = false }
                }
            }
        }
    }

    private var bankWithdrawSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                if let bank = viewModel.wallet?.linkedBankAccount {
                    HStack {
                        Image(systemName: "building.2.fill").foregroundColor(.success)
                        Text("To \(bank.name) ••\(bank.lastFour ?? "")")
                            .font(.body.weight(.medium))
                    }
                    .padding(Spacing.md)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(Layout.cardCornerRadius)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Amount (USD)")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $viewModel.withdrawAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(.title3, design: .monospaced))
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(Layout.buttonCornerRadius)
                }
                Text("ACH transfers typically arrive in 1-2 business days.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                GoldButton("Withdraw to Bank", isLoading: viewModel.withdrawIsLoading) {
                    if let id = viewModel.wallet?.linkedBankAccount?.id {
                        let success = await viewModel.withdrawToBank(fundingSourceId: id)
                        if success { showBankWithdraw = false }
                    }
                }
                Spacer()
            }
            .padding(Layout.screenMargin)
            .navigationTitle("ACH Withdrawal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBankWithdraw = false }
                }
            }
        }
    }

    private var receiveSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Text("Your Wallet Address")
                    .font(.headline)

                // QR code placeholder (real QR generation in polish pass)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 200, height: 200)
                    Image(systemName: "qrcode")
                        .font(.system(size: 140))
                        .foregroundColor(.black)
                }

                Text(walletAddress)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                GoldButton("Copy Address") {
                    UIPasteboard.general.string = walletAddress
                    showReceiveQR = false
                }
                .padding(.horizontal, Layout.screenMargin)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showReceiveQR = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private var walletPlaceholder: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
            .fill(Color.backgroundSecondary)
            .frame(height: 180)
            .shimmering()
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2).foregroundColor(.gold)
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func truncatedAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundColor(.primary)
    }
}
