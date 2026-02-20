import SwiftUI

// MARK: - PayoutChoiceSheet
// Presented after a comp is awarded that requires a payout choice.
// User picks: Send to MetaMask (crypto), Send to Bank (ACH), or Choose Later.

struct PayoutChoiceSheet: View {
    let comp: CompEarned
    let onChoice: (String) -> Void  // method: "crypto" | "bank" | "later"

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.sm)

                // Header
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.gold.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gold)
                    }
                    Text("+$\(comp.amount.formatted(.number.precision(.fractionLength(2))))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.gold)
                    Text("Comp Earned!")
                        .font(.title3.weight(.semibold))
                    Text("Choose how you'd like to receive this comp.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Divider()
                    .padding(.horizontal, Layout.screenMargin)

                // Choices
                VStack(spacing: Spacing.sm) {
                    choiceButton(
                        icon: "bitcoinsign.circle.fill",
                        title: "Send to MetaMask",
                        subtitle: "Add to crypto balance · Withdraw anytime",
                        method: "crypto",
                        color: .gold
                    )
                    choiceButton(
                        icon: "building.2.fill",
                        title: "Send to Bank",
                        subtitle: "Add to ACH balance · 1-2 business days",
                        method: "bank",
                        color: .success
                    )
                    choiceButton(
                        icon: "clock.fill",
                        title: "Choose Later",
                        subtitle: "Decide at withdrawal screen",
                        method: "later",
                        color: .secondary
                    )
                }
                .padding(.horizontal, Layout.screenMargin)

                Spacer()
            }
            .padding(.top, Spacing.lg)
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("How do you want your comp?")
                        .font(.headline)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func choiceButton(icon: String, title: String, subtitle: String, method: String, color: Color) -> some View {
        Button {
            onChoice(method)
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)
            .cornerRadius(Layout.cardCornerRadius)
        }
    }
}

// MARK: - Preview

#Preview {
    PayoutChoiceSheet(
        comp: CompEarned(id: "mock-uuid", amount: 100.00, status: "pending_choice", requiresPayoutChoice: true)
    ) { method in
        print("Chose: \(method)")
    }
}
