package com.blakjaks.app.core.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// FDA-required nicotine warning. Never dismissible.
// Add ONLY to: SplashScreen, ShopScreen, CartScreen, CheckoutScreen.
@Composable
fun NicotineWarningBanner(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = (0.20f * 800).dp) // ~20% of screen
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "WARNING: This product contains nicotine. Nicotine is an addictive chemical.",
            color = Color.White,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 16.dp)
        )
    }
}
