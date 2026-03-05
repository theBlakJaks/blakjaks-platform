import Foundation

// MARK: - Message Segment

enum MessageSegment: Identifiable {
    case text(id: String, String)
    case emote(id: String, CachedEmote, zeroWidth: Bool)

    var id: String {
        switch self {
        case .text(let id, _): return id
        case .emote(let id, _, _): return id
        }
    }
}

// MARK: - EmoteParser

enum EmoteParser {

    /// Splits message content into text and emote segments.
    /// Exact case-sensitive match against emoteMap, split by whitespace.
    static func parseToSegments(_ content: String, emoteMap: [String: CachedEmote]) -> [MessageSegment] {
        guard !emoteMap.isEmpty else { return [.text(id: "t_0", content)] }

        let words = content.split(separator: " ", omittingEmptySubsequences: false)
        var segments: [MessageSegment] = []
        var textBuffer = ""
        var segmentIndex = 0

        for word in words {
            let wordStr = String(word)
            if let emote = emoteMap[wordStr] {
                // Flush text buffer
                if !textBuffer.isEmpty {
                    segments.append(.text(id: "t_\(segmentIndex)", textBuffer))
                    segmentIndex += 1
                    textBuffer = ""
                }
                segments.append(.emote(id: "e_\(emote.id)_\(segmentIndex)", emote, zeroWidth: emote.zeroWidth))
                segmentIndex += 1
            } else {
                if !textBuffer.isEmpty { textBuffer += " " }
                textBuffer += wordStr
            }
        }

        if !textBuffer.isEmpty {
            segments.append(.text(id: "t_\(segmentIndex)", textBuffer))
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
