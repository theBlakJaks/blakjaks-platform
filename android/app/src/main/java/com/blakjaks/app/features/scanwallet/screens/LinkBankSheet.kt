package com.blakjaks.app.features.scanwallet.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.scanwallet.WalletViewModel

// ─── LinkBankSheet ────────────────────────────────────────────────────────────
// ModalBottomSheet stub for Dwolla bank-account linking.
// Full Plaid / Dwolla token-exchange flow comes in a future polish pass.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LinkBankSheet(
    viewModel: WalletViewModel,
    onDismiss: () -> Unit
) {
    val isLinkingBank by viewModel.isLinkingBank.collectAsState()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BackgroundSurface,
        dragHandle = { BottomSheetDefaults.DragHandle(color = TextDim) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Layout.screenMargin)
                .padding(bottom = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            // ─── Icon ─────────────────────────────────────────────────────────
            Icon(
                imageVector = Icons.Default.AccountBalance,
                contentDescription = null,
                tint = Gold,
                modifier = Modifier.size(52.dp)
            )

            // ─── Title ────────────────────────────────────────────────────────
            Text(
                text = "Link Bank Account",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )

            // ─── Description ──────────────────────────────────────────────────
            Text(
                text = "Connect your bank account to withdraw your BlakJaks comp balance via ACH direct deposit. Transfers typically arrive within 1–2 business days.",
                color = TextSecondary,
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                lineHeight = 20.sp
            )

            Spacer(modifier = Modifier.height(Spacing.xs))

            // ─── Benefits list ─────────────────────────────────────────────────
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(Spacing.sm)
            ) {
                BenefitRow(text = "Secure bank-grade encryption via Dwolla")
                BenefitRow(text = "One-time setup — instant future withdrawals")
                BenefitRow(text = "Minimum withdrawal: \$1.00 USD")
                BenefitRow(text = "No fees for ACH transfers")
            }

            Spacer(modifier = Modifier.height(Spacing.sm))

            // ─── Connect Button ────────────────────────────────────────────────
            GoldButton(
                text = "Connect via Plaid / Dwolla",
                isLoading = isLinkingBank,
                onClick = { viewModel.linkBankAccount() }
            )

            // ─── Powered by Dwolla ─────────────────────────────────────────────
            Text(
                text = "Powered by Dwolla",
                color = TextDim,
                fontSize = 11.sp,
                textAlign = TextAlign.Center
            )
        }
    }
}

// ─── BenefitRow ───────────────────────────────────────────────────────────────

@Composable
private fun BenefitRow(text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
    ) {
        Text(text = "✓", color = Success, fontWeight = FontWeight.Bold, fontSize = 13.sp)
        Text(text = text, color = TextSecondary, fontSize = 13.sp)
    }
}
