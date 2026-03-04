import SwiftUI

// MARK: - LazyView
// Defers initialization of a view until it is first rendered,
// preventing all 5 tabs from being eagerly created at launch.

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) { self.build = build }
    var body: some View { build() }
}

// MARK: - MainTabView
// Root tab bar matching the mockup's 5-tab bottom nav:
// Insights · Scan & Wallet · Shop · Social · Profile

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LazyView(InsightsMenuView())
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(0)

            LazyView(ScanWalletView())
                .tabItem { Label("Wallet", systemImage: "qrcode.viewfinder") }
                .tag(1)

            LazyView(ShopView())
                .tabItem { Label("Shop", systemImage: "bag.fill") }
                .tag(2)

            LazyView(SocialHubView())
                .tabItem { Label("Social", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(3)

            LazyView(ProfileView())
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color.gold)
        .onAppear { styleTabBar() }
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bgPrimary)
        // Subtle gold top border
        appearance.shadowColor = UIColor(Color.goldMid.opacity(0.25))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
