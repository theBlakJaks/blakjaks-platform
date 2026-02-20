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
            ZStack(alignment: .topLeading) {
                videoArea

                // Overlaid badges (top-left)
                if stream.isLive {
                    HStack(spacing: Spacing.sm) {
                        liveBadge
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
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.5), radius: 3)
                        }
                        .padding(Spacing.sm)
                    }
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .background(Color.black)
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
            // Offline placeholder
            ZStack {
                Color.black

                VStack(spacing: Spacing.md) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)

                    Text("Stream Offline")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)

                    Text("Check back soon")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Live Badge

    private var liveBadge: some View {
        Text("● LIVE")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.failure)
            .clipShape(Capsule())
    }

    // MARK: - Viewer Count Badge

    private var viewerCountBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "eye.fill")
                .font(.system(size: 10))
            Text("\(stream.viewerCount)")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
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
