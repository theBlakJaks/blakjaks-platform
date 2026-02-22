import SwiftUI
import AVKit

// MARK: - LiveStreamView
// HLS live stream player with inline chat overlay.
// When stream.isLive == false: shows an offline placeholder.

struct LiveStreamView: View {

    let stream: LiveStream
    @ObservedObject var socialVM: SocialViewModel

    @State private var showChat = true
    @State private var player: AVPlayer? = nil

    // Fallback channel for the live stream chat
    private var liveChannel: Channel {
        socialVM.selectedChannel ?? Channel(
            id: 0,
            name: "live",
            category: "community",
            description: "Live stream chat",
            memberCount: stream.viewerCount,
            lastMessageAt: nil
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Video Player Area
            ZStack(alignment: .top) {
                videoArea

                // Top HUD — LIVE badge top-left, viewer count top-right
                if stream.isLive {
                    HStack {
                        liveBadge
                        Spacer()
                        viewerCountBadge
                    }
                    .padding(Spacing.sm)
                }

                // Show/hide chat chevron (bottom-right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showChat.toggle()
                            }
                        } label: {
                            Image(systemName: showChat ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .shadow(color: .black.opacity(0.5), radius: 3)
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .padding(Spacing.sm)
                    }
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .background(Color(UIColor.systemBackground).opacity(0))
            // Dark container for video area — use a system color that reads as near-black in dark mode
            .background(Color(UIColor.label).opacity(0.95))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showChat)

            // MARK: Chat area
            if showChat {
                ChatView(socialVM: socialVM, channel: liveChannel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Spacer()
            }
        }
        .background(Color.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(stream.title)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
        .onAppear {
            if stream.isLive, let hlsUrlString = stream.hlsUrl,
               let hlsUrl = URL(string: hlsUrlString) {
                player = AVPlayer(url: hlsUrl)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    // MARK: - Video Area

    @ViewBuilder
    private var videoArea: some View {
        if stream.isLive, let _ = stream.hlsUrl, let player {
            VideoPlayer(player: player)
        } else {
            // Offline placeholder — dark background is intentional for video container
            ZStack {
                Color(UIColor.label).opacity(0.95)

                VStack(spacing: Spacing.md) {
                    Image(systemName: "video.slash.fill")
                        .font(.largeTitle.weight(.light))
                        .foregroundColor(.secondary)

                    Text("Stream Offline")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("Check back soon")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Live Badge
    // Color.error background, white text, .caption font, top-left per spec

    private var liveBadge: some View {
        Text("LIVE")
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.error)
            .clipShape(Capsule())
    }

    // MARK: - Viewer Count Badge
    // Color.backgroundSecondary.opacity(0.8) pill, SF Symbol person.2.fill, top-right per spec

    private var viewerCountBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "person.2.fill")
                .font(.caption)
            Text("\(stream.viewerCount)")
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.primary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.backgroundSecondary.opacity(0.8))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LiveStreamView(
            stream: MockLiveStream.live,
            socialVM: SocialViewModel(apiClient: MockAPIClient())
        )
    }
}
