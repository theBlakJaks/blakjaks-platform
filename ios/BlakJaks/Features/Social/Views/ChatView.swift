import SwiftUI
import UIKit

// MARK: - ChatView
// Full-featured chat view with message grouping, reactions, translation, and a composer.

struct ChatView: View {

    @ObservedObject var socialVM: SocialViewModel
    let channel: Channel

    // MARK: - State

    @State private var replyTo: ChatMessage? = nil
    @State private var showEmotePicker = false
    @State private var showGiphyPicker = false
    @State private var showReactionPicker: Int? = nil  // messageId
    @FocusState private var composerFocused: Bool
    @State private var isAtBottom = true
    @State private var translatedMessages: [Int: String] = [:]  // messageId → translated text

    private let fixedReactions = ["💯", "❤️", "😂", "✅", "❌"]

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pinned message banner
                if let pinned = socialVM.pinnedMessage {
                    pinnedBanner(pinned)
                }

                // Message list
                messageList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Composer
                composerBar
            }

            // New messages floating pill
            if !isAtBottom && socialVM.newMessageCount > 0 {
                newMessagesPill
                    .padding(.bottom, 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $showEmotePicker) {
            NavigationStack {
                EmotePickerView(selectedEmote: Binding(
                    get: { nil },
                    set: { emote in
                        if let emote {
                            socialVM.draftMessage += ":\(emote): "
                        }
                    }
                ))
            }
        }
        .sheet(isPresented: $showGiphyPicker) {
            NavigationStack {
                GiphyPickerView(selectedGifUrl: Binding(
                    get: { nil },
                    set: { url in
                        if let url {
                            socialVM.draftMessage += " \(url)"
                        }
                    }
                ))
            }
        }
    }

    // MARK: - Message List

    @ViewBuilder
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(socialVM.messages.enumerated()), id: \.element.id) { index, message in
                        let isGrouped = isMessageGrouped(at: index)
                        let showDateSeparator = shouldShowDateSeparator(at: index)

                        if showDateSeparator {
                            dateSeparatorPill(for: message)
                        }

                        if message.content.hasPrefix("[SYSTEM]") {
                            systemEventPill(message: message)
                        } else {
                            messageBubble(message: message, isGrouped: isGrouped, index: index)
                        }
                    }

                    // Bottom anchor for auto-scroll
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.bottom, Spacing.sm)
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("scroll")).maxY
                    )
                }
            )
            .coordinateSpace(name: "scroll")
            .onChange(of: socialVM.messages.count) { _ in
                if isAtBottom {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                } else {
                    socialVM.newMessageCount += 1
                }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .overlay(alignment: .bottom) {
                if !isAtBottom && socialVM.newMessageCount > 0 {
                    Button {
                        socialVM.newMessageCount = 0
                        isAtBottom = true
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    } label: {
                        newMessagesPill
                    }
                    .padding(.bottom, Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(message: ChatMessage, isGrouped: Bool, index: Int) -> some View {
        let isOwn = message.userId == socialVM.currentUserId
        let translated = translatedMessages[message.id]

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                if !isGrouped {
                    avatarCircle(message)
                } else {
                    // Placeholder to preserve alignment
                    Color.clear.frame(width: 32, height: 1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Header: name + tier + time (only shown for first in group)
                    if !isGrouped {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(message.userFullName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(tierColor(message.userTier))

                            tierPill(message.userTier)

                            Text(shortTime(message.createdAt))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Reply quote block
                    if message.content.hasPrefix("[REPLY]") {
                        replyQuoteBlock(content: message.content)
                    }

                    // Message content
                    let displayContent: String = {
                        var c = message.content
                        if c.hasPrefix("[REPLY]"), let range = c.range(of: "]") {
                            c = String(c[c.index(after: range.upperBound)...]).trimmingCharacters(in: .whitespaces)
                        }
                        return translated ?? c
                    }()

                    Text(displayContent)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Translation indicator
                    if translated != nil {
                        Text("Translated")
                            .font(.system(size: 10))
                            .foregroundColor(.info)
                            .italic()
                    }

                    // Reactions
                    if let reactions = message.reactionSummary, !reactions.isEmpty {
                        reactionRow(message: message, reactions: reactions)
                    }

                    // Inline reaction picker (shown on long press)
                    if showReactionPicker == message.id {
                        inlineReactionPicker(for: message)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, isGrouped ? 2 : Spacing.sm)
        }
        .contextMenu {
            Button {
                replyTo = message
                composerFocused = true
            } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showReactionPicker = showReactionPicker == message.id ? nil : message.id
                }
            } label: {
                Label("React", systemImage: "face.smiling")
            }

            Button {
                Task {
                    if let translated = await socialVM.translateMessage(message) {
                        translatedMessages[message.id] = translated
                    }
                }
            } label: {
                Label("Translate", systemImage: "character.bubble")
            }
        }
    }

    // MARK: - Reply Quote Block

    private func replyQuoteBlock(content: String) -> some View {
        // Parse: [REPLY to User: quoted text] actual message
        let inner: String = {
            if let start = content.firstIndex(of: "["),
               let end = content.firstIndex(of: "]") {
                return String(content[content.index(after: start)..<end])
            }
            return content
        }()

        return HStack(spacing: 0) {
            Rectangle()
                .fill(Color.gold)
                .frame(width: 3)
            Text(inner)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(4)
    }

    // MARK: - Reaction Row

    private func reactionRow(message: ChatMessage, reactions: [String: Int]) -> some View {
        FlowLayout(spacing: 4) {
            ForEach(reactions.sorted(by: { $0.value > $1.value }), id: \.key) { emoji, count in
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    Task {
                        await socialVM.addReaction(to: message, emoji: emoji)
                    }
                } label: {
                    Text("\(emoji) \(count)")
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Inline Reaction Picker

    private func inlineReactionPicker(for message: ChatMessage) -> some View {
        HStack(spacing: Spacing.sm) {
            ForEach(fixedReactions, id: \.self) { emoji in
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    Task {
                        await socialVM.addReaction(to: message, emoji: emoji)
                    }
                    withAnimation { showReactionPicker = nil }
                } label: {
                    Text(emoji)
                        .font(.title3)
                        .padding(Spacing.xs)
                }
            }
        }
        .padding(Spacing.xs)
        .background(Color.backgroundSecondary)
        .cornerRadius(20)
    }

    // MARK: - System Event Pill

    private func systemEventPill(message: ChatMessage) -> some View {
        let text = message.content.replacingOccurrences(of: "[SYSTEM]", with: "").trimmingCharacters(in: .whitespaces)
        return HStack {
            Spacer()
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 5)
                .background(Color.backgroundSecondary)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: - Date Separator Pill

    private func dateSeparatorPill(for message: ChatMessage) -> some View {
        HStack {
            Rectangle().fill(Color.backgroundSecondary).frame(height: 1)
            Text(formattedDate(message.createdAt))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.sm)
            Rectangle().fill(Color.backgroundSecondary).frame(height: 1)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Pinned Banner

    private func pinnedBanner(_ message: ChatMessage) -> some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Color.gold)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pinned Message")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gold)
                Text(message.content)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "pin.fill")
                .font(.system(size: 11))
                .foregroundColor(.gold)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.backgroundSecondary)
    }

    // MARK: - New Messages Pill

    private var newMessagesPill: some View {
        Text("↓ \(socialVM.newMessageCount) new message\(socialVM.newMessageCount == 1 ? "" : "s")")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.gold)
            .clipShape(Capsule())
            .shadow(color: Color.gold.opacity(0.4), radius: 6, x: 0, y: 3)
    }

    // MARK: - Composer Bar

    @ViewBuilder
    private var composerBar: some View {
        VStack(spacing: 0) {
            Divider()

            // Reply preview
            if let reply = replyTo {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption)
                        .foregroundColor(.gold)
                    Text("Replying to \(reply.userFullName)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button { replyTo = nil } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.backgroundSecondary)
            }

            // Composer HStack
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                // Emote button
                Button { showEmotePicker = true } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }

                // GIF button
                Button { showGiphyPicker = true } label: {
                    Text("GIF")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        )
                }

                // Text field + character counter
                VStack(alignment: .trailing, spacing: 2) {
                    TextField("Message #\(channel.name)", text: $socialVM.draftMessage, axis: .vertical)
                        .font(.system(size: 14))
                        .lineLimit(1...5)
                        .focused($composerFocused)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 8)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(20)

                    if socialVM.draftMessage.count > 400 {
                        Text("\(socialVM.draftMessage.count)/500")
                            .font(.system(size: 10))
                            .foregroundColor(socialVM.draftMessage.count >= 500 ? .failure : .secondary)
                    }
                }

                // Send button
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    Task { await socialVM.sendMessage() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(sendButtonDisabled ? Color.backgroundTertiary : Color.gold)
                            .frame(width: 36, height: 36)

                        if socialVM.isRateLimited {
                            Text("\(socialVM.rateLimitRemainingSeconds)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(sendButtonDisabled ? .secondary : .black)
                        }
                    }
                }
                .disabled(sendButtonDisabled)
                .animation(.easeInOut(duration: 0.2), value: socialVM.isRateLimited)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.backgroundPrimary)
        }
    }

    // MARK: - Helpers

    private var sendButtonDisabled: Bool {
        socialVM.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || socialVM.draftMessage.count > 500
            || socialVM.isRateLimited
    }

    private func isMessageGrouped(at index: Int) -> Bool {
        guard index > 0 else { return false }
        let prev = socialVM.messages[index - 1]
        let current = socialVM.messages[index]
        guard prev.userId == current.userId else { return false }
        let iso = ISO8601DateFormatter()
        guard let prevDate = iso.date(from: prev.createdAt),
              let currDate = iso.date(from: current.createdAt) else { return false }
        return currDate.timeIntervalSince(prevDate) < 60
    }

    private func shouldShowDateSeparator(at index: Int) -> Bool {
        guard index > 0 else { return false }
        let prev = socialVM.messages[index - 1]
        let current = socialVM.messages[index]
        let iso = ISO8601DateFormatter()
        guard let prevDate = iso.date(from: prev.createdAt),
              let currDate = iso.date(from: current.createdAt) else { return false }
        let cal = Calendar.current
        return !cal.isDate(prevDate, inSameDayAs: currDate)
    }

    private func formattedDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func shortTime(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: isoString) else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func tierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "vip": return .tierVIP
        case "highroller": return .tierHighRoller
        case "whale": return .tierWhale
        default: return .tierStandard
        }
    }

    private func avatarCircle(_ message: ChatMessage) -> some View {
        Circle()
            .fill(tierColor(message.userTier).opacity(0.2))
            .overlay(
                Text(String(message.userFullName.prefix(1)))
                    .font(.caption.weight(.bold))
                    .foregroundColor(tierColor(message.userTier))
            )
            .frame(width: 32, height: 32)
    }

    private func tierPill(_ tier: String) -> some View {
        Text(tier.uppercased())
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(tierColor(tier))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(tierColor(tier).opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - ScrollOffsetPreferenceKey

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - FlowLayout (wrapping HStack for reactions)

private struct FlowLayout: SwiftUI.Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - String Range Extension

private extension String.Index {
    var upperIndex: String.Index { self }
}

// MARK: - Preview

#Preview {
    let vm = SocialViewModel(apiClient: MockAPIClient())
    let channel = Channel(
        id: 1,
        name: "General",
        category: "community",
        description: "Main chat",
        memberCount: 1234,
        lastMessageAt: nil
    )
    return NavigationStack {
        ChatView(socialVM: vm, channel: channel)
            .navigationTitle("#general")
            .navigationBarTitleDisplayMode(.inline)
    }
}
