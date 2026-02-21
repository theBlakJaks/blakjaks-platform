package com.blakjaks.app.features.auth.screens

import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.*
import androidx.compose.foundation.shape.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.*
import androidx.compose.ui.text.font.*
import androidx.compose.ui.text.style.*
import androidx.compose.ui.unit.*
import androidx.navigation.NavController
import com.blakjaks.app.core.components.*
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.navigation.Screen

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun WelcomeScreen(navController: NavController) {
    val pagerState = rememberPagerState(pageCount = { 3 })
    val onboardingItems = listOf(
        Triple("Scan & Earn", "Scan BlakJaks products to earn real cash comps.", "Earn up to \$10,000 in crypto comps."),
        Triple("Level Up", "More scans = higher tier = bigger multipliers.", "Standard -> VIP -> High Roller -> Whale"),
        Triple("Cash Out", "Withdraw to your bank or crypto wallet anytime.", "Instant ACH or crypto withdrawals.")
    )

    Box(modifier = Modifier.fillMaxSize().background(BackgroundPrimary)) {
        Column(
            modifier = Modifier.fillMaxSize().padding(Layout.screenMargin),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(Spacing.xxl))
            // Logo / Wordmark
            Text(
                text = "BlakJaks",
                style = MaterialTheme.typography.displayLarge,
                color = Gold
            )
            Spacer(Modifier.height(Spacing.xl))
            // Onboarding carousel
            HorizontalPager(state = pagerState, modifier = Modifier.weight(1f)) { page ->
                val (title, body, subtitle) = onboardingItems[page]
                Column(
                    modifier = Modifier.fillMaxWidth().padding(Spacing.md),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleLarge,
                        color = Gold,
                        textAlign = TextAlign.Center
                    )
                    Spacer(Modifier.height(Spacing.md))
                    Text(
                        text = body,
                        style = MaterialTheme.typography.bodyLarge,
                        color = TextPrimary,
                        textAlign = TextAlign.Center
                    )
                    Spacer(Modifier.height(Spacing.sm))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = TextSecondary,
                        textAlign = TextAlign.Center
                    )
                }
            }
            // Page indicator dots
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                repeat(3) { i ->
                    val size = if (pagerState.currentPage == i) 8.dp else 6.dp
                    val color = if (pagerState.currentPage == i) Gold else TextDim
                    Box(modifier = Modifier.size(size).background(color, CircleShape))
                }
            }
            Spacer(Modifier.height(Spacing.xl))
            // CTAs
            GoldButton(
                text = "Create Account",
                onClick = { navController.navigate(Screen.Signup.route) }
            )
            Spacer(Modifier.height(Spacing.sm))
            TextButton(onClick = { navController.navigate(Screen.Login.route) }) {
                Text("Sign In", color = Gold)
            }
            Spacer(Modifier.height(Spacing.lg))
        }
    }
}
