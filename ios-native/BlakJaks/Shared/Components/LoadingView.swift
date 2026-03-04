import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.gold)
                .scaleEffect(1.2)
            Text(message)
                .font(BJFont.caption)
                .foregroundColor(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
    }
}

struct InlineLoadingView: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            ProgressView().tint(Color.gold)
            Text("Loading...")
                .font(BJFont.caption)
                .foregroundColor(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
    }
}
