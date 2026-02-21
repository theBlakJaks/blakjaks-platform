package com.blakjaks.app.features.social.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.AppNotification
import com.blakjaks.app.core.theme.*
import kotlinx.coroutines.launch
import org.koin.compose.koinInject

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(navController: NavController) {
    val apiClient: ApiClientInterface = koinInject()
    var notifications by remember { mutableStateOf<List<AppNotification>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        coroutineScope.launch {
            try {
                notifications = apiClient.getNotifications(null, 50, 0)
            } catch (_: Exception) {
                // Silently handle load error
            } finally {
                isLoading = false
            }
        }
    }

    Scaffold(
        containerColor = BackgroundPrimary,
        topBar = {
            TopAppBar(
                title = {
                    Text("Notifications", color = TextPrimary, fontWeight = FontWeight.Bold)
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Gold)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = BackgroundCard)
            )
        }
    ) { paddingValues ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = Gold)
            }
        } else if (notifications.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text("No notifications yet", color = TextDim)
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(notifications, key = { it.id }) { notification ->
                    NotificationRow(notification = notification)
                    HorizontalDivider(color = BorderColor, thickness = 0.5.dp)
                }
            }
        }
    }
}

@Composable
private fun NotificationRow(notification: AppNotification) {
    val (icon, iconTint) = when (notification.type) {
        "comp_earned", "comp_award" -> Pair(Icons.Default.Star, Gold)
        "social", "chat_message" -> Pair(Icons.Default.Info, Info)
        "order_update", "order" -> Pair(Icons.Default.ShoppingBag, Success)
        else -> Pair(Icons.Default.Notifications, Warning)
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (!notification.isRead) Gold.copy(alpha = 0.05f) else BackgroundPrimary)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.Top
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier
                .size(24.dp)
                .padding(top = 2.dp)
        )

        Spacer(Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = notification.title,
                    color = TextPrimary,
                    fontWeight = if (!notification.isRead) FontWeight.Bold else FontWeight.Normal,
                    fontSize = 14.sp,
                    modifier = Modifier.weight(1f)
                )
                if (!notification.isRead) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(Gold, androidx.compose.foundation.shape.CircleShape)
                    )
                }
            }

            Spacer(Modifier.height(3.dp))

            Text(
                text = notification.body,
                color = TextSecondary,
                fontSize = 13.sp
            )

            Spacer(Modifier.height(4.dp))

            Text(
                text = formatTimestamp(notification.createdAt),
                color = TextDim,
                fontSize = 11.sp
            )
        }
    }
}

private fun formatTimestamp(isoString: String): String {
    // Simple display — in production parse to relative time
    return isoString.take(10)
}
