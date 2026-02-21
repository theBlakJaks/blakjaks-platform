package com.blakjaks.app.features.insights.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.components.*
import com.blakjaks.app.core.network.models.ActivityFeedItem
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.insights.InsightsTab
import com.blakjaks.app.features.insights.InsightsViewModel
import com.blakjaks.app.navigation.Screen
import org.koin.androidx.compose.koinViewModel
import java.text.NumberFormat
import java.time.Instant
import java.time.temporal.ChronoUnit

// ─── InsightsMenuScreen ───────────────────────────────────────────────────────
// Main Insights tab. Mirrors iOS InsightsMenuView.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsMenuScreen(navController: NavController) {
    val viewModel: InsightsViewModel = koinViewModel()
    val overview by viewModel.overview.collectAsState()
    val treasury by viewModel.treasury.collectAsState()
    val activityFeed by viewModel.activityFeed.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    var isRefreshing by remember { mutableStateOf(false) }

    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = {
            isRefreshing = true
            viewModel.refresh()
            isRefreshing = false
        },
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(BackgroundPrimary),
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            // ─── Header ──────────────────────────────────────────────────────
            item {
                InsightsHeader(navController = navController)
            }

            // ─── Nicotine Warning Banner ──────────────────────────────────────
            item {
                NicotineWarningBanner()
            }

            // ─── Live Stats Card (GoldAccentCard) ─────────────────────────────
            item {
                GoldAccentCard(modifier = Modifier.padding(horizontal = Layout.screenMargin)) {
                    Text(
                        text = "Live Stats",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    if (overview == null) {
                        LoadingView(modifier = Modifier.fillMaxWidth())
                    } else {
                        val ov = overview!!
                        StatRow(
                            label = "Total Scans",
                            value = NumberFormat.getNumberInstance().format(ov.globalScanCount)
                        )
                        StatRow(
                            label = "Active Members",
                            value = NumberFormat.getNumberInstance().format(ov.activeMembers)
                        )
                        StatRow(
                            label = "Payouts (24h)",
                            value = "$${"%,.2f".format(ov.payoutsLast24h)}"
                        )
                    }
                }
            }

            // ─── Treasury Card (BlakJaksCard) ─────────────────────────────────
            item {
                BlakJaksCard(modifier = Modifier.padding(horizontal = Layout.screenMargin)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Treasury",
                            color = Gold,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp
                        )
                        if (treasury?.reconciliationStatus?.status?.lowercase() == "ok") {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .background(Success, CircleShape)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "Healthy",
                                    color = Success,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    if (treasury == null) {
                        LoadingView(modifier = Modifier.fillMaxWidth())
                    } else {
                        val t = treasury!!
                        val totalOnChain = t.onChainBalances.sumOf { it.balance }
                        StatRow(
                            label = "On-Chain Total",
                            value = "$${"%,.2f".format(totalOnChain)} USDC"
                        )
                        t.bankBalances.forEach { bank ->
                            StatRow(
                                label = bank.accountName,
                                value = "$${"%,.2f".format(bank.balance)}"
                            )
                        }
                        StatRow(
                            label = "Reconciled",
                            value = t.reconciliationStatus.lastRunAt.take(10)
                        )
                    }
                }
            }

            // ─── Activity Feed ────────────────────────────────────────────────
            item {
                Text(
                    text = "Live Activity",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    modifier = Modifier.padding(horizontal = Layout.screenMargin)
                )
            }
            if (activityFeed == null) {
                item { LoadingView(modifier = Modifier.padding(horizontal = Layout.screenMargin)) }
            } else {
                items(activityFeed ?: emptyList()) { item ->
                    ActivityFeedRow(item = item)
                }
            }

            // ─── Quick Nav Grid ───────────────────────────────────────────────
            item {
                Text(
                    text = "Insights",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    modifier = Modifier.padding(horizontal = Layout.screenMargin)
                )
                Spacer(modifier = Modifier.height(Spacing.sm))
                QuickNavGrid(navController = navController)
                Spacer(modifier = Modifier.height(Spacing.xl))
            }
        }
    }
}

// ─── InsightsHeader ───────────────────────────────────────────────────────────

@Composable
private fun InsightsHeader(navController: NavController) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Layout.screenMargin, vertical = Spacing.md),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "BlakJaks",
            color = Gold,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.Bold,
            fontSize = 22.sp
        )
        IconButton(
            onClick = {
                navController.navigate("notifications")
            }
        ) {
            Icon(
                imageVector = Icons.Default.Notifications,
                contentDescription = "Notifications",
                tint = TextPrimary
            )
        }
    }
}

// ─── StatRow ──────────────────────────────────────────────────────────────────

@Composable
private fun StatRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, color = TextSecondary, fontSize = 14.sp)
        Text(text = value, color = TextPrimary, fontWeight = FontWeight.Medium, fontSize = 14.sp)
    }
}

// ─── ActivityFeedRow ─────────────────────────────────────────────────────────

@Composable
private fun ActivityFeedRow(item: ActivityFeedItem) {
    val dotColor = when (item.type) {
        "comp_awarded", "comp_earned" -> Gold
        "scan"                        -> Info
        "payout"                      -> Success
        "milestone"                   -> Warning
        else                          -> TextDim
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Layout.screenMargin, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .background(dotColor, CircleShape)
        )
        Spacer(modifier = Modifier.width(Spacing.sm))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.description,
                color = TextPrimary,
                fontSize = 13.sp,
                maxLines = 2
            )
        }
        Spacer(modifier = Modifier.width(Spacing.sm))
        Text(
            text = relativeTime(item.createdAt),
            color = TextDim,
            fontSize = 11.sp
        )
    }
}

// ─── QuickNavGrid ─────────────────────────────────────────────────────────────

private data class NavTile(
    val label: String,
    val icon: ImageVector,
    val route: String
)

@Composable
private fun QuickNavGrid(navController: NavController) {
    val tiles = listOf(
        NavTile("Treasury", Icons.Default.AccountBalance, "insights_treasury"),
        NavTile("Systems",  Icons.Default.Memory,         "insights_systems"),
        NavTile("Comps",    Icons.Default.CardGiftcard,   "insights_comps"),
        NavTile("Partners", Icons.Default.People,         "insights_partners")
    )
    Column(
        modifier = Modifier.padding(horizontal = Layout.screenMargin),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        tiles.chunked(2).forEach { rowTiles ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
            ) {
                rowTiles.forEach { tile ->
                    QuickNavTile(
                        tile = tile,
                        modifier = Modifier.weight(1f),
                        onClick = { navController.navigate(tile.route) }
                    )
                }
                // Pad last row if odd number of tiles
                if (rowTiles.size == 1) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun QuickNavTile(
    tile: NavTile,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier
            .height(80.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(Layout.cardCornerRadius),
        colors = CardDefaults.cardColors(containerColor = BackgroundCard),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(Spacing.md),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = tile.icon,
                contentDescription = tile.label,
                tint = Gold,
                modifier = Modifier.size(22.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = tile.label,
                color = TextPrimary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

// ─── Utility ─────────────────────────────────────────────────────────────────

private fun relativeTime(isoTimestamp: String): String {
    return try {
        val instant = Instant.parse(isoTimestamp)
        val now = Instant.now()
        val minutes = ChronoUnit.MINUTES.between(instant, now)
        when {
            minutes < 1   -> "just now"
            minutes < 60  -> "${minutes}m ago"
            minutes < 1440 -> "${minutes / 60}h ago"
            else          -> "${minutes / 1440}d ago"
        }
    } catch (e: Exception) {
        ""
    }
}
