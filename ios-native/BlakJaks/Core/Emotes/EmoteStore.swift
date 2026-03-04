import Foundation

// MARK: - CachedEmote

struct CachedEmote: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let animated: Bool
    let zeroWidth: Bool

    func url(size: String = "2x") -> URL? {
        URL(string: "https://cdn.7tv.app/emote/\(id)/\(size).webp")
    }
}

// MARK: - EmoteState

struct EmoteState {
    var emoteMap: [String: CachedEmote] = [:]
    var emoteList: [CachedEmote] = []
    var recentlyUsed: [CachedEmote] = []
    var savedEmotes: [CachedEmote] = []
}

// MARK: - ImageDownloadThrottle

/// Limits concurrent image downloads across the app.
actor ImageDownloadThrottle {
    static let shared = ImageDownloadThrottle()

    private let maxConcurrent = 6
    private var active = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if active < maxConcurrent {
            active += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if let next = waiters.first {
            waiters.removeFirst()
            next.resume()
        } else {
            active -= 1
        }
    }

    func throttled<T>(_ work: @Sendable () async throws -> T) async rethrows -> T {
        await acquire()
        defer { Task { await release() } }
        return try await work()
    }
}

// MARK: - EmoteStore

/// Singleton emote store. Loads the 7TV global emote set plus top emotes,
/// caches them in memory and on disk, and tracks recently used emotes.

@MainActor
final class EmoteStore: ObservableObject {

    static let shared = EmoteStore()

    /// Consolidated state — reduces @Published cascade to a single property.
    /// Access emoteMap, emoteList, recentlyUsed through this.
    @Published private(set) var state = EmoteState()

    @Published private(set) var isLoading = false
    @Published var searchResults: [CachedEmote] = []
    @Published var isSearching = false

    // Public convenience accessors to preserve existing API
    var emoteMap: [String: CachedEmote] { state.emoteMap }
    var emoteList: [CachedEmote] { state.emoteList }
    var recentlyUsed: [CachedEmote] { state.recentlyUsed }
    var savedEmotes: [CachedEmote] { state.savedEmotes }

    private let maxRecent = 24
    private let recentKey = "com.blakjaks.chat.recentEmotes"
    private let savedEmotesKey = "com.blakjaks.chat.savedEmotes"
    private var reorderDebounce: DispatchWorkItem?
    private let diskCacheTTL: TimeInterval = 3600 // 1 hour

    private var diskCacheURL: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("emotes", isDirectory: true)
    }

    private var diskCacheFile: URL {
        diskCacheURL.appendingPathComponent("emote_metadata.json")
    }

    private var diskCacheTimestampFile: URL {
        diskCacheURL.appendingPathComponent("emote_cache_ts")
    }

    private init() {
        restoreRecents()
        restoreSavedEmotesLocally()
    }

    // MARK: - Initialize

    func initializeEmotes() async {
        // Always fetch saved emotes from server on init (source of truth)
        await loadSavedEmotes()

        guard state.emoteList.isEmpty else { return }
        isLoading = true

        // Try loading from disk cache first (instant)
        if let cached = loadFromDiskCache() {
            state.emoteList = cached
            state.emoteMap = Dictionary(cached.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
            isLoading = false
            resolveRecents()

            // Refresh from network in background
            Task { [weak self] in
                await self?.refreshFromNetwork()
            }
            return
        }

        await refreshFromNetwork()
        isLoading = false
    }

    private func refreshFromNetwork() async {
        // Fetch global emote set and top emotes in parallel
        async let globalResult = fetchGlobalEmoteSet()
        async let topResult = fetch7TVSearch(query: "", limit: 100, page: 0, category: "TOP")
        let (global, top) = await (globalResult, topResult)

        var emotes = global
        let existingIds = Set(emotes.map(\.id))
        for emote in top where !existingIds.contains(emote.id) {
            emotes.append(emote)
        }

        state.emoteList = emotes
        state.emoteMap = Dictionary(emotes.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        isLoading = false

        resolveRecents()
        saveToDiskCache(emotes)
    }

    // MARK: - Disk Cache

    private func saveToDiskCache(_ emotes: [CachedEmote]) {
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: diskCacheURL.path) {
                try fm.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
            }
            let data = try JSONEncoder().encode(emotes)
            try data.write(to: diskCacheFile, options: .atomic)
            // Write timestamp
            let ts = Date().timeIntervalSince1970
            try "\(ts)".write(to: diskCacheTimestampFile, atomically: true, encoding: .utf8)
        } catch {
            print("[EmoteStore] Failed to save disk cache: \(error)")
        }
    }

    private func loadFromDiskCache() -> [CachedEmote]? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: diskCacheFile.path),
              fm.fileExists(atPath: diskCacheTimestampFile.path) else { return nil }

        do {
            // Check TTL
            let tsString = try String(contentsOf: diskCacheTimestampFile, encoding: .utf8)
            guard let ts = TimeInterval(tsString) else { return nil }
            let age = Date().timeIntervalSince1970 - ts
            guard age < diskCacheTTL else { return nil }

            let data = try Data(contentsOf: diskCacheFile)
            return try JSONDecoder().decode([CachedEmote].self, from: data)
        } catch {
            print("[EmoteStore] Failed to load disk cache: \(error)")
            return nil
        }
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
        guard state.emoteMap[emote.name] == nil else { return }
        state.emoteMap[emote.name] = emote
        state.emoteList.append(emote)
    }

    // MARK: - Recently Used

    func markUsed(_ emote: CachedEmote) {
        addEmote(emote)
        state.recentlyUsed.removeAll { $0.id == emote.id }
        state.recentlyUsed.insert(emote, at: 0)
        if state.recentlyUsed.count > maxRecent {
            state.recentlyUsed = Array(state.recentlyUsed.prefix(maxRecent))
        }
        persistRecents()
    }

    // MARK: - Prefix Match

    func prefixMatch(_ prefix: String, limit: Int = 5) -> [CachedEmote] {
        let lower = prefix.lowercased()
        return state.emoteList
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

    // MARK: - Saved Emotes

    /// Loads saved emotes from the server. Falls back to local cache on failure.
    func loadSavedEmotes() async {
        do {
            let remote = try await APIClient.shared.getSavedEmotes()
            let emotes = remote.map { CachedEmote(id: $0.emoteId, name: $0.emoteName, animated: $0.animated, zeroWidth: $0.zeroWidth) }
            state.savedEmotes = emotes
            persistSavedEmotesLocally()
        } catch {
            // Fallback to local cache so emotes appear even while offline
            restoreSavedEmotesLocally()
            print("[EmoteStore] Failed to load saved emotes from server, using local cache: \(error)")
        }
    }

    func saveEmote(_ emote: CachedEmote) {
        guard !state.savedEmotes.contains(where: { $0.id == emote.id }) else { return }
        state.savedEmotes.insert(emote, at: 0)
        addEmote(emote)
        persistSavedEmotesLocally()
        // Sync to server
        Task {
            do {
                _ = try await APIClient.shared.saveEmote(emoteId: emote.id, emoteName: emote.name, animated: emote.animated, zeroWidth: emote.zeroWidth)
            } catch {
                print("[EmoteStore] Failed to save emote to server: \(error)")
            }
        }
    }

    func isEmoteSaved(_ emote: CachedEmote) -> Bool {
        state.savedEmotes.contains { $0.id == emote.id }
    }

    func removeFromSaved(_ emote: CachedEmote) {
        state.savedEmotes.removeAll { $0.id == emote.id }
        persistSavedEmotesLocally()
        // Sync to server
        Task {
            do {
                try await APIClient.shared.deleteSavedEmote(emoteId: emote.id)
            } catch {
                print("[EmoteStore] Failed to delete emote from server: \(error)")
            }
        }
    }

    func moveSavedEmote(from source: IndexSet, to destination: Int) {
        state.savedEmotes.move(fromOffsets: source, toOffset: destination)
        persistSavedEmotesLocally()
        // Sync order to server (debounced — user may drag multiple times)
        reorderDebounce?.cancel()
        let ids = state.savedEmotes.map(\.id)
        let work = DispatchWorkItem {
            Task {
                do {
                    try await APIClient.shared.reorderSavedEmotes(emoteIds: ids)
                } catch {
                    print("[EmoteStore] Failed to reorder emotes on server: \(error)")
                }
            }
        }
        reorderDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    /// Local cache — survives app restarts while offline, but server is source of truth.
    private func persistSavedEmotesLocally() {
        guard let data = try? JSONEncoder().encode(state.savedEmotes) else { return }
        UserDefaults.standard.set(data, forKey: savedEmotesKey)
    }

    private func restoreSavedEmotesLocally() {
        guard let data = UserDefaults.standard.data(forKey: savedEmotesKey),
              let emotes = try? JSONDecoder().decode([CachedEmote].self, from: data) else { return }
        state.savedEmotes = emotes
    }

    // MARK: - Persistence

    private func persistRecents() {
        let ids = state.recentlyUsed.map { $0.id }
        UserDefaults.standard.set(ids, forKey: recentKey)
    }

    private func restoreRecents() {
        // Just store IDs — resolve after emoteList loads
    }

    private func resolveRecents() {
        guard let ids = UserDefaults.standard.stringArray(forKey: recentKey) else { return }
        state.recentlyUsed = ids.compactMap { id in
            state.emoteList.first { $0.id == id }
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
