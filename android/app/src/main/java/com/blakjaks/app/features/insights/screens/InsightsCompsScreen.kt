package com.blakjaks.app.features.insights.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.components.BlakJaksCard
import com.blakjaks.app.core.components.GoldAccentCard
import com.blakjaks.app.core.components.LoadingView
import com.blakjaks.app.core.network.models.CompTierStats
import com.blakjaks.app.core.network.models.MilestoneProgress
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.insights.InsightsViewModel
import org.koin.androidx.compose.koinViewModel

// ─── InsightsCompsScreen ──────────────────────────────────────────────────────
// Shows comp tier stats, guaranteed comp totals, vault economy, and milestones.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsCompsScreen(navController: NavController) {
    val viewModel: InsightsViewModel = koinViewModel()
    val comps by viewModel.comps.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadComps()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Comps",
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
        if (isLoading && comps == null) {
            LoadingView(modifier = Modifier.padding(paddingValues))
            return@Scaffold
        }

        val c = comps
        if (c == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text("No comps data available.", color = TextSecondary)
            }
            return@Scaffold
        }

        // Build tier list for display
        val tierStatList = listOf(
            "\$100 Tier" to c.tier100,
            "\$1K Tier"  to c.tier1k,
            "\$10K Tier" to c.tier10k,
            "\$200K Trip" to c.tier200kTrip
        )

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
            // ─── Comp Tier Stats ──────────────────────────────────────────────
            item {
                Text(
                    text = "Comp Tier Stats",
                    color = Gold,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp
                )
            }
            items(tierStatList) { (label, stats) ->
                CompTierCard(label = label, stats = stats)
            }

            // ─── Guaranteed Comp Totals ───────────────────────────────────────
            item {
                Spacer(modifier = Modifier.height(Spacing.xs))
                Text(
                    text = "Guaranteed Comps",
                    color = Gold,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp
                )
                Spacer(modifier = Modifier.height(Spacing.sm))
                BlakJaksCard {
                    CompStatRow(
                        label = "Total Paid This Year",
                        value = "$${"%,.2f".format(c.guaranteedCompTotals.totalPaidThisYear)}"
                    )
                    CompStatRow(
                        label = "Total Recipients",
                        value = "%,d".format(c.guaranteedCompTotals.totalRecipients)
                    )
                    CompStatRow(
                        label = "Next Run Date",
                        value = c.guaranteedCompTotals.nextRunDate
                    )
                }
            }

            // ─── Vault Economy ────────────────────────────────────────────────
            item {
                Spacer(modifier = Modifier.height(Spacing.xs))
                Text(
                    text = "Vault Economy",
                    color = Gold,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp
                )
                Spacer(modifier = Modifier.height(Spacing.sm))
                GoldAccentCard {
                    CompStatRow(
                        label = "Total Held in Vaults",
                        value = "$${"%,.2f".format(c.vaultEconomy.totalInVaults)}"
                    )
                    CompStatRow(
                        label = "Avg Vault Balance",
                        value = "$${"%,.2f".format(c.vaultEconomy.avgVaultBalance)}"
                    )
                    CompStatRow(
                        label = "Gold Chips Issued",
                        value = "%,d".format(c.vaultEconomy.goldChipsIssued)
                    )
                }
            }

            // ─── Milestone Progress ───────────────────────────────────────────
            if (c.milestoneProgress.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(Spacing.xs))
                    Text(
                        text = "Platform Milestones",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
                items(c.milestoneProgress) { milestone ->
                    MilestoneCard(milestone = milestone)
                }
            }

            item { Spacer(modifier = Modifier.height(Spacing.xl)) }
        }
    }
}

// ─── CompTierCard ─────────────────────────────────────────────────────────────

@Composable
private fun CompTierCard(label: String, stats: CompTierStats) {
    BlakJaksCard {
        Text(
            text = label,
            color = TextPrimary,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp
        )
        Spacer(modifier = Modifier.height(Spacing.xs))
        CompStatRow(label = "Total Paid", value = "$${"%,.2f".format(stats.totalPaid)}")
        CompStatRow(label = "Recipients", value = "%,d".format(stats.totalRecipients))
        CompStatRow(label = "Avg Payout", value = "$${"%,.2f".format(stats.averagePayout)}")
        CompStatRow(label = "Period", value = stats.periodLabel)
    }
}

// ─── MilestoneCard ────────────────────────────────────────────────────────────

@Composable
private fun MilestoneCard(milestone: MilestoneProgress) {
    BlakJaksCard {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = milestone.label,
                color = TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp
            )
            Text(
                text = "${"%.1f".format(milestone.percentage)}%",
                color = Gold,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp
            )
        }
        Spacer(modifier = Modifier.height(6.dp))
        // Progress bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(BackgroundSurface)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth((milestone.percentage / 100.0).coerceIn(0.0, 1.0).toFloat())
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(4.dp))
                    .background(Gold)
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "%,.0f".format(milestone.current),
                color = TextSecondary,
                fontSize = 11.sp
            )
            Text(
                text = "%,.0f".format(milestone.target),
                color = TextDim,
                fontSize = 11.sp
            )
        }
    }
}

// ─── CompStatRow ─────────────────────────────────────────────────────────────

@Composable
private fun CompStatRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 3.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, color = TextSecondary, fontSize = 13.sp)
        Text(text = value, color = TextPrimary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}
