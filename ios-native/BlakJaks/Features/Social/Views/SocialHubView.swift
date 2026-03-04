import SwiftUI

// MARK: - Static alert data (will be replaced by real notifications later)

private struct AlertItem: Identifiable {
    let id = UUID()
    let iconText: String
    let iconBg: Color
    let title: String
    let subtitle: String
    let time: String
    let isUnread: Bool
}

private let staticAlerts: [AlertItem] = [
    AlertItem(iconText: "₮",  iconBg: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.15),
              title: "Comp Payout Processed",
              subtitle: "$87.50 USDC sent to your wallet",
              time: "2h ago",   isUnread: false),
    AlertItem(iconText: "♠",  iconBg: Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.15),
              title: "Scan Milestone",
              subtitle: "You've hit 200 scans! VIP tier unlocked",
              time: "Yesterday", isUnread: false),
    AlertItem(iconText: "🏆", iconBg: Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.15),
              title: "New Proposal Active",
              subtitle: "Vote on flavor: Blue Razz vs Peach Mango",
              time: "3h ago",   isUnread: true)
]

// MARK: - SocialHubView

struct SocialHubView: View {

    @EnvironmentObject private var chatEngine: ChatEngine
    @StateObject private var vm = ChannelListViewModel()
    @State private var selectedTab: Int = 0          // 0 = Channels, 1 = Alerts
    @State private var selectedChannel: Channel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    tabBar
                    Divider().background(Color(white: 0.07))

                    ScrollView(showsIndicators: false) {
                        if selectedTab == 0 {
                            channelsContent
                        } else {
                            alertsContent
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("COMMUNITY")
                        .font(BJFont.sora(13, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Color.gold)
                }
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { selectedChannel != nil },
                    set: { if !$0 { selectedChannel = nil } }
                )
            ) {
                if let ch = selectedChannel {
                    if ch.roomType == "governance" {
                        GovernancePollView(channel: ch)
                    } else {
                        ChatView(channel: ch, engine: chatEngine)
                    }
                }
            }
            .task {
                await vm.loadChannels()
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(label: "Channels", index: 0)
            tabButton(label: "Alerts",   index: 1)
        }
        .padding(.horizontal, 4)
    }

    private func tabButton(label: String, index: Int) -> some View {
        let isActive = selectedTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = index }
        } label: {
            VStack(spacing: 0) {
                Text(label)
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(isActive ? Color.gold : Color(white: 0.27))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                Rectangle()
                    .fill(isActive ? Color.gold : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Channels Content

    private var channelsContent: some View {
        VStack(spacing: 2) {
            if vm.isLoading {
                ProgressView()
                    .tint(Color.gold)
                    .padding(Spacing.xl)
            } else if let error = vm.errorMessage {
                VStack(spacing: Spacing.md) {
                    Text("Failed to load channels")
                        .font(BJFont.sora(14, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                    Text(error)
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                    Button("Retry") {
                        Task { await vm.loadChannels() }
                    }
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.gold)
                }
                .padding(Spacing.xl)
            } else {
                ForEach(vm.channelsByCategory, id: \.category) { group in
                    categorySection(category: group.category, channels: group.channels)
                }
            }
        }
        .padding(.bottom, Spacing.xxxl)
    }

    private func categorySection(category: String, channels: [Channel]) -> some View {
        let isCollapsed = vm.collapsedCategories.contains(category)
        return VStack(spacing: 0) {
            // Category header
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    vm.toggleCategory(category)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isCollapsed ? "▶" : "▼")
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.27))

                    Text(category.uppercased())
                        .font(BJFont.outfit(11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.33))

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Channel items
            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(channels) { channel in
                        channelRow(channel)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private func channelRow(_ channel: Channel) -> some View {
        Button {
            guard !channel.isLocked else { return }
            selectedChannel = channel
        } label: {
            HStack(spacing: 8) {
                // Prefix icon
                Text(vm.channelPrefix(for: channel))
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.33))
                    .frame(width: 18, alignment: .center)

                // Channel name
                Text(channel.name)
                    .font(BJFont.outfit(14, weight: .medium))
                    .foregroundColor(channel.isLocked ? Color(white: 0.33) : Color(white: 0.53))
                    .lineLimit(1)

                Spacer()

                // Badges / lock
                HStack(spacing: 6) {
                    if (channel.unreadCount ?? 0) > 0 && !channel.isLocked {
                        unreadBadge((channel.unreadCount ?? 0))
                    }
                    if channel.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.27))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(ChannelRowButtonStyle())
        .opacity(channel.isLocked ? 0.5 : 1.0)
    }

    private func unreadBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Color.gold)
            .clipShape(Capsule())
            .frame(minWidth: 18)
    }

    // MARK: - Alerts Content

    private var alertsContent: some View {
        VStack(spacing: 0) {
            ForEach(staticAlerts) { alert in
                alertRow(alert)
                    .background(alert.isUnread ? Color.gold.opacity(0.03) : Color.clear)
            }
            Spacer(minLength: Spacing.xxxl)
        }
    }

    private func alertRow(_ alert: AlertItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(alert.iconBg)
                    .frame(width: 40, height: 40)

                Text(alert.iconText)
                    .font(.system(size: 16))
            }
            .fixedSize()

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(BJFont.outfit(13, weight: .semibold))
                    .foregroundColor(Color(white: 0.87))

                Text(alert.subtitle)
                    .font(BJFont.sora(11, weight: .regular))
                    .foregroundColor(Color(white: 0.4))
                    .fixedSize(horizontal: false, vertical: true)

                Text(alert.time)
                    .font(BJFont.sora(10, weight: .regular))
                    .foregroundColor(Color(white: 0.27))
                    .padding(.top, 1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .overlay(
            Divider()
                .background(Color(white: 0.05)),
            alignment: .bottom
        )
    }
}

// MARK: - ChannelRowButtonStyle

private struct ChannelRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.white.opacity(0.04)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Hashable conformances for navigation

extension LiveStream: Hashable {
    public static func == (lhs: LiveStream, rhs: LiveStream) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension GovernanceVote: Hashable {
    public static func == (lhs: GovernanceVote, rhs: GovernanceVote) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    SocialHubView()
        .environmentObject(AuthState())
        .environmentObject(ChatEngine())
        .preferredColorScheme(.dark)
}
