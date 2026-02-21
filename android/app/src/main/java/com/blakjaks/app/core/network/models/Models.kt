package com.blakjaks.app.core.network.models

import com.google.gson.annotations.SerializedName

// ─── Auth ───────────────────────────────────────────────────────────────────

data class AuthTokens(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String,
    @SerializedName("token_type") val tokenType: String
)

data class LoginRequest(
    @SerializedName("email") val email: String,
    @SerializedName("password") val password: String
)

data class SignupRequest(
    @SerializedName("email") val email: String,
    @SerializedName("password") val password: String,
    @SerializedName("full_name") val fullName: String,
    @SerializedName("date_of_birth") val dateOfBirth: String
)

data class TokenRefreshRequest(
    @SerializedName("refresh_token") val refreshToken: String
)

// ─── User / Profile ──────────────────────────────────────────────────────────

data class UserProfile(
    @SerializedName("id") val id: Int,
    @SerializedName("email") val email: String,
    @SerializedName("full_name") val fullName: String,
    @SerializedName("member_id") val memberId: String,
    @SerializedName("tier") val tier: String,
    @SerializedName("avatar_url") val avatarUrl: String?,
    @SerializedName("bio") val bio: String?,
    @SerializedName("wallet_balance") val walletBalance: Double,
    @SerializedName("pending_balance") val pendingBalance: Double,
    @SerializedName("gold_chips") val goldChips: Int,
    @SerializedName("lifetime_usdc") val lifetimeUsdc: Double,
    @SerializedName("scans_this_quarter") val scansThisQuarter: Int,
    @SerializedName("is_affiliate") val isAffiliate: Boolean,
    @SerializedName("created_at") val createdAt: String
)

data class UpdateProfileRequest(
    @SerializedName("full_name") val fullName: String?,
    @SerializedName("bio") val bio: String?
)

data class PushTokenRequest(
    @SerializedName("push_token") val pushToken: String,
    @SerializedName("platform") val platform: String = "android"
)

data class MemberCard(
    @SerializedName("member_id") val memberId: String,
    @SerializedName("full_name") val fullName: String,
    @SerializedName("tier") val tier: String,
    @SerializedName("join_date") val joinDate: String,
    @SerializedName("avatar_url") val avatarUrl: String?,
    @SerializedName("wallet_balance") val walletBalance: Double
)

data class WalletDetail(
    @SerializedName("comp_balance") val compBalance: Double,
    @SerializedName("available_balance") val availableBalance: Double,
    @SerializedName("pending_balance") val pendingBalance: Double,
    @SerializedName("currency") val currency: String,
    @SerializedName("wallet_address") val walletAddress: String?,
    @SerializedName("linked_bank_account") val linkedBankAccount: DwollaFundingSource?
)

// ─── Insights ────────────────────────────────────────────────────────────────

data class InsightsOverview(
    @SerializedName("global_scan_count") val globalScanCount: Int,
    @SerializedName("active_members") val activeMembers: Int,
    @SerializedName("payouts_last_24h") val payoutsLast24h: Double,
    @SerializedName("live_feed") val liveFeed: List<ActivityFeedItem>,
    @SerializedName("milestone_progress") val milestoneProgress: List<MilestoneProgress>
)

data class MilestoneProgress(
    @SerializedName("id") val id: String,
    @SerializedName("label") val label: String,
    @SerializedName("current") val current: Double,
    @SerializedName("target") val target: Double,
    @SerializedName("percentage") val percentage: Double
)

data class ActivityFeedItem(
    @SerializedName("id") val id: Int,
    @SerializedName("type") val type: String,
    @SerializedName("description") val description: String,
    @SerializedName("amount") val amount: Double?,
    @SerializedName("user_id") val userId: Int?,
    @SerializedName("created_at") val createdAt: String
)

data class InsightsTreasury(
    @SerializedName("on_chain_balances") val onChainBalances: List<PoolBalance>,
    @SerializedName("bank_balances") val bankBalances: List<BankBalance>,
    @SerializedName("dwolla_platform_balance") val dwollaPlatformBalance: DwollaBalance,
    @SerializedName("sparklines") val sparklines: Map<String, List<SparklinePoint>>,
    @SerializedName("reconciliation_status") val reconciliationStatus: ReconciliationStatus,
    @SerializedName("payout_ledger") val payoutLedger: List<PayoutLedgerEntry>
)

data class PoolBalance(
    @SerializedName("id") val id: String,
    @SerializedName("pool_type") val poolType: String,
    @SerializedName("balance") val balance: Double,
    @SerializedName("currency") val currency: String,
    @SerializedName("wallet_address") val walletAddress: String
)

data class BankBalance(
    @SerializedName("id") val id: String,
    @SerializedName("account_name") val accountName: String,
    @SerializedName("institution") val institution: String,
    @SerializedName("balance") val balance: Double,
    @SerializedName("last_sync_at") val lastSyncAt: String
)

data class DwollaBalance(
    @SerializedName("available") val available: Double,
    @SerializedName("total") val total: Double,
    @SerializedName("currency") val currency: String
)

data class SparklinePoint(
    @SerializedName("timestamp") val timestamp: String,
    @SerializedName("value") val value: Double
)

data class ReconciliationStatus(
    @SerializedName("last_run_at") val lastRunAt: String,
    @SerializedName("status") val status: String,
    @SerializedName("variance") val variance: Double,
    @SerializedName("tolerance") val tolerance: Double
)

data class PayoutLedgerEntry(
    @SerializedName("id") val id: Int,
    @SerializedName("amount") val amount: Double,
    @SerializedName("type") val type: String,
    @SerializedName("recipient_member_id") val recipientMemberId: String,
    @SerializedName("status") val status: String,
    @SerializedName("created_at") val createdAt: String
)

data class InsightsSystems(
    @SerializedName("comp_budget_health") val compBudgetHealth: CompBudgetHealth,
    @SerializedName("payout_pipeline_queue_depth") val payoutPipelineQueueDepth: Int,
    @SerializedName("payout_pipeline_success_rate") val payoutPipelineSuccessRate: Double,
    @SerializedName("scan_velocity") val scanVelocity: ScanVelocity,
    @SerializedName("polygon_node_status") val polygonNodeStatus: NodeStatus,
    @SerializedName("teller_last_sync") val tellerLastSync: String,
    @SerializedName("tier_distribution") val tierDistribution: Map<String, Int>
)

data class CompBudgetHealth(
    @SerializedName("total_budget") val totalBudget: Double,
    @SerializedName("used_budget") val usedBudget: Double,
    @SerializedName("remaining_budget") val remainingBudget: Double,
    @SerializedName("percent_used") val percentUsed: Double,
    @SerializedName("projected_exhaustion_date") val projectedExhaustionDate: String?
)

data class ScanVelocity(
    @SerializedName("per_minute") val perMinute: Double,
    @SerializedName("per_hour") val perHour: Double,
    @SerializedName("last_60_min") val last60Min: List<SparklinePoint>
)

data class NodeStatus(
    @SerializedName("connected") val connected: Boolean,
    @SerializedName("block_number") val blockNumber: Int?,
    @SerializedName("syncing") val syncing: Boolean,
    @SerializedName("provider") val provider: String
)

data class InsightsComps(
    @SerializedName("tier_100") val tier100: CompTierStats,
    @SerializedName("tier_1k") val tier1k: CompTierStats,
    @SerializedName("tier_10k") val tier10k: CompTierStats,
    @SerializedName("tier_200k_trip") val tier200kTrip: CompTierStats,
    @SerializedName("milestone_progress") val milestoneProgress: List<MilestoneProgress>,
    @SerializedName("guaranteed_comp_totals") val guaranteedCompTotals: GuaranteedCompTotals,
    @SerializedName("vault_economy") val vaultEconomy: VaultEconomy
)

data class CompTierStats(
    @SerializedName("total_paid") val totalPaid: Double,
    @SerializedName("total_recipients") val totalRecipients: Int,
    @SerializedName("average_payout") val averagePayout: Double,
    @SerializedName("period_label") val periodLabel: String
)

data class GuaranteedCompTotals(
    @SerializedName("total_paid_this_year") val totalPaidThisYear: Double,
    @SerializedName("total_recipients") val totalRecipients: Int,
    @SerializedName("next_run_date") val nextRunDate: String
)

data class VaultEconomy(
    @SerializedName("total_in_vaults") val totalInVaults: Double,
    @SerializedName("avg_vault_balance") val avgVaultBalance: Double,
    @SerializedName("gold_chips_issued") val goldChipsIssued: Int
)

data class InsightsPartners(
    @SerializedName("affiliate_active_count") val affiliateActiveCount: Int,
    @SerializedName("sunset_engine_status") val sunsetEngineStatus: String,
    @SerializedName("weekly_pool") val weeklyPool: Double,
    @SerializedName("lifetime_match_total") val lifetimeMatchTotal: Double,
    @SerializedName("permanent_tier_floor_counts") val permanentTierFloorCounts: Map<String, Int>,
    @SerializedName("wholesale_active_accounts") val wholesaleActiveAccounts: Int,
    @SerializedName("wholesale_order_value_this_month") val wholesaleOrderValueThisMonth: Double
)

// ─── Scan & Wallet ───────────────────────────────────────────────────────────

data class ScanSubmitRequest(
    @SerializedName("qr_code") val qrCode: String
)

data class ScanResult(
    @SerializedName("success") val success: Boolean,
    @SerializedName("product_name") val productName: String,
    @SerializedName("usdc_earned") val usdcEarned: Double,
    @SerializedName("tier_multiplier") val tierMultiplier: Double,
    @SerializedName("tier_progress") val tierProgress: TierProgress,
    @SerializedName("comp_earned") val compEarned: CompEarned?,
    @SerializedName("milestone_hit") val milestoneHit: Boolean,
    @SerializedName("wallet_balance") val walletBalance: Double,
    @SerializedName("global_scan_count") val globalScanCount: Int
)

data class TierProgress(
    @SerializedName("quarter") val quarter: String,
    @SerializedName("current_count") val currentCount: Int,
    @SerializedName("next_tier") val nextTier: String?,
    @SerializedName("scans_required") val scansRequired: Int?
)

data class CompEarned(
    @SerializedName("id") val id: String,
    @SerializedName("amount") val amount: Double,
    @SerializedName("status") val status: String,
    @SerializedName("requires_payout_choice") val requiresPayoutChoice: Boolean
)

data class Scan(
    @SerializedName("id") val id: Int,
    @SerializedName("qr_code") val qrCode: String,
    @SerializedName("product_name") val productName: String,
    @SerializedName("product_sku") val productSku: String,
    @SerializedName("usdc_earned") val usdcEarned: Double,
    @SerializedName("tier_multiplier") val tierMultiplier: Double,
    @SerializedName("tier") val tier: String,
    @SerializedName("created_at") val createdAt: String
)

data class Transaction(
    @SerializedName("id") val id: Int,
    @SerializedName("type") val type: String,
    @SerializedName("amount") val amount: Double,
    @SerializedName("currency") val currency: String,
    @SerializedName("status") val status: String,
    @SerializedName("description") val description: String,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("processed_at") val processedAt: String?,
    @SerializedName("tx_hash") val txHash: String?
)

data class CompVault(
    @SerializedName("available_balance") val availableBalance: Double,
    @SerializedName("lifetime_comps") val lifetimeComps: Double,
    @SerializedName("gold_chips") val goldChips: Int,
    @SerializedName("milestones") val milestones: List<CompMilestone>,
    @SerializedName("guaranteed_comps") val guaranteedComps: List<GuaranteedComp>
)

data class CompMilestone(
    @SerializedName("id") val id: String,
    @SerializedName("threshold") val threshold: Double,
    @SerializedName("label") val label: String,
    @SerializedName("achieved") val achieved: Boolean,
    @SerializedName("achieved_at") val achievedAt: String?
)

data class GuaranteedComp(
    @SerializedName("id") val id: Int,
    @SerializedName("amount") val amount: Double,
    @SerializedName("month") val month: String,
    @SerializedName("status") val status: String,
    @SerializedName("paid_at") val paidAt: String?
)

data class WithdrawRequest(
    @SerializedName("amount") val amount: Double,
    @SerializedName("to_address") val toAddress: String?,
    @SerializedName("method") val method: String
)

data class CompPayoutChoiceRequest(
    @SerializedName("comp_id") val compId: String,
    @SerializedName("method") val method: String
)

data class CompPayoutResult(
    @SerializedName("comp_id") val compId: String,
    @SerializedName("method") val method: String,
    @SerializedName("status") val status: String,
    @SerializedName("amount") val amount: Double
)

// ─── Dwolla ──────────────────────────────────────────────────────────────────

data class DwollaFundingSource(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("bank_name") val bankName: String?,
    @SerializedName("last_four") val lastFour: String?,
    @SerializedName("type") val type: String,
    @SerializedName("status") val status: String
)

data class DwollaTransfer(
    @SerializedName("transfer_id") val transferId: String,
    @SerializedName("status") val status: String,
    @SerializedName("amount") val amount: Double,
    @SerializedName("estimated_arrival") val estimatedArrival: String
)

// ─── Shop ────────────────────────────────────────────────────────────────────

data class Product(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("sku") val sku: String,
    @SerializedName("description") val description: String,
    @SerializedName("price") val price: Double,
    @SerializedName("image_url") val imageUrl: String?,
    @SerializedName("category") val category: String,
    @SerializedName("flavor") val flavor: String,
    @SerializedName("nicotine_strength") val nicotineStrength: String,
    @SerializedName("in_stock") val inStock: Boolean,
    @SerializedName("stock_count") val stockCount: Int
)

data class Cart(
    @SerializedName("items") val items: List<CartItem>,
    @SerializedName("subtotal") val subtotal: Double,
    @SerializedName("item_count") val itemCount: Int
)

data class CartItem(
    @SerializedName("id") val id: Int,
    @SerializedName("product_id") val productId: Int,
    @SerializedName("product_name") val productName: String,
    @SerializedName("image_url") val imageUrl: String?,
    @SerializedName("quantity") val quantity: Int,
    @SerializedName("unit_price") val unitPrice: Double,
    @SerializedName("line_total") val lineTotal: Double
)

data class AddToCartRequest(
    @SerializedName("product_id") val productId: Int,
    @SerializedName("quantity") val quantity: Int
)

data class UpdateCartItemRequest(
    @SerializedName("product_id") val productId: Int,
    @SerializedName("quantity") val quantity: Int
)

data class ShippingAddress(
    @SerializedName("first_name") val firstName: String,
    @SerializedName("last_name") val lastName: String,
    @SerializedName("line1") val line1: String,
    @SerializedName("line2") val line2: String?,
    @SerializedName("city") val city: String,
    @SerializedName("state") val state: String,
    @SerializedName("zip") val zip: String,
    @SerializedName("country") val country: String
)

data class TaxEstimate(
    @SerializedName("subtotal") val subtotal: Double,
    @SerializedName("tax_amount") val taxAmount: Double,
    @SerializedName("tax_rate") val taxRate: Double,
    @SerializedName("total") val total: Double,
    @SerializedName("jurisdiction") val jurisdiction: String
)

data class CreateOrderRequest(
    @SerializedName("shipping_address") val shippingAddress: ShippingAddress,
    @SerializedName("payment_token") val paymentToken: String
)

data class Order(
    @SerializedName("id") val id: Int,
    @SerializedName("status") val status: String,
    @SerializedName("items") val items: List<CartItem>,
    @SerializedName("shipping_address") val shippingAddress: ShippingAddress,
    @SerializedName("subtotal") val subtotal: Double,
    @SerializedName("tax_amount") val taxAmount: Double,
    @SerializedName("total") val total: Double,
    @SerializedName("age_verification_id") val ageVerificationId: String?,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("tracking_number") val trackingNumber: String?
)

// ─── Notifications ───────────────────────────────────────────────────────────

data class AppNotification(
    @SerializedName("id") val id: Int,
    @SerializedName("type") val type: String,
    @SerializedName("title") val title: String,
    @SerializedName("body") val body: String,
    @SerializedName("is_read") val isRead: Boolean,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("data") val data: Map<String, String>?
)

data class UnreadCountResponse(
    @SerializedName("count") val count: Int
)

// ─── Social ──────────────────────────────────────────────────────────────────

data class Channel(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("category") val category: String,
    @SerializedName("description") val description: String?,
    @SerializedName("member_count") val memberCount: Int,
    @SerializedName("last_message_at") val lastMessageAt: String?
)

data class ChatMessage(
    @SerializedName("id") val id: Int,
    @SerializedName("channel_id") val channelId: Int,
    @SerializedName("user_id") val userId: Int,
    @SerializedName("user_full_name") val userFullName: String,
    @SerializedName("user_avatar_url") val userAvatarUrl: String?,
    @SerializedName("user_tier") val userTier: String,
    @SerializedName("content") val content: String,
    @SerializedName("media_type") val mediaType: String?,
    @SerializedName("media_url") val mediaUrl: String?,
    @SerializedName("reaction_summary") val reactionSummary: Map<String, Int>?,
    @SerializedName("created_at") val createdAt: String
)

data class SendMessageRequest(
    @SerializedName("content") val content: String,
    @SerializedName("media_type") val mediaType: String?
)

data class TranslateRequest(
    @SerializedName("target_language") val targetLanguage: String
)

data class TranslatedMessage(
    @SerializedName("translated_text") val translatedText: String,
    @SerializedName("source_language") val sourceLanguage: String,
    @SerializedName("cached") val cached: Boolean
)

data class ReactionRequest(
    @SerializedName("emoji") val emoji: String
)

// ─── Affiliate ───────────────────────────────────────────────────────────────

data class AffiliateDashboard(
    @SerializedName("referral_code") val referralCode: String,
    @SerializedName("total_downline") val totalDownline: Int,
    @SerializedName("active_downline") val activeDownline: Int,
    @SerializedName("weekly_pool") val weeklyPool: Double,
    @SerializedName("lifetime_earnings") val lifetimeEarnings: Double,
    @SerializedName("chip_balance") val chipBalance: Int,
    @SerializedName("next_payout_date") val nextPayoutDate: String,
    @SerializedName("sunset_engine_active") val sunsetEngineActive: Boolean
)

data class AffiliatePayout(
    @SerializedName("id") val id: Int,
    @SerializedName("amount") val amount: Double,
    @SerializedName("payout_date") val payoutDate: String,
    @SerializedName("status") val status: String,
    @SerializedName("pool_share") val poolShare: Double
)

data class ReferralCode(
    @SerializedName("code") val code: String,
    @SerializedName("referral_url") val referralUrl: String,
    @SerializedName("total_uses") val totalUses: Int
)
