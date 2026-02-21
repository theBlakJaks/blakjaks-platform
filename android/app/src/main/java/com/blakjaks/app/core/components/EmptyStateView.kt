package com.blakjaks.app.core.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import com.blakjaks.app.core.theme.*

@Composable
fun EmptyStateView(
    icon: ImageVector,
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth().padding(Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = Gold, modifier = Modifier.size(Spacing.xxl))
        Text(text = title, style = BlakJaksTypography.titleMedium, color = TextPrimary, textAlign = TextAlign.Center)
        Text(text = subtitle, style = BlakJaksTypography.bodyMedium, color = TextSecondary, textAlign = TextAlign.Center)
    }
}
