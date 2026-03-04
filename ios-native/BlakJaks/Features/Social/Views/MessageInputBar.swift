import SwiftUI

// MARK: - MessageInputBar

struct MessageInputBar: View {

    @ObservedObject var vm: ChatRoomViewModel
    let emoteMap: [String: CachedEmote]
    let emoteList: [CachedEmote]
    let emoteStore: EmoteStore
    let onSendGif: (String) -> Void
    let onMarkUsed: (CachedEmote) -> Void

    @State private var showEmotePicker = false
    @State private var showGifPicker = false
    @State private var stagedGifUrl: String?
    @State private var pendingEmote: CachedEmote?
    @State private var localInput = ""

    private let maxCharacters = 500

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.borderSubtle)

            if vm.channel.isViewOnly || vm.channel.roomType == "announcements" {
                readOnlyBanner
            } else {
                VStack(spacing: 0) {
                    // Emote autocomplete
                    if !autocompleteMatches.isEmpty && !showEmotePicker {
                        EmoteAutocomplete(
                            matches: autocompleteMatches,
                            onSelect: { emote in
                                onMarkUsed(emote)
                                pendingEmote = emote
                            }
                        )
                    }

                    // Reply preview
                    if let reply = vm.replyingTo {
                        replyPreview(reply)
                    }

                    // Staged GIF preview
                    if let gifUrl = stagedGifUrl, let url = URL(string: gifUrl) {
                        stagedGifPreview(url: url)
                    }

                    // Input row
                    HStack(alignment: .bottom, spacing: Spacing.xs) {
                        pickerButtons
                        richInput
                        sendButton
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)

                    // Char counter
                    if localInput.count > 400 {
                        charCounter
                    }
                }
                .background(Color.bgPrimary)
                .overlay(cooldownOverlay)

                // Emote picker panel (replaces keyboard)
                // EmotePicker observes the store directly for search
                if showEmotePicker {
                    EmotePicker(
                        store: emoteStore,
                        onSelect: { emote in
                            onMarkUsed(emote)
                            pendingEmote = emote
                        },
                        onDismiss: {
                            showEmotePicker = false
                        }
                    )
                    .frame(height: 300)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showEmotePicker)
    }

    // MARK: - Rich Input

    private var richInput: some View {
        EmoteRichInput(
            text: $localInput,
            pendingEmote: $pendingEmote,
            placeholder: "Message \(vm.channel.name)...",
            maxCharacters: maxCharacters,
            emoteMap: emoteMap,
            onSubmit: {
                vm.inputText = localInput
                Task {
                    await vm.sendMessage()
                    localInput = ""
                }
            },
            onTextChange: { text in
                if !text.isEmpty {
                    vm.sendTypingIfNeeded()
                }
            }
        )
        .frame(minHeight: 38, maxHeight: 120)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.bgInput)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderSubtle, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Read-Only Banner

    private var readOnlyBanner: some View {
        Text("This channel is read-only")
            .font(BJFont.sora(12, weight: .medium))
            .foregroundColor(Color.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.bgPrimary)
    }

    // MARK: - Reply Preview

    private func replyPreview(_ message: ChatMessage) -> some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.goldMid)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to \(message.username)")
                    .font(BJFont.sora(10, weight: .semibold))
                    .foregroundColor(Color.goldMid)
                Text(message.content)
                    .font(BJFont.sora(11, weight: .regular))
                    .foregroundColor(Color.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                vm.clearReply()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.bgCard)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        let textEmpty = localInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isEmpty = textEmpty && stagedGifUrl == nil
        let isDisabled = vm.isSending || isEmpty || vm.cooldownActive

        return Button {
            if let gifUrl = stagedGifUrl {
                onSendGif(gifUrl)
                stagedGifUrl = nil
            } else {
                vm.inputText = localInput
                Task {
                    await vm.sendMessage()
                    localInput = ""
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isEmpty || vm.cooldownActive
                        ? AnyShapeStyle(Color.bgCard)
                        : AnyShapeStyle(LinearGradient.goldShimmer)
                    )
                    .frame(width: 36, height: 36)

                if vm.isSending {
                    ProgressView()
                        .tint(Color.bgPrimary)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isDisabled ? Color.textTertiary : Color.bgPrimary)
                }
            }
        }
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.15), value: localInput)
    }

    // MARK: - Character Counter

    private var charCounter: some View {
        let remaining = maxCharacters - localInput.count
        let isWarning = remaining <= 50
        return HStack {
            Spacer()
            Text("\(remaining)")
                .font(BJFont.sora(10, weight: .semibold))
                .foregroundColor(isWarning ? .red : Color.textTertiary)
                .padding(.trailing, Spacing.md)
                .padding(.bottom, 2)
        }
    }

    // MARK: - Picker Buttons

    private var pickerButtons: some View {
        VStack(spacing: 6) {
            Button {
                if showEmotePicker {
                    showEmotePicker = false
                } else {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showEmotePicker = true
                    }
                }
            } label: {
                Image(systemName: showEmotePicker ? "keyboard" : "face.smiling")
                    .font(.system(size: 22))
                    .foregroundColor(showEmotePicker ? Color.gold : Color.textTertiary)
            }

            Button {
                showGifPicker = true
            } label: {
                Text("GIF")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.textTertiary, lineWidth: 0.8)
                    )
            }
            .sheet(isPresented: $showGifPicker) {
                GiphyPicker { gifUrl in
                    stagedGifUrl = gifUrl
                    showGifPicker = false
                }
                .presentationDetents([.medium, .large])
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Staged GIF Preview

    private func stagedGifPreview(url: URL) -> some View {
        HStack(spacing: Spacing.sm) {
            AnimatedImageView(
                url: url,
                height: 80,
                maxWidth: 80,
                contentMode: .scaleAspectFit
            )
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

            Spacer()

            Button {
                stagedGifUrl = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.bgCard)
    }

    // MARK: - Autocomplete

    private var autocompleteMatches: [CachedEmote] {
        guard let lastWord = localInput.split(separator: " ").last,
              lastWord.count >= 2 else { return [] }
        let lower = String(lastWord).lowercased()
        return emoteList
            .filter { $0.name.lowercased().hasPrefix(lower) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Cooldown Overlay

    @ViewBuilder
    private var cooldownOverlay: some View {
        if vm.cooldownActive {
            Color.bgPrimary.opacity(0.6)
                .allowsHitTesting(false)
                .overlay(
                    Text("Wait...")
                        .font(BJFont.sora(11, weight: .medium))
                        .foregroundColor(Color.textTertiary)
                )
        }
    }
}
