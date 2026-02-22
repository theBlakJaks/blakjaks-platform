import SwiftUI

// MARK: - ScanWalletView
// Center tab — the primary action hub. Scrollable, top to bottom:
// MemberCard → Scan Circle → Wallet → Transactions → Scan History → Comp Vault

struct ScanWalletView: View {
    @StateObject private var viewModel = ScanWalletViewModel(apiClient: MockAPIClient())
    @StateObject private var scannerVM = ScannerViewModel(apiClient: MockAPIClient())
    @State private var showScanModal = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.wallet == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            MemberCardView(memberCard: viewModel.memberCard)
                                .padding(.bottom, Spacing.xxl)

                            scanCircleButton
                                .padding(.bottom, Spacing.xxl)

                            WalletSectionView(viewModel: viewModel)
                                .padding(.bottom, Spacing.xl)

                            TransactionsView(viewModel: viewModel)
                                .padding(.bottom, Spacing.xl)

                            ScanHistoryView(scans: viewModel.scans)
                                .padding(.bottom, Spacing.xl)

                            CompVaultView(compVault: viewModel.compVault)
                        }
                        .padding(.top, Spacing.lg)
                    }
                    .refreshable { await viewModel.refresh() }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: Spacing.xl)
                    }
                }
            }
            .navigationTitle("Scan & Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadAll() }
            .fullScreenCover(isPresented: $showScanModal) {
                ScanModalView(viewModel: scannerVM, isPresented: $showScanModal)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }

    // MARK: - Scan Circle Button

    private var scanCircleButton: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                showScanModal = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.gold.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.gold.opacity(0.15), radius: 20)

                    Image(systemName: "suit.spade.fill")
                        .font(.system(.largeTitle, design: .default).weight(.medium))
                        .foregroundColor(.gold)
                }
            }
            .buttonStyle(ScaleButtonStyle())

            VStack(spacing: Spacing.xs) {
                Text("Tap to Scan")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("QR or NFC")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - ScaleButtonStyle (local)

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScanWalletView()
}
