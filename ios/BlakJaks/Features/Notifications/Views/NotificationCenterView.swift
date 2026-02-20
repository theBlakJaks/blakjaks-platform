import SwiftUI

// MARK: - NotificationCenterView
// Sorted notification feed with read/unread state, icon types, and relative timestamps.

struct NotificationCenterView: View {

    @ObservedObject var notifVM: NotificationViewModel

    private var sortedNotifications: [AppNotification] {
        notifVM.notifications.sorted { a, b in
            let iso = ISO8601DateFormatter()
            let aDate = iso.date(from: a.createdAt) ?? .distantPast
            let bDate = iso.date(from: b.createdAt) ?? .distantPast
            return aDate > bDate
        }
    }

    var body: some View {
        Group {
            if notifVM.isLoading && notifVM.notifications.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundPrimary)
            } else if notifVM.notifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "No Notifications",
                    subtitle: "You're all caught up!"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundPrimary)
            } else {
                List {
                    ForEach(sortedNotifications) { notification in
                        notificationRow(notification)
                            .listRowBackground(
                                notification.isRead
                                    ? Color.backgroundPrimary
                                    : Color.gold.opacity(0.06)
                            )
                            .listRowSeparatorTint(Color.backgroundSecondary)
                            .onTapGesture {
                                Task { await notifVM.markRead(id: notification.id) }
                            }
                    }
                }
                .listStyle(.plain)
                .background(Color.backgroundPrimary)
                .refreshable {
                    await notifVM.loadNotifications()
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if notifVM.unreadCount > 0 {
                    Button("Mark All Read") {
                        Task { await notifVM.markAllRead() }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gold)
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { notifVM.error != nil },
            set: { _ in notifVM.clearError() }
        )) {
            Button("OK", role: .cancel) { notifVM.clearError() }
        } message: {
            Text(notifVM.error?.localizedDescription ?? "")
        }
        .task {
            await notifVM.loadNotifications()
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ notification: AppNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Icon
            notifIcon(notification.type)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.footnote.weight(notification.isRead ? .regular : .semibold))
                    .foregroundColor(.primary)

                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            // Time + unread dot
            VStack(alignment: .trailing, spacing: 4) {
                Text(relativeTime(notification.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                if !notification.isRead {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.gold)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Icon Helper

    private func notifIcon(_ type: String) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case "comp_earned": return ("dollarsign.circle.fill", .success)
            case "tier_upgrade": return ("star.fill", .gold)
            case "mention": return ("at.circle.fill", .info)
            case "reply": return ("bubble.left.fill", .info)
            case "pin": return ("pin.fill", .warning)
            default: return ("bell.fill", .secondary)
            }
        }()
        return Image(systemName: icon)
            .font(.title3)
            .foregroundColor(color)
            .frame(width: 36, height: 36)
    }

    // MARK: - Relative Time Helper

    private func relativeTime(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: isoString) else { return isoString }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationCenterView(notifVM: {
            let vm = NotificationViewModel(apiClient: MockAPIClient())
            return vm
        }())
    }
}
