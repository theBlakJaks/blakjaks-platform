import Foundation

// MARK: - CachedEmote

struct CachedEmote: Identifiable, Hashable {
    let id: String
    let name: String
    let animated: Bool
    let zeroWidth: Bool

    func url(size: String = "2x") -> URL? {
        URL(string: "https://cdn.7tv.app/emote/\(id)/\(size).webp")
    }
}

// MARK: - EmoteStore

/// Singleton emote store. Loads the 7TV global emote set plus top emotes,
/// caches them in memory, and tracks recently used emotes.

@MainActor
final class EmoteStore: ObservableObject {

    static let shared = EmoteStore()

    @Published private(set) var emoteMap: [String: CachedEmote] = [:]
    @Published private(set) var emoteList: [CachedEmote] = []
    @Published private(set) var recentlyUsed: [CachedEmote] = []
    @Published private(set) var isLoading = false
    @Published var searchResults: [CachedEmote] = []
    @Published var isSearching = false

    private let maxRecent = 24
    private let recentKey = "com.blakjaks.chat.recentEmotes"

    private init() {
        restoreRecents()
    }

    // MARK: - Initialize

    func initializeEmotes() async {
        guard emoteList.isEmpty else { return }
        isLoading = true

        // 1) Fetch the 7TV global emote set (44 curated emotes)
        var emotes = await fetchGlobalEmoteSet()

        // 2) Supplement with TOP emotes (most popular across 7TV, max 100)
        let top = await fetch7TVSearch(query: "", limit: 100, page: 0, category: "TOP")
        let existingIds = Set(emotes.map(\.id))
        for emote in top where !existingIds.contains(emote.id) {
            emotes.append(emote)
        }

        emoteList = emotes
        emoteMap = Dictionary(emotes.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        isLoading = false

        resolveRecents()
    }

    // MARK: - Search Online

    func searchOnline(query: String, page: Int = 0) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        let results = await fetch7TVSearch(query: query, limit: 20, page: page)
        if page == 0 {
            searchResults = results
        } else {
            searchResults.append(contentsOf: results)
        }
        isSearching = false
    }

    // MARK: - Add Emote

    func addEmote(_ emote: CachedEmote) {
        guard emoteMap[emote.name] == nil else { return }
        emoteMap[emote.name] = emote
        emoteList.append(emote)
    }

    // MARK: - Recently Used

    func markUsed(_ emote: CachedEmote) {
        addEmote(emote)
        recentlyUsed.removeAll { $0.id == emote.id }
        recentlyUsed.insert(emote, at: 0)
        if recentlyUsed.count > maxRecent {
            recentlyUsed = Array(recentlyUsed.prefix(maxRecent))
        }
        persistRecents()
    }

    // MARK: - Prefix Match

    func prefixMatch(_ prefix: String, limit: Int = 5) -> [CachedEmote] {
        let lower = prefix.lowercased()
        return emoteList
            .filter { $0.name.lowercased().hasPrefix(lower) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - 7TV Global Emote Set (REST)

    private func fetchGlobalEmoteSet() async -> [CachedEmote] {
        guard let url = URL(string: "https://7tv.io/v3/emote-sets/global") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GlobalEmoteSetResponse.self, from: data)
            return response.emotes.map { emote in
                let animated = emote.data?.animated ?? false
                let flags = emote.data?.flags ?? 0
                let zeroWidth = flags & 256 != 0
                return CachedEmote(id: emote.id, name: emote.name, animated: animated, zeroWidth: zeroWidth)
            }
        } catch {
            print("[EmoteStore] Failed to fetch global emote set: \(error)")
            return []
        }
    }

    // MARK: - 7TV GraphQL Search

    private func fetch7TVSearch(query: String, limit: Int, page: Int = 0, category: String? = nil) async -> [CachedEmote] {
        guard let gqlURL = URL(string: "https://7tv.io/v3/gql") else { return [] }

        let escapedQuery = query.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let filterClause: String
        if let category {
            filterClause = ", filter: {category: \(category)}"
        } else {
            filterClause = ""
        }

        let gqlQuery = """
        { emotes(query: "\(escapedQuery)", limit: \(limit), page: \(page + 1)\(filterClause)) { items { id name animated flags } } }
        """

        var request = URLRequest(url: gqlURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": gqlQuery])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GQLSearchResponse.self, from: data)
            guard let emoteData = response.data else {
                print("[EmoteStore] GQL returned null data (errors in response)")
                return []
            }
            return emoteData.emotes.items.map { item in
                let zeroWidth = (item.flags ?? 0) & 256 != 0
                return CachedEmote(id: item.id, name: item.name, animated: item.animated, zeroWidth: zeroWidth)
            }
        } catch {
            print("[EmoteStore] 7TV search error: \(error)")
            return []
        }
    }

    // MARK: - Persistence

    private func persistRecents() {
        let ids = recentlyUsed.map { $0.id }
        UserDefaults.standard.set(ids, forKey: recentKey)
    }

    private func restoreRecents() {
        // Just store IDs — resolve after emoteList loads
    }

    private func resolveRecents() {
        guard let ids = UserDefaults.standard.stringArray(forKey: recentKey) else { return }
        recentlyUsed = ids.compactMap { id in
            emoteList.first { $0.id == id }
        }
    }
}

// MARK: - 7TV REST Global Emote Set DTOs

private struct GlobalEmoteSetResponse: Codable {
    let emotes: [GlobalEmoteEntry]
}

private struct GlobalEmoteEntry: Codable {
    let id: String
    let name: String
    let flags: Int?
    let data: GlobalEmoteData?
}

private struct GlobalEmoteData: Codable {
    let animated: Bool
    let flags: Int
}

// MARK: - 7TV GraphQL Search DTOs

private struct GQLSearchResponse: Codable {
    let data: GQLSearchData?
}

private struct GQLSearchData: Codable {
    let emotes: GQLEmoteResult
}

private struct GQLEmoteResult: Codable {
    let items: [GQLEmote]
}

private struct GQLEmote: Codable {
    let id: String
    let name: String
    let animated: Bool
    let flags: Int?
}
