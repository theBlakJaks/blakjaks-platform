import SwiftUI

// MARK: - MainTabView
// Root tab bar matching the mockup's 5-tab bottom nav:
// Insights · Scan & Wallet · Shop · Social · Profile

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InsightsMenuView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(0)

            ScanWalletView()
                .tabItem { Label("Wallet", systemImage: "qrcode.viewfinder") }
                .tag(1)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag.fill") }
                .tag(2)

            SocialHubView()
                .tabItem { Label("Social", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(3)

            ProfileView()
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
