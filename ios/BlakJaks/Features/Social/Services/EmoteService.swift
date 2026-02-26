import SwiftUI
import Combine

// MARK: - CachedEmote

struct CachedEmote: Identifiable, Codable {
    let id: String
    let name: String
    let animated: Bool
    let zeroWidth: Bool
}

// MARK: - EmoteStatus

enum EmoteStatus { case idle, loading, ready, error }

// MARK: - EmoteService
// Mirror of emote-store.ts. Fetches the global 7TV emote set, optionally via the
// backend proxy first (authenticated), then falls back to the direct 7TV API.

@MainActor
class EmoteService: ObservableObject {

    static let shared = EmoteService()

    @Published var emotes: [String: CachedEmote] = [:]
    @Published var emoteList: [CachedEmote] = []
    @Published var status: EmoteStatus = .idle
    @Published var recentlyUsed: [String] = []

    private let recentKey = "blakjaks_emote_recent"
    private let maxRecent = 24
    private let refreshInterval: TimeInterval = 30 * 60
    private var lastFetchedAt: Date? = nil

    // 7TV endpoints
    private let sevenTVGlobalURL = URL(string: "https://7tv.io/v3/emote-sets/global")!
    private let sevenTVGQLURL    = URL(string: "https://7tv.io/v3/gql")!

    // Backend base URL derived from the same Config the rest of the app uses.
    // Config.apiBaseURL is already the versioned base (e.g. https://api-dev.blakjaks.com/v1),
    // so we strip the path and use the scheme+host only to build /api/* routes.
    private var backendBaseURL: String {
        let base = Config.apiBaseURL
        if let scheme = base.scheme, let host = base.host {
            let port = base.port.map { ":\($0)" } ?? ""
            return "\(scheme)://\(host)\(port)"
        }
        return "https://api-dev.blakjaks.com"
    }

    private init() {
        recentlyUsed = (UserDefaults.standard.array(forKey: recentKey) as? [String]) ?? []
    }

    // MARK: - Emote CDN URL

    static func emoteURL(id: String, size: String = "2x") -> URL {
        // Use .gif so CGImageSource can decode animation frames on iOS
        URL(string: "https://cdn.7tv.app/emote/\(id)/\(size).gif")!
    }

    // MARK: - Initialize

    /// Fetches the global emote set. Calls the backend proxy first (uses the
    /// KeychainManager access token), then falls back to direct 7TV.
    func initializeEmotes() async {
        guard status != .loading else { return }
        if let last = lastFetchedAt, Date().timeIntervalSince(last) < refreshInterval { return }

        status = .loading

        // Attempt 1: backend proxy (authenticated)
        var data: EmoteSetResponse? = nil
        if let token = KeychainManager.shared.accessToken {
            var req = URLRequest(url: URL(string: "\(backendBaseURL)/api/emotes")!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let (d, res) = try? await URLSession.shared.data(for: req),
               (res as? HTTPURLResponse)?.statusCode == 200 {
                data = try? JSONDecoder().decode(EmoteSetResponse.self, from: d)
            }
        }

        // Attempt 2: direct 7TV global set
        if data == nil {
            if let (d, _) = try? await URLSession.shared.data(from: sevenTVGlobalURL) {
                data = try? JSONDecoder().decode(EmoteSetResponse.self, from: d)
            }
        }

        guard let data else {
            status = .error
            return
        }

        var map: [String: CachedEmote] = [:]
        var list: [CachedEmote] = []
        for e in data.emotes ?? [] {
            let emote = CachedEmote(
                id: e.id,
                name: e.name,
                animated: e.data?.animated ?? false,
                zeroWidth: ((e.data?.flags ?? 0) & 1) == 1
            )
            map[e.name] = emote
            list.append(emote)
        }
        list.sort { $0.name < $1.name }

        self.emotes = map
        self.emoteList = list
        self.status = .ready
        self.lastFetchedAt = Date()
    }

    // MARK: - Search (7TV GQL)

    /// Searches 7TV for emotes matching `query`. Tries the backend proxy first,
    /// then falls back to querying the 7TV GraphQL endpoint directly.
    func searchOnline(query: String, page: Int = 1) async -> [CachedEmote] {
        guard query.count >= 2 else { return [] }

        let gqlBody: [String: Any] = [
            "query": """
            query SearchEmotes($query: String!, $page: Int!, $limit: Int!) {
              emotes(query: $query, page: $page, limit: $limit) {
                items { id name flags animated }
              }
            }
            """,
            "variables": ["query": query, "page": page, "limit": 16]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: gqlBody) else { return [] }

        // Try backend proxy first (authenticated)
        if let token = KeychainManager.shared.accessToken {
            var req = URLRequest(url: URL(string: "\(backendBaseURL)/api/emotes/search")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.httpBody = bodyData
            if let (d, res) = try? await URLSession.shared.data(for: req),
               (res as? HTTPURLResponse)?.statusCode == 200,
               let result = try? JSONDecoder().decode(GQLSearchResponse.self, from: d) {
                return result.data?.emotes?.items?.map {
                    CachedEmote(
                        id: $0.id,
                        name: $0.name,
                        animated: $0.animated ?? false,
                        zeroWidth: (($0.flags ?? 0) & 1) == 1
                    )
                } ?? []
            }
        }

        // Fallback: direct 7TV GQL
        var req = URLRequest(url: sevenTVGQLURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData
        guard let (d, _) = try? await URLSession.shared.data(for: req),
              let result = try? JSONDecoder().decode(GQLSearchResponse.self, from: d) else { return [] }
        return result.data?.emotes?.items?.map {
            CachedEmote(
                id: $0.id,
                name: $0.name,
                animated: $0.animated ?? false,
                zeroWidth: (($0.flags ?? 0) & 1) == 1
            )
        } ?? []
    }

    // MARK: - Recently Used

    func addRecentlyUsed(_ name: String) {
        var updated = recentlyUsed.filter { $0 != name }
        updated.insert(name, at: 0)
        updated = Array(updated.prefix(maxRecent))
        recentlyUsed = updated
        UserDefaults.standard.set(updated, forKey: recentKey)
    }

    /// Inserts an emote obtained from search into the local cache so it can be
    /// rendered inline in messages even before the next full refresh.
    func addEmote(_ emote: CachedEmote) {
        guard emotes[emote.name] == nil else { return }
        emotes[emote.name] = emote
        emoteList.append(emote)
        emoteList.sort { $0.name < $1.name }
    }
}

// MARK: - Private API Response Models

private struct EmoteSetResponse: Decodable {
    let emotes: [EmoteEntry]?

    struct EmoteEntry: Decodable {
        let id: String
        let name: String
        let data: EmoteData?

        struct EmoteData: Decodable {
            let animated: Bool?
            let flags: Int?
        }
    }
}

private struct GQLSearchResponse: Decodable {
    let data: GQLData?

    struct GQLData: Decodable {
        let emotes: GQLEmotes?

        struct GQLEmotes: Decodable {
            let items: [GQLEmoteItem]?
        }
    }

    struct GQLEmoteItem: Decodable {
        let id: String
        let name: String
        let flags: Int?
        let animated: Bool?
    }
}
