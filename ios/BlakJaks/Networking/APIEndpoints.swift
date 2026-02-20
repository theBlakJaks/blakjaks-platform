import Foundation

// MARK: - APIEndpoints
// Centralized endpoint definitions. All paths are relative to Config.apiBaseURL.

enum APIEndpoints {

    // MARK: - Auth
    static let login             = "/auth/login"
    static let signup            = "/auth/register"
    static let logout            = "/auth/logout"
    static let refreshToken      = "/auth/refresh"
    static let intercomToken     = "/auth/intercom-token"

    // MARK: - User
    static let me                = "/users/me"
    static let memberCard        = "/users/me/member-card"
    static let avatarUpload      = "/users/me/avatar"

    // MARK: - Insights
    static let insightsOverview  = "/insights/overview"
    static let insightsTreasury  = "/insights/treasury"
    static let insightsSystems   = "/insights/systems"
    static let insightsComps     = "/insights/comps"
    static let insightsPartners  = "/insights/partners"
    static let insightsFeed      = "/insights/feed"

    // MARK: - Scan & Wallet
    static let scan              = "/scans"
    static let scanHistory       = "/scans/history"
    static let wallet            = "/wallet"
    static let transactions      = "/wallet/transactions"
    static let compVault         = "/wallet/comp-vault"
    static let cryptoWithdraw    = "/wallet/withdraw/crypto"
    static let bankWithdraw      = "/wallet/withdraw/bank"

    // MARK: - Dwolla ACH
    static let dwollaFundingSources = "/dwolla/funding-sources"
    static let dwollaPlaidToken     = "/dwolla/plaid/link-token"
    static let dwollaExchangeSession = "/dwolla/exchange-sessions"
    static func dwollaFundingSource(_ id: String) -> String { "/dwolla/funding-sources/\(id)" }
    static let dwollaTransfers      = "/dwolla/transfers"
    static func dwollaTransfer(_ id: String) -> String { "/dwolla/transfers/\(id)" }

    // MARK: - Shop
    static let products          = "/shop/products"
    static func product(_ id: Int) -> String { "/shop/products/\(id)" }
    static let cart              = "/shop/cart"
    static let cartItems         = "/shop/cart/items"
    static func cartItem(_ id: Int) -> String { "/shop/cart/items/\(id)" }
    static let taxEstimate       = "/shop/tax-estimate"
    static let orders            = "/shop/orders"
    static func order(_ id: Int) -> String { "/shop/orders/\(id)" }
    static let checkout          = "/shop/checkout"

    // MARK: - Notifications
    static let notifications         = "/notifications"
    static let notificationsMarkRead = "/notifications/read-all"
    static let pushToken             = "/notifications/push-token"

    // MARK: - Social Hub
    static let channels          = "/social/channels"
    static func channelMessages(_ id: String) -> String { "/social/channels/\(id)/messages" }
    static let liveStreams        = "/social/streams"

    // MARK: - Governance
    static let proposals         = "/governance/proposals"
    static func vote(_ id: Int) -> String { "/governance/proposals/\(id)/vote" }

    // MARK: - Wholesale / Affiliate
    static let wholesaleDashboard  = "/wholesale/dashboard"
    static let affiliateDashboard  = "/affiliate/dashboard"
    static let affiliateReferrals  = "/affiliate/referrals"
    static let affiliatePayouts    = "/affiliate/payouts"
}
