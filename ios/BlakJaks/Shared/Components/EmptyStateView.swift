import SwiftUI

// MARK: - EmptyStateView
// icon + title + subtitle for empty list/section states.

struct EmptyStateView: View {
    let icon: String         // SF Symbol name
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.secondary)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.gold)
            }
        }
        .padding(Layout.screenMargin * 2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EmptyStateView(
            icon: "qrcode.viewfinder",
            title: "No Scans Yet",
            subtitle: "Scan your first BlakJaks product QR code to start earning USDC rewards.",
            actionTitle: "Scan Now",
            action: {}
        )

        EmptyStateView(
            icon: "bell.slash",
            title: "No Notifications",
            subtitle: "You're all caught up."
        )
    }
    .background(Color.backgroundPrimary)
}
