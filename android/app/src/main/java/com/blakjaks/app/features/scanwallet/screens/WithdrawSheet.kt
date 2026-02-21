package com.blakjaks.app.features.scanwallet.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.network.models.DwollaFundingSource
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.scanwallet.WalletViewModel

// ─── WithdrawSheet ────────────────────────────────────────────────────────────
// ModalBottomSheet for withdrawing comp balance via crypto or ACH bank transfer.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WithdrawSheet(
    viewModel: WalletViewModel,
    onDismiss: () -> Unit
) {
    val walletDetail by viewModel.walletDetail.collectAsState()
    val dwollaFundingSources by viewModel.dwollaFundingSources.collectAsState()
    val isWithdrawing by viewModel.isWithdrawing.collectAsState()
    val withdrawAmount by viewModel.withdrawAmount.collectAsState()
    val selectedFundingSource by viewModel.selectedFundingSource.collectAsState()

    // "crypto" | "bank"
    var selectedMethod by remember { mutableStateOf("crypto") }
    var showFundingSourceDropdown by remember { mutableStateOf(false) }

    val compBalance = walletDetail?.compBalance ?: 0.0
    val parsedAmount = withdrawAmount.toDoubleOrNull() ?: 0.0

    val isValid = parsedAmount > 0.0 &&
        parsedAmount <= compBalance &&
        (selectedMethod == "crypto" || (selectedMethod == "bank" && selectedFundingSource != null))

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BackgroundSurface,
        dragHandle = { BottomSheetDefaults.DragHandle(color = TextDim) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Layout.screenMargin)
                .padding(bottom = 36.dp),
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            // ─── Title ────────────────────────────────────────────────────────
            Text(
                text = "Withdraw Funds",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )

            // ─── Available Balance ─────────────────────────────────────────────
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(BackgroundCard, RoundedCornerShape(12.dp))
                    .padding(Spacing.md),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = "Available Balance", color = TextSecondary, fontSize = 13.sp)
                Text(
                    text = "$${"%,.2f".format(compBalance)}",
                    color = Gold,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp
                )
            }

            // ─── Amount Input ─────────────────────────────────────────────────
            OutlinedTextField(
                value = withdrawAmount,
                onValueChange = { viewModel.withdrawAmount.value = it },
                label = { Text("Amount (USD)", color = TextSecondary) },
                placeholder = { Text("0.00", color = TextDim) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = Gold,
                    unfocusedBorderColor = BorderColor,
                    focusedLabelColor = Gold,
                    unfocusedLabelColor = TextSecondary,
                    cursorColor = Gold,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary
                ),
                shape = RoundedCornerShape(12.dp),
                leadingIcon = {
                    Text(
                        text = "$",
                        color = TextSecondary,
                        fontSize = 16.sp,
                        modifier = Modifier.padding(start = 4.dp)
                    )
                }
            )

            // Validation helper text
            if (parsedAmount > compBalance && parsedAmount > 0) {
                Text(
                    text = "Amount exceeds available balance.",
                    color = Failure,
                    fontSize = 12.sp
                )
            }

            // ─── Method Selector ──────────────────────────────────────────────
            Text(
                text = "Withdrawal Method",
                color = TextSecondary,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
            ) {
                // Crypto (MetaMask)
                MethodCard(
                    title = "Crypto (MetaMask)",
                    subtitle = "USDC on Polygon",
                    icon = Icons.Default.AccountBalanceWallet,
                    isSelected = selectedMethod == "crypto",
                    modifier = Modifier.weight(1f),
                    onClick = {
                        selectedMethod = "crypto"
                        viewModel.selectedFundingSource.value = null
                    }
                )

                // Bank Transfer (ACH)
                MethodCard(
                    title = "Bank Transfer",
                    subtitle = "ACH (1–2 business days)",
                    icon = Icons.Default.AccountBalance,
                    isSelected = selectedMethod == "bank",
                    modifier = Modifier.weight(1f),
                    onClick = { selectedMethod = "bank" }
                )
            }

            // ─── Funding Source Selector (bank only) ──────────────────────────
            if (selectedMethod == "bank") {
                if (dwollaFundingSources.isEmpty()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(BackgroundCard, RoundedCornerShape(12.dp))
                            .padding(Spacing.md),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Info,
                            contentDescription = null,
                            tint = Warning,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = "No linked bank accounts. Link a bank to withdraw via ACH.",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                } else {
                    Box(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(BackgroundCard, RoundedCornerShape(12.dp))
                                .border(
                                    width = 1.dp,
                                    color = if (selectedFundingSource != null) Gold else BorderColor,
                                    shape = RoundedCornerShape(12.dp)
                                )
                                .clickable { showFundingSourceDropdown = true }
                                .padding(Spacing.md),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = selectedFundingSource?.let { "${it.name} ••${it.lastFour ?: ""}" }
                                    ?: "Select bank account",
                                color = if (selectedFundingSource != null) TextPrimary else TextDim,
                                fontSize = 14.sp
                            )
                            Icon(
                                imageVector = Icons.Default.ExpandMore,
                                contentDescription = "Select bank",
                                tint = TextSecondary
                            )
                        }

                        DropdownMenu(
                            expanded = showFundingSourceDropdown,
                            onDismissRequest = { showFundingSourceDropdown = false },
                            modifier = Modifier.background(BackgroundCard)
                        ) {
                            dwollaFundingSources.forEach { source ->
                                DropdownMenuItem(
                                    text = {
                                        Column {
                                            Text(
                                                text = source.name,
                                                color = TextPrimary,
                                                fontSize = 14.sp
                                            )
                                            source.lastFour?.let { last4 ->
                                                Text(
                                                    text = "••$last4 · ${source.type.replaceFirstChar { it.uppercase() }}",
                                                    color = TextSecondary,
                                                    fontSize = 12.sp
                                                )
                                            }
                                        }
                                    },
                                    onClick = {
                                        viewModel.selectedFundingSource.value = source
                                        showFundingSourceDropdown = false
                                    }
                                )
                            }
                        }
                    }
                }
            }

            // ─── Withdraw Button ──────────────────────────────────────────────
            GoldButton(
                text = if (selectedMethod == "crypto") "Withdraw as Crypto" else "Withdraw to Bank",
                isLoading = isWithdrawing,
                isEnabled = isValid,
                onClick = { viewModel.requestWithdrawal(selectedMethod) }
            )

            // Disclaimer
            Text(
                text = when (selectedMethod) {
                    "bank"   -> "ACH transfers typically arrive in 1–2 business days. Minimum \$1.00."
                    else     -> "USDC will be sent to your registered MetaMask wallet on Polygon. Minimum \$1.00."
                },
                color = TextDim,
                fontSize = 11.sp,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

// ─── MethodCard ───────────────────────────────────────────────────────────────

@Composable
private fun MethodCard(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier
            .clickable(onClick = onClick)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = if (isSelected) Gold else BorderColor,
                shape = RoundedCornerShape(12.dp)
            ),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) Gold.copy(alpha = 0.08f) else BackgroundCard
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.sm),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (isSelected) Gold else TextSecondary,
                modifier = Modifier.size(22.dp)
            )
            Text(
                text = title,
                color = if (isSelected) Gold else TextPrimary,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = subtitle,
                color = TextDim,
                fontSize = 10.sp
            )
        }
    }
}
