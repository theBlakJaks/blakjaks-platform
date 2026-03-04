import SwiftUI

// MARK: - TypingIndicator

/// Shows "user is typing..." or "user1, user2 are typing..." with animated dots.

struct TypingIndicator: View {

    let usernames: [String]

    @State private var dotPhase = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        if !usernames.isEmpty {
            HStack(spacing: 4) {
                dots
                Text(label)
                    .font(BJFont.sora(11, weight: .regular))
                    .foregroundColor(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 4)
            .transition(.opacity)
            .onReceive(timer) { _ in
                dotPhase = (dotPhase + 1) % 4
            }
        }
    }

    // MARK: - Animated Dots

    private var dots: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.textTertiary)
                    .frame(width: 4, height: 4)
                    .opacity(dotPhase > i ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.2), value: dotPhase)
            }
        }
    }

    // MARK: - Label

    private var label: String {
        switch usernames.count {
        case 1:
            return "\(usernames[0]) is typing"
        case 2:
            return "\(usernames[0]) and \(usernames[1]) are typing"
        default:
            return "\(usernames[0]) and \(usernames.count - 1) others are typing"
        }
    }
}
