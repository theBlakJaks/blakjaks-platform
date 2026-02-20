import Foundation

enum APIEndpoint {
    // Auth
    case login, signup, logout, refreshToken, intercomToken

    // User
    case me, updateProfile, uploadAvatar, memberCard

    // Insights
    case insightsOverview, insightsTreasury, insightsSystems, insightsComps, insightsPartners, insightsFeed(limit: Int, offset: Int)

    // Scan & Wallet
    case submitScan, scanHistory(limit: Int, offset: Int), wallet, transactions(limit: Int, offset: Int, status: String?), compVault, withdrawCrypto

    // Dwolla
    case dwollaFundingSources, dwollaCreateCustomer, plaidLinkToken, linkBank, withdrawToBank(amount: Double, fundingSourceId: String)

    // Shop
    case products(category: String?, limit: Int, offset: Int), product(id: Int), cart, addToCart, updateCartItem, removeFromCart(productId: Int), estimateTax, createOrder

    // Notifications
    case notifications(typeFilter: String?, limit: Int, offset: Int), markNotificationRead(id: Int), markAllRead, unreadCount

    // Social
    case channels, messages(channelId: Int, limit: Int, before: Int?), sendMessage(channelId: Int), translateMessage(id: Int), addReaction(messageId: Int), removeReaction(messageId: Int, emoji: String)

    // Governance
    case activeVotes, voteDetail(id: Int), castBallot(voteId: Int)

    // Wholesale
    case wholesaleApply, wholesaleDashboard, wholesaleOrders(limit: Int, offset: Int), createWholesaleOrder, wholesaleChips

    // Affiliate
    case affiliateDashboard, affiliateDownline(limit: Int, offset: Int), affiliateChips, affiliatePayouts(limit: Int, offset: Int), affiliateReferralCode

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .signup: return "/auth/signup"
        case .logout: return "/auth/logout"
        case .refreshToken: return "/auth/refresh"
        case .intercomToken: return "/intercom/token"
        case .me: return "/users/me"
        case .updateProfile: return "/users/me"
        case .uploadAvatar: return "/users/me/avatar"
        case .memberCard: return "/users/me/member-card"
        case .insightsOverview: return "/insights/overview"
        case .insightsTreasury: return "/insights/treasury"
        case .insightsSystems: return "/insights/systems"
        case .insightsComps: return "/insights/comps"
        case .insightsPartners: return "/insights/partners"
        case .insightsFeed(let limit, let offset): return "/insights/feed?limit=\(limit)&offset=\(offset)"
        case .submitScan: return "/scans/submit"
        case .scanHistory(let limit, let offset): return "/scans/history?limit=\(limit)&offset=\(offset)"
        case .wallet: return "/users/me/wallet"
        case .transactions(let limit, let offset, let status):
            var path = "/wallet/transactions?limit=\(limit)&offset=\(offset)"
            if let status { path += "&status=\(status)" }
            return path
        case .compVault: return "/users/me/comp-vault"
        case .withdrawCrypto: return "/wallet/withdraw"
        case .dwollaFundingSources: return "/users/me/dwolla/funding-sources"
        case .dwollaCreateCustomer: return "/users/me/dwolla/customer"
        case .plaidLinkToken: return "/users/me/dwolla/plaid-link-token"
        case .linkBank: return "/users/me/dwolla/link-bank"
        case .withdrawToBank: return "/users/me/dwolla/withdraw"
        case .products(let category, let limit, let offset):
            var path = "/shop/products?limit=\(limit)&offset=\(offset)"
            if let category { path += "&category=\(category)" }
            return path
        case .product(let id): return "/shop/products/\(id)"
        case .cart: return "/cart"
        case .addToCart: return "/cart/add"
        case .updateCartItem: return "/cart/update"
        case .removeFromCart(let productId): return "/cart/remove/\(productId)"
        case .estimateTax: return "/tax/estimate"
        case .createOrder: return "/orders/create"
        case .notifications(let typeFilter, let limit, let offset):
            var path = "/notifications?limit=\(limit)&offset=\(offset)"
            if let typeFilter { path += "&type=\(typeFilter)" }
            return path
        case .markNotificationRead(let id): return "/notifications/\(id)/read"
        case .markAllRead: return "/notifications/read-all"
        case .unreadCount: return "/notifications/unread-count"
        case .channels: return "/social/channels"
        case .messages(let channelId, let limit, let before):
            var path = "/social/channels/\(channelId)/messages?limit=\(limit)"
            if let before { path += "&before=\(before)" }
            return path
        case .sendMessage(let channelId): return "/social/channels/\(channelId)/messages"
        case .translateMessage(let id): return "/social/messages/\(id)/translate"
        case .addReaction(let messageId): return "/social/messages/\(messageId)/reactions"
        case .removeReaction(let messageId, let emoji): return "/social/messages/\(messageId)/reactions/\(emoji)"
        case .activeVotes: return "/governance/votes"
        case .voteDetail(let id): return "/governance/votes/\(id)"
        case .castBallot(let voteId): return "/governance/votes/\(voteId)/ballot"
        case .wholesaleApply: return "/wholesale/apply"
        case .wholesaleDashboard: return "/wholesale/dashboard"
        case .wholesaleOrders(let limit, let offset): return "/wholesale/orders?limit=\(limit)&offset=\(offset)"
        case .createWholesaleOrder: return "/wholesale/orders"
        case .wholesaleChips: return "/wholesale/chips"
        case .affiliateDashboard: return "/affiliate/dashboard"
        case .affiliateDownline(let limit, let offset): return "/affiliate/downline?limit=\(limit)&offset=\(offset)"
        case .affiliateChips: return "/affiliate/chips"
        case .affiliatePayouts(let limit, let offset): return "/affiliate/payouts?limit=\(limit)&offset=\(offset)"
        case .affiliateReferralCode: return "/affiliate/referral-code"
        }
    }
}
