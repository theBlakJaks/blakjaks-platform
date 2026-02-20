import Foundation

// MARK: - NotificationViewModel

@MainActor
final class NotificationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private let apiClient: APIClientProtocol

    // MARK: - Init

    init(apiClient: APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Load

    func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchedNotifications = apiClient.getNotifications(typeFilter: nil, limit: 50, offset: 0)
            async let fetchedCount = apiClient.getUnreadNotificationCount()
            let (notifs, count) = try await (fetchedNotifications, fetchedCount)
            notifications = notifs
            unreadCount = count
        } catch {
            self.error = error
        }
    }

    // MARK: - Mark Read

    func markRead(id: Int) async {
        do {
            try await apiClient.markNotificationRead(id: id)
            // Reload the list so isRead is accurately reflected from the server
            await loadNotifications()
        } catch {
            self.error = error
        }
    }

    func markAllRead() async {
        do {
            try await apiClient.markAllNotificationsRead()
            // Update local state immediately for snappy UI
            notifications = notifications.map { notif in
                AppNotification(
                    id: notif.id,
                    type: notif.type,
                    title: notif.title,
                    body: notif.body,
                    isRead: true,
                    createdAt: notif.createdAt,
                    data: notif.data
                )
            }
            unreadCount = 0
        } catch {
            self.error = error
        }
    }

    // MARK: - Error

    func clearError() {
        error = nil
    }
}
