import SwiftUI

// MARK: - EmotePicker

/// Keyboard-replacement emote picker panel. Shows emote grid immediately
/// (no search required). Sits below the input bar, same position as keyboard.
/// Stays open for multiple selections (Twitch-style).

struct EmotePicker: View {

    @ObservedObject var store: EmoteStore
    let onSelect: (CachedEmote) -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var searchPage = 0
    @State private var searchDebounce: DispatchWorkItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.textTertiary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 4)

            // Search bar
            searchBar

            Divider().background(Color.borderSubtle)

            // Emote grid
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                    if !searchText.isEmpty {
                        searchResultsSection
                    } else {
                        if store.isLoading {
                            HStack {
                                Spacer()
                                ProgressView().tint(Color.gold)
                                Spacer()
                            }
                            .padding(Spacing.xl)
                        } else {
                            if !store.recentlyUsed.isEmpty {
                                emoteSection(title: "RECENTLY USED", emotes: store.recentlyUsed)
                            }
                            if !store.emoteList.isEmpty {
                                emoteSection(title: "7TV EMOTES", emotes: store.emoteList)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }

            // Bottom bar: ABC button to switch back to keyboard
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Text("ABC")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(Color.bgPrimary)
        }
        .background(Color.bgPrimary)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(Color.textTertiary)

            TextField("Search emotes...", text: $searchText)
                .font(.system(size: 13))
                .foregroundColor(Color.textPrimary)
                .tint(Color.goldMid)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { newValue in
                    searchDebounce?.cancel()
                    guard !newValue.isEmpty else {
                        store.searchResults = []
                        return
                    }
                    let work = DispatchWorkItem { [newValue] in
                        Task {
                            searchPage = 0
                            await store.searchOnline(query: newValue, page: 0)
                        }
                    }
                    searchDebounce = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    store.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if store.isSearching && store.searchResults.isEmpty {
                HStack {
                    Spacer()
                    ProgressView().tint(Color.gold)
                    Spacer()
                }
                .padding(Spacing.lg)
            } else if store.searchResults.isEmpty && !store.isSearching {
                Text("No emotes found")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textTertiary)
                    .padding(Spacing.lg)
            } else {
                emoteGrid(store.searchResults)

                if !store.isSearching && store.searchResults.count >= 20 && store.searchResults.count % 20 == 0 {
                    Button {
                        searchPage += 1
                        Task { await store.searchOnline(query: searchText, page: searchPage) }
                    } label: {
                        Text("Load More")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.gold)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.xs)
                    }
                }

                if store.isSearching && !store.searchResults.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView().tint(Color.gold).scaleEffect(0.7)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Emote Section

    private func emoteSection(title: String, emotes: [CachedEmote]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color.textTertiary)
                .padding(.leading, 2)

            emoteGrid(emotes)
        }
    }

    private func emoteGrid(_ emotes: [CachedEmote]) -> some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(emotes) { emote in
                emoteCell(emote)
            }
        }
    }

    private func emoteCell(_ emote: CachedEmote) -> some View {
        Group {
            if let url = emote.url(size: "2x") {
                AnimatedImageView(url: url, height: 36)
                    .frame(width: 36, height: 36)
                    .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bgCard)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(4)
        .contentShape(Rectangle())
        .onTapGesture {
            store.markUsed(emote)
            onSelect(emote)
        }
    }
}
