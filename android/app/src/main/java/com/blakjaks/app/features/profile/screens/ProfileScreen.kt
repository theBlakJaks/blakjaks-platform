package com.blakjaks.app.features.profile.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.blakjaks.app.core.components.BlakJaksCard
import com.blakjaks.app.core.components.GoldAccentCard
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.components.TierBadge
import com.blakjaks.app.core.network.models.Order
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.profile.ProfileViewModel
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(navController: NavController) {
    val viewModel: ProfileViewModel = koinViewModel()
    val context = LocalContext.current

    val profile by viewModel.profile.collectAsState()
    val orders by viewModel.orders.collectAsState()
    val affiliateDashboard by viewModel.affiliateDashboard.collectAsState()
    val affiliatePayouts by viewModel.affiliatePayouts.collectAsState()
    val isLoadingProfile by viewModel.isLoadingProfile.collectAsState()
    val isUpdatingProfile by viewModel.isUpdatingProfile.collectAsState()
    val error by viewModel.error.collectAsState()
    val successMessage by viewModel.successMessage.collectAsState()

    // Edit form state
    var showEditForm by remember { mutableStateOf(false) }
    var editName by remember { mutableStateOf("") }
    var editBio by remember { mutableStateOf("") }
    var showAvatarPicker by remember { mutableStateOf(false) }

    // Sync edit fields when profile loads
    LaunchedEffect(profile) {
        profile?.let {
            editName = it.fullName
            editBio = it.bio ?: ""
        }
    }

    // Load orders and affiliate data on enter
    LaunchedEffect(Unit) {
        viewModel.loadOrders()
        viewModel.loadAffiliateDashboard()
    }

    // Success / error snackbar
    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(error) {
        if (error != null) {
            snackbarHostState.showSnackbar(error ?: "An error occurred")
            viewModel.clearError()
        }
    }
    LaunchedEffect(successMessage) {
        if (successMessage != null) {
            snackbarHostState.showSnackbar(successMessage ?: "")
            viewModel.clearSuccessMessage()
        }
    }

    Scaffold(
        containerColor = BackgroundPrimary,
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        if (isLoadingProfile && profile == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = Gold)
            }
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {

            // ── Avatar section ──────────────────────────────────────────────
            item {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Avatar circle
                    Box(
                        modifier = Modifier
                            .size(88.dp)
                            .clip(CircleShape)
                            .background(BackgroundSurface),
                        contentAlignment = Alignment.Center
                    ) {
                        if (profile?.avatarUrl != null) {
                            AsyncImage(
                                model = profile!!.avatarUrl,
                                contentDescription = "Avatar",
                                modifier = Modifier.fillMaxSize().clip(CircleShape)
                            )
                        } else {
                            Text(
                                text = profile?.fullName?.take(1)?.uppercase() ?: "?",
                                color = Gold,
                                fontWeight = FontWeight.Bold,
                                fontSize = 36.sp
                            )
                        }
                    }

                    Spacer(Modifier.height(4.dp))

                    // Edit avatar button
                    TextButton(onClick = { showAvatarPicker = true }) {
                        Text("Change Photo", color = Gold, fontSize = 12.sp)
                    }

                    Spacer(Modifier.height(4.dp))

                    Text(
                        text = profile?.fullName ?: "",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 22.sp
                    )

                    Spacer(Modifier.height(4.dp))

                    TierBadge(tier = profile?.tier ?: "Standard")

                    Spacer(Modifier.height(4.dp))

                    // Member ID in monospace
                    Text(
                        text = profile?.memberId ?: "",
                        color = TextSecondary,
                        fontFamily = FontFamily.Monospace,
                        fontSize = 13.sp
                    )
                }
            }

            // ── Edit Profile form (collapsible) ─────────────────────────────
            item {
                BlakJaksCard {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Edit Profile",
                            color = TextPrimary,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.weight(1f)
                        )
                        IconButton(onClick = { showEditForm = !showEditForm }) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = if (showEditForm) "Collapse" else "Expand",
                                tint = Gold
                            )
                        }
                    }

                    if (showEditForm) {
                        Spacer(Modifier.height(8.dp))
                        OutlinedTextField(
                            value = editName,
                            onValueChange = { editName = it },
                            label = { Text("Full Name", color = TextSecondary) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = TextPrimary,
                                unfocusedTextColor = TextPrimary,
                                focusedBorderColor = Gold,
                                unfocusedBorderColor = BorderColor,
                                cursorColor = Gold
                            )
                        )
                        Spacer(Modifier.height(8.dp))
                        OutlinedTextField(
                            value = editBio,
                            onValueChange = { editBio = it },
                            label = { Text("Bio", color = TextSecondary) },
                            modifier = Modifier.fillMaxWidth(),
                            maxLines = 3,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = TextPrimary,
                                unfocusedTextColor = TextPrimary,
                                focusedBorderColor = Gold,
                                unfocusedBorderColor = BorderColor,
                                cursorColor = Gold
                            )
                        )
                        Spacer(Modifier.height(12.dp))
                        GoldButton(
                            text = "Save Changes",
                            isLoading = isUpdatingProfile,
                            onClick = {
                                viewModel.updateProfile(editName, editBio)
                                showEditForm = false
                            }
                        )
                    }
                }
            }

            // ── Stats row ────────────────────────────────────────────────────
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    StatCard(
                        label = "Total Scans",
                        value = "${profile?.scansThisQuarter ?: 0}",
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        label = "Lifetime Comps",
                        value = "$${String.format("%.0f", profile?.lifetimeUsdc ?: 0.0)}",
                        modifier = Modifier.weight(1f)
                    )
                    StatCard(
                        label = "Tier",
                        value = profile?.tier ?: "Standard",
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // ── Referral code card ────────────────────────────────────────────
            item {
                GoldAccentCard {
                    Text(
                        text = "Your Referral Code",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = affiliateDashboard?.referralCode ?: "Loading…",
                            color = Gold,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 20.sp,
                            modifier = Modifier.weight(1f)
                        )
                        // Copy button
                        IconButton(onClick = {
                            val code = affiliateDashboard?.referralCode ?: return@IconButton
                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            clipboard.setPrimaryClip(ClipData.newPlainText("Referral Code", code))
                        }) {
                            Icon(Icons.Default.ContentCopy, contentDescription = "Copy", tint = Gold)
                        }
                        // Share button
                        IconButton(onClick = {
                            val code = affiliateDashboard?.referralCode ?: return@IconButton
                            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, "Join BlakJaks with my referral code: $code — https://blakjaks.com/ref/$code")
                            }
                            context.startActivity(Intent.createChooser(shareIntent, "Share Referral Code"))
                        }) {
                            Icon(Icons.Default.Share, contentDescription = "Share", tint = Gold)
                        }
                    }
                }
            }

            // ── Affiliate section ─────────────────────────────────────────────
            if (affiliateDashboard != null) {
                item {
                    BlakJaksCard {
                        Text(
                            text = "Affiliate Dashboard",
                            color = TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp
                        )
                        Spacer(Modifier.height(12.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            LabelValue("Downline", "${affiliateDashboard!!.totalDownline}")
                            LabelValue("Active", "${affiliateDashboard!!.activeDownline}")
                            LabelValue("Lifetime Earned", "$${String.format("%.2f", affiliateDashboard!!.lifetimeEarnings)}")
                        }
                        if (affiliatePayouts.isNotEmpty()) {
                            Spacer(Modifier.height(12.dp))
                            Text("Recent Payouts", color = TextSecondary, fontSize = 12.sp)
                            Spacer(Modifier.height(6.dp))
                            affiliatePayouts.take(5).forEach { payout ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 4.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = payout.payoutDate,
                                        color = TextSecondary,
                                        fontSize = 13.sp
                                    )
                                    Text(
                                        text = "$${String.format("%.2f", payout.amount)}",
                                        color = Gold,
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 13.sp
                                    )
                                    StatusChip(payout.status)
                                }
                            }
                        }
                    }
                }
            }

            // ── Order History section ─────────────────────────────────────────
            item {
                BlakJaksCard {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Order History",
                            color = TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            modifier = Modifier.weight(1f)
                        )
                        TextButton(onClick = { /* TODO: navigate to OrderHistoryScreen */ }) {
                            Text("View All", color = Gold, fontSize = 12.sp)
                        }
                    }

                    if (orders.isEmpty()) {
                        Spacer(Modifier.height(8.dp))
                        Text("No orders yet", color = TextDim, fontSize = 14.sp)
                    } else {
                        Spacer(Modifier.height(8.dp))
                        orders.take(3).forEach { order ->
                            OrderRow(order = order)
                            HorizontalDivider(color = BorderColor, thickness = 0.5.dp, modifier = Modifier.padding(vertical = 6.dp))
                        }
                    }
                }
            }

            // ── Account section ───────────────────────────────────────────────
            item {
                BlakJaksCard {
                    Text(
                        text = "Account",
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                    Spacer(Modifier.height(12.dp))

                    // Language row (stub)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Language", color = TextPrimary, modifier = Modifier.weight(1f))
                        Text("English", color = TextSecondary)
                    }

                    HorizontalDivider(color = BorderColor, modifier = Modifier.padding(vertical = 8.dp))

                    // Sign Out button
                    TextButton(
                        onClick = {
                            viewModel.logout {
                                navController.navigate("auth") {
                                    popUpTo(0) { inclusive = true }
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = "Sign Out",
                            color = Failure,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp
                        )
                    }
                }
            }

            item { Spacer(Modifier.height(32.dp)) }
        }
    }

    // Avatar picker bottom sheet
    if (showAvatarPicker) {
        AvatarPickerSheet(
            viewModel = viewModel,
            onDismiss = { showAvatarPicker = false }
        )
    }
}

// ─── Helper Composables ───────────────────────────────────────────────────────

@Composable
private fun StatCard(label: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = BackgroundCard),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                color = Gold,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = label,
                color = TextSecondary,
                fontSize = 11.sp
            )
        }
    }
}

@Composable
private fun LabelValue(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = value, color = Gold, fontWeight = FontWeight.Bold, fontSize = 15.sp)
        Text(text = label, color = TextSecondary, fontSize = 11.sp)
    }
}

@Composable
private fun StatusChip(status: String) {
    val color = when (status.lowercase()) {
        "processed", "completed" -> Success
        "pending" -> Warning
        "failed" -> Failure
        else -> TextSecondary
    }
    Text(
        text = status.uppercase(),
        color = color,
        fontSize = 10.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier
            .background(color.copy(alpha = 0.15f), RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    )
}

@Composable
private fun OrderRow(order: Order) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Order #${order.id}",
                color = TextPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp
            )
            Text(
                text = order.createdAt.take(10),
                color = TextSecondary,
                fontSize = 12.sp
            )
        }
        Spacer(Modifier.width(8.dp))
        StatusChip(order.status)
        Spacer(Modifier.width(8.dp))
        Text(
            text = "$${String.format("%.2f", order.total)}",
            color = Gold,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp
        )
    }
}
