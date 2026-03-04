import SwiftUI

@main
struct BlakJaksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authState = AuthState()
    @StateObject private var chatEngine = ChatEngine()

    init() {
        // UserDefaults is wiped on app deletion; Keychain is not.
        // On a fresh install the flag is missing, so we clear any stale
        // keychain tokens left over from a previous install.
        let key = "bj_app_installed"
        if !UserDefaults.standard.bool(forKey: key) {
            // Move Keychain clear off the main thread to avoid blocking launch
            Task.detached(priority: .userInitiated) {
                KeychainManager.shared.clearAll()
            }
            UserDefaults.standard.set(true, forKey: key)
        }

    }

    // Auth flow (unauthenticated):
    //   UILaunchScreen → SplashOverlay → fade-to-black → WelcomeView (ENTER) → HubView (LOGIN / SIGN UP) → LoginView / SignupView
    // Auth flow (authenticated):
    //   UILaunchScreen → SplashOverlay → fade-to-black → MainTabView (Insights · Wallet · Shop · Social · Profile)

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Cythe frequency ook nowso i havthat fixed the globe but it madontent loads underneath the splash from the start.
                Group {
                    if authState.isAuthenticated {
                        MainTabView()
                    } else {
                        WelcomeView()
                    }
                }
                .environmentObject(authState)
                .environmentObject(chatEngine)

                // Splash overlay — matches the storyboard launch screen exactly
                // so the handoff from UILaunchScreen is seamless.
                if showSplash {
                    SplashOverlay {
                        showSplash = false
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                authState.chatEngine = chatEngine
            }
        }
    }
}

// MARK: - SplashOverlay
// Full-screen launch image that holds briefly then fades out smoothly.
// Uses UIKit snapshot approach to guarantee the image is visible from the very
// first frame — no async image loading race.

private struct SplashOverlay: View {
    var onComplete: () -> Void

    @State private var opacity: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Match storyboard background: #0A0A0A
                Color(red: 0.039, green: 0.039, blue: 0.039)

                Image("launch-screen-composite")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            // Hold briefly for seamless handoff, then fade out.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 0
                }
                // Remove from view tree after fade completes.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - AuthState
// Single source of truth for authentication state.
// The app always starts unauthenticated — there is no auto-login on launch.
// Tokens remain in the keychain so Face ID can quickly re-authenticate the
// user without a password, but an explicit login action is always required
// after the app is killed or fresh-installed.

final class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?

    /// Set by BlakJaksApp after init so auth state changes can connect/disconnect the engine.
    weak var chatEngine: ChatEngine?

    func signOut() {
        // Disconnect chat engine before clearing tokens
        Task { @MainActor in chatEngine?.disconnect() }
        // Clear keychain immediately and synchronously before anything async.
        // This guarantees tokens are gone even if the network call below fails.
        KeychainManager.shared.clearAll()
        isAuthenticated = false
        currentUser = nil
        // Best-effort server-side token invalidation — fire and forget.
        Task { try? await APIClient.shared.logout() }
    }

    func didAuthenticate(user: UserProfile? = nil) {
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentUser = user
            // Connect chat engine with current access token
            self.chatEngine?.connect {
                KeychainManager.shared.accessToken
            }
            // Pre-load emotes so they're ready before the picker opens
            Task { await EmoteStore.shared.initializeEmotes() }
        }
    }
}
