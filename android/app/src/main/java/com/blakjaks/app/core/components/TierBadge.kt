package com.blakjaks.app.core.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.blakjaks.app.core.theme.*

@Composable
fun TierBadge(tier: String, modifier: Modifier = Modifier) {
    val color = when (tier.lowercase()) {
        "vip" -> TierVIP
        "high_roller", "high roller" -> TierHighRoller
        "whale" -> TierWhale
        else -> TierStandard
    }
    Text(
        text = tier.uppercase(),
        fontSize = 10.sp,
        fontWeight = FontWeight.Bold,
        color = color,
        modifier = modifier
            .background(color.copy(alpha = 0.15f), RoundedCornerShape(4.dp))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    )
}
