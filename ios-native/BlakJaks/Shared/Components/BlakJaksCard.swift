import SwiftUI

// MARK: - BlakJaksCard
// Dark card container with subtle gold border, matching the mockup's card style.

struct BlakJaksCard<Content: View>: View {
    let content: () -> Content
    var padding: CGFloat = Spacing.md

    init(padding: CGFloat = Spacing.md, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.borderGold, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

// MARK: - SectionHeader
// Eyebrow + title pattern used throughout the mockup.

struct SectionHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(BJFont.eyebrow)
                .tracking(4)
                .foregroundColor(Color.goldMid)
            Text(title)
                .font(BJFont.heading)
                .foregroundColor(Color.textPrimary)
        }
    }
}
