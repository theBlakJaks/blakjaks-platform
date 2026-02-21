package com.blakjaks.app.features.shop.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.NicotineWarningBanner
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.network.models.CartItem
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.shop.CartViewModel
import com.blakjaks.app.features.shop.CheckoutStep
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CartScreen(navController: NavController) {
    val viewModel: CartViewModel = koinViewModel()

    val cart by viewModel.cart.collectAsState()
    val checkoutStep by viewModel.checkoutStep.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val isPlacingOrder by viewModel.isPlacingOrder.collectAsState()
    val error by viewModel.error.collectAsState()
    val completedOrder by viewModel.completedOrder.collectAsState()

    // Load cart on first entry
    LaunchedEffect(Unit) {
        viewModel.loadCart()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
    ) {
        // Nicotine warning banner
        NicotineWarningBanner()

        // Top bar with back button (except Confirmation)
        if (checkoutStep !is CheckoutStep.Confirmation) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.md, vertical = Spacing.sm),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = {
                    when (checkoutStep) {
                        is CheckoutStep.Shipping -> navController.popBackStack()
                        is CheckoutStep.AgeVerification -> viewModel.checkoutStep.value = CheckoutStep.Shipping
                        is CheckoutStep.Payment -> viewModel.checkoutStep.value = CheckoutStep.AgeVerification
                        is CheckoutStep.Review -> viewModel.checkoutStep.value = CheckoutStep.Payment
                        else -> {}
                    }
                }) {
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = TextPrimary
                    )
                }
                Text(
                    text = checkoutStep.title,
                    color = TextPrimary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = Spacing.sm)
                )
            }
        }

        // Checkout step indicator (except Confirmation)
        if (checkoutStep !is CheckoutStep.Confirmation) {
            CheckoutStepIndicator(currentStep = checkoutStep)
        }

        // Error banner
        error?.let { msg ->
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Layout.screenMargin, vertical = Spacing.xs)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Failure.copy(alpha = 0.15f))
                    .border(1.dp, Failure.copy(alpha = 0.4f), RoundedCornerShape(8.dp))
                    .padding(Spacing.md)
            ) {
                Text(text = msg, color = Failure, fontSize = 13.sp)
            }
        }

        // Step content
        Box(modifier = Modifier.weight(1f)) {
            when (checkoutStep) {
                is CheckoutStep.Shipping        -> ShippingStep(viewModel, isLoading)
                is CheckoutStep.AgeVerification -> AgeVerificationStep(viewModel)
                is CheckoutStep.Payment         -> PaymentStep(viewModel)
                is CheckoutStep.Review          -> ReviewStep(viewModel, cart?.items ?: emptyList(), isPlacingOrder)
                is CheckoutStep.Confirmation    -> ConfirmationStep(
                    orderNumber = completedOrder?.id?.toString() ?: "—",
                    onContinueShopping = {
                        viewModel.resetCheckout()
                        navController.navigate("shop") {
                            popUpTo("shop") { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}

// ─── Checkout Step Indicator ─────────────────────────────────────────────────

@Composable
private fun CheckoutStepIndicator(currentStep: CheckoutStep) {
    val steps = listOf(
        CheckoutStep.Shipping,
        CheckoutStep.AgeVerification,
        CheckoutStep.Payment,
        CheckoutStep.Review
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Layout.screenMargin, vertical = Spacing.sm),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        steps.forEachIndexed { index, step ->
            val isActive = currentStep.stepIndex >= step.stepIndex
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(if (isActive) Gold else BackgroundSurface)
                    .border(1.dp, if (isActive) Gold else BorderColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = (index + 1).toString(),
                    color = if (isActive) Color.Black else TextDim,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            if (index < steps.size - 1) {
                HorizontalDivider(
                    modifier = Modifier.width(32.dp),
                    color = if (currentStep.stepIndex > step.stepIndex) Gold else BorderColor,
                    thickness = 2.dp
                )
            }
        }
    }
}

// ─── Shipping Step ────────────────────────────────────────────────────────────

@Composable
private fun ShippingStep(viewModel: CartViewModel, isLoading: Boolean) {
    val firstName by viewModel.firstName.collectAsState()
    val lastName by viewModel.lastName.collectAsState()
    val line1 by viewModel.line1.collectAsState()
    val line2 by viewModel.line2.collectAsState()
    val city by viewModel.city.collectAsState()
    val state by viewModel.state.collectAsState()
    val zip by viewModel.zip.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Layout.screenMargin)
    ) {
        Text(
            text = "Shipping Address",
            color = TextPrimary,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(modifier = Modifier.height(Spacing.md))

        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            CheckoutTextField(
                label = "First Name",
                value = firstName,
                onValueChange = { viewModel.firstName.value = it },
                modifier = Modifier.weight(1f)
            )
            CheckoutTextField(
                label = "Last Name",
                value = lastName,
                onValueChange = { viewModel.lastName.value = it },
                modifier = Modifier.weight(1f)
            )
        }
        Spacer(modifier = Modifier.height(Spacing.sm))
        CheckoutTextField(
            label = "Address Line 1",
            value = line1,
            onValueChange = { viewModel.line1.value = it }
        )
        Spacer(modifier = Modifier.height(Spacing.sm))
        CheckoutTextField(
            label = "Address Line 2 (optional)",
            value = line2,
            onValueChange = { viewModel.line2.value = it }
        )
        Spacer(modifier = Modifier.height(Spacing.sm))
        CheckoutTextField(
            label = "City",
            value = city,
            onValueChange = { viewModel.city.value = it }
        )
        Spacer(modifier = Modifier.height(Spacing.sm))
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            CheckoutTextField(
                label = "State",
                value = state,
                onValueChange = { viewModel.state.value = it },
                modifier = Modifier.weight(1f)
            )
            CheckoutTextField(
                label = "ZIP",
                value = zip,
                onValueChange = { viewModel.zip.value = it },
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xl))

        GoldButton(
            text = "Continue",
            isLoading = isLoading,
            onClick = { viewModel.proceedFromShipping() }
        )
    }
}

// ─── Age Verification Step ────────────────────────────────────────────────────

@Composable
private fun AgeVerificationStep(viewModel: CartViewModel) {
    val ageVerified by viewModel.ageVerified.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(Layout.screenMargin),
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        Text(
            text = "Age Verification",
            color = TextPrimary,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold
        )

        Text(
            text = "You must be 21 or older to purchase nicotine products.",
            color = TextSecondary,
            fontSize = 14.sp
        )

        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(BackgroundCard)
                .padding(Spacing.md)
        ) {
            Checkbox(
                checked = ageVerified,
                onCheckedChange = { viewModel.ageVerified.value = it },
                colors = CheckboxDefaults.colors(
                    checkedColor = Gold,
                    uncheckedColor = TextDim,
                    checkmarkColor = Color.Black
                )
            )
            Spacer(modifier = Modifier.width(Spacing.sm))
            Text(
                text = "I confirm I am 21 or older and consent to purchase nicotine products",
                color = TextPrimary,
                fontSize = 13.sp,
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        GoldButton(
            text = "Continue",
            isEnabled = ageVerified,
            onClick = { viewModel.proceedFromAgeVerification() }
        )
    }
}

// ─── Payment Step ─────────────────────────────────────────────────────────────

@Composable
private fun PaymentStep(viewModel: CartViewModel) {
    val paymentToken by viewModel.paymentToken.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Layout.screenMargin)
    ) {
        Text(
            text = "Payment",
            color = TextPrimary,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(Spacing.md))

        CheckoutTextField(
            label = "Card Token (Authorize.net)",
            value = paymentToken,
            onValueChange = { viewModel.paymentToken.value = it }
        )

        Spacer(modifier = Modifier.height(Spacing.md))

        // Age Verification stub
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(BackgroundSurface)
                .border(1.dp, BorderColor, RoundedCornerShape(8.dp))
                .padding(Spacing.md)
        ) {
            Text(
                text = "Age verification powered by AgeChecker.net",
                color = TextSecondary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xl))

        GoldButton(
            text = "Continue",
            isEnabled = paymentToken.isNotBlank(),
            onClick = { viewModel.proceedFromPayment() }
        )
    }
}

// ─── Review Step ──────────────────────────────────────────────────────────────

@Composable
private fun ReviewStep(
    viewModel: CartViewModel,
    items: List<CartItem>,
    isPlacingOrder: Boolean
) {
    val taxEstimate by viewModel.taxEstimate.collectAsState()
    val coroutineScope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Layout.screenMargin)
    ) {
        Text(
            text = "Order Review",
            color = TextPrimary,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(Spacing.md))

        // Items list
        Text("Items", color = Gold, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
        Spacer(modifier = Modifier.height(Spacing.xs))
        items.forEach { item ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${item.productName} x${item.quantity}",
                    color = TextPrimary,
                    fontSize = 13.sp,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = "${"$%.2f".format(item.lineTotal)}",
                    color = TextPrimary,
                    fontSize = 13.sp
                )
            }
        }

        HorizontalDivider(
            modifier = Modifier.padding(vertical = Spacing.sm),
            color = BorderColor
        )

        // Shipping address summary
        Text("Ship To", color = Gold, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
        Spacer(modifier = Modifier.height(Spacing.xs))
        Text(
            text = "${viewModel.firstName.value} ${viewModel.lastName.value}\n" +
                   "${viewModel.line1.value}" +
                   (if (viewModel.line2.value.isNotBlank()) "\n${viewModel.line2.value}" else "") +
                   "\n${viewModel.city.value}, ${viewModel.state.value} ${viewModel.zip.value}",
            color = TextSecondary,
            fontSize = 13.sp
        )

        HorizontalDivider(
            modifier = Modifier.padding(vertical = Spacing.sm),
            color = BorderColor
        )

        // Price breakdown
        SummaryRow("Subtotal", "${"$%.2f".format(viewModel.subtotal)}")
        SummaryRow(
            label = if (viewModel.isFreeShipping) "Shipping" else "Shipping",
            value = if (viewModel.isFreeShipping) "FREE" else "${"$%.2f".format(viewModel.shippingCost)}"
        )
        taxEstimate?.let {
            SummaryRow("Tax (${it.jurisdiction})", "${"$%.2f".format(it.taxAmount)}")
        }

        HorizontalDivider(
            modifier = Modifier.padding(vertical = Spacing.sm),
            color = BorderColor
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text("Total", color = TextPrimary, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Text(
                "${"$%.2f".format(viewModel.total)}",
                color = Gold,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xl))

        GoldButton(
            text = "Place Order",
            isLoading = isPlacingOrder,
            onClick = { viewModel.placeOrder() }
        )
    }
}

// ─── Confirmation Step ────────────────────────────────────────────────────────

@Composable
private fun ConfirmationStep(orderNumber: String, onContinueShopping: () -> Unit) {
    var showCheck by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(800)
        showCheck = true
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(Layout.screenMargin),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (!showCheck) {
            CircularProgressIndicator(color = Gold, modifier = Modifier.size(64.dp))
        } else {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape)
                    .background(Success.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "✓", color = Success, fontSize = 36.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.height(Spacing.lg))

        Text(
            text = "Order Placed!",
            color = TextPrimary,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(Spacing.sm))

        Text(
            text = "Order #$orderNumber",
            color = Gold,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(Spacing.sm))

        Text(
            text = "Your order is being processed. You will receive a confirmation email shortly.",
            color = TextSecondary,
            fontSize = 14.sp,
            modifier = Modifier.padding(horizontal = Spacing.lg),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )

        Spacer(modifier = Modifier.height(Spacing.xxl))

        SecondaryButton(
            text = "Continue Shopping",
            onClick = onContinueShopping
        )
    }
}

// ─── Shared Composables ───────────────────────────────────────────────────────

@Composable
private fun CheckoutTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, color = TextDim) },
        modifier = modifier.fillMaxWidth(),
        singleLine = true,
        shape = RoundedCornerShape(10.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Gold,
            unfocusedBorderColor = BorderColor,
            focusedTextColor = TextPrimary,
            unfocusedTextColor = TextPrimary,
            cursorColor = Gold,
            focusedContainerColor = BackgroundCard,
            unfocusedContainerColor = BackgroundCard
        )
    )
}

@Composable
private fun SummaryRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = TextSecondary, fontSize = 13.sp)
        Text(value, color = TextPrimary, fontSize = 13.sp)
    }
}
