import SwiftUI

// MARK: - GiphyPicker

/// Sheet with search and 2-column grid of GIFs from Giphy API.
/// Selecting a GIF returns its URL for the message.

struct GiphyPicker: View {

    let onSelect: (String) -> Void   // returns the GIF URL

    @State private var searchText = ""
    @State private var gifs: [GiphyGif] = []
    @State private var isLoading = false
    @State private var searchDebounce: DispatchWorkItem?

    // Giphy public beta key — should be replaced with backend proxy in production
    private let apiKey = "GlVGYHkr3WSBnllca54iNt0yFbjz7L65"
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider().background(Color.borderSubtle)

                ScrollView(showsIndicators: false) {
                    if isLoading && gifs.isEmpty {
                        ProgressView().tint(Color.gold).padding(Spacing.xl)
                    } else if gifs.isEmpty {
                        Text("Search for GIFs")
                            .font(BJFont.sora(13, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                            .padding(Spacing.xl)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(gifs) { gif in
                                gifCell(gif)
                            }
                        }
                        .padding(Spacing.md)
                    }
                }
            }
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("GIFs")
                        .font(BJFont.sora(13, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Color.gold)
                }
            }
            .task {
                await loadTrending()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Color.textTertiary)

            TextField("Search GIFs...", text: $searchText)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textPrimary)
                .tint(Color.goldMid)
                .onChange(of: searchText) { newValue in
                    searchDebounce?.cancel()
                    let work = DispatchWorkItem { [newValue] in
                        Task {
                            if newValue.isEmpty {
                                await loadTrending()
                            } else {
                                await search(newValue)
                            }
                        }
                    }
                    searchDebounce = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await loadTrending() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
    }

    // MARK: - GIF Cell

    private func gifCell(_ gif: GiphyGif) -> some View {
        Button {
            onSelect(gif.fullUrl)
        } label: {
            AsyncImage(url: URL(string: gif.previewUrl)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                case .failure:
                    Color.bgCard.frame(height: 120)
                default:
                    Color.bgCard.frame(height: 120)
                        .overlay(ProgressView().tint(Color.gold).scaleEffect(0.6))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - API

    private func loadTrending() async {
        isLoading = true
        guard let url = URL(string: "https://api.giphy.com/v1/gifs/trending?api_key=\(apiKey)&limit=20&rating=pg-13") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GiphyResponse.self, from: data)
            gifs = response.data.map { GiphyGif(from: $0) }
        } catch {
            // Silently fail
        }
        isLoading = false
    }

    private func search(_ query: String) async {
        isLoading = true
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://api.giphy.com/v1/gifs/search?api_key=\(apiKey)&q=\(encoded)&limit=20&rating=pg-13") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GiphyResponse.self, from: data)
            gifs = response.data.map { GiphyGif(from: $0) }
        } catch {
            // Silently fail
        }
        isLoading = false
    }
}

// MARK: - Giphy Models

private struct GiphyGif: Identifiable {
    let id: String
    let previewUrl: String    // fixed_width_small for grid
    let fullUrl: String       // fixed_width for message

    init(from dto: GiphyDataItem) {
        self.id = dto.id
        self.previewUrl = dto.images.fixedWidthSmall?.url ?? dto.images.fixedWidth.url
        self.fullUrl = dto.images.fixedWidth.url
    }
}

private struct GiphyResponse: Codable {
    let data: [GiphyDataItem]
}

private struct GiphyDataItem: Codable {
    let id: String
    let images: GiphyImages
}

private struct GiphyImages: Codable {
    let fixedWidth: GiphyImage
    let fixedWidthSmall: GiphyImage?

    enum CodingKeys: String, CodingKey {
        case fixedWidth = "fixed_width"
        case fixedWidthSmall = "fixed_width_small"
    }
}

private struct GiphyImage: Codable {
    let url: String
}
