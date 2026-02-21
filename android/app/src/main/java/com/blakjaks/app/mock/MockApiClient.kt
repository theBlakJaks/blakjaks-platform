package com.blakjaks.app.mock

import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.*
import kotlin.random.Random

/**
 * MockApiClient — implements ApiClientInterface with hardcoded mock data.
 * Use in ViewModels during development and unit tests.
 * Mirrors ios/BlakJaks/MockData/MockAPIClient.swift exactly.
 */
class MockApiClient : ApiClientInterface {

    // ─── Mock Data ───────────────────────────────────────────────────────────

    private val mockUser = UserProfile(
        id = 1,
        email = "alex@example.com",
        fullName = "Alex Johnson",
        memberId = "BJ-0001-VIP",
        tier = "VIP",
        avatarUrl = null,
        bio = "BlakJaks enthusiast since 2024.",
        walletBalance = 1250.75,
        pendingBalance = 85.00,
        goldChips = 42,
        lifetimeUsdc = 4820.50,
        scansThisQuarter = 67,
        isAffiliate = true,
        createdAt = "2024-01-15T10:00:00Z"
    )

    private val mockLinkedBank = DwollaFundingSource(
        id = "fs-001",
        name = "Chase Checking",
        bankName = "Chase",
        lastFour = "4242",
        type = "checking",
        status = "verified"
    )

    private val mockWallet = WalletDetail(
        compBalance = 847.50,
        availableBalance = 1250.75,
        pendingBalance = 85.00,
        currency = "USD",
        walletAddress = "0x3f2A9c8B1D7e4F0a5C6E2d8B9A1F3c7E4D2b0A8F",
        linkedBankAccount = mockLinkedBank
    )

    private val mockFeedItems = listOf(
        ActivityFeedItem(id = 1, type = "comp_earned", description = "BJ-0892-HR earned \$100 milestone comp", amount = 100.0, userId = null, createdAt = "2026-02-20T12:01:00Z"),
        ActivityFeedItem(id = 2, type = "tier_upgrade", description = "BJ-1204-ST upgraded to VIP", amount = null, userId = null, createdAt = "2026-02-20T11:58:00Z"),
        ActivityFeedItem(id = 3, type = "new_member", description = "New member BJ-8241-ST joined", amount = null, userId = null, createdAt = "2026-02-20T11:55:00Z"),
        ActivityFeedItem(id = 4, type = "payout", description = "ACH payout of \$250 processed for BJ-0423-VIP", amount = 250.0, userId = null, createdAt = "2026-02-20T11:50:00Z")
    )

    private val mockMilestoneProgress = listOf(
        MilestoneProgress(id = "active-members", label = "10K Members", current = 8241.0, target = 10000.0, percentage = 82.4),
        MilestoneProgress(id = "payouts", label = "\$1M Payouts", current = 487320.0, target = 1000000.0, percentage = 48.7)
    )

    private val mockOverview = InsightsOverview(
        globalScanCount = 1_487_392,
        activeMembers = 8_241,
        payoutsLast24h = 12_450.75,
        liveFeed = mockFeedItems,
        milestoneProgress = mockMilestoneProgress
    )

    private val mockTreasury = InsightsTreasury(
        onChainBalances = listOf(
            PoolBalance(id = "member", poolType = "member_treasury", balance = 245_820.50, currency = "USDC", walletAddress = "0x1234...5678"),
            PoolBalance(id = "affiliate", poolType = "affiliate_treasury", balance = 89_450.25, currency = "USDC", walletAddress = "0xabcd...ef12"),
            PoolBalance(id = "wholesale", poolType = "wholesale_treasury", balance = 55_200.00, currency = "USDC", walletAddress = "0x7890...abcd")
        ),
        bankBalances = listOf(
            BankBalance(id = "operating", accountName = "Operating Account", institution = "Chase Business", balance = 125_000.00, lastSyncAt = "2026-02-20T06:00:00Z"),
            BankBalance(id = "reserve", accountName = "Reserve Account", institution = "Chase Business", balance = 500_000.00, lastSyncAt = "2026-02-20T06:00:00Z"),
            BankBalance(id = "comp", accountName = "Comp Pool Account", institution = "Chase Business", balance = 85_250.75, lastSyncAt = "2026-02-20T06:00:00Z")
        ),
        dwollaPlatformBalance = DwollaBalance(available = 42_150.50, total = 44_800.00, currency = "USD"),
        sparklines = emptyMap(),
        reconciliationStatus = ReconciliationStatus(
            lastRunAt = "2026-02-20T05:00:00Z",
            status = "ok",
            variance = 2.15,
            tolerance = 10.00
        ),
        payoutLedger = emptyList()
    )

    private val mockSystems = InsightsSystems(
        compBudgetHealth = CompBudgetHealth(
            totalBudget = 500_000.0,
            usedBudget = 87_320.50,
            remainingBudget = 412_679.50,
            percentUsed = 17.46,
            projectedExhaustionDate = null
        ),
        payoutPipelineQueueDepth = 12,
        payoutPipelineSuccessRate = 99.7,
        scanVelocity = ScanVelocity(perMinute = 42.3, perHour = 2538.0, last60Min = emptyList()),
        polygonNodeStatus = NodeStatus(connected = true, blockNumber = 57_923_841, syncing = false, provider = "Infura"),
        tellerLastSync = "2026-02-20T06:00:00Z",
        tierDistribution = mapOf("Standard" to 5820, "VIP" to 1890, "High Roller" to 412, "Whale" to 119)
    )

    private val mockComps = InsightsComps(
        tier100 = CompTierStats(totalPaid = 24_800.0, totalRecipients = 248, averagePayout = 100.0, periodLabel = "All Time"),
        tier1k = CompTierStats(totalPaid = 38_000.0, totalRecipients = 38, averagePayout = 1000.0, periodLabel = "All Time"),
        tier10k = CompTierStats(totalPaid = 50_000.0, totalRecipients = 5, averagePayout = 10000.0, periodLabel = "All Time"),
        tier200kTrip = CompTierStats(totalPaid = 0.0, totalRecipients = 0, averagePayout = 200000.0, periodLabel = "Not yet triggered"),
        milestoneProgress = mockMilestoneProgress,
        guaranteedCompTotals = GuaranteedCompTotals(
            totalPaidThisYear = 32_500.0,
            totalRecipients = 650,
            nextRunDate = "2026-03-01"
        ),
        vaultEconomy = VaultEconomy(totalInVaults = 89_450.25, avgVaultBalance = 10.85, goldChipsIssued = 34_820)
    )

    private val mockPartners = InsightsPartners(
        affiliateActiveCount = 284,
        sunsetEngineStatus = "active",
        weeklyPool = 4_200.00,
        lifetimeMatchTotal = 18_750.50,
        permanentTierFloorCounts = mapOf("VIP" to 42, "High Roller" to 8),
        wholesaleActiveAccounts = 37,
        wholesaleOrderValueThisMonth = 142_800.00
    )

    private val mockScanResult = ScanResult(
        success = true,
        productName = "BlakJaks Classic",
        usdcEarned = 1.50,
        tierMultiplier = 1.5,
        tierProgress = TierProgress(
            quarter = "Q1 2026",
            currentCount = 68,
            nextTier = "High Roller",
            scansRequired = 32
        ),
        compEarned = CompEarned(
            id = "mock-comp-uuid-001",
            amount = 100.00,
            status = "pending_choice",
            requiresPayoutChoice = true
        ),
        milestoneHit = false,
        walletBalance = 1252.25,
        globalScanCount = 1_487_392
    )

    private val mockScanHistory = listOf(
        Scan(id = 1, qrCode = "ABCD-1234-EFGH", productName = "BlakJaks Classic", productSku = "BJC-001", usdcEarned = 1.50, tierMultiplier = 1.5, tier = "VIP", createdAt = "2026-02-20T11:30:00Z"),
        Scan(id = 2, qrCode = "IJKL-5678-MNOP", productName = "BlakJaks Gold", productSku = "BJG-001", usdcEarned = 2.00, tierMultiplier = 1.5, tier = "VIP", createdAt = "2026-02-19T15:00:00Z"),
        Scan(id = 3, qrCode = "QRST-9012-UVWX", productName = "BlakJaks Frost", productSku = "BJF-001", usdcEarned = 1.50, tierMultiplier = 1.5, tier = "VIP", createdAt = "2026-02-18T09:15:00Z"),
        Scan(id = 4, qrCode = "YZAB-3456-CDEF", productName = "BlakJaks Classic", productSku = "BJC-001", usdcEarned = 1.50, tierMultiplier = 1.5, tier = "VIP", createdAt = "2026-02-17T14:45:00Z")
    )

    private val mockTransactions = listOf(
        Transaction(id = 1, type = "comp_earned", amount = 100.00, currency = "USD", status = "processed", description = "Milestone Comp — \$100 tier", createdAt = "2026-02-18T14:30:00Z", processedAt = "2026-02-18T14:30:00Z", txHash = null),
        Transaction(id = 2, type = "scan_earn", amount = 1.50, currency = "USD", status = "processed", description = "QR Scan Earn — BlakJaks Classic (1.5x VIP)", createdAt = "2026-02-18T13:00:00Z", processedAt = "2026-02-18T13:00:00Z", txHash = null),
        Transaction(id = 3, type = "bank_withdrawal", amount = -200.00, currency = "USD", status = "processed", description = "ACH Withdrawal to Chase ••4242", createdAt = "2026-02-17T10:00:00Z", processedAt = "2026-02-19T10:00:00Z", txHash = null),
        Transaction(id = 4, type = "crypto_withdrawal", amount = -50.00, currency = "USDC", status = "pending", description = "USDC Withdrawal to 0xabc…def", createdAt = "2026-02-20T11:00:00Z", processedAt = null, txHash = "0xabc123def456"),
        Transaction(id = 5, type = "guaranteed_comp", amount = 50.00, currency = "USD", status = "processed", description = "Monthly Guaranteed Comp — February 2026", createdAt = "2026-02-01T02:00:00Z", processedAt = "2026-02-01T02:00:00Z", txHash = null)
    )

    private val mockCompVault = CompVault(
        availableBalance = 1250.75,
        lifetimeComps = 4820.50,
        goldChips = 42,
        milestones = listOf(
            CompMilestone(id = "100", threshold = 100.0, label = "\$100 Milestone", achieved = true, achievedAt = "2025-03-01T00:00:00Z"),
            CompMilestone(id = "1000", threshold = 1000.0, label = "\$1,000 Milestone", achieved = true, achievedAt = "2025-08-15T00:00:00Z"),
            CompMilestone(id = "10000", threshold = 10000.0, label = "\$10,000 Milestone", achieved = false, achievedAt = null),
            CompMilestone(id = "200000", threshold = 200000.0, label = "\$200K Vegas Trip", achieved = false, achievedAt = null)
        ),
        guaranteedComps = listOf(
            GuaranteedComp(id = 1, amount = 50.00, month = "February 2026", status = "paid", paidAt = "2026-02-01T02:00:00Z"),
            GuaranteedComp(id = 2, amount = 50.00, month = "January 2026", status = "paid", paidAt = "2026-01-01T02:00:00Z")
        )
    )

    private val mockProducts = listOf(
        Product(id = 1, name = "BlakJaks Classic", sku = "BJC-001", description = "Our flagship nicotine pouch — smooth, bold, and balanced.", price = 12.99, imageUrl = null, category = "pouches", flavor = "Classic Mint", nicotineStrength = "6mg", inStock = true, stockCount = 500),
        Product(id = 2, name = "BlakJaks Gold", sku = "BJG-001", description = "Premium gold-tier blend with enhanced nicotine delivery.", price = 15.99, imageUrl = null, category = "pouches", flavor = "Spearmint", nicotineStrength = "8mg", inStock = true, stockCount = 250),
        Product(id = 3, name = "BlakJaks Frost", sku = "BJF-001", description = "Ice-cold menthol blast for maximum freshness.", price = 12.99, imageUrl = null, category = "pouches", flavor = "Arctic Frost", nicotineStrength = "4mg", inStock = true, stockCount = 180),
        Product(id = 4, name = "BlakJaks Citrus", sku = "BJCT-001", description = "Bright citrus notes with a clean finish.", price = 12.99, imageUrl = null, category = "pouches", flavor = "Blood Orange", nicotineStrength = "6mg", inStock = false, stockCount = 0)
    )

    private val mockCartItems = listOf(
        CartItem(id = 1, productId = 1, productName = "BlakJaks Classic", imageUrl = null, quantity = 2, unitPrice = 12.99, lineTotal = 25.98),
        CartItem(id = 2, productId = 2, productName = "BlakJaks Gold", imageUrl = null, quantity = 1, unitPrice = 15.99, lineTotal = 15.99)
    )

    private val mockCart = Cart(
        items = mockCartItems,
        subtotal = 41.97,
        itemCount = 3
    )

    private val mockShippingAddress = ShippingAddress(
        firstName = "Alex",
        lastName = "Johnson",
        line1 = "123 Main St",
        line2 = null,
        city = "Austin",
        state = "TX",
        zip = "78701",
        country = "US"
    )

    private val mockOrder = Order(
        id = 1001,
        status = "processing",
        items = mockCartItems,
        shippingAddress = mockShippingAddress,
        subtotal = 41.97,
        taxAmount = 3.78,
        total = 45.75,
        ageVerificationId = "age-verified-uuid",
        createdAt = "2026-02-20T12:00:00Z",
        trackingNumber = null
    )

    // ─── Auth ────────────────────────────────────────────────────────────────

    override suspend fun login(email: String, password: String): AuthTokens =
        AuthTokens(accessToken = "mock-access-token", refreshToken = "mock-refresh-token", tokenType = "Bearer")

    override suspend fun signup(email: String, password: String, fullName: String, dateOfBirth: String): AuthTokens =
        AuthTokens(accessToken = "mock-access-token", refreshToken = "mock-refresh-token", tokenType = "Bearer")

    override suspend fun logout() {}

    // ─── User ────────────────────────────────────────────────────────────────

    override suspend fun getMe(): UserProfile = mockUser

    override suspend fun updateProfile(fullName: String?, bio: String?): UserProfile = mockUser

    override suspend fun getMemberCard(): MemberCard = MemberCard(
        memberId = "BJ-0001-VIP",
        fullName = "Alex Johnson",
        tier = "VIP",
        joinDate = "2024-01-15",
        avatarUrl = null,
        walletBalance = 1250.75
    )

    override suspend fun getWallet(): WalletDetail = mockWallet

    // ─── Insights ────────────────────────────────────────────────────────────

    override suspend fun getInsightsOverview(): InsightsOverview = mockOverview
    override suspend fun getInsightsTreasury(): InsightsTreasury = mockTreasury
    override suspend fun getInsightsSystems(): InsightsSystems = mockSystems
    override suspend fun getInsightsComps(): InsightsComps = mockComps
    override suspend fun getInsightsPartners(): InsightsPartners = mockPartners
    override suspend fun getInsightsFeed(limit: Int, offset: Int): List<ActivityFeedItem> = mockFeedItems

    // ─── Scan & Wallet ───────────────────────────────────────────────────────

    override suspend fun submitScan(qrCode: String): ScanResult = mockScanResult

    override suspend fun getScanHistory(limit: Int, offset: Int): List<Scan> = mockScanHistory

    override suspend fun getTransactions(limit: Int, offset: Int): List<Transaction> = mockTransactions

    override suspend fun getCompVault(): CompVault = mockCompVault

    override suspend fun withdraw(amount: Double, toAddress: String?, method: String): Transaction =
        Transaction(
            id = 999,
            type = if (method == "crypto") "crypto_withdrawal" else "bank_withdrawal",
            amount = -amount,
            currency = if (method == "crypto") "USDC" else "USD",
            status = "pending",
            description = "Withdrawal of \$${"%.2f".format(amount)}",
            createdAt = "2026-02-20T12:00:00Z",
            processedAt = null,
            txHash = if (method == "crypto") "0xmocktxhash" else null
        )

    override suspend fun submitPayoutChoice(compId: String, method: String): CompPayoutResult =
        CompPayoutResult(
            compId = compId,
            method = method,
            status = "held",
            amount = 100.00
        )

    // ─── Shop ────────────────────────────────────────────────────────────────

    override suspend fun getProducts(category: String?, limit: Int, offset: Int): List<Product> = mockProducts

    override suspend fun getProduct(id: Int): Product = mockProducts.firstOrNull { it.id == id } ?: mockProducts[0]

    override suspend fun getCart(): Cart = mockCart

    override suspend fun addToCart(productId: Int, quantity: Int): Cart = mockCart

    override suspend fun updateCartItem(productId: Int, quantity: Int): Cart = mockCart

    override suspend fun removeFromCart(productId: Int): Cart = Cart(items = emptyList(), subtotal = 0.0, itemCount = 0)

    override suspend fun estimateTax(shippingAddress: ShippingAddress): TaxEstimate =
        TaxEstimate(
            subtotal = 29.97,
            taxAmount = 2.70,
            taxRate = 0.09,
            total = 32.67,
            jurisdiction = "TX"
        )

    override suspend fun createOrder(shippingAddress: ShippingAddress, paymentToken: String): Order = mockOrder

    // ─── Notifications ───────────────────────────────────────────────────────

    override suspend fun getNotifications(typeFilter: String?, limit: Int, offset: Int): List<AppNotification> = listOf(
        AppNotification(
            id = 1,
            type = "comp_earned",
            title = "Comp Earned!",
            body = "You earned \$100 USDC — milestone reached.",
            isRead = false,
            createdAt = "2026-02-20T12:00:00Z",
            data = mapOf("amount" to "100")
        ),
        AppNotification(
            id = 2,
            type = "tier_upgrade",
            title = "Tier Upgraded",
            body = "You've been upgraded to VIP tier.",
            isRead = true,
            createdAt = "2026-02-19T09:00:00Z",
            data = mapOf("new_tier" to "VIP")
        )
    )

    override suspend fun markNotificationRead(id: Int) {}

    override suspend fun markAllNotificationsRead() {}

    override suspend fun getUnreadCount(): Int = 1

    // ─── Social ──────────────────────────────────────────────────────────────

    override suspend fun getChannels(): List<Channel> = listOf(
        Channel(id = 1, name = "General", category = "community", description = "Main community chat", memberCount = 1234, lastMessageAt = "2026-02-20T12:00:00Z"),
        Channel(id = 2, name = "Flavors", category = "governance", description = "Vote on new flavors", memberCount = 567, lastMessageAt = "2026-02-20T11:00:00Z"),
        Channel(id = 3, name = "VIP Lounge", category = "tier", description = "VIP+ exclusive chat", memberCount = 89, lastMessageAt = "2026-02-20T10:00:00Z")
    )

    override suspend fun getMessages(channelId: Int, limit: Int, before: Int?): List<ChatMessage> = listOf(
        ChatMessage(
            id = 1,
            channelId = channelId,
            userId = 2,
            userFullName = "Alex J.",
            userAvatarUrl = null,
            userTier = "VIP",
            content = "Welcome to BlakJaks!",
            mediaType = null,
            mediaUrl = null,
            reactionSummary = mapOf("\uD83D\uDD25" to 3),
            createdAt = "2026-02-20T11:55:00Z"
        )
    )

    override suspend fun sendMessage(channelId: Int, content: String, mediaType: String?): ChatMessage =
        ChatMessage(
            id = Random.nextInt(1000, 9999),
            channelId = channelId,
            userId = 1,
            userFullName = "You",
            userAvatarUrl = null,
            userTier = "VIP",
            content = content,
            mediaType = mediaType,
            mediaUrl = null,
            reactionSummary = null,
            createdAt = "2026-02-20T12:01:00Z"
        )

    override suspend fun translateMessage(messageId: Int, targetLanguage: String): TranslatedMessage =
        TranslatedMessage(translatedText = "Translated text here", sourceLanguage = "en", cached = false)

    override suspend fun addReaction(messageId: Int, emoji: String) {}

    override suspend fun removeReaction(messageId: Int, emoji: String) {}

    // ─── Affiliate ───────────────────────────────────────────────────────────

    override suspend fun getAffiliateDashboard(): AffiliateDashboard =
        AffiliateDashboard(
            referralCode = "ALEX123",
            totalDownline = 42,
            activeDownline = 38,
            weeklyPool = 850.00,
            lifetimeEarnings = 4200.00,
            chipBalance = 210,
            nextPayoutDate = "2026-02-23",
            sunsetEngineActive = true
        )

    override suspend fun getAffiliatePayouts(limit: Int, offset: Int): List<AffiliatePayout> = listOf(
        AffiliatePayout(id = 1, amount = 250.00, payoutDate = "2026-02-16", status = "processed", poolShare = 0.062),
        AffiliatePayout(id = 2, amount = 180.00, payoutDate = "2026-02-09", status = "processed", poolShare = 0.048)
    )

    override suspend fun getAffiliateReferralCode(): ReferralCode =
        ReferralCode(code = "ALEX123", referralUrl = "https://blakjaks.com/ref/ALEX123", totalUses = 42)
}
