import SwiftUI

// MARK: - MessageSegment

private enum MessageSegment {
    case text(String)
    case emote(CachedEmote, zeroWidth: Bool)
}

// MARK: - EmoteParsedMessageView
// Mirror of EmoteParsedMessage.tsx.
// Splits a message string on whitespace, replaces known emote names with inline
// AsyncImage cells, and flows the mixed text + image tokens using a custom Layout.

struct EmoteParsedMessageView: View {
    let content: String
    var emoteSize: CGFloat = 20

    @ObservedObject private var emoteService = EmoteService.shared

    private var segments: [MessageSegment] {
        parseSegments(content: content, emotes: emoteService.emotes)
    }

    var body: some View {
        SegmentFlowView(segments: segments, emoteSize: emoteSize)
    }

    // MARK: - Segment Parser

    private func parseSegments(
        content: String,
        emotes: [String: CachedEmote]
    ) -> [MessageSegment] {
        guard !content.isEmpty, !emotes.isEmpty else {
            return [.text(content)]
        }

        let tokens = content.components(separatedBy: .whitespaces)
        var result: [MessageSegment] = []
        var prevWasEmote = false

        for (i, token) in tokens.enumerated() {
            if let emote = emotes[token] {
                // Zero-width emotes overlap the preceding emote when consecutive
                let isZeroWidth = emote.zeroWidth && prevWasEmote
                result.append(.emote(emote, zeroWidth: isZeroWidth))
                prevWasEmote = true
            } else {
                // Preserve inter-token space for all but the final token
                let text = i < tokens.count - 1 ? token + " " : token
                result.append(.text(text))
                prevWasEmote = false
            }
        }
        return result
    }
}

// MARK: - SegmentFlowView

private struct SegmentFlowView: View {
    let segments: [MessageSegment]
    let emoteSize: CGFloat

    var body: some View {
        FlowSegmentLayout(spacing: 2) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let value):
                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)

                case .emote(let emote, _):
                    AnimatedEmoteView(
                        url: EmoteService.emoteURL(id: emote.id, size: "2x"),
                        size: emoteSize
                    )
                    .frame(width: emoteSize, height: emoteSize)
                }
            }
        }
    }
}

// MARK: - FlowSegmentLayout
// A custom SwiftUI Layout that wraps children left-to-right, breaking to a new
// row when a child would exceed the available width — analogous to CSS flex-wrap.

private struct FlowSegmentLayout: SwiftUI.Layout {
    var spacing: CGFloat = 2

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        EmoteParsedMessageView(content: "Hello world no emotes here")
        EmoteParsedMessageView(content: "Nice play KEKW that was wild PogChamp")
        EmoteParsedMessageView(content: "Plain text message with no known tokens")
    }
    .padding()
}
