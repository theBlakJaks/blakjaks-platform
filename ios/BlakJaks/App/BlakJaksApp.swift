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

// MARK: - Root ContentView

struct ContentView: View {
    @AppStorage("age_verified") private var ageVerified = false
    @AppStorage("is_authenticated") private var isAuthenticated = false

    var body: some View {
        Group {
            if !ageVerified {
                AgeGateView(isVerified: $ageVerified)
            } else if !isAuthenticated {
                NavigationStack {
                    WelcomeView(isAuthenticated: $isAuthenticated)
                }
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Main Tab View with Center Bubble

struct MainTabView: View {
    @State private var selectedTab = 2  // Default: center Scan & Wallet tab

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                InsightsMenuView()
                    .tag(0)

                ShopView()
                    .tag(1)

                ScanWalletView()
                    .tag(2)

                SocialHubView()
                    .tag(3)

                ProfileView()
                    .tag(4)
            }

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar with Center Bubble

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("chart.bar.fill", "Insights"),
        ("bag.fill", "Shop"),
        ("suit.spade.fill", ""),     // Center bubble — no label
        ("bubble.left.and.bubble.right.fill", "Social"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab bar background
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    if index == 2 {
                        // Center: transparent spacer behind the bubble
                        Spacer()
                            .frame(maxWidth: .infinity)
                    } else {
                        tabButton(index: index)
                    }
                }
            }
            .frame(height: 60)
            .background(Color.backgroundSecondary.ignoresSafeArea(edges: .bottom))
            .overlay(
                Divider().frame(height: 0.5).foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )

            // Center bubble — ♠ spade, extends above tab bar
            Button {
                selectedTab = 2
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedTab == 2 ? Color.gold : Color.backgroundTertiary)
                        .frame(width: Layout.tabBarCenterBubbleSize, height: Layout.tabBarCenterBubbleSize)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)

                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(selectedTab == 2 ? .black : .secondary)
                }
            }
            .offset(y: -(Layout.tabBarCenterBubbleSize / 2 - 10))
        }
    }

    @ViewBuilder
    private func tabButton(index: Int) -> some View {
        let tab = tabs[index]
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? .gold : .secondary)
                if !tab.label.isEmpty {
                    Text(tab.label)
                        .font(.caption2)
                        .foregroundColor(selectedTab == index ? .gold : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Age Gate

struct AgeGateView: View {
    @Binding var isVerified: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Logo
                Text("BlakJaks")
                    .font(.brandLargeTitle)
                    .foregroundColor(.gold)

                Text("Premium Nicotine Products")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer().frame(height: Spacing.xl)

                // FDA Warning Banner — shown on splash per 21 CFR § 1143.3
                NicotineWarningBanner()

                Spacer().frame(height: Spacing.xl)

                Text("Are you 21 or older?")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                HStack(spacing: Spacing.md) {
                    Button {
                        if let url = URL(string: "https://www.google.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("No")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.buttonHeight)
                            .background(Color.backgroundTertiary)
                            .cornerRadius(Layout.buttonCornerRadius)
                    }

                    Button {
                        isVerified = true
                    } label: {
                        Text("Yes, I am 21+")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.buttonHeight)
                            .background(Color.gold)
                            .cornerRadius(Layout.buttonCornerRadius)
                    }
                }
                .padding(.horizontal, Layout.screenMargin)

                Text("By entering, you confirm you are 21 or older and agree to our Terms of Service.")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.screenMargin * 2)
            }
            .padding(.vertical, Spacing.xxl)
        }
    }
}
