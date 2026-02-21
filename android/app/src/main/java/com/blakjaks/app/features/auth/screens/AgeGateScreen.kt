package com.blakjaks.app.features.auth.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.navigation.NavController
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.navigation.Screen

// Age gate screen — shown before onboarding if age hasn't been confirmed yet.
// The definitive age check happens server-side during signup (DOB field).
// This screen serves as a soft gate and legal acknowledgment.
@Composable
fun AgeGateScreen(navController: NavController) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
            .padding(Layout.screenMargin),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.VerifiedUser,
            contentDescription = "Age verification",
            tint = Gold,
            modifier = Modifier.size(Spacing.xxl)
        )

        Spacer(Modifier.height(Spacing.lg))

        Text(
            text = "Age Verification",
            style = MaterialTheme.typography.titleLarge,
            color = TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(Spacing.md))

        Text(
            text = "BlakJaks products contain nicotine and are intended for adults 21 and older only.",
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(Spacing.sm))

        Text(
            text = "WARNING: This product contains nicotine. Nicotine is an addictive chemical.",
            style = MaterialTheme.typography.bodyMedium,
            color = TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(Spacing.xl))

        GoldButton(
            text = "I confirm I am 21 or older",
            onClick = {
                navController.navigate(Screen.Welcome.route) {
                    popUpTo(Screen.AgeGate.route) { inclusive = true }
                }
            }
        )

        Spacer(Modifier.height(Spacing.sm))

        TextButton(onClick = { /* Exit app or show legal page */ }) {
            Text("I am under 21", color = TextSecondary)
        }
    }
}
