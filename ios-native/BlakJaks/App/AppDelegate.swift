import UIKit
import UserNotifications
import CoreText

// MARK: - AppDelegate
// Handles APNs device token registration and notification delivery.

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Register custom fonts on a background thread — avoids blocking launch.
        // UIAppFonts in Info.plist loads fonts synchronously (11s delay for variable fonts).
        // Background registration completes before the first SwiftUI layout pass.
        DispatchQueue.global(qos: .userInitiated).async { Self.registerFonts() }

        return true
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task { try? await APIClient.shared.registerPushToken(token) }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .sound, .badge])
    }

    // MARK: - Font Registration
    // Loads each font file from the bundle and registers it with CoreText.
    // Called off the main thread to keep launch instant.

    private static func registerFonts() {
        let fonts: [(name: String, ext: String)] = [
            ("PlayfairDisplay", "ttf"),
            ("Sora",            "ttf"),
            ("Outfit",          "ttf"),
            ("Pulpo",           "otf"),
        ]
        for font in fonts {
            guard let url = Bundle.main.url(forResource: font.name, withExtension: font.ext) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
