package com.blakjaks.app.features.scanwallet.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.components.GoldAccentCard
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.network.models.CompEarned
import com.blakjaks.app.core.network.models.DwollaFundingSource
import com.blakjaks.app.core.network.models.Transaction
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.scanwallet.WalletViewModel
import org.koin.androidx.compose.koinViewModel
import java.time.Instant
import java.time.temporal.ChronoUnit

// ─── WalletDetailScreen ───────────────────────────────────────────────────────
// Full wallet detail screen navigated to from the Wallet sub-tab.
// Shows comp balance, pending comps, Dwolla/bank section, and transaction history.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WalletDetailScreen(navController: NavController) {
    val viewModel: WalletViewModel = koinViewModel()

    val walletDetail by viewModel.walletDetail.collectAsState()
    val transactions by viewModel.transactions.collectAsState()
    val dwollaFundingSources by viewModel.dwollaFundingSources.collectAsState()
    val pendingComps by viewModel.pendingComps.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val showWithdrawSheet by viewModel.showWithdrawSheet.collectAsState()
    val showLinkBankSheet by viewModel.showLinkBankSheet.collectAsState()
    val error by viewModel.error.collectAsState()
    val successMessage by viewModel.successMessage.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }

    // Show success message in snackbar
    LaunchedEffect(successMessage) {
        successMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearSuccessMessage()
        }
    }

    // Show error in snackbar
    LaunchedEffect(error) {
        error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    Scaffold(
        containerColor = BackgroundPrimary,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Wallet",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back",
                            tint = Gold
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BackgroundCard
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(BackgroundPrimary),
            contentPadding = PaddingValues(
                horizontal = Layout.screenMargin,
                vertical = Spacing.md
            ),
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {

            // ─── Comp Balance Card ─────────────────────────────────────────────
            item {
                GoldAccentCard {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Comp Balance",
                            color = TextSecondary,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.height(Spacing.xs))

                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(36.dp),
                                color = Gold,
                                strokeWidth = 2.5.dp
                            )
                        } else {
                            Text(
                                text = "$${"%,.2f".format(walletDetail?.compBalance ?: 0.0)}",
                                color = Gold,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 44.sp
                            )
                        }

                        Spacer(modifier = Modifier.height(Spacing.xs))
                        Text(
                            text = "BlakJaks Virtual Balance",
                            color = TextDim,
                            fontSize = 11.sp
                        )

                        walletDetail?.let { w ->
                            if (w.pendingBalance > 0) {
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "+${"%.2f".format(w.pendingBalance)} pending",
                                    color = TextSecondary,
                                    fontSize = 12.sp
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(Spacing.md))
                        GoldButton(
                            text = "Withdraw",
                            isLoading = isLoading,
                            onClick = { viewModel.openWithdrawSheet() }
                        )
                    }
                }
            }

            // ─── Pending Comps ─────────────────────────────────────────────────
            if (pendingComps.isNotEmpty()) {
                item {
                    Text(
                        text = "Pending Comps",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                }
                items(pendingComps) { comp ->
                    PendingCompRow(
                        comp = comp,
                        onChoosePayout = {
                            // PayoutChoiceSheet handled in ScanWalletScreen flow
                            // Here we open via parent navigation or state
                        }
                    )
                }
            }

            // ─── Dwolla / Bank Section ─────────────────────────────────────────
            item {
                Text(
                    text = "Bank Account",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }

            if (dwollaFundingSources.isEmpty()) {
                item {
                    SecondaryButton(
                        text = "Link Bank Account",
                        onClick = { viewModel.openLinkBankSheet() }
                    )
                }
            } else {
                items(dwollaFundingSources) { source ->
                    FundingSourceRow(source = source)
                }
                item {
                    SecondaryButton(
                        text = "Link Another Bank",
                        onClick = { viewModel.openLinkBankSheet() }
                    )
                }
            }

            // ─── Transaction History ───────────────────────────────────────────
            item {
                Text(
                    text = "Transaction History",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }

            if (transactions.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No transactions yet.",
                            color = TextSecondary
                        )
                    }
                }
            } else {
                items(transactions) { tx ->
                    TransactionRow(transaction = tx)
                }
            }

            item { Spacer(modifier = Modifier.height(Spacing.xl)) }
        }
    }

    // ─── Withdraw Bottom Sheet ─────────────────────────────────────────────────
    if (showWithdrawSheet) {
        WithdrawSheet(
            viewModel = viewModel,
            onDismiss = { viewModel.closeWithdrawSheet() }
        )
    }

    // ─── Link Bank Bottom Sheet ────────────────────────────────────────────────
    if (showLinkBankSheet) {
        LinkBankSheet(
            viewModel = viewModel,
            onDismiss = { viewModel.closeLinkBankSheet() }
        )
    }
}

// ─── PendingCompRow ────────────────────────────────────────────────────────────

@Composable
private fun PendingCompRow(
    comp: CompEarned,
    onChoosePayout: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = BackgroundCard),
        shape = RoundedCornerShape(Layout.cardCornerRadius)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Layout.cardPadding),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "${"%.2f".format(comp.amount)} comp",
                    color = TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                CompStatusPill(status = comp.status)
            }
            if (comp.status == "pending_choice") {
                Spacer(modifier = Modifier.width(Spacing.sm))
                Button(
                    onClick = onChoosePayout,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Gold,
                        contentColor = Color.Black
                    ),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = "Choose Payout",
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}

// ─── CompStatusPill ────────────────────────────────────────────────────────────

@Composable
private fun CompStatusPill(status: String) {
    val (backgroundColor, textColor, label) = when (status) {
        "pending_choice" -> Triple(Warning.copy(alpha = 0.15f), Warning, "Pending Choice")
        "held"           -> Triple(Info.copy(alpha = 0.15f), Info, "Held")
        "processing"     -> Triple(Gold.copy(alpha = 0.15f), Gold, "Processing")
        "completed"      -> Triple(Success.copy(alpha = 0.15f), Success, "Completed")
        "failed"         -> Triple(Failure.copy(alpha = 0.15f), Failure, "Failed")
        else             -> Triple(TextDim.copy(alpha = 0.15f), TextDim, status.replaceFirstChar { it.uppercase() })
    }

    Box(
        modifier = Modifier
            .background(backgroundColor, RoundedCornerShape(6.dp))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        Text(
            text = label,
            color = textColor,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// ─── FundingSourceRow ──────────────────────────────────────────────────────────

@Composable
private fun FundingSourceRow(source: DwollaFundingSource) {
    val statusColor = when (source.status) {
        "verified" -> Success
        "unverified" -> Warning
        "suspended" -> Failure
        else -> TextDim
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = BackgroundCard),
        shape = RoundedCornerShape(Layout.cardCornerRadius)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Layout.cardPadding),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.AccountBalance,
                contentDescription = null,
                tint = Success,
                modifier = Modifier.size(22.dp)
            )
            Spacer(modifier = Modifier.width(Spacing.sm))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = source.name,
                    color = TextPrimary,
                    fontWeight = FontWeight.Medium,
                    fontSize = 14.sp
                )
                source.lastFour?.let { last4 ->
                    Text(
                        text = "••$last4 · ${source.type.replaceFirstChar { it.uppercase() }}",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                }
            }
            // Status dot
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(statusColor)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = source.status.replaceFirstChar { it.uppercase() },
                color = statusColor,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

// ─── TransactionRow ───────────────────────────────────────────────────────────

@Composable
private fun TransactionRow(transaction: Transaction) {
    val isInbound = transaction.amount >= 0
    val amountColor = if (isInbound) Success else Failure
    val amountText = if (isInbound) "+${"%.2f".format(transaction.amount)}" else "${"%.2f".format(transaction.amount)}"

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
            // Direction icon
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(if (isInbound) Success.copy(alpha = 0.1f) else Failure.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isInbound) Icons.Default.ArrowUpward else Icons.Default.ArrowDownward,
                    contentDescription = null,
                    tint = amountColor,
                    modifier = Modifier.size(16.dp)
                )
            }
            Spacer(modifier = Modifier.width(Spacing.sm))
            Column {
                Text(
                    text = transaction.description,
                    color = TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1
                )
                Text(
                    text = relativeTimeTransaction(transaction.createdAt),
                    color = TextDim,
                    fontSize = 11.sp
                )
            }
        }
        Spacer(modifier = Modifier.width(Spacing.sm))
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = amountText,
                color = amountColor,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp
            )
            Text(
                text = transaction.currency,
                color = TextDim,
                fontSize = 10.sp
            )
        }
    }
}

// ─── Utility ──────────────────────────────────────────────────────────────────

private fun relativeTimeTransaction(isoTimestamp: String): String {
    return try {
        val instant = Instant.parse(isoTimestamp)
        val now = Instant.now()
        val minutes = ChronoUnit.MINUTES.between(instant, now)
        when {
            minutes < 1    -> "just now"
            minutes < 60   -> "${minutes}m ago"
            minutes < 1440 -> "${minutes / 60}h ago"
            else           -> "${minutes / 1440}d ago"
        }
    } catch (e: Exception) {
        isoTimestamp.take(10) // fallback: show date portion
    }
}
