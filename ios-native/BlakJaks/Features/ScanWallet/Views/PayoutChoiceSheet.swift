import SwiftUI

// MARK: - PayoutChoiceSheet
// Bottom sheet allowing the member to choose between USDC Wallet and Bank Transfer
// when a comp has been earned that requires an explicit payout method selection.

struct PayoutChoiceSheet: View {

    @ObservedObject var vm: ScanWalletViewModel
    let comp: CompEarned
    let onComplete: () -> Void

    @State private var selectedMethod: PayoutMethod = .usdc
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    enum PayoutMethod: String, CaseIterable {
        case usdc = "usdc"
        case bank = "bank"

        var displayTitle: String {
            switch self {
            case .usdc: return "USDC Wallet"
            case .bank: return "Bank Transfer"
            }
        }

        var description: String {
            switch self {
            case .usdc: return "Sent to your Polygon wallet"
            case .bank: return "ACH via Dwolla (2–3 business days)"
            }
        }

        var icon: String {
            switch self {
            case .usdc: return "bitcoinsign.circle"
            case .bank: return "building.columns"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.borderGold)
                    .frame(width: 40, height: 3)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xl)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        headerSection
                        optionCards
                        confirmSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("COMP EARNED")
                .font(BJFont.eyebrow)
                .tracking(4)
                .foregroundColor(Color.textTertiary)

            Text("Choose Payout Method")
                .font(BJFont.playfair(24, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)

            // Comp amount callout
            Text(comp.amount.usdFormatted)
                .font(BJFont.outfit(40, weight: .heavy))
                .foregroundStyle(LinearGradient.goldShimmer)
                .padding(.vertical, Spacing.xs)

            Text("Select how you'd like to receive your comp.")
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Option Cards

    private var optionCards: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(PayoutMethod.allCases, id: \.self) { method in
                payoutOptionCard(method)
            }
        }
    }

    private func payoutOptionCard(_ method: PayoutMethod) -> some View {
        let isSelected = selectedMethod == method

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedMethod = method
            }
        } label: {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.gold.opacity(0.15) : Color.bgCard)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().stroke(
                                isSelected ? Color.gold.opacity(0.5) : Color.borderGold,
                                lineWidth: isSelected ? 1.2 : 0.5
                            )
                        )
                    Image(systemName: method.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? Color.gold : Color.textSecondary)
                }

                // Text info
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayTitle)
                        .font(BJFont.sora(15, weight: .semibold))
                        .foregroundColor(isSelected ? Color.textPrimary : Color.textSecondary)

                    Text(method.description)
                        .font(BJFont.caption)
                        .foregroundColor(isSelected ? Color.textSecondary : Color.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.gold : Color.borderGold, lineWidth: isSelected ? 1.5 : 0.8)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.gold)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(
                        isSelected ? Color.gold.opacity(0.6) : Color.borderGold,
                        lineWidth: isSelected ? 1.2 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(
                color: isSelected ? Color.gold.opacity(0.12) : Color.clear,
                radius: 12
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        VStack(spacing: Spacing.md) {
            // Error message
            if let err = errorMessage {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(Color.error)
                    Text(err)
                        .font(BJFont.caption)
                        .foregroundColor(Color.error)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Color.error.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(Color.error.opacity(0.25), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }

            // Summary line
            HStack {
                Text("Payout method:")
                    .font(BJFont.caption)
                    .foregroundColor(Color.textTertiary)
                Spacer()
                Text(selectedMethod.displayTitle)
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.goldMid)
            }
            .padding(.horizontal, 4)

            GoldButton(
                title: "Confirm Payout",
                action: submitChoice,
                isLoading: isSubmitting
            )

            Text("This selection is final once confirmed.")
                .font(BJFont.micro)
                .tracking(0.5)
                .foregroundColor(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Submit

    private func submitChoice() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await vm.submitPayoutChoice(compId: comp.id, method: selectedMethod.rawValue)
                await vm.loadWallet()
                onComplete()
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

#Preview {
    let sampleComp = CompEarned(
        id: "comp-abc-123",
        amount: 250.00,
        status: "pending",
        requiresPayoutChoice: true
    )
    PayoutChoiceSheet(
        vm: ScanWalletViewModel(),
        comp: sampleComp,
        onComplete: {}
    )
    .background(Color.bgPrimary)
}
