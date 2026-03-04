import Foundation

// MARK: - Config
// Reads API_BASE_URL and ENVIRONMENT from xcconfig (injected into Info.plist).

enum Config {
    static let apiBaseURL: URL = {
        // Check Info.plist first (set via xcconfig when properly wired)
        if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !raw.isEmpty, !raw.hasPrefix("$"),
           let url = URL(string: raw), url.host != nil {
            return url
        }
        #if DEBUG
        return URL(string: "https://staging-api.blakjaks.com/api")!
        #else
        return URL(string: "https://api.blakjaks.com/api")!
        #endif
    }()

    static let environment: String = {
        Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String ?? "development"
    }()

    static var isProduction: Bool { environment == "production" }

    /// WebSocket URL derived from apiBaseURL: strip /api, switch to wss scheme.
    static let wsBaseURL: URL = {
        var str = apiBaseURL.absoluteString
        // Strip trailing /api or /api/
        if str.hasSuffix("/api") { str = String(str.dropLast(4)) }
        else if str.hasSuffix("/api/") { str = String(str.dropLast(5)) }
        str = str.replacingOccurrences(of: "https://", with: "wss://")
                 .replacingOccurrences(of: "http://", with: "ws://")
        return URL(string: str)!
    }()
}
