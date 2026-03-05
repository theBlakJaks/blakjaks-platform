import SwiftUI

// MARK: - EmoteParsedText

/// Renders a chat message with inline emote images using a wrapping flow layout.

struct EmoteParsedText: View, Equatable {

    let content: String
    let emoteMap: [String: CachedEmote]

    static func == (lhs: EmoteParsedText, rhs: EmoteParsedText) -> Bool {
        lhs.content == rhs.content && lhs.emoteMap.count == rhs.emoteMap.count
    }

    var body: some View {
        let segments = EmoteParser.parseToSegments(content, emoteMap: emoteMap)

        if segments.count == 1, case .text(_, let s) = segments[0] {
            Text(s)
                .font(BJFont.body)
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            WrappingEmoteLayout {
                ForEach(segments) { segment in
                    switch segment {
                    case .text(_, let text):
                        ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, word in
                            Text(String(word))
                                .font(BJFont.body)
                                .foregroundColor(Color.textPrimary)
                        }
                    case .emote(_, let emote, _):
                        if let url = emote.url(size: "2x") {
                            AnimatedImageView(url: url, height: 28)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - WrappingEmoteLayout

/// Custom Layout that wraps children horizontally like a flow/flex-wrap layout.

struct WrappingEmoteLayout: Layout {

    var hSpacing: CGFloat = 4
    var vSpacing: CGFloat = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += lineHeight + vSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + hSpacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += lineHeight + vSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + hSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
