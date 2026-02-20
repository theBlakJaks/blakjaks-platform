import SwiftUI

@main
struct BlakJaksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Root ContentView (age gate + auth gate)

struct ContentView: View {
    @AppStorage("age_verified") private var ageVerified = false
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if !ageVerified {
                AgeGateView(isVerified: $ageVerified)
            } else if !isAuthenticated {
                WelcomeView(isAuthenticated: $isAuthenticated)
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 2  // Default to center Scan & Wallet tab

    var body: some View {
        TabView(selection: $selectedTab) {
            InsightsMenuView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(0)

            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(1)

            ScanWalletView()
                .tabItem {
                    Label("Scan & Wallet", systemImage: "suit.spade.fill")
                }
                .tag(2)

            SocialHubView()
                .tabItem {
                    Label("Social", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(Color("BrandGold"))
    }
}

// MARK: - Age Gate View (stub — implemented in I3)

struct AgeGateView: View {
    @Binding var isVerified: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Text("BlakJaks")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("BrandGold"))

                Text("Are you 21 or older?")
                    .font(.title2)
                    .foregroundColor(.white)

                HStack(spacing: 24) {
                    Button("Yes, I am 21+") {
                        isVerified = true
                    }
                    .padding()
                    .background(Color("BrandGold"))
                    .foregroundColor(.black)
                    .cornerRadius(12)

                    Button("No") {
                        if let url = URL(string: "https://www.google.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}
