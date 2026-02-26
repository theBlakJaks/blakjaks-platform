import SwiftUI

// MARK: - EmotePickerView
// Real 7TV emote picker. Mirrors the webapp's EmotePicker component.
// Displays the global 7TV emote set in a grid, supports live search via the
// 7TV GQL API, and tracks recently used emotes.
//
// Backward-compatible with existing call sites: the @Binding var selectedEmote
// signature is preserved. An optional onSelect closure is also provided for
// callers that want the full CachedEmote value.

struct EmotePickerView: View {

    // Legacy binding kept for existing call sites in ChatView
    @Binding var selectedEmote: String?
    // Optional closure for callers that need the full emote object
    var onSelect: ((CachedEmote) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var emoteService = EmoteService.shared

    @State private var query = ""
    @State private var searchResults: [CachedEmote] = []
    @State private var searching = false
    @State private var searchPage = 1
    @State private var hasMore = false
    @State private var loadingMore = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)

    private var isSearching: Bool { query.count >= 2 }
    private var displayEmotes: [CachedEmote] { isSearching ? searchResults : emoteService.emoteList }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            recentlyUsedRow
            sectionLabel

            if emoteService.status == .loading && !isSearching {
                Spacer()
                ProgressView().frame(maxWidth: .infinity)
                Spacer()
            } else if searching {
                Spacer()
                ProgressView().frame(maxWidth: .infinity)
                Spacer()
            } else if displayEmotes.isEmpty {
                Spacer()
                Text(isSearching ? "No emotes found" : "No emotes loaded")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                emoteGrid
            }

            poweredByFooter
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Emotes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            await emoteService.initializeEmotes()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search all 7TV emotes...", text: $query)
                .font(.body)
                .onChange(of: query) { q in
                    handleSearch(q)
                }
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
        .padding(Spacing.md)
    }

    // MARK: - Recently Used Row

    @ViewBuilder
    private var recentlyUsedRow: some View {
        if !isSearching, !emoteService.recentlyUsed.isEmpty {
            let recentEmotes = emoteService.recentlyUsed.compactMap { emoteService.emotes[$0] }
            if !recentEmotes.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("RECENTLY USED")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.md)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(recentEmotes) { emote in
                                Button { select(emote) } label: {
                                    AnimatedEmoteView(
                                        url: EmoteService.emoteURL(id: emote.id, size: "2x"),
                                        size: 32
                                    )
                                    .frame(width: 40, height: 40)
                                }
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.bottom, Spacing.xs)
            }
        }
    }

    // MARK: - Section Label

    private var sectionLabel: some View {
        HStack {
            Text(isSearching
                 ? (searching
                    ? "Searching..."
                    : "\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                 : "Global 7TV")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }

    // MARK: - Emote Grid

    private var emoteGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(displayEmotes) { emote in
                    Button { select(emote) } label: {
                        AnimatedEmoteView(
                            url: EmoteService.emoteURL(id: emote.id, size: "2x"),
                            size: 40
                        )
                        .frame(width: 40, height: 40)
                        .padding(4)
                    }
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, Spacing.md)

            if isSearching && hasMore {
                Button(loadingMore ? "Loading..." : "Load More") {
                    Task { await loadMore() }
                }
                .disabled(loadingMore)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .padding(.vertical, Spacing.sm)
            }
        }
    }

    // MARK: - Footer

    private var poweredByFooter: some View {
        Text("Powered by 7TV")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(Spacing.sm)
    }

    // MARK: - Actions

    private func select(_ emote: CachedEmote) {
        emoteService.addRecentlyUsed(emote.name)
        emoteService.addEmote(emote)
        selectedEmote = emote.name   // legacy binding used by ChatView
        onSelect?(emote)
        dismiss()
    }

    private func handleSearch(_ q: String) {
        guard q.count >= 2 else {
            searchResults = []
            return
        }
        searching = true
        Task {
            let results = await emoteService.searchOnline(query: q, page: 1)
            searchResults = results
            searchPage = 1
            hasMore = results.count >= 16
            searching = false
        }
    }

    private func loadMore() async {
        guard !loadingMore else { return }
        loadingMore = true
        let next = searchPage + 1
        let more = await emoteService.searchOnline(query: query, page: next)
        searchResults += more
        searchPage = next
        hasMore = more.count >= 16
        loadingMore = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmotePickerView(selectedEmote: .constant(nil))
    }
}
