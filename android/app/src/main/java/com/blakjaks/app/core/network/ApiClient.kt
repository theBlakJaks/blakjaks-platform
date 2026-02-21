package com.blakjaks.app.core.network

import com.blakjaks.app.core.network.models.*
import com.blakjaks.app.core.storage.TokenManager
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

class ApiClient(private val tokenManager: TokenManager) : ApiClientInterface {

    private val gson: Gson = GsonBuilder().setLenient().create()

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(AuthInterceptor(tokenManager))
        .also {
            // Only log HTTP bodies in debug builds — NEVER in production (exposes credentials/PII)
            if (BuildConfig.DEBUG) {
                it.addInterceptor(HttpLoggingInterceptor().apply {
                    level = HttpLoggingInterceptor.Level.BODY
                })
            }
        }
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(Config.apiBaseUrl + "/api")
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create(gson))
        .build()

    private val service = retrofit.create(ApiService::class.java)

    override suspend fun login(email: String, password: String): AuthTokens =
        service.login(LoginRequest(email, password)).also { tokenManager.saveTokens(it) }

    override suspend fun signup(email: String, password: String, fullName: String, dateOfBirth: String): AuthTokens =
        service.signup(SignupRequest(email, password, fullName, dateOfBirth)).also { tokenManager.saveTokens(it) }

    override suspend fun logout() { service.logout(); tokenManager.clearAll() }

    override suspend fun getMe(): UserProfile = service.getMe()
    override suspend fun updateProfile(fullName: String?, bio: String?): UserProfile =
        service.updateProfile(UpdateProfileRequest(fullName, bio))
    override suspend fun getMemberCard(): MemberCard = service.getMemberCard()
    override suspend fun getWallet(): WalletDetail = service.getWallet()

    override suspend fun getInsightsOverview(): InsightsOverview = service.getInsightsOverview()
    override suspend fun getInsightsTreasury(): InsightsTreasury = service.getInsightsTreasury()
    override suspend fun getInsightsSystems(): InsightsSystems = service.getInsightsSystems()
    override suspend fun getInsightsComps(): InsightsComps = service.getInsightsComps()
    override suspend fun getInsightsPartners(): InsightsPartners = service.getInsightsPartners()
    override suspend fun getInsightsFeed(limit: Int, offset: Int): List<ActivityFeedItem> =
        service.getInsightsFeed(limit, offset)

    override suspend fun submitScan(qrCode: String): ScanResult =
        service.submitScan(ScanSubmitRequest(qrCode))
    override suspend fun getScanHistory(limit: Int, offset: Int): List<Scan> =
        service.getScanHistory(limit, offset)
    override suspend fun getTransactions(limit: Int, offset: Int): List<Transaction> =
        service.getTransactions(limit, offset)
    override suspend fun getCompVault(): CompVault = service.getCompVault()
    override suspend fun withdraw(amount: Double, toAddress: String?, method: String): Transaction =
        service.withdraw(WithdrawRequest(amount, toAddress, method))
    override suspend fun submitPayoutChoice(compId: String, method: String): CompPayoutResult =
        service.submitPayoutChoice(CompPayoutChoiceRequest(compId, method))

    override suspend fun getProducts(category: String?, limit: Int, offset: Int): List<Product> =
        service.getProducts(category, limit, offset)
    override suspend fun getProduct(id: Int): Product = service.getProduct(id)
    override suspend fun getCart(): Cart = service.getCart()
    override suspend fun addToCart(productId: Int, quantity: Int): Cart =
        service.addToCart(AddToCartRequest(productId, quantity))
    override suspend fun updateCartItem(productId: Int, quantity: Int): Cart =
        service.updateCartItem(UpdateCartItemRequest(productId, quantity))
    override suspend fun removeFromCart(productId: Int): Cart = service.removeFromCart(productId)
    override suspend fun estimateTax(shippingAddress: ShippingAddress): TaxEstimate =
        service.estimateTax(shippingAddress)
    override suspend fun createOrder(shippingAddress: ShippingAddress, paymentToken: String): Order =
        service.createOrder(CreateOrderRequest(shippingAddress, paymentToken))

    override suspend fun getNotifications(typeFilter: String?, limit: Int, offset: Int): List<AppNotification> =
        service.getNotifications(typeFilter, limit, offset)
    override suspend fun markNotificationRead(id: Int) = service.markNotificationRead(id)
    override suspend fun markAllNotificationsRead() = service.markAllNotificationsRead()
    override suspend fun getUnreadCount(): Int = service.getUnreadCount().count

    override suspend fun getChannels(): List<Channel> = service.getChannels()
    override suspend fun getMessages(channelId: Int, limit: Int, before: Int?): List<ChatMessage> =
        service.getMessages(channelId, limit, before)
    override suspend fun sendMessage(channelId: Int, content: String, mediaType: String?): ChatMessage =
        service.sendMessage(channelId, SendMessageRequest(content, mediaType))
    override suspend fun translateMessage(messageId: Int, targetLanguage: String): TranslatedMessage =
        service.translateMessage(messageId, TranslateRequest(targetLanguage))
    override suspend fun addReaction(messageId: Int, emoji: String) =
        service.addReaction(messageId, ReactionRequest(emoji))
    override suspend fun removeReaction(messageId: Int, emoji: String) =
        service.removeReaction(messageId, emoji)

    override suspend fun getAffiliateDashboard(): AffiliateDashboard = service.getAffiliateDashboard()
    override suspend fun getAffiliatePayouts(limit: Int, offset: Int): List<AffiliatePayout> =
        service.getAffiliatePayouts(limit, offset)
    override suspend fun getAffiliateReferralCode(): ReferralCode = service.getAffiliateReferralCode()
}
