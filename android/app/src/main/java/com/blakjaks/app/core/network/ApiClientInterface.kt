package com.blakjaks.app.core.network

import com.blakjaks.app.core.network.models.*

interface ApiClientInterface {
    // Auth
    suspend fun login(email: String, password: String): AuthTokens
    suspend fun signup(email: String, password: String, fullName: String, dateOfBirth: String): AuthTokens
    suspend fun logout()
    // User
    suspend fun getMe(): UserProfile
    suspend fun updateProfile(fullName: String?, bio: String?): UserProfile
    suspend fun getMemberCard(): MemberCard
    suspend fun getWallet(): WalletDetail
    // Insights
    suspend fun getInsightsOverview(): InsightsOverview
    suspend fun getInsightsTreasury(): InsightsTreasury
    suspend fun getInsightsSystems(): InsightsSystems
    suspend fun getInsightsComps(): InsightsComps
    suspend fun getInsightsPartners(): InsightsPartners
    suspend fun getInsightsFeed(limit: Int, offset: Int): List<ActivityFeedItem>
    // Scan & Wallet
    suspend fun submitScan(qrCode: String): ScanResult
    suspend fun getScanHistory(limit: Int, offset: Int): List<Scan>
    suspend fun getTransactions(limit: Int, offset: Int): List<Transaction>
    suspend fun getCompVault(): CompVault
    suspend fun withdraw(amount: Double, toAddress: String?, method: String): Transaction
    suspend fun submitPayoutChoice(compId: String, method: String): CompPayoutResult
    // Shop
    suspend fun getProducts(category: String?, limit: Int, offset: Int): List<Product>
    suspend fun getProduct(id: Int): Product
    suspend fun getCart(): Cart
    suspend fun addToCart(productId: Int, quantity: Int): Cart
    suspend fun updateCartItem(productId: Int, quantity: Int): Cart
    suspend fun removeFromCart(productId: Int): Cart
    suspend fun estimateTax(shippingAddress: ShippingAddress): TaxEstimate
    suspend fun createOrder(shippingAddress: ShippingAddress, paymentToken: String): Order
    // Notifications
    suspend fun getNotifications(typeFilter: String?, limit: Int, offset: Int): List<AppNotification>
    suspend fun markNotificationRead(id: Int)
    suspend fun markAllNotificationsRead()
    suspend fun getUnreadCount(): Int
    // Social
    suspend fun getChannels(): List<Channel>
    suspend fun getMessages(channelId: Int, limit: Int, before: Int?): List<ChatMessage>
    suspend fun sendMessage(channelId: Int, content: String, mediaType: String?): ChatMessage
    suspend fun translateMessage(messageId: Int, targetLanguage: String): TranslatedMessage
    suspend fun addReaction(messageId: Int, emoji: String)
    suspend fun removeReaction(messageId: Int, emoji: String)
    // Affiliate
    suspend fun getAffiliateDashboard(): AffiliateDashboard
    suspend fun getAffiliatePayouts(limit: Int, offset: Int): List<AffiliatePayout>
    suspend fun getAffiliateReferralCode(): ReferralCode
}
