package com.blakjaks.app.features.scanwallet.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.network.models.ScanResult
import com.blakjaks.app.core.theme.*

// ─── ScanResultSheet ─────────────────────────────────────────────────────────
// ModalBottomSheet shown when a QR scan returns a result.
// Shows points earned, tier progress, and comp earned (if any).

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScanResultSheet(
    scanResult: ScanResult,
    onDismiss: () -> Unit,
    onClaimComp: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BackgroundCard,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = 12.dp, bottom = 8.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(BorderColor)
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Layout.screenMargin)
                .padding(bottom = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            // ─── Header ───────────────────────────────────────────────────────
            Text(
                text = if (scanResult.success) "Scan Successful!" else "Scan Failed",
                color = if (scanResult.success) Success else Failure,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )

            Text(
                text = scanResult.productName,
                color = TextSecondary,
                fontSize = 14.sp
            )

            // ─── Points Earned ────────────────────────────────────────────────
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "+${"%.2f".format(scanResult.usdcEarned)}",
                    color = Gold,
                    fontWeight = FontWeight.Bold,
                    fontSize = 40.sp
                )
                Text(
                    text = "USD Earned (${scanResult.tierMultiplier}x multiplier)",
                    color = TextSecondary,
                    fontSize = 13.sp
                )
            }

            // ─── Tier Progress ────────────────────────────────────────────────
            val progress = scanResult.tierProgress
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = BackgroundSurface),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(modifier = Modifier.padding(Spacing.md)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Quarter: ${progress.quarter}",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                        Text(
                            text = "${progress.currentCount} scans",
                            color = TextPrimary,
                            fontWeight = FontWeight.Medium,
                            fontSize = 12.sp
                        )
                    }
                    progress.nextTier?.let { nextTier ->
                        val required = progress.scansRequired ?: 0
                        Spacer(modifier = Modifier.height(6.dp))
                        val pct = if (required > 0) {
                            (progress.currentCount.toFloat() / (progress.currentCount + required))
                                .coerceIn(0f, 1f)
                        } else 1f
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .clip(RoundedCornerShape(4.dp))
                                .background(BackgroundPrimary)
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(pct)
                                    .fillMaxHeight()
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(Gold)
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "$required scans to $nextTier",
                            color = TextDim,
                            fontSize = 11.sp
                        )
                    }
                }
            }

            // ─── Comp Earned Card ─────────────────────────────────────────────
            val comp = scanResult.compEarned
            if (comp != null) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Gold.copy(alpha = 0.12f)),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(Spacing.md),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Comp Earned!",
                            color = Gold,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "$${"%,.2f".format(comp.amount)}",
                            color = Gold,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 28.sp
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        if (comp.requiresPayoutChoice) {
                            GoldButton(
                                text = "Claim Comp",
                                onClick = onClaimComp
                            )
                        } else {
                            Text(
                                text = "Status: ${comp.status}",
                                color = TextSecondary,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }

            // ─── Wallet Balance ───────────────────────────────────────────────
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(text = "New Balance", color = TextSecondary, fontSize = 13.sp)
                Text(
                    text = "$${"%,.2f".format(scanResult.walletBalance)}",
                    color = TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp
                )
            }

            // ─── Dismiss ──────────────────────────────────────────────────────
            SecondaryButton(
                text = "Done",
                onClick = onDismiss
            )
        }
    }
}
