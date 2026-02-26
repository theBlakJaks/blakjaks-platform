import SwiftUI
import AVKit

// MARK: - GiphyPickerView
// Fetches GIFs from the backend proxy (mirrors the webapp's GiphyPicker component).
// Trending:  GET {backendBaseURL}/api/giphy/trending          → { data: [GiphyGif] }
// Search:    GET {backendBaseURL}/api/giphy/search?q=…&limit=20 → { data: [GiphyGif] }

struct GiphyPickerView: View {
    @Binding var selectedGifUrl: String?
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var gifs: [GiphyGif] = []
    @State private var loading = false
    @State private var debounceTask: Task<Void, Never>? = nil

    // Derive the scheme+host from Config.apiBaseURL so that the Giphy proxy
    // routes (/api/giphy/…) resolve correctly regardless of environment.
    private var backendOrigin: String {
        let base = Config.apiBaseURL
        if let scheme = base.scheme, let host = base.host {
            if let port = base.port { return "\(scheme)://\(host):\(port)" }
            return "\(scheme)://\(host)"
        }
        return base.absoluteString
    }

    // Giphy API key from Info.plist (set via xcconfig GIPHY_API_KEY)
    private var giphyAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GIPHY_API_KEY") as? String ?? ""
    }

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search GIFs...", text: $query)
                    .font(.body)
                    .onChange(of: query) { q in
                        debounceTask?.cancel()
                        debounceTask = Task {
                            try? await Task.sleep(nanoseconds: 400_000_000)
                            guard !Task.isCancelled else { return }
                            await fetchSearch(q)
                        }
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                        Task { await fetchTrending() }
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

            // Section header
            HStack {
                Text(query.isEmpty ? "TRENDING" : "SEARCH")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xs)

            // Grid or placeholder states
            if loading {
                Spacer()
                ProgressView()
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if gifs.isEmpty {
                Spacer()
                Text(query.isEmpty ? "Could not load GIFs" : "No GIFs found")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(gifs) { gif in
                            Button {
                                // Prefer mp4 for animated playback in chat
                                selectedGifUrl = gif.images.fixedWidth.mp4 ?? gif.images.fixedWidth.url
                                dismiss()
                            } label: {
                                GifCellView(variant: gif.images.fixedWidthSmall)
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }

            Text("Powered by GIPHY")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(Spacing.sm)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("GIFs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .task { await fetchTrending() }
    }

    // MARK: - Fetch helpers

    private func fetchTrending() async {
        // Try backend proxy first; fall back to direct Giphy API
        let backendURL = "\(backendOrigin)/api/giphy/trending"
        let directURL = "https://api.giphy.com/v1/gifs/trending?api_key=\(giphyAPIKey)&limit=20&rating=g"
        await fetchWithFallback(primary: backendURL, fallback: directURL, isBackendProxy: true)
    }

    private func fetchSearch(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { await fetchTrending(); return }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let backendURL = "\(backendOrigin)/api/giphy/search?q=\(encoded)&limit=20"
        let directURL = "https://api.giphy.com/v1/gifs/search?api_key=\(giphyAPIKey)&q=\(encoded)&limit=20&rating=g"
        await fetchWithFallback(primary: backendURL, fallback: directURL, isBackendProxy: true)
    }

    private func fetchWithFallback(primary: String, fallback: String, isBackendProxy: Bool) async {
        loading = true
        defer { loading = false }

        if let result = await fetchURL(primary, addAuth: isBackendProxy) {
            gifs = result; return
        }
        // Backend unavailable — try direct Giphy API
        if !giphyAPIKey.isEmpty, let result = await fetchURL(fallback, addAuth: false) {
            gifs = result; return
        }
        gifs = []
    }

    private func fetchURL(_ urlString: String, addAuth: Bool) async -> [GiphyGif]? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        if addAuth, let token = KeychainManager.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        guard
            let (data, resp) = try? await URLSession.shared.data(for: req),
            (resp as? HTTPURLResponse)?.statusCode == 200,
            let decoded = try? JSONDecoder().decode(GiphyResponse.self, from: data)
        else { return nil }
        return decoded.data
    }
}

// MARK: - GifCellView
// Uses mp4 via AVPlayer for smooth looping animation.
// Falls back to AsyncImage (static) when mp4 is unavailable.

struct GifCellView: View {
    let variant: GiphyGif.GiphyImageVariant

    var body: some View {
        if let mp4 = variant.mp4, let url = URL(string: mp4) {
            LoopingVideoPlayer(url: url)
        } else if let url = URL(string: variant.url) {
            AsyncImage(url: url) { phase in
                if let img = phase.image { img.resizable().scaledToFill() }
                else { Color.backgroundSecondary.overlay(ProgressView()) }
            }
        } else {
            Color.backgroundSecondary
        }
    }
}

// MARK: - LoopingVideoPlayer
// UIViewRepresentable wrapping AVPlayerLayer — no controls, silent, loops forever.

struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {}
}

final class LoopingPlayerUIView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    init(url: URL) {
        super.init(frame: .zero)
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        playerLayer = layer
        player = queuePlayer
        queuePlayer.play()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

// MARK: - Models

struct GiphyGif: Identifiable, Decodable {
    let id: String
    let title: String
    let images: GiphyImages

    struct GiphyImages: Decodable {
        let fixedWidth: GiphyImageVariant
        let fixedWidthSmall: GiphyImageVariant

        enum CodingKeys: String, CodingKey {
            case fixedWidth      = "fixed_width"
            case fixedWidthSmall = "fixed_width_small"
        }
    }

    struct GiphyImageVariant: Decodable {
        let url: String
        let width: String
        let height: String
        let mp4: String?   // Giphy provides mp4 on all variants — use for animation
    }
}

private struct GiphyResponse: Decodable {
    let data: [GiphyGif]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GiphyPickerView(selectedGifUrl: .constant(nil))
    }
}
