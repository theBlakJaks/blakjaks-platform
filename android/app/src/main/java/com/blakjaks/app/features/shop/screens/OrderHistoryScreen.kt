package com.blakjaks.app.features.shop.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.network.models.Order
import com.blakjaks.app.core.theme.*

// ─── OrderHistoryScreen ───────────────────────────────────────────────────────
// Navigated to from Profile. Displays a list of past orders.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderHistoryScreen(
    orders: List<Order>,
    navController: NavController
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
    ) {
        // Top bar with back button
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { navController.popBackStack() }) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = TextPrimary
                )
            }
            Text(
                text = "Order History",
                color = TextPrimary,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(start = Spacing.sm)
            )
        }

        if (orders.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(Layout.screenMargin),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "No Orders Yet",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(Spacing.sm))
                    Text(
                        text = "Your order history will appear here.",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                }
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(
                    horizontal = Layout.screenMargin,
                    vertical = Spacing.sm
                ),
                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                modifier = Modifier.fillMaxSize()
            ) {
                items(orders) { order ->
                    OrderHistoryCard(order = order)
                }
            }
        }
    }
}

// ─── OrderHistoryCard ─────────────────────────────────────────────────────────

@Composable
private fun OrderHistoryCard(order: Order) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(Layout.cardCornerRadius),
        colors = CardDefaults.cardColors(containerColor = BackgroundCard),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(Layout.cardPadding)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Order #${order.id}",
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
                OrderStatusBadge(status = order.status)
            }

            Spacer(modifier = Modifier.height(Spacing.xs))

            // Date
            Text(
                text = formatOrderDate(order.createdAt),
                color = TextDim,
                fontSize = 12.sp
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            // Items summary
            Text(
                text = "${order.items.size} item${if (order.items.size != 1) "s" else ""}",
                color = TextSecondary,
                fontSize = 13.sp
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            HorizontalDivider(color = BorderColor)

            Spacer(modifier = Modifier.height(Spacing.sm))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Total", color = TextSecondary, fontSize = 13.sp)
                Text(
                    text = "${"$%.2f".format(order.total)}",
                    color = Gold,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            // Tracking number if available
            order.trackingNumber?.let { tracking ->
                Spacer(modifier = Modifier.height(Spacing.xs))
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text("Tracking: ", color = TextSecondary, fontSize = 12.sp)
                    Text(tracking, color = Info, fontSize = 12.sp)
                }
            }
        }
    }
}

// ─── OrderStatusBadge ─────────────────────────────────────────────────────────

@Composable
private fun OrderStatusBadge(status: String) {
    val (bgColor, textColor) = when (status.lowercase()) {
        "processing"  -> Warning.copy(alpha = 0.15f) to Warning
        "shipped"     -> Info.copy(alpha = 0.15f) to Info
        "delivered"   -> Success.copy(alpha = 0.15f) to Success
        "cancelled"   -> Failure.copy(alpha = 0.15f) to Failure
        "refunded"    -> Failure.copy(alpha = 0.15f) to Failure
        else          -> BorderColor to TextSecondary
    }

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(bgColor)
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(
            text = status.replaceFirstChar { it.uppercase() },
            color = textColor,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// ─── Date Formatter ───────────────────────────────────────────────────────────

private fun formatOrderDate(isoDate: String): String {
    return try {
        val inputFormat = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US)
        val outputFormat = java.text.SimpleDateFormat("MMM d, yyyy", java.util.Locale.US)
        val date = inputFormat.parse(isoDate)
        if (date != null) outputFormat.format(date) else isoDate
    } catch (e: Exception) {
        isoDate
    }
}
