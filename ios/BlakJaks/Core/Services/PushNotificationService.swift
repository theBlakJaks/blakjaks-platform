import UIKit
import UserNotifications

// MARK: - PushNotificationService
// Manages APNs device token registration and notification routing.
// Firebase FCM is NOT used on iOS — APNs direct only.

@MainActor
final class PushNotificationService: ObservableObject {
    static let shared = PushNotificationService()

    @Published var deviceToken: String? = nil
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    // MARK: - Permission Request

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            print("[APNs] Permission request failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Token Management

    func storeDeviceToken(_ token: String) {
        deviceToken = token
        // TODO: POST token to backend (PATCH /users/me/push-token) in production polish pass
        print("[APNs] Device token registered: \(token.prefix(20))...")
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error { print("[APNs] Badge update failed: \(error)") }
        }
    }

    func clearBadge() {
        updateBadgeCount(0)
    }

    // MARK: - Deep Link Routing

    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        // Deep link routing — handle in production polish pass with NavigationPath
        switch type {
        case "comp_earned":
            print("[APNs] Deep link → Wallet")
        case "tier_upgrade":
            print("[APNs] Deep link → Profile")
        case "mention", "reply", "pin":
            if let channelId = userInfo["channel_id"] as? String {
                print("[APNs] Deep link → Social channel \(channelId)")
            }
        default:
            print("[APNs] Deep link → \(type)")
        }
        // TODO: production — post Notification to NavigationCoordinator
    }
}
