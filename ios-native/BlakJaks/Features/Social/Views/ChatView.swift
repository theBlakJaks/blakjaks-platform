import SwiftUI

// MARK: - ChatView

struct ChatView: View {

    let channel: Channel
    @EnvironmentObject private var chatEngine: ChatEngine
    @EnvironmentObject private var authState: AuthState
    @StateObject private var vm: ChatRoomViewModel
    private let emoteStore = EmoteStore.shared
    @State private var translatedMessages: [String: String] = [:]
    @State private var isTranslating: String? = nil
    @State private var showPinnedSheet = false
    @State private var frozenEmoteMap: [String: CachedEmote] = [:]

    init(channel: Channel, engine: ChatEngine) {
        self.channel = channel
        _vm = StateObject(wrappedValue: ChatRoomViewModel(
            channel: channel,
            engine: engine
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Session expired banner only
                ConnectionStatusBanner(
                    connectionState: chatEngine.connectionState,
                    onSignOut: { authState.signOut() }
                )

                messagesArea

                // Typing indicator
                TypingIndicator(usernames: vm.typingUsernames)

                MessageInputBar(
                    vm: vm,
                    emoteMap: frozenEmoteMap,
                    emoteList: emoteStore.emoteList,
                    emoteStore: emoteStore,
                    onSendGif: { gifUrl in Task { await vm.sendGif(gifUrl) } },
                    onMarkUsed: { emote in
                        emoteStore.markUsed(emote)
                        // Keep frozenEmoteMap in sync so messages render new emotes
                        if frozenEmoteMap[emote.name] == nil {
                            frozenEmoteMap[emote.name] = emote
                        }
                    }
                )
            }

            // New message indicator
            if vm.newMessageCount > 0 {
                NewMessageIndicator(count: vm.newMessageCount) {
                    // Will be scrolled by onChange
                    vm.setAtBottom(true)
                }
                .padding(.bottom, 80) // above input bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(channel.name)
                        .font(BJFont.sora(14, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    Text("\(channel.memberCount ?? 0) members")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showPinnedSheet = true
                } label: {
                    Image(systemName: "pin")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showPinnedSheet) {
            PinnedMessagesSheet(channelId: channel.id) { messageId in
                // Scroll to pinned message
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            async let loadMessages: () = vm.loadInitial()
            async let loadEmotes: () = emoteStore.initializeEmotes()
            _ = await (loadMessages, loadEmotes)
            frozenEmoteMap = emoteStore.emoteMap
        }
        .onDisappear {
            vm.onDisappear()
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Load more trigger
                    if vm.hasMoreHistory {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                Task { await vm.loadMore() }
                            }
                    }

                    if vm.isLoadingMore {
                        ProgressView()
                            .tint(Color.gold)
                            .padding(Spacing.md)
                    }

                    if vm.isLoading && vm.messages.isEmpty {
                        ProgressView()
                            .tint(Color.gold)
                            .padding(Spacing.xl)
                    }

                    // Catching up indicator
                    if vm.isCatchingUp {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(Color.goldMid)
                            Text("Catching up...")
                                .font(BJFont.sora(11, weight: .medium))
                                .foregroundColor(Color.goldMid)
                        }
                        .padding(Spacing.sm)
                    }

                    ForEach(vm.messages) { message in
                        let msgIndex = vm.messages.firstIndex(where: { $0.id == message.id })
                        let prevTimestamp: String? = {
                            guard let idx = msgIndex, idx > 0 else { return nil }
                            return vm.messages[idx - 1].createdAt
                        }()

                        // Date separator
                        if DateSeparatorHelper.shouldShowSeparator(current: message.createdAt, previous: prevTimestamp),
                           let date = DateSeparatorHelper.parseISO(message.createdAt) {
                            DateSeparatorView(date: date)
                        }

                        MessageRow(
                            message: message,
                            currentUserId: vm.currentUserId,
                            emoteMap: frozenEmoteMap,
                            translatedText: translatedMessages[message.id],
                            isTranslating: isTranslating == message.id,
                            onTranslate: {
                                isTranslating = message.id
                                Task {
                                    let result = await vm.translate(messageId: message.id)
                                    translatedMessages[message.id] = result
                                    isTranslating = nil
                                }
                            },
                            onReact: { emoji in
                                vm.toggleReaction(messageId: message.id, emoji: emoji)
                            },
                            onReply: {
                                vm.setReply(message)
                            },
                            onRetry: message.deliveryStatus == .failed ? {
                                if let key = message.idempotencyKey {
                                    chatEngine.retryMessage(key)
                                }
                            } : nil
                        )
                        .equatable()
                        .id(message.id)
                    }

                    // Anchor for scrolling to bottom
                    Color.clear
                        .frame(height: 1)
                        .id("bottom-anchor")
                }
                .padding(.vertical, Spacing.sm)
            }
            .onChange(of: vm.messages.count) { _ in
                guard vm.isUserAtBottom else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
        }
    }

}

#Preview {
    let engine = ChatEngine()
    NavigationStack {
        ChatView(channel: Channel(
            id: "preview-1",
            name: "General",
            description: "General discussion",
            category: "general",
            tierRequired: nil,
            locked: false,
            viewOnly: false,
            roomType: "chat",
            unreadCount: 0,
            memberCount: 1204
        ), engine: engine)
        .environmentObject(engine)
        .environmentObject(AuthState())
    }
    .preferredColorScheme(.dark)
}
