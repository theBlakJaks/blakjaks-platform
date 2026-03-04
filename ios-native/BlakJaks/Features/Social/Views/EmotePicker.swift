import SwiftUI

// MARK: - EmotePicker

/// Keyboard-replacement emote picker panel with two tabs:
/// "My Emotes" (persistent saved emotes) and "Search Emotes" (browse/search 7TV).

struct EmotePicker: View {

    enum EmoteTab { case myEmotes, searchEmotes }

    @ObservedObject var store: EmoteStore
    let onSelect: (CachedEmote) -> Void

    @State private var selectedTab: EmoteTab = .myEmotes
    @State private var searchText = ""
    @State private var searchPage = 0
    @State private var searchDebounce: DispatchWorkItem?
    @State private var savePromptEmote: CachedEmote?
    @State private var isEditing = false
    @State private var deletePromptEmote: CachedEmote?
    @State private var draggingEmote: CachedEmote?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.textTertiary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 4)

            // Tab bar
            tabBar

            Divider().background(Color.borderSubtle)

            // Content
            ZStack(alignment: .bottom) {
                if selectedTab == .myEmotes {
                    myEmotesContent
                } else {
                    searchEmotesContent
                }

                // Save prompt toast overlay
                if let emote = savePromptEmote {
                    savePromptView(emote: emote)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: savePromptEmote?.id)
        }
        .background(Color.bgPrimary)
        // Dismiss save prompt when switching tabs or selecting another emote
        .onChange(of: selectedTab) { _ in
            savePromptEmote = nil
        }
        // Delete confirmation alert
        .alert("Delete Emote", isPresented: Binding(
            get: { deletePromptEmote != nil },
            set: { if !$0 { deletePromptEmote = nil } }
        )) {
            Button("Yes", role: .destructive) {
                if let emote = deletePromptEmote {
                    store.removeFromSaved(emote)
                }
                deletePromptEmote = nil
            }
            Button("No", role: .cancel) {
                deletePromptEmote = nil
            }
        } message: {
            if let emote = deletePromptEmote {
                Text("Delete \"\(emote.name)\"?")
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "My Emotes", tab: .myEmotes)
            tabButton(title: "Search Emotes", tab: .searchEmotes)
        }
        .padding(.horizontal, Spacing.sm)
    }

    private func tabButton(title: String, tab: EmoteTab) -> some View {
        Button {
            selectedTab = tab
            if tab != .myEmotes { isEditing = false }
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(selectedTab == tab ? Color.gold : Color.textTertiary)
                Rectangle()
                    .fill(selectedTab == tab ? Color.gold : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - My Emotes Content

    private var myEmotesContent: some View {
        Group {
            if store.savedEmotes.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Spacer()
                    Text("No Emotes Saved")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                    Text("Search and save emotes to find them here")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textTertiary.opacity(0.7))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Edit hint
                    Text("Hold to rearrange or delete emotes")
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary.opacity(0.6))
                        .padding(.top, 6)
                        .padding(.bottom, 2)

                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(store.savedEmotes) { emote in
                                savedEmoteCell(emote)
                                    .onDrag {
                                        draggingEmote = emote
                                        return NSItemProvider(object: emote.id as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: EmoteDropDelegate(
                                        emote: emote,
                                        dragging: $draggingEmote,
                                        store: store
                                    ))
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .animation(.default, value: store.savedEmotes)
    }

    // MARK: - Saved Emote Cell (with jiggle + delete badge)

    private func savedEmoteCell(_ emote: CachedEmote) -> some View {
        ZStack(alignment: .topTrailing) {
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
            .opacity(draggingEmote?.id == emote.id ? 0.4 : 1.0)

            // Delete badge
            if isEditing {
                Button {
                    deletePromptEmote = emote
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 4, y: -4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                deletePromptEmote = emote
            } else {
                onSelect(emote)
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing.toggle()
            }
        }
    }

    // MARK: - Search Emotes Content

    private var searchEmotesContent: some View {
        VStack(spacing: 0) {
            searchBar

            Divider().background(Color.borderSubtle)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                        // Anchor for scroll-to-top (fixes search bug)
                        Color.clear
                            .frame(height: 0)
                            .id("emoteScrollTop")

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
                            } else if !store.emoteList.isEmpty {
                                emoteSection(title: "7TV EMOTES", emotes: store.emoteList)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                }
                .onChange(of: searchText) { _ in
                    withAnimation {
                        proxy.scrollTo("emoteScrollTop", anchor: .top)
                    }
                }
            }
        }
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
                emoteGrid(store.searchResults, fromSearch: true)

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

            emoteGrid(emotes, fromSearch: true)
        }
    }

    private func emoteGrid(_ emotes: [CachedEmote], fromSearch: Bool) -> some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(emotes) { emote in
                emoteCell(emote, fromSearch: fromSearch)
            }
        }
    }

    private func emoteCell(_ emote: CachedEmote, fromSearch: Bool) -> some View {
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
            // Dismiss any existing save prompt first (acts as "No")
            savePromptEmote = nil

            onSelect(emote)

            // Show save prompt for unsaved emotes in search tab
            if fromSearch && !store.isEmoteSaved(emote) {
                savePromptEmote = emote
            }
        }
    }

    // MARK: - Save Prompt Toast

    private func savePromptView(emote: CachedEmote) -> some View {
        HStack(spacing: Spacing.sm) {
            if let url = emote.url(size: "1x") {
                AnimatedImageView(url: url, height: 24)
                    .frame(width: 24, height: 24)
            }

            Text("Save \(emote.name)?")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                store.saveEmote(emote)
                withAnimation { savePromptEmote = nil }
            } label: {
                Text("Yes")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gold.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Button {
                withAnimation { savePromptEmote = nil }
            } label: {
                Text("No")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.borderSubtle, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: -2)
        .padding(.horizontal, Spacing.sm)
        .padding(.bottom, Spacing.xs)
    }
}

// MARK: - EmoteDropDelegate

struct EmoteDropDelegate: DropDelegate {
    let emote: CachedEmote
    @Binding var dragging: CachedEmote?
    let store: EmoteStore

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging.id != emote.id else { return }
        guard let fromIndex = store.savedEmotes.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = store.savedEmotes.firstIndex(where: { $0.id == emote.id }) else { return }
        withAnimation(.default) {
            store.moveSavedEmote(from: IndexSet(integer: fromIndex), to: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}
