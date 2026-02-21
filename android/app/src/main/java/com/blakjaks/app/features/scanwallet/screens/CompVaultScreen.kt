package com.blakjaks.app.features.scanwallet.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.network.models.Transaction
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.scanwallet.WalletViewModel
import org.koin.androidx.compose.koinViewModel
import java.time.Instant
import java.time.temporal.ChronoUnit

// ─── CompVaultScreen ──────────────────────────────────────────────────────────
// Shows comp history filtered from the full transaction list. Displays each
// comp deposit with earned amount, date, status, and payout destination.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CompVaultScreen(navController: NavController) {
    val viewModel: WalletViewModel = koinViewModel()
    val transactions by viewModel.transactions.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    // Filter to comp-related transaction types
    val compTransactions = remember(transactions) {
        transactions.filter { tx ->
            tx.type in listOf(
                "comp_earned",
                "comp_deposit",
                "guaranteed_comp",
                "comp_payout"
            )
        }
    }

    Scaffold(
        containerColor = BackgroundPrimary,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Comp Vault",
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
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(BackgroundPrimary)
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center),
                    color = Gold
                )
            } else if (compTransactions.isEmpty()) {
                // ─── Empty State ───────────────────────────────────────────────
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(Layout.screenMargin),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Savings,
                        contentDescription = null,
                        tint = TextDim,
                        modifier = Modifier.size(72.dp)
                    )
                    Spacer(modifier = Modifier.height(Spacing.md))
                    Text(
                        text = "No Comp History Yet",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    Text(
                        text = "Scan product QR codes to earn comps. Your comp history will appear here.",
                        color = TextSecondary,
                        fontSize = 14.sp,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        lineHeight = 20.sp
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(
                        horizontal = Layout.screenMargin,
                        vertical = Spacing.md
                    ),
                    verticalArrangement = Arrangement.spacedBy(Spacing.sm)
                ) {
                    // ─── Summary header ────────────────────────────────────────
                    item {
                        val totalEarned = compTransactions.filter { it.amount > 0 }.sumOf { it.amount }
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
                                Column {
                                    Text(
                                        text = "Total Comps Earned",
                                        color = TextSecondary,
                                        fontSize = 12.sp
                                    )
                                    Text(
                                        text = "$${"%,.2f".format(totalEarned)}",
                                        color = Gold,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 22.sp
                                    )
                                }
                                Text(
                                    text = "${compTransactions.size} comp${if (compTransactions.size != 1) "s" else ""}",
                                    color = TextSecondary,
                                    fontSize = 13.sp
                                )
                            }
                        }
                    }

                    item {
                        Text(
                            text = "Comp History",
                            color = TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            modifier = Modifier.padding(top = Spacing.xs)
                        )
                    }

                    // ─── Comp list items ───────────────────────────────────────
                    items(compTransactions) { tx ->
                        CompVaultRow(transaction = tx)
                    }

                    item { Spacer(modifier = Modifier.height(Spacing.xl)) }
                }
            }
        }
    }
}

// ─── CompVaultRow ─────────────────────────────────────────────────────────────

@Composable
private fun CompVaultRow(transaction: Transaction) {
    val statusColor = when (transaction.status) {
        "processed"  -> Success
        "pending"    -> Warning
        "failed"     -> Failure
        "cancelled"  -> Failure
        else         -> TextDim
    }

    // Derive a payout destination label from the transaction type
    val payoutDestination = when {
        transaction.type.contains("crypto") -> "Crypto (USDC)"
        transaction.type.contains("bank")   -> "Bank (ACH)"
        else                                 -> null
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = BackgroundCard),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Layout.cardPadding)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = transaction.description,
                        color = TextPrimary,
                        fontWeight = FontWeight.Medium,
                        fontSize = 14.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = relativeTimeComp(transaction.createdAt),
                        color = TextDim,
                        fontSize = 11.sp
                    )
                }
                Spacer(modifier = Modifier.width(Spacing.sm))
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "+${"%.2f".format(transaction.amount)}",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                    Text(
                        text = transaction.currency,
                        color = TextDim,
                        fontSize = 10.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.sm))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Status pill
                Surface(
                    color = statusColor.copy(alpha = 0.12f),
                    shape = RoundedCornerShape(6.dp)
                ) {
                    Text(
                        text = transaction.status.replaceFirstChar { it.uppercase() },
                        color = statusColor,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }

                // Payout destination
                payoutDestination?.let { dest ->
                    Text(
                        text = "→ $dest",
                        color = TextSecondary,
                        fontSize = 11.sp
                    )
                }
            }
        }
    }
}

// ─── Utility ──────────────────────────────────────────────────────────────────

private fun relativeTimeComp(isoTimestamp: String): String {
    return try {
        val instant = Instant.parse(isoTimestamp)
        val now = Instant.now()
        val days = ChronoUnit.DAYS.between(instant, now)
        val minutes = ChronoUnit.MINUTES.between(instant, now)
        when {
            minutes < 1    -> "just now"
            minutes < 60   -> "${minutes}m ago"
            minutes < 1440 -> "${minutes / 60}h ago"
            days < 30      -> "${days}d ago"
            else           -> isoTimestamp.take(10) // YYYY-MM-DD
        }
    } catch (e: Exception) {
        isoTimestamp.take(10)
    }
}
