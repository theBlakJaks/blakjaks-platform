package com.blakjaks.app.features.insights.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.blakjaks.app.core.components.GoldAccentCard
import com.blakjaks.app.core.components.LoadingView
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.insights.InsightsViewModel
import org.koin.androidx.compose.koinViewModel

// ─── InsightsPartnersScreen ───────────────────────────────────────────────────
// Shows affiliate partner stats: active count, weekly pool, top partners,
// permanent tier floor counts, and wholesale stats.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsPartnersScreen(navController: NavController) {
    val viewModel: InsightsViewModel = koinViewModel()
    val partners by viewModel.partners.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadPartners()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Partners",
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
        if (isLoading && partners == null) {
            LoadingView(modifier = Modifier.padding(paddingValues))
            return@Scaffold
        }

        val p = partners
        if (p == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text("No partner data available.", color = TextSecondary)
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
            // ─── Affiliate Overview ───────────────────────────────────────────
            item {
                GoldAccentCard {
                    Text(
                        text = "Affiliate Program",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    PartnerStatRow(
                        label = "Active Partners",
                        value = "%,d".format(p.affiliateActiveCount)
                    )
                    PartnerStatRow(
                        label = "Weekly Pool",
                        value = "$${"%,.2f".format(p.weeklyPool)}"
                    )
                    PartnerStatRow(
                        label = "Lifetime Match Total",
                        value = "$${"%,.2f".format(p.lifetimeMatchTotal)}"
                    )
                    PartnerStatRow(
                        label = "Sunset Engine",
                        value = p.sunsetEngineStatus.replaceFirstChar { it.uppercase() }
                    )
                }
            }

            // ─── Permanent Tier Floor Counts ──────────────────────────────────
            if (p.permanentTierFloorCounts.isNotEmpty()) {
                item {
                    BlakJaksCard {
                        Text(
                            text = "Permanent Tier Floors",
                            color = Gold,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp
                        )
                        Spacer(modifier = Modifier.height(Spacing.sm))
                        p.permanentTierFloorCounts.entries.forEach { (tier, count) ->
                            PartnerStatRow(
                                label = tier,
                                value = "%,d affiliates".format(count)
                            )
                        }
                    }
                }
            }

            // ─── Wholesale ────────────────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Wholesale",
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    PartnerStatRow(
                        label = "Active Accounts",
                        value = "%,d".format(p.wholesaleActiveAccounts)
                    )
                    PartnerStatRow(
                        label = "Order Value (This Month)",
                        value = "$${"%,.2f".format(p.wholesaleOrderValueThisMonth)}"
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(Spacing.xl)) }
        }
    }
}

// ─── PartnerStatRow ───────────────────────────────────────────────────────────

@Composable
private fun PartnerStatRow(label: String, value: String) {
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
