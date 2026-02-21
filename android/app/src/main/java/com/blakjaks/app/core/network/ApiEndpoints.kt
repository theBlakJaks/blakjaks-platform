package com.blakjaks.app.core.network

object ApiEndpoints {
    // Auth
    const val LOGIN = "/auth/login"
    const val SIGNUP = "/auth/signup"
    const val LOGOUT = "/auth/logout"
    const val REFRESH_TOKEN = "/auth/refresh"
    const val INTERCOM_TOKEN = "/intercom/token"

    // User
    const val ME = "/users/me"
    const val UPDATE_PROFILE = "/users/me"
    const val UPLOAD_AVATAR = "/users/me/avatar"
    const val MEMBER_CARD = "/users/me/member-card"
    const val WALLET = "/users/me/wallet"
    const val PUSH_TOKEN = "/users/me/push-token"

    // Insights
    const val INSIGHTS_OVERVIEW = "/insights/overview"
    const val INSIGHTS_TREASURY = "/insights/treasury"
    const val INSIGHTS_SYSTEMS = "/insights/systems"
    const val INSIGHTS_COMPS = "/insights/comps"
    const val INSIGHTS_PARTNERS = "/insights/partners"
    const val INSIGHTS_FEED = "/insights/feed"

    // Scan & Wallet
    const val SUBMIT_SCAN = "/scans/submit"
    const val SCAN_HISTORY = "/scans/history"
    const val WALLET_TRANSACTIONS = "/wallet/transactions"
    const val COMP_VAULT = "/users/me/comp-vault"
    const val WITHDRAW = "/wallet/withdraw"
    const val COMP_PAYOUT_CHOICE = "/wallet/comp-payout-choice"

    // Dwolla
    const val DWOLLA_FUNDING_SOURCES = "/users/me/dwolla/funding-sources"
    const val DWOLLA_CREATE_CUSTOMER = "/users/me/dwolla/customer"
    const val PLAID_LINK_TOKEN = "/users/me/dwolla/plaid-link-token"
    const val LINK_BANK = "/users/me/dwolla/link-bank"
    const val WITHDRAW_TO_BANK = "/users/me/dwolla/withdraw"

    // Shop
    const val PRODUCTS = "/shop/products"
    const val CART = "/cart"
    const val ADD_TO_CART = "/cart/add"
    const val UPDATE_CART_ITEM = "/cart/update"
    const val ESTIMATE_TAX = "/tax/estimate"
    const val CREATE_ORDER = "/orders/create"

    // Notifications
    const val NOTIFICATIONS = "/notifications"
    const val MARK_ALL_READ = "/notifications/read-all"
    const val UNREAD_COUNT = "/notifications/unread-count"

    // Social
    const val CHANNELS = "/social/channels"
    const val SEND_MESSAGE = "/social/channels/{channelId}/messages"
    const val TRANSLATE_MESSAGE = "/social/messages/{id}/translate"
    const val ADD_REACTION = "/social/messages/{id}/reactions"

    // Affiliate
    const val AFFILIATE_DASHBOARD = "/affiliate/dashboard"
    const val AFFILIATE_PAYOUTS = "/affiliate/payouts"
    const val AFFILIATE_REFERRAL_CODE = "/affiliate/referral-code"
}
