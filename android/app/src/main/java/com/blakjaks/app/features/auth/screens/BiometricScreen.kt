package com.blakjaks.app.features.auth.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.navigation.NavController
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.navigation.Screen

// Biometric enrollment prompt shown after signup / first login.
// Enable biometrics for faster subsequent sign-ins.
// User may skip — preference stored in UserPreferences.isBiometricEnrolled.
@Composable
fun BiometricScreen(navController: NavController) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
            .padding(Layout.screenMargin),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Fingerprint,
            contentDescription = "Biometric authentication",
            tint = Gold,
            modifier = Modifier.size(Spacing.xxl)
        )

        Spacer(Modifier.height(Spacing.lg))

        Text(
            text = "Enable Biometrics",
            style = MaterialTheme.typography.titleLarge,
            color = TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(Spacing.md))

        Text(
            text = "Use fingerprint or face recognition for faster, more secure sign-ins to BlakJaks.",
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(Spacing.xl))

        GoldButton(
            text = "Enable Biometrics",
            onClick = {
                // In production: call UserPreferences.setBiometricEnrolled(true)
                // then trigger system biometric enrollment if needed
                navController.navigate(Screen.Insights.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
        )

        Spacer(Modifier.height(Spacing.sm))

        SecondaryButton(
            text = "Skip for Now",
            onClick = {
                navController.navigate(Screen.Insights.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
        )
    }
}
