import Foundation

// MARK: - Message Segment

enum MessageSegment: Identifiable {
    case text(String)
    case emote(CachedEmote, zeroWidth: Bool)

    var id: String {
        switch self {
        case .text(let s): return "t_\(s.hashValue)"
        case .emote(let e, _): return "e_\(e.id)_\(UUID().uuidString.prefix(4))"
        }
    }
}

// MARK: - EmoteParser

enum EmoteParser {

    /// Splits message content into text and emote segments.
    /// Exact case-sensitive match against emoteMap, split by whitespace.
    static func parseToSegments(_ content: String, emoteMap: [String: CachedEmote]) -> [MessageSegment] {
        guard !emoteMap.isEmpty else { return [.text(content)] }

        let words = content.split(separator: " ", omittingEmptySubsequences: false)
        var segments: [MessageSegment] = []
        var textBuffer = ""

        for word in words {
            let wordStr = String(word)
            if let emote = emoteMap[wordStr] {
                // Flush text buffer
                if !textBuffer.isEmpty {
                    segments.append(.text(textBuffer))
                    textBuffer = ""
                }
                segments.append(.emote(emote, zeroWidth: emote.zeroWidth))
            } else {
                if !textBuffer.isEmpty { textBuffer += " " }
                textBuffer += wordStr
            }
        }

        if !textBuffer.isEmpty {
            segments.append(.text(textBuffer))
        }

        return segments
    }

    /// Case-insensitive prefix match for autocomplete.
    static func prefixMatchEmotes(_ prefix: String, emoteList: [CachedEmote], limit: Int = 5) -> [CachedEmote] {
        let lower = prefix.lowercased()
        return emoteList
            .filter { $0.name.lowercased().hasPrefix(lower) }
            .prefix(limit)
            .map { $0 }
    }
}
