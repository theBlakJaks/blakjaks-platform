import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile?
    @Published var memberCard: MemberCard?
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var editingFullName = ""
    @Published var editingBio = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Stats loaded from wallet (not part of UserProfile)
    @Published var totalScans: Int? = nil
    @Published var walletBalance: Double? = nil
    @Published var usdcBalance: Double? = nil

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadProfile() async {
        isLoading = true
        do {
            async let u = api.getMe()
            async let mc = api.getMemberCard()
            async let nc = api.getUnreadNotificationCount()
            user = try await u
            memberCard = try? await mc
            unreadCount = (try? await nc) ?? 0
            if let u = user {
                editingFullName = u.displayName
                editingBio = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveProfile() async {
        isSaving = true
        errorMessage = nil
        do {
            user = try await api.updateProfile(
                fullName: editingFullName.isEmpty ? nil : editingFullName,
                bio: editingBio.isEmpty ? nil : editingBio
            )
            successMessage = "Profile updated."
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func loadNotifications() async {
        do {
            notifications = try await api.getNotifications(typeFilter: nil, limit: 30, offset: 0)
        } catch {}
    }

    func markAllRead() async {
        do {
            try await api.markAllNotificationsRead()
            notifications = notifications.map {
                AppNotification(id: $0.id, type: $0.type, title: $0.title, body: $0.body, isRead: true, createdAt: $0.createdAt, data: $0.data)
            }
            unreadCount = 0
        } catch {}
    }
}
