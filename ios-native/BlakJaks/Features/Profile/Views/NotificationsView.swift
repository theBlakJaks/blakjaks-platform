import SwiftUI

// MARK: - NotificationsView

struct NotificationsView: View {

    @ObservedObject var vm: ProfileViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.notifications.isEmpty && !vm.isLoading {
                EmptyStateView(
                    icon: "🔔",
                    title: "No Notifications",
                    subtitle: "You're all caught up"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.notifications) { notification in
                        NotificationRow(notification: notification)
                            .listRowBackground(Color.bgPrimary)
                            .listRowSeparatorTint(Color.borderSubtle)
                            .listRowInsets(EdgeInsets(top: 0, leading: Spacing.md, bottom: 0, trailing: Spacing.md))
                    }
                }
                .listStyle(.plain)
                .background(Color.bgPrimary)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NOTIFICATIONS")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.gold)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Mark All Read") {
                    Task { await vm.markAllRead() }
                }
                .font(BJFont.sora(12, weight: .semibold))
                .foregroundColor(Color.goldMid)
                .disabled(vm.notifications.allSatisfy { $0.isRead })
            }
        }
        .disableSwipeBack()
        .task {
            await vm.loadNotifications()
        }
    }
}

// MARK: - NotificationRow

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(BJFont.sora(14, weight: notification.isRead ? .regular : .bold))
                    .foregroundColor(notification.isRead ? Color.textSecondary : Color.textPrimary)
                    .lineLimit(1)

                Text(notification.body)
                    .font(BJFont.caption)
                    .foregroundColor(Color.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(relativeTime(from: notification.createdAt))
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
                    .padding(.top, 1)
            }

            Spacer(minLength: Spacing.xs)

            // Unread dot + date
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                if !notification.isRead {
                    Circle()
                        .fill(Color.gold)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.gold.opacity(0.5), radius: 3)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .opacity(notification.isRead ? 0.75 : 1)
    }

    // MARK: - Icon mapping

    private var iconName: String {
        switch notification.type.lowercased() {
        case "gift", "reward", "bonus":       return "gift.fill"
        case "scan", "qr":                     return "qrcode.viewfinder"
        case "transfer", "payment", "payout": return "dollarsign.circle.fill"
        case "verification", "approved":      return "checkmark.shield.fill"
        case "alert", "warning":              return "exclamationmark.triangle.fill"
        case "referral", "affiliate":         return "person.2.fill"
        case "vote", "governance":            return "checkmark.seal.fill"
        case "order", "shop":                 return "bag.fill"
        default:                              return "bell.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type.lowercased() {
        case "gift", "reward", "bonus":       return Color.gold
        case "transfer", "payment", "payout": return Color.success
        case "alert", "warning":              return Color.warning
        case "verification", "approved":      return Color.success
        case "vote", "governance":            return Color.goldMid
        default:                              return Color.textSecondary
        }
    }

    private func relativeTime(from iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) else { return iso }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        if diff < 604800 { return "\(Int(diff / 86400))d ago" }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }
}

#Preview {
    let vm = ProfileViewModel()
    return NavigationStack {
        NotificationsView(vm: vm)
    }
    .preferredColorScheme(.dark)
}
