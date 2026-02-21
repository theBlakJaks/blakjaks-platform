package com.blakjaks.app.core.network

import com.blakjaks.app.core.network.models.*
import retrofit2.http.*

interface ApiService {

    // Auth
    @POST(ApiEndpoints.LOGIN)
    suspend fun login(@Body body: LoginRequest): AuthTokens

    @POST(ApiEndpoints.SIGNUP)
    suspend fun signup(@Body body: SignupRequest): AuthTokens

    @POST(ApiEndpoints.LOGOUT)
    suspend fun logout()

    @POST(ApiEndpoints.REFRESH_TOKEN)
    suspend fun refreshToken(@Body body: TokenRefreshRequest): AuthTokens

    // User
    @GET(ApiEndpoints.ME)
    suspend fun getMe(): UserProfile

    @PATCH(ApiEndpoints.UPDATE_PROFILE)
    suspend fun updateProfile(@Body body: UpdateProfileRequest): UserProfile

    @GET(ApiEndpoints.MEMBER_CARD)
    suspend fun getMemberCard(): MemberCard

    @GET(ApiEndpoints.WALLET)
    suspend fun getWallet(): WalletDetail

    @PATCH(ApiEndpoints.PUSH_TOKEN)
    suspend fun updatePushToken(@Body body: PushTokenRequest)

    // Insights
    @GET(ApiEndpoints.INSIGHTS_OVERVIEW)
    suspend fun getInsightsOverview(): InsightsOverview

    @GET(ApiEndpoints.INSIGHTS_TREASURY)
    suspend fun getInsightsTreasury(): InsightsTreasury

    @GET(ApiEndpoints.INSIGHTS_SYSTEMS)
    suspend fun getInsightsSystems(): InsightsSystems

    @GET(ApiEndpoints.INSIGHTS_COMPS)
    suspend fun getInsightsComps(): InsightsComps

    @GET(ApiEndpoints.INSIGHTS_PARTNERS)
    suspend fun getInsightsPartners(): InsightsPartners

    @GET(ApiEndpoints.INSIGHTS_FEED)
    suspend fun getInsightsFeed(@Query("limit") limit: Int, @Query("offset") offset: Int): List<ActivityFeedItem>

    // Scan & Wallet
    @POST(ApiEndpoints.SUBMIT_SCAN)
    suspend fun submitScan(@Body body: ScanSubmitRequest): ScanResult

    @GET(ApiEndpoints.SCAN_HISTORY)
    suspend fun getScanHistory(@Query("limit") limit: Int, @Query("offset") offset: Int): List<Scan>

    @GET(ApiEndpoints.WALLET_TRANSACTIONS)
    suspend fun getTransactions(@Query("limit") limit: Int, @Query("offset") offset: Int): List<Transaction>

    @GET(ApiEndpoints.COMP_VAULT)
    suspend fun getCompVault(): CompVault

    @POST(ApiEndpoints.WITHDRAW)
    suspend fun withdraw(@Body body: WithdrawRequest): Transaction

    @POST(ApiEndpoints.COMP_PAYOUT_CHOICE)
    suspend fun submitPayoutChoice(@Body body: CompPayoutChoiceRequest): CompPayoutResult

    // Shop
    @GET(ApiEndpoints.PRODUCTS)
    suspend fun getProducts(@Query("category") category: String?, @Query("limit") limit: Int, @Query("offset") offset: Int): List<Product>

    @GET("${ApiEndpoints.PRODUCTS}/{id}")
    suspend fun getProduct(@Path("id") id: Int): Product

    @GET(ApiEndpoints.CART)
    suspend fun getCart(): Cart

    @POST(ApiEndpoints.ADD_TO_CART)
    suspend fun addToCart(@Body body: AddToCartRequest): Cart

    @PUT(ApiEndpoints.UPDATE_CART_ITEM)
    suspend fun updateCartItem(@Body body: UpdateCartItemRequest): Cart

    @DELETE("${ApiEndpoints.CART}/remove/{productId}")
    suspend fun removeFromCart(@Path("productId") productId: Int): Cart

    @POST(ApiEndpoints.ESTIMATE_TAX)
    suspend fun estimateTax(@Body body: ShippingAddress): TaxEstimate

    @POST(ApiEndpoints.CREATE_ORDER)
    suspend fun createOrder(@Body body: CreateOrderRequest): Order

    // Notifications
    @GET(ApiEndpoints.NOTIFICATIONS)
    suspend fun getNotifications(@Query("type") type: String?, @Query("limit") limit: Int, @Query("offset") offset: Int): List<AppNotification>

    @POST("${ApiEndpoints.NOTIFICATIONS}/{id}/read")
    suspend fun markNotificationRead(@Path("id") id: Int)

    @POST(ApiEndpoints.MARK_ALL_READ)
    suspend fun markAllNotificationsRead()

    @GET(ApiEndpoints.UNREAD_COUNT)
    suspend fun getUnreadCount(): UnreadCountResponse

    // Social
    @GET(ApiEndpoints.CHANNELS)
    suspend fun getChannels(): List<Channel>

    @GET("/social/channels/{channelId}/messages")
    suspend fun getMessages(@Path("channelId") channelId: Int, @Query("limit") limit: Int, @Query("before") before: Int?): List<ChatMessage>

    @POST("/social/channels/{channelId}/messages")
    suspend fun sendMessage(@Path("channelId") channelId: Int, @Body body: SendMessageRequest): ChatMessage

    @POST("/social/messages/{id}/translate")
    suspend fun translateMessage(@Path("id") id: Int, @Body body: TranslateRequest): TranslatedMessage

    @POST("/social/messages/{id}/reactions")
    suspend fun addReaction(@Path("id") id: Int, @Body body: ReactionRequest)

    @DELETE("/social/messages/{id}/reactions/{emoji}")
    suspend fun removeReaction(@Path("id") id: Int, @Path("emoji") emoji: String)

    // Affiliate
    @GET(ApiEndpoints.AFFILIATE_DASHBOARD)
    suspend fun getAffiliateDashboard(): AffiliateDashboard

    @GET(ApiEndpoints.AFFILIATE_PAYOUTS)
    suspend fun getAffiliatePayouts(@Query("limit") limit: Int, @Query("offset") offset: Int): List<AffiliatePayout>

    @GET(ApiEndpoints.AFFILIATE_REFERRAL_CODE)
    suspend fun getAffiliateReferralCode(): ReferralCode
}
