import UserNotifications
import Foundation

// Stub — wired in Task I7
class PushNotificationService {
    static let shared = PushNotificationService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }
}
