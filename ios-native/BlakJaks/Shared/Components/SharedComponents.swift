import SwiftUI

// MARK: - InsightsLoadingView
// Inline spinner used within Insights sub-screens while data loads.

struct InsightsLoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView().tint(Color.gold).scaleEffect(1.1)
            Text("Loading...").font(BJFont.caption).foregroundColor(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - InsightsErrorView
// Inline error view used within Insights sub-screens.

struct InsightsErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(Color.error)
            Text(message)
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .font(BJFont.sora(12, weight: .semibold))
                .foregroundColor(Color.goldMid)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
    }
}
