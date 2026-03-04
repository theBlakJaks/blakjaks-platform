import SwiftUI
import AppTrackingTransparency

// MARK: - WelcomeView
// Matches app-mockup.html screen #s-welcome:
// - Full-screen #0A0A0A background
// - 3 animated vertical gold spotlight beams
// - 3 ambient gold glow blobs (pulsing)
// - BlakJaks logo image centered on screen
// - Gold "ENTER" CTA button pinned to bottom
// - Navigates to HubView on tap

struct WelcomeView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var showHub = false
    // Deferred so the first frame (logo + button) renders before Metal compiles
    // the blur shaders used by WelcomeBackground. Without this the launch screen
    // is held for several seconds while shader compilation blocks the main thread.
    // ChipParticleView (SceneKit/Metal) and LogoAnimationView are NOT gated —
    // SceneKit scenes initialise on first use with no blocking shader pre-warm.
    @State private var backgroundReady = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                // Show background only after the first frame is on screen.
                if backgroundReady {
                    WelcomeBackground()
                }

                // Chip canvas — CoreGraphics, no Metal shader compilation cost.
                ChipParticleView()

                // 3D animated logo via WKWebView.
                LogoAnimationView(width: 280)
                    .frame(width: 320, height: 180)

                // Bottom — ENTER button
                VStack {
                    Spacer()
                    NeonGoldButton("ENTER", tracking: 4, height: 52) { showHub = true }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationDestination(isPresented: $showHub) {
                HubView()
            }
            .task {
                // Yield to the run loop so SwiftUI commits the first frame,
                // then enable the Metal blur background.
                await Task.yield()
                backgroundReady = true
                // Request App Tracking Transparency once the screen is visible.
                // Must be called after app UI is presented — calling during
                // didFinishLaunching is silently ignored by iOS.
                // The system prompt only appears once; subsequent calls are no-ops.
                await requestTrackingAuthorization()
            }
        }
    }

    @MainActor
    private func requestTrackingAuthorization() async {
        guard #available(iOS 14, *) else { return }
        // Small pause so the welcome screen is fully visible before the
        // system dialog interrupts it.
        try? await Task.sleep(nanoseconds: 500_000_000)
        await ATTrackingManager.requestTrackingAuthorization()
    }
}

// MARK: - WelcomeBackground
// All animation @State lives here. Re-renders are scoped to this struct only.
// Blur is used for softness but frames are generously oversized so the blur
// fully dissipates before reaching the frame boundary — no clipped-edge pixelation.

private struct WelcomeBackground: View {
    // Spotlight sweep angles
    @State private var spot1Angle: Double = -8
    @State private var spot2Angle: Double = 0
    @State private var spot3Angle: Double = 8

    // Glow blob pulse scale
    @State private var glowScale1: CGFloat = 1.0
    @State private var glowScale2: CGFloat = 1.0
    @State private var glowScale3: CGFloat = 1.0

    private let W = UIScreen.main.bounds.width
    private let H = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            glowLayer
            spotlightLayer
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { startAnimations() }
    }

    // MARK: Glow blobs
    // Frame = gradient diameter + 3× blur radius on each side so blur never clips.
    // blur(r=60) needs +360 pt of frame padding → use ~500-600 pt frames.
    private var glowLayer: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.goldAmber.opacity(0.35),
                        Color.goldAmber.opacity(0.15),
                        Color.clear
                    ],
                    center: .center, startRadius: 0, endRadius: 150
                ))
                .frame(width: 600, height: 600)
                .blur(radius: 60)
                .scaleEffect(glowScale1)
                .position(x: 80, y: 80)

            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.goldAmber.opacity(0.30),
                        Color.goldAmber.opacity(0.12),
                        Color.clear
                    ],
                    center: .center, startRadius: 0, endRadius: 130
                ))
                .frame(width: 560, height: 560)
                .blur(radius: 60)
                .scaleEffect(glowScale2)
                .position(x: W + 75, y: H * 0.35)

            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.goldAmber.opacity(0.28),
                        Color.goldAmber.opacity(0.10),
                        Color.clear
                    ],
                    center: .center, startRadius: 0, endRadius: 110
                ))
                .frame(width: 500, height: 500)
                .blur(radius: 60)
                .scaleEffect(glowScale3)
                .position(x: W * 0.15, y: H - 80)
        }
    }

    // MARK: Spotlight beams
    // Width is wider than the visual beam so blur(r=30) has room to fade on both sides.
    private var spotlightLayer: some View {
        ZStack {
            SpotlightBeam()
                .frame(width: 220, height: H)
                .position(x: W * 0.10 + 110, y: H / 2)
                .rotationEffect(.degrees(spot1Angle), anchor: .top)

            SpotlightBeam()
                .frame(width: 220, height: H)
                .position(x: W * 0.50 + 110, y: H / 2)
                .rotationEffect(.degrees(spot2Angle), anchor: .top)

            SpotlightBeam()
                .frame(width: 220, height: H)
                .position(x: W * 0.90 + 110, y: H / 2)
                .rotationEffect(.degrees(spot3Angle), anchor: .top)
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            spot1Angle = 8
        }
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            spot2Angle = -6
        }
        withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
            spot3Angle = -8
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            glowScale1 = 1.18
        }
        withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
            glowScale2 = 1.14
        }
        withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
            glowScale3 = 1.12
        }
    }
}

// MARK: - SpotlightBeam
// Vertical gold gradient. Frame is wider than the visual beam so blur(r=30)
// fully feathers both side edges without clipping.

private struct SpotlightBeam: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.goldAmber.opacity(0.35), location: 0.00),
                .init(color: Color.goldAmber.opacity(0.20), location: 0.20),
                .init(color: Color.goldAmber.opacity(0.10), location: 0.40),
                .init(color: Color.clear,                   location: 0.60),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 30)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthState())
}
