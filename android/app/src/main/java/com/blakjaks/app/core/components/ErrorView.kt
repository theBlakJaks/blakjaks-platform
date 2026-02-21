package com.blakjaks.app.core.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.blakjaks.app.core.theme.*

@Composable
fun ErrorView(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth().padding(Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        Icon(imageVector = Icons.Default.Warning, contentDescription = null, tint = Failure, modifier = Modifier.size(Spacing.xxl))
        Text(text = message, style = BlakJaksTypography.bodyMedium, color = TextSecondary)
        GoldButton(text = "Try Again", modifier = Modifier.padding(horizontal = Spacing.xl), onClick = onRetry)
    }
}
