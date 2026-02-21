package com.blakjaks.app.features.insights.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
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
import com.blakjaks.app.core.components.LoadingView
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.insights.InsightsViewModel
import org.koin.androidx.compose.koinViewModel

// ─── InsightsSystemsScreen ────────────────────────────────────────────────────
// Shows system health: node status, scan velocity, comp budget health bar.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsSystemsScreen(navController: NavController) {
    val viewModel: InsightsViewModel = koinViewModel()
    val systems by viewModel.systems.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadSystems()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Systems",
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
        if (isLoading && systems == null) {
            LoadingView(modifier = Modifier.padding(paddingValues))
            return@Scaffold
        }

        val s = systems
        if (s == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text("No system data available.", color = TextSecondary)
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
            // ─── Polygon Node Status ──────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Polygon Node",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .background(
                                        if (s.polygonNodeStatus.connected) Success else Failure,
                                        CircleShape
                                    )
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (s.polygonNodeStatus.connected) "Connected" else "Disconnected",
                                color = if (s.polygonNodeStatus.connected) Success else Failure,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp
                            )
                        }
                        Text(
                            text = "via ${s.polygonNodeStatus.provider}",
                            color = TextDim,
                            fontSize = 12.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    s.polygonNodeStatus.blockNumber?.let { blockNum ->
                        SystemStatRow(
                            label = "Block",
                            value = "%,d".format(blockNum)
                        )
                    }
                    SystemStatRow(
                        label = "Syncing",
                        value = if (s.polygonNodeStatus.syncing) "Yes" else "No"
                    )
                    SystemStatRow(
                        label = "Teller Last Sync",
                        value = s.tellerLastSync.take(10)
                    )
                }
            }

            // ─── Scan Velocity ────────────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Scan Velocity",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        VelocityStat(
                            label = "Per Minute",
                            value = "%.1f".format(s.scanVelocity.perMinute)
                        )
                        VelocityStat(
                            label = "Per Hour",
                            value = "%,.0f".format(s.scanVelocity.perHour)
                        )
                    }
                }
            }

            // ─── Payout Pipeline ─────────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Payout Pipeline",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    SystemStatRow(
                        label = "Queue Depth",
                        value = s.payoutPipelineQueueDepth.toString()
                    )
                    SystemStatRow(
                        label = "Success Rate",
                        value = "${"%.1f".format(s.payoutPipelineSuccessRate)}%"
                    )
                }
            }

            // ─── Comp Budget Health ───────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Comp Budget Health",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    val budget = s.compBudgetHealth
                    val pct = (budget.percentUsed / 100.0).coerceIn(0.0, 1.0).toFloat()
                    val barColor = when {
                        pct < 0.6f -> Success
                        pct < 0.85f -> Warning
                        else -> Failure
                    }
                    // Budget usage bar
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(12.dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(BackgroundSurface)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(pct)
                                .fillMaxHeight()
                                .clip(RoundedCornerShape(6.dp))
                                .background(barColor)
                        )
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "${"%.1f".format(budget.percentUsed)}% used",
                            color = barColor,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "$${"%,.0f".format(budget.remainingBudget)} remaining",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    SystemStatRow(
                        label = "Total Budget",
                        value = "$${"%,.2f".format(budget.totalBudget)}"
                    )
                    SystemStatRow(
                        label = "Used",
                        value = "$${"%,.2f".format(budget.usedBudget)}"
                    )
                    budget.projectedExhaustionDate?.let { date ->
                        SystemStatRow(label = "Projected Exhaustion", value = date)
                    }
                }
            }

            // ─── Tier Distribution ────────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Tier Distribution",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    s.tierDistribution.entries.forEach { (tier, count) ->
                        SystemStatRow(
                            label = tier,
                            value = "%,d".format(count)
                        )
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(Spacing.xl)) }
        }
    }
}

// ─── SystemStatRow ────────────────────────────────────────────────────────────

@Composable
private fun SystemStatRow(label: String, value: String) {
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

// ─── VelocityStat ─────────────────────────────────────────────────────────────

@Composable
private fun VelocityStat(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            color = TextPrimary,
            fontWeight = FontWeight.Bold,
            fontSize = 22.sp
        )
        Text(
            text = label,
            color = TextSecondary,
            fontSize = 12.sp
        )
    }
}
