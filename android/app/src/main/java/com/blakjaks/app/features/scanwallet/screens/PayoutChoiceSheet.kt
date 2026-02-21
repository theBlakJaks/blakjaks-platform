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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.network.models.CompEarned
import com.blakjaks.app.core.theme.*

// ─── PayoutChoiceSheet ────────────────────────────────────────────────────────
// ModalBottomSheet with 3 payout options:
//   "crypto"  → Send to MetaMask
//   "bank"    → Send to Bank (ACH via Dwolla)
//   "later"   → Choose Later (comp held as IOU)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayoutChoiceSheet(
    comp: CompEarned,
    isSubmitting: Boolean,
    onChoice: (String) -> Unit,
    onDismiss: () -> Unit
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
            verticalArrangement = Arrangement.spacedBy(Spacing.sm)
        ) {
            // ─── Header ───────────────────────────────────────────────────────
            Text(
                text = "You Earned a Comp!",
                color = Gold,
                fontWeight = FontWeight.Bold,
                fontSize = 22.sp
            )
            Text(
                text = "$${"%,.2f".format(comp.amount)}",
                color = TextPrimary,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 36.sp
            )
            Spacer(modifier = Modifier.height(Spacing.xs))
            Text(
                text = "How would you like to receive your comp?",
                color = TextSecondary,
                fontSize = 14.sp,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(Spacing.sm))

            // ─── Option 1: MetaMask (crypto) ──────────────────────────────────
            GoldButton(
                text = "Send to MetaMask",
                isLoading = isSubmitting,
                isEnabled = !isSubmitting,
                onClick = { onChoice("crypto") }
            )

            // ─── Option 2: Bank (ACH) ─────────────────────────────────────────
            Button(
                onClick = { onChoice("bank") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(Layout.buttonHeight),
                enabled = !isSubmitting,
                shape = RoundedCornerShape(Layout.buttonCornerRadius),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Success.copy(alpha = 0.15f),
                    contentColor = Success,
                    disabledContainerColor = Success.copy(alpha = 0.07f),
                    disabledContentColor = Success.copy(alpha = 0.4f)
                )
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = Success,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Send to Bank",
                        fontWeight = FontWeight.Bold,
                        color = Success
                    )
                }
            }

            // ─── Option 3: Choose Later ───────────────────────────────────────
            TextButton(
                onClick = { onChoice("later") },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isSubmitting
            ) {
                Text(
                    text = "Choose Later",
                    color = TextSecondary,
                    fontSize = 15.sp
                )
            }

            // ─── Disclaimer ───────────────────────────────────────────────────
            Text(
                text = "Choosing later holds your comp as a virtual balance. You can withdraw anytime from your wallet.",
                color = TextDim,
                fontSize = 11.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = Spacing.md)
            )
        }
    }
}
