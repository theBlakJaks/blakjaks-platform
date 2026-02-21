package com.blakjaks.app.features.insights.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.components.BlakJaksCard
import com.blakjaks.app.core.components.LoadingView
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.insights.InsightsViewModel
import org.koin.androidx.compose.koinViewModel

// ─── InsightsTreasuryScreen ───────────────────────────────────────────────────
// Shows on-chain pool balances, bank balances, Dwolla platform balance,
// and reconciliation status.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsTreasuryScreen(navController: NavController) {
    val viewModel: InsightsViewModel = koinViewModel()
    val treasury by viewModel.treasury.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadTreasury()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Treasury",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Gold
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BackgroundPrimary
                )
            )
        },
        containerColor = BackgroundPrimary
    ) { paddingValues ->
        if (isLoading && treasury == null) {
            LoadingView(modifier = Modifier.padding(paddingValues))
            return@Scaffold
        }

        val t = treasury
        if (t == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text("No treasury data available.", color = TextSecondary)
            }
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(BackgroundPrimary)
                .padding(paddingValues),
            verticalArrangement = Arrangement.spacedBy(Spacing.md),
            contentPadding = PaddingValues(
                horizontal = Layout.screenMargin,
                vertical = Spacing.md
            )
        ) {
            // ─── On-Chain Pools ───────────────────────────────────────────────
            item {
                SectionHeader(title = "On-Chain Pools")
            }
            items(t.onChainBalances) { pool ->
                BlakJaksCard {
                    Text(
                        text = pool.poolType.replace("_", " ").replaceFirstChar { it.uppercase() },
                        color = Gold,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "${"%,.2f".format(pool.balance)} ${pool.currency}",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = truncateAddress(pool.walletAddress),
                        color = TextDim,
                        fontSize = 12.sp
                    )
                }
            }

            // ─── Bank Balances ────────────────────────────────────────────────
            item {
                Spacer(modifier = Modifier.height(Spacing.xs))
                SectionHeader(title = "Bank Balances")
            }
            items(t.bankBalances) { bank ->
                BlakJaksCard {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = bank.accountName,
                                color = TextPrimary,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp
                            )
                            Text(
                                text = bank.institution,
                                color = TextSecondary,
                                fontSize = 12.sp
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "$${"%,.2f".format(bank.balance)}",
                                color = TextPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                            Text(
                                text = "Synced ${bank.lastSyncAt.take(10)}",
                                color = TextDim,
                                fontSize = 11.sp
                            )
                        }
                    }
                }
            }

            // ─── Dwolla Platform Balance ──────────────────────────────────────
            item {
                Spacer(modifier = Modifier.height(Spacing.xs))
                SectionHeader(title = "Dwolla Platform")
                Spacer(modifier = Modifier.height(Spacing.sm))
                BlakJaksCard {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "Available",
                                color = TextSecondary,
                                fontSize = 13.sp
                            )
                            Text(
                                text = "$${"%,.2f".format(t.dwollaPlatformBalance.available)}",
                                color = Success,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "Total",
                                color = TextSecondary,
                                fontSize = 13.sp
                            )
                            Text(
                                text = "$${"%,.2f".format(t.dwollaPlatformBalance.total)}",
                                color = TextPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                    }
                }
            }

            // ─── Reconciliation Status ────────────────────────────────────────
            item {
                Spacer(modifier = Modifier.height(Spacing.xs))
                SectionHeader(title = "Reconciliation")
                Spacer(modifier = Modifier.height(Spacing.sm))
                BlakJaksCard {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Status",
                                color = TextSecondary,
                                fontSize = 13.sp
                            )
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                val statusOk = t.reconciliationStatus.status.lowercase() == "ok"
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .background(
                                            if (statusOk) Success else Failure,
                                            CircleShape
                                        )
                                )
                                Text(
                                    text = t.reconciliationStatus.status.uppercase(),
                                    color = if (statusOk) Success else Failure,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp
                                )
                            }
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "Last Run",
                                color = TextSecondary,
                                fontSize = 13.sp
                            )
                            Text(
                                text = t.reconciliationStatus.lastRunAt.take(10),
                                color = TextPrimary,
                                fontSize = 14.sp
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Variance: $${"%,.2f".format(t.reconciliationStatus.variance)}",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                        Text(
                            text = "Tolerance: $${"%,.2f".format(t.reconciliationStatus.tolerance)}",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(Spacing.xl)) }
        }
    }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        color = Gold,
        fontWeight = FontWeight.Bold,
        fontSize = 15.sp
    )
}

private fun truncateAddress(address: String): String {
    return if (address.length > 12) "${address.take(6)}...${address.takeLast(4)}" else address
}
