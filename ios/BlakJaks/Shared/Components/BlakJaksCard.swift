import SwiftUI

// MARK: - BlakJaksCard
// Elevated card with 16pt radius.
// Usage: BlakJaksCard { content }

struct BlakJaksCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Layout.cardPadding)
            .background(Color.backgroundSecondary)
            .cornerRadius(Layout.cardCornerRadius)
    }
}

// MARK: - GoldAccentCard (with gold top border)

struct GoldAccentCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gold)
                .frame(height: 3)
            content
                .padding(Layout.cardPadding)
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(Layout.cardCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Wallet Balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$1,250.75")
                    .font(.walletBalanceSmall)
            }
        }

        GoldAccentCard {
            Text("VIP Member")
                .font(.brandTitle2)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}
