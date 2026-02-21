package com.blakjaks.app.features.social.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavController
import com.blakjaks.app.core.theme.BackgroundPrimary
import com.blakjaks.app.core.theme.Gold

// Stub — full implementation in J6
@Composable
fun SocialHubScreen(navController: NavController) {
    Box(
        modifier = Modifier.fillMaxSize().background(BackgroundPrimary),
        contentAlignment = Alignment.Center
    ) {
        Text("Social — coming soon", color = Gold)
    }
}
