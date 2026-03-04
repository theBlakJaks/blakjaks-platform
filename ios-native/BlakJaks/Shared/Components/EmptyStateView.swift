import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(icon)
                .font(.system(size: 40))
            Text(title)
                .font(BJFont.subheading)
                .foregroundColor(Color.textPrimary)
            Text(subtitle)
                .font(BJFont.caption)
                .foregroundColor(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
