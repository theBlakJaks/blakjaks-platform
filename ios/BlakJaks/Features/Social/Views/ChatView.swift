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

                // Composer pinned above keyboard/tab bar
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
        // Keeps composer above keyboard and tab bar
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
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

        return VStack(alignment: isOwn ? .trailing : .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Avatar only for incoming, ungrouped messages
                if !isOwn {
                    if !isGrouped {
                        avatarCircle(message)
                    } else {
                        Color.clear.frame(width: 32, height: 1)
                    }
                } else {
                    Spacer(minLength: 60)
                }

                VStack(alignment: isOwn ? .trailing : .leading, spacing: 3) {
                    // Header: name + tier + time (only shown for first in group)
                    if !isGrouped {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            if isOwn {
                                // Timestamp left of name for own messages
                                Text(shortTime(message.createdAt))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else {
                                // Username: Color.gold for high-tier users, .secondary otherwise
                                Text(message.userFullName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(isHighTierUser(message.userTier) ? Color.gold : .secondary)

                                // Tier badge inline with username
                                tierPill(message.userTier)

                                Text(shortTime(message.createdAt))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Reply quote block
                    if message.content.hasPrefix("[REPLY]") {
                        replyQuoteBlock(content: message.content)
                    }

                    // Message content — bubble styled per sender
                    let displayContent: String = {
                        var c = message.content
                        if c.hasPrefix("[REPLY]"), let range = c.range(of: "]") {
                            c = String(c[c.index(after: range.upperBound)...]).trimmingCharacters(in: .whitespaces)
                        }
                        return translated ?? c
                    }()

                    Text(displayContent)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            isOwn
                                ? Color.gold.opacity(0.2)
                                : Color.backgroundSecondary
                        )
                        // 16pt corner radius; flat corner on sender side (standard chat style)
                        .clipShape(
                            ChatBubbleShape(isOwn: isOwn)
                        )

                    // Translation indicator
                    if translated != nil {
                        Text("Translated")
                            .font(.caption2)
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
                .frame(maxWidth: .infinity, alignment: isOwn ? .trailing : .leading)

                // Spacer on the left for own messages to push right
                if isOwn {
                    if !isGrouped {
                        avatarCircle(message)
                    } else {
                        Color.clear.frame(width: 32, height: 1)
                    }
                } else {
                    Spacer(minLength: 60)
                }
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
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
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
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
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
                        // 44pt touch target
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
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
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.backgroundSecondary)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Date Separator Pill

    private func dateSeparatorPill(for message: ChatMessage) -> some View {
        HStack {
            Rectangle().fill(Color.backgroundSecondary).frame(height: 1)
            Text(formattedDate(message.createdAt))
                .font(.caption2.weight(.semibold))
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
                    .font(.caption.weight(.bold))
                    .foregroundColor(.gold)
                Text(message.content)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "pin.fill")
                .font(.caption)
                .foregroundColor(.gold)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.backgroundSecondary)
    }

    // MARK: - New Messages Pill

    private var newMessagesPill: some View {
        Text("↓ \(socialVM.newMessageCount) new message\(socialVM.newMessageCount == 1 ? "" : "s")")
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
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
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            // 44pt touch target
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.backgroundSecondary)
            }

            // Composer HStack
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                // Emote button — 44pt touch target
                Button { showEmotePicker = true } label: {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                // GIF button — 44pt touch target
                Button { showGiphyPicker = true } label: {
                    Text("GIF")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }

                // Text field (44pt height) + character counter
                VStack(alignment: .trailing, spacing: 2) {
                    TextField("Message #\(channel.name)", text: $socialVM.draftMessage, axis: .vertical)
                        .font(.body)
                        .lineLimit(1...5)
                        .focused($composerFocused)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .frame(minHeight: 44)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(Spacing.md)

                    if socialVM.draftMessage.count > 400 {
                        Text("\(socialVM.draftMessage.count)/500")
                            .font(.caption2)
                            .foregroundColor(socialVM.draftMessage.count >= 500 ? .error : .secondary)
                    }
                }

                // Send button — Color.gold, SF Symbol paperplane.fill, 44pt minimum touch target
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    Task { await socialVM.sendMessage() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(sendButtonDisabled ? Color.backgroundTertiary : Color.gold)
                            .frame(width: 44, height: 44)

                        if socialVM.isRateLimited {
                            Text("\(socialVM.rateLimitRemainingSeconds)")
                                .font(.callout.weight(.bold))
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.callout.weight(.semibold))
                                .foregroundColor(sendButtonDisabled ? .secondary : .primary)
                        }
                    }
                }
                .disabled(sendButtonDisabled)
                .animation(.easeInOut(duration: 0.2), value: socialVM.isRateLimited)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.backgroundSecondary)
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

    /// High-tier users get Color.gold username label per spec
    private func isHighTierUser(_ tier: String) -> Bool {
        switch tier.lowercased() {
        case "vip", "highroller", "whale": return true
        default: return false
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
            .font(.caption2.weight(.bold))
            .foregroundColor(tierColor(tier))
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(tierColor(tier).opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - ChatBubbleShape
// 16pt corners everywhere; flat bottom-right for outgoing, flat bottom-left for incoming.

private struct ChatBubbleShape: Shape {
    let isOwn: Bool
    let radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = min(radius, h / 2, w / 2)

        if isOwn {
            // Outgoing: flat bottom-right corner
            path.move(to: CGPoint(x: r, y: 0))
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: w, y: h))          // flat bottom-right
            path.addLine(to: CGPoint(x: r, y: h))
            path.addArc(center: CGPoint(x: r, y: h - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Incoming: flat bottom-left corner
            path.move(to: CGPoint(x: r, y: 0))
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: w, y: h - r))
            path.addArc(center: CGPoint(x: w - r, y: h - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: h))           // flat bottom-left
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
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
