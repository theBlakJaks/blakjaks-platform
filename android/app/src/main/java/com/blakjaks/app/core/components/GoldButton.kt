package com.blakjaks.app.core.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.blakjaks.app.core.theme.*

@Composable
fun GoldButton(
    text: String,
    modifier: Modifier = Modifier,
    isLoading: Boolean = false,
    isEnabled: Boolean = true,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(Layout.buttonHeight),
        enabled = isEnabled && !isLoading,
        shape = RoundedCornerShape(Layout.buttonCornerRadius),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isEnabled && !isLoading) Gold else Gold.copy(alpha = 0.4f),
            contentColor = Color.Black,
            disabledContainerColor = Gold.copy(alpha = 0.4f),
            disabledContentColor = Color.Black
        )
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = Color.Black,
                strokeWidth = 2.dp
            )
        } else {
            Text(text = text, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun SecondaryButton(
    text: String,
    modifier: Modifier = Modifier,
    isLoading: Boolean = false,
    onClick: () -> Unit
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(Layout.buttonHeight),
        enabled = !isLoading,
        shape = RoundedCornerShape(Layout.buttonCornerRadius),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = Gold),
        border = androidx.compose.foundation.BorderStroke(1.5.dp, Gold)
    ) {
        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.size(20.dp), color = Gold, strokeWidth = 2.dp)
        } else {
            Text(text = text, fontWeight = FontWeight.Bold, color = Gold)
        }
    }
}
