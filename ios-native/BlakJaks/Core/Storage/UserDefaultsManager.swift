import Foundation

// MARK: - UserDefaultsManager
// Lightweight typed wrapper around UserDefaults for non-sensitive preferences.

final class UserDefaultsManager {

    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    private init() {}

    private enum Key {
        static let selectedTab        = "selected_tab"
        static let hasSeenOnboarding  = "has_seen_onboarding"
        static let preferredLanguage  = "preferred_language"
        static let lastScanDate       = "last_scan_date"
    }

    var selectedTab: Int {
        get { defaults.integer(forKey: Key.selectedTab) }
        set { defaults.set(newValue, forKey: Key.selectedTab) }
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: Key.hasSeenOnboarding) }
    }

    var preferredLanguage: String {
        get { defaults.string(forKey: Key.preferredLanguage) ?? "en" }
        set { defaults.set(newValue, forKey: Key.preferredLanguage) }
    }

    var lastScanDate: Date? {
        get { defaults.object(forKey: Key.lastScanDate) as? Date }
        set { defaults.set(newValue, forKey: Key.lastScanDate) }
    }
}
