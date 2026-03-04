import SwiftUI

// MARK: - MessageRow

struct MessageRow: View {

    let message: ChatMessage
    let currentUserId: String?
    let emoteMap: [String: CachedEmote]
    let translatedText: String?
    let isTranslating: Bool
    let onTranslate: () -> Void
    let onReact: (String) -> Void
    let onReply: () -> Void
    let onRetry: (() -> Void)?

    private static let defaultReactions = ["👍", "❤️", "😂", "🔥", "💰", "🎰"]

    var body: some View {
        if message.isSystem == true {
            systemRow
        } else {
            userMessageRow
        }
    }

    // MARK: - System Message

    private var systemRow: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(BJFont.sora(11, weight: .regular))
                .foregroundColor(Color.textTertiary)
                .italic()
                .padding(.vertical, Spacing.xs)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - User Message

    private var userMessageRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                avatarView
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    // Username + tier + timestamp
                    HStack(spacing: Spacing.xs) {
                        Text(message.username)
                            .font(BJFont.sora(12, weight: .semibold))
                            .foregroundColor(Color.goldMid)

                        if let tier = message.userTier, !tier.isEmpty {
                            TierBadge(tier: tier)
                        }

                        Spacer()

                        Text(shortTime(from: message.createdAt))
                            .font(BJFont.micro)
                            .foregroundColor(Color.textTertiary)
                    }

                    // Reply context
                    if message.replyToId != nil, let preview = message.replyPreview {
                        replyPreviewBanner(content: preview)
                    }

                    // Pinned indicator
                    if message.isPinned == true {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color.gold)
                            Text("Pinned")
                                .font(BJFont.micro)
                                .foregroundColor(Color.gold)
                        }
                    }

                    // GIF or text content
                    if let gifUrl = effectiveGifUrl {
                        gifContent(url: gifUrl)
                    } else if let translated = translatedText {
                        Text(translated)
                            .font(BJFont.body)
                            .foregroundColor(Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        EmoteParsedText(content: message.content, emoteMap: emoteMap)
                    }

                    // Translation status
                    if isTranslating {
                        HStack(spacing: 4) {
                            ProgressView()
                                .tint(Color.goldMid)
                                .scaleEffect(0.7)
                            Text("Translating...")
                                .font(BJFont.micro)
                                .foregroundColor(Color.textTertiary)
                        }
                    } else if translatedText != nil {
                        Text("Translated from original")
                            .font(BJFont.micro)
                            .foregroundColor(Color.textTertiary)
                            .italic()
                    }

                    // Reactions
                    if !message.reactionMap.isEmpty {
                        ReactionBar(
                            reactions: message.reactionMap,
                            currentUserId: currentUserId,
                            onToggle: { emoji in onReact(emoji) }
                        )
                    }

                    // Delivery status
                    deliveryIndicator
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    onReply()
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }
                Button {
                    onTranslate()
                } label: {
                    Label("Translate", systemImage: "globe")
                }
                Menu("React") {
                    ForEach(Self.defaultReactions, id: \.self) { emoji in
                        Button(emoji) { onReact(emoji) }
                    }
                }
                Button {
                    UIPasteboard.general.string = message.content
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Group {
            if let urlStr = message.avatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsAvatar
                }
            } else {
                initialsAvatar
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(Circle())
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.goldShimmer)
            Text(String(message.username.prefix(1)).uppercased())
                .font(BJFont.sora(13, weight: .bold))
                .foregroundColor(Color.bgPrimary)
        }
    }

    // MARK: - Reply Preview

    private func replyPreviewBanner(content: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.goldMid.opacity(0.4))
                .frame(width: 2)

            Text(content)
                .font(BJFont.sora(10, weight: .regular))
                .foregroundColor(Color.textTertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }

    // MARK: - GIF

    private var effectiveGifUrl: URL? {
        if let gif = message.gifUrl, let url = URL(string: gif) { return url }
        // Detect Giphy URLs in content
        let pattern = #"^https://media\d*\.giphy\.com/.+"#
        if message.content.range(of: pattern, options: .regularExpression) != nil,
           let url = URL(string: message.content) {
            return url
        }
        return nil
    }

    private func gifContent(url: URL) -> some View {
        AnimatedImageView(
            url: url,
            height: 200,
            maxWidth: 240,
            contentMode: .scaleAspectFit
        )
        .frame(maxWidth: 240, maxHeight: 200)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Delivery Indicator

    @ViewBuilder
    private var deliveryIndicator: some View {
        switch message.deliveryStatus {
        case .sending:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Color.textTertiary)
                Text("Sending...")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
        case .failed:
            Button {
                onRetry?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Text("Failed — Tap to retry")
                        .font(BJFont.micro)
                        .foregroundColor(.red)
                }
            }
        case .sent, .none:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private func shortTime(from iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) else { return "" }
        let display = DateFormatter()
        display.dateFormat = "h:mm a"
        return display.string(from: date)
    }
}

// MARK: - Equatable

extension MessageRow: Equatable {
    static func == (lhs: MessageRow, rhs: MessageRow) -> Bool {
        lhs.message.id == rhs.message.id &&
        lhs.message.reactions == rhs.message.reactions &&
        lhs.message.deliveryStatus == rhs.message.deliveryStatus &&
        lhs.translatedText == rhs.translatedText &&
        lhs.isTranslating == rhs.isTranslating &&
        lhs.emoteMap.count == rhs.emoteMap.count
    }
}
