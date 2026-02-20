import SwiftUI

// MARK: - SocialHubView
// Root shell for the Social tab. Hosts the channel drawer, chat area, and live stream bar.

struct SocialHubView: View {

    @StateObject private var socialVM = SocialViewModel()
    @StateObject private var notifVM = NotificationViewModel()

    @State private var showChannelDrawer = false
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MARK: Main content
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: LIVE bar — gold bottom banner
                if socialVM.currentLiveStream?.isLive == true,
                   let stream = socialVM.currentLiveStream {
                    NavigationLink(destination: LiveStreamView(stream: stream, socialVM: socialVM)) {
                        liveBanner
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // MARK: Channel drawer overlay
                if showChannelDrawer {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { showChannelDrawer = false } }

                    HStack(spacing: 0) {
                        ChannelListDrawerView(socialVM: socialVM, isPresented: $showChannelDrawer)
                            .frame(width: 280)
                            .offset(x: showChannelDrawer ? 0 : -280)
                            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showChannelDrawer)
                        Spacer()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Left — hamburger (opens channel drawer)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showChannelDrawer = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 17, weight: .medium))
                    }
                }

                // Center — title
                ToolbarItem(placement: .principal) {
                    Text(socialVM.selectedChannel.map { "#\($0.name)" } ?? "Social")
                        .font(.headline)
                }

                // Right — bell with unread badge
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 17, weight: .medium))
                            if notifVM.unreadCount > 0 {
                                Text("\(min(notifVM.unreadCount, 99))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.info)
                                    .clipShape(Capsule())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NavigationStack {
                    NotificationCenterView(notifVM: notifVM)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { socialVM.error != nil },
                set: { _ in socialVM.clearError() }
            )) {
                Button("OK", role: .cancel) { socialVM.clearError() }
            } message: {
                Text(socialVM.error?.localizedDescription ?? "Something went wrong.")
            }
            .task {
                await socialVM.loadChannels()
                await notifVM.loadNotifications()
                // Auto-select first channel if none selected
                if socialVM.selectedChannel == nil, let first = socialVM.channels.first {
                    await socialVM.selectChannel(first)
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if let channel = socialVM.selectedChannel {
            ChatView(socialVM: socialVM, channel: channel)
        } else if socialVM.isLoadingChannels {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundPrimary)
        } else {
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: "No Channels",
                subtitle: "Tap the menu to select a channel.",
                actionTitle: "Open Channels"
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showChannelDrawer = true
                }
            }
            .background(Color.backgroundPrimary)
        }
    }

    // MARK: - Live Banner

    private var liveBanner: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.failure)
                .frame(width: 8, height: 8)
            Text("LIVE — tap to watch")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black.opacity(0.6))
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.vertical, Spacing.sm)
        .background(Color.gold)
        .clipShape(Capsule())
        .padding(.horizontal, Layout.screenMargin)
        .padding(.bottom, Spacing.sm)
        .shadow(color: Color.gold.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    SocialHubView()
}
