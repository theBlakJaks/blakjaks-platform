import SwiftUI

// MARK: - NewMessageIndicator

/// Floating badge that appears when there are unread messages below the viewport.
/// Tapping it scrolls to the bottom.

struct NewMessageIndicator: View {

    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                Text(count == 1 ? "1 new message" : "\(count) new messages")
                    .font(BJFont.sora(12, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(Color.gold)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        }
    }
}
