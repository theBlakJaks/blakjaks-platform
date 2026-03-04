import SwiftUI

// MARK: - PinnedMessagesSheet

/// Sheet displaying pinned messages for a channel.
/// Tapping a message scrolls to it in the chat (via callback).

struct PinnedMessagesSheet: View {

    let channelId: String
    let onTapMessage: (String) -> Void   // message ID

    @State private var pinnedMessages: [ChatMessage] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    private let api: APIClientProtocol = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Color.gold)
                } else if pinnedMessages.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "pin.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Color.textTertiary)
                        Text("No pinned messages")
                            .font(BJFont.sora(14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(pinnedMessages) { message in
                                pinnedRow(message)
                            }
                        }
                        .padding(Spacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PINNED")
                        .font(BJFont.sora(13, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Color.gold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .task {
                await loadPinned()
            }
        }
    }

    // MARK: - Pinned Row

    private func pinnedRow(_ message: ChatMessage) -> some View {
        Button {
            dismiss()
            onTapMessage(message.id)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(message.username)
                        .font(BJFont.sora(12, weight: .bold))
                        .foregroundColor(Color.goldMid)

                    Spacer()

                    Text(formattedDate(message.createdAt))
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                }

                Text(message.content)
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(Spacing.md)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func loadPinned() async {
        isLoading = true
        do {
            pinnedMessages = try await api.getPinnedMessages(channelId: channelId)
        } catch {
            // Show empty state
        }
        isLoading = false
    }

    private func formattedDate(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }
}
