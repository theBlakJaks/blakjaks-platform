import Foundation

// MARK: - Config
// Reads API_BASE_URL and ENVIRONMENT from xcconfig (injected into Info.plist).

enum Config {
    static let apiBaseURL: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              !raw.isEmpty,
              let url = URL(string: raw) else {
            // Fallback to sandbox in Simulator / tests
            return URL(string: "https://api-dev.blakjaks.com/v1")!
        }
        return url
    }()

    static let environment: String = {
        Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String ?? "development"
    }()

    static var isProduction: Bool { environment == "production" }
}
