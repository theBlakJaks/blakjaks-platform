import SwiftUI

// MARK: - ReactionBar

/// Displays existing reactions as emoji badges and provides a quick picker on long-press.

struct ReactionBar: View {

    let reactions: [String: [String]]   // emoji → [userId]
    let currentUserId: String?
    let onToggle: (String) -> Void      // toggle add/remove for emoji

    @State private var showPicker = false

    private static let quickEmojis = ["👍", "❤️", "😂", "🔥", "💰", "🎰"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Existing reaction badges
            HStack(spacing: 4) {
                ForEach(sortedReactions, id: \.key) { emoji, userIds in
                    reactionBadge(emoji: emoji, userIds: userIds)
                }

                // "+" button to add a reaction
                addButton
            }

            // Quick picker (shown on long-press of "+")
            if showPicker {
                quickPicker
                    .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
    }

    // MARK: - Sorted Reactions

    private var sortedReactions: [(key: String, value: [String])] {
        reactions.sorted { $0.value.count > $1.value.count }
    }

    // MARK: - Reaction Badge

    private func reactionBadge(emoji: String, userIds: [String]) -> some View {
        let userReacted = currentUserId.map { userIds.contains($0) } ?? false
        return Button {
            onToggle(emoji)
        } label: {
            HStack(spacing: 3) {
                Text(emoji).font(.system(size: 13))
                Text("\(userIds.count)")
                    .font(BJFont.micro)
                    .foregroundColor(userReacted ? Color.gold : Color.textSecondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(userReacted ? Color.goldDim.opacity(0.12) : Color.bgCard)
            .overlay(
                Capsule().stroke(
                    userReacted ? Color.borderGold : Color.borderSubtle,
                    lineWidth: userReacted ? 1 : 0.5
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                showPicker.toggle()
            }
        } label: {
            Image(systemName: "face.smiling")
                .font(.system(size: 12))
                .foregroundColor(Color.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.bgCard)
                .overlay(Capsule().stroke(Color.borderSubtle, lineWidth: 0.5))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Picker

    private var quickPicker: some View {
        HStack(spacing: 4) {
            ForEach(Self.quickEmojis, id: \.self) { emoji in
                Button {
                    onToggle(emoji)
                    withAnimation(.easeOut(duration: 0.15)) {
                        showPicker = false
                    }
                } label: {
                    Text(emoji)
                        .font(.system(size: 22))
                        .padding(4)
                        .background(Color.bgCard)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.borderSubtle, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
