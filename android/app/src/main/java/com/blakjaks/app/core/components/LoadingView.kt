package com.blakjaks.app.core.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.blakjaks.app.core.theme.*

@Composable
fun ShimmerBox(modifier: Modifier = Modifier) {
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    val shimmerX by infiniteTransition.animateFloat(
        initialValue = -400f,
        targetValue = 400f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmerX"
    )
    val brush = Brush.linearGradient(
        colors = listOf(BackgroundCard, BackgroundSurface, BackgroundCard),
        start = Offset(shimmerX, 0f),
        end = Offset(shimmerX + 400f, 0f)
    )
    Box(
        modifier = modifier
            .background(brush, RoundedCornerShape(Layout.cardCornerRadius))
    )
}

@Composable
fun LoadingView(modifier: Modifier = Modifier) {
    Column(modifier = modifier.padding(Layout.screenMargin), verticalArrangement = Arrangement.spacedBy(Spacing.md)) {
        ShimmerBox(modifier = Modifier.fillMaxWidth().height(180.dp))
        ShimmerBox(modifier = Modifier.fillMaxWidth().height(80.dp))
        ShimmerBox(modifier = Modifier.fillMaxWidth().height(80.dp))
    }
}
