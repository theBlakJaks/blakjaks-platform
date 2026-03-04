import SwiftUI
import AVKit

// MARK: - LiveStreamView

struct LiveStreamView: View {

    let stream: LiveStream
    @State private var player: AVPlayer?
    @State private var showChat = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                videoSection

                streamInfoSection
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(stream.title)
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { showChat.toggle() }
                } label: {
                    Image(systemName: showChat ? "bubble.left.fill" : "bubble.left")
                        .foregroundColor(Color.goldMid)
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    // MARK: - Video Section

    private var videoSection: some View {
        ZStack {
            if stream.isLive, let hlsUrl = stream.hlsUrl, let url = URL(string: hlsUrl) {
                // Live HLS player
                VideoPlayerRepresentable(player: player ?? AVPlayer(url: url))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(Color.black)
                    .overlay(alignment: .topLeading) {
                        liveBadge
                            .padding(Spacing.sm)
                    }
                    .overlay(alignment: .topTrailing) {
                        viewerBadge
                            .padding(Spacing.sm)
                    }
            } else {
                offlinePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(Color.black)
    }

    // MARK: - Offline Placeholder

    private var offlinePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.08), Color.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: Spacing.md) {
                Image(systemName: "play.slash.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.goldDim)

                Text(stream.title)
                    .font(BJFont.playfair(20, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                Text("Stream Offline")
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.error)

                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textTertiary)
                    Text(stream.hostName)
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
    }

    // MARK: - Stream Info

    private var streamInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(stream.title)
                .font(BJFont.playfair(22, weight: .bold))
                .foregroundColor(Color.textPrimary)

            HStack(spacing: Spacing.md) {
                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.goldMid)
                    Text(stream.hostName)
                        .font(BJFont.sora(13, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()

                if stream.isLive {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textTertiary)
                        Text("\(stream.viewerCount) watching")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)
                    }
                } else {
                    Text("Offline")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                }
            }

            Divider().background(Color.borderSubtle)
        }
    }

    // MARK: - Badges

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.error)
                .frame(width: 7, height: 7)
                .shadow(color: Color.error.opacity(0.8), radius: 4)
            Text("LIVE")
                .font(BJFont.micro)
                .tracking(2)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.error.opacity(0.85))
        .clipShape(Capsule())
        .shadow(radius: 4)
    }

    private var viewerBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "eye.fill")
                .font(.system(size: 10))
            Text("\(stream.viewerCount)")
                .font(BJFont.micro)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.65))
        .clipShape(Capsule())
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        guard stream.isLive, let hlsStr = stream.hlsUrl, let url = URL(string: hlsStr) else { return }
        let newPlayer = AVPlayer(url: url)
        newPlayer.play()
        player = newPlayer
    }
}

// MARK: - VideoPlayerRepresentable

struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: AVPlayerView, context: Context) {
        uiView.player = player
    }
}

// MARK: - AVPlayerView

final class AVPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
}

#Preview {
    NavigationStack {
        LiveStreamView(stream: LiveStream(
            id: 1,
            title: "VIP Lounge Live Q&A",
            hlsUrl: nil,
            viewerCount: 247,
            isLive: false,
            hostName: "BlakJaks Official",
            thumbnailUrl: nil
        ))
    }
    .preferredColorScheme(.dark)
}
