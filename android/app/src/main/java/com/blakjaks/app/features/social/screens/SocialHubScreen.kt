package com.blakjaks.app.features.social.screens

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.blakjaks.app.core.components.GoldAccentCard
import com.blakjaks.app.core.components.TierBadge
import com.blakjaks.app.core.network.models.Channel
import com.blakjaks.app.core.network.models.ChatMessage
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.social.SocialViewModel
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun SocialHubScreen(navController: NavController) {
    val viewModel: SocialViewModel = koinViewModel()

    val channels by viewModel.channels.collectAsState()
    val selectedChannel by viewModel.selectedChannel.collectAsState()
    val messages by viewModel.messages.collectAsState()
    val currentLiveStream by viewModel.currentLiveStream.collectAsState()
    val isLoadingMessages by viewModel.isLoadingMessages.collectAsState()
    val isRateLimited by viewModel.isRateLimited.collectAsState()
    val rateLimitSeconds by viewModel.rateLimitRemainingSeconds.collectAsState()
    val draftMessage by viewModel.draftMessage.collectAsState()
    val error by viewModel.error.collectAsState()

    val drawerState = rememberDrawerState(DrawerValue.Closed)
    val coroutineScope = rememberCoroutineScope()
    val listState = rememberLazyListState()

    // Reaction picker state
    var reactionTargetMessage by remember { mutableStateOf<ChatMessage?>(null) }
    val reactionEmojis = listOf("👍", "❤️", "🔥", "💰", "😂")

    // Error snackbar
    val snackbarHostState = remember { SnackbarHostState() }
    LaunchedEffect(error) {
        if (error != null) {
            snackbarHostState.showSnackbar(error ?: "An error occurred")
            viewModel.clearError()
        }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet(drawerContainerColor = BackgroundCard) {
                Spacer(Modifier.height(24.dp))
                Text(
                    text = "Channels",
                    color = Gold,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
                HorizontalDivider(color = BorderColor)
                Spacer(Modifier.height(8.dp))

                channels.forEach { channel ->
                    ChannelDrawerItem(
                        channel = channel,
                        isSelected = channel.id == selectedChannel?.id,
                        onClick = {
                            viewModel.selectChannel(channel)
                            coroutineScope.launch { drawerState.close() }
                        }
                    )
                }
            }
        }
    ) {
        Scaffold(
            containerColor = BackgroundPrimary,
            snackbarHost = { SnackbarHost(snackbarHostState) },
            topBar = {
                TopAppBar(
                    title = {
                        Column {
                            Text(
                                text = selectedChannel?.let { "#${it.name}" } ?: "BlakJaks Social",
                                color = TextPrimary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                            if (selectedChannel != null) {
                                Text(
                                    text = "${selectedChannel!!.memberCount} members",
                                    color = TextSecondary,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    },
                    navigationIcon = {
                        IconButton(onClick = { coroutineScope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = "Open channels", tint = Gold)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = BackgroundCard)
                )
            }
        ) { paddingValues ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .background(BackgroundPrimary)
            ) {
                // ── Live stream card ─────────────────────────────────────────
                currentLiveStream?.let { stream ->
                    GoldAccentCard(modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Thumbnail placeholder
                            Box(
                                modifier = Modifier
                                    .size(64.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(BackgroundSurface),
                                contentAlignment = Alignment.Center
                            ) {
                                if (stream.thumbnailUrl != null) {
                                    AsyncImage(
                                        model = stream.thumbnailUrl,
                                        contentDescription = "Stream thumbnail",
                                        modifier = Modifier.fillMaxSize()
                                    )
                                } else {
                                    Icon(
                                        imageVector = Icons.Default.PlayArrow,
                                        contentDescription = null,
                                        tint = Gold,
                                        modifier = Modifier.size(32.dp)
                                    )
                                }
                            }

                            Spacer(Modifier.width(12.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    // LIVE badge
                                    Text(
                                        text = "LIVE",
                                        color = Color.White,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier
                                            .background(Color.Red, RoundedCornerShape(4.dp))
                                            .padding(horizontal = 6.dp, vertical = 2.dp)
                                    )
                                    Spacer(Modifier.width(8.dp))
                                    Text(
                                        text = "${stream.viewerCount} watching",
                                        color = TextSecondary,
                                        fontSize = 12.sp
                                    )
                                }
                                Spacer(Modifier.height(4.dp))
                                Text(
                                    text = stream.title,
                                    color = TextPrimary,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 14.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = stream.host,
                                    color = TextSecondary,
                                    fontSize = 12.sp
                                )
                            }

                            Spacer(Modifier.width(8.dp))

                            IconButton(onClick = { navController.navigate("live_stream") }) {
                                Icon(Icons.Default.PlayArrow, contentDescription = "Watch live", tint = Gold)
                            }
                        }
                    }
                }

                // ── Messages list ────────────────────────────────────────────
                Box(modifier = Modifier.weight(1f)) {
                    when {
                        isLoadingMessages && messages.isEmpty() -> {
                            CircularProgressIndicator(
                                color = Gold,
                                modifier = Modifier.align(Alignment.Center)
                            )
                        }
                        messages.isEmpty() && selectedChannel != null -> {
                            Text(
                                text = "No messages yet. Say something!",
                                color = TextDim,
                                modifier = Modifier.align(Alignment.Center)
                            )
                        }
                        selectedChannel == null -> {
                            Text(
                                text = "Select a channel to start chatting",
                                color = TextDim,
                                modifier = Modifier.align(Alignment.Center)
                            )
                        }
                        else -> {
                            LazyColumn(
                                state = listState,
                                reverseLayout = true,
                                modifier = Modifier.fillMaxSize(),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                items(
                                    items = messages.asReversed(),
                                    key = { it.id }
                                ) { message ->
                                    MessageBubble(
                                        message = message,
                                        isOwnMessage = message.userId == viewModel.currentUserId,
                                        onLongPress = { reactionTargetMessage = message }
                                    )
                                }
                            }
                        }
                    }
                }

                // ── Rate limit countdown bar ──────────────────────────────────
                if (isRateLimited) {
                    LinearProgressIndicator(
                        progress = { rateLimitSeconds / 5f },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp),
                        color = Gold,
                        trackColor = BorderColor
                    )
                    Text(
                        text = "Rate limit: ${rateLimitSeconds}s",
                        color = TextSecondary,
                        fontSize = 11.sp,
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(BackgroundCard)
                            .padding(horizontal = 16.dp, vertical = 4.dp)
                    )
                }

                // ── Message input bar ─────────────────────────────────────────
                Surface(color = BackgroundCard) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = draftMessage,
                            onValueChange = { if (it.length <= 500) viewModel.draftMessage.value = it },
                            modifier = Modifier.weight(1f),
                            placeholder = {
                                Text(
                                    text = if (selectedChannel != null)
                                        "Message #${selectedChannel!!.name}"
                                    else "Select a channel",
                                    color = TextDim
                                )
                            },
                            enabled = selectedChannel != null && !isRateLimited,
                            singleLine = false,
                            maxLines = 4,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = TextPrimary,
                                unfocusedTextColor = TextPrimary,
                                focusedBorderColor = Gold,
                                unfocusedBorderColor = BorderColor,
                                cursorColor = Gold
                            ),
                            trailingIcon = {
                                Text(
                                    text = "${draftMessage.length}/500",
                                    fontSize = 10.sp,
                                    color = if (draftMessage.length >= 490) Warning else TextDim,
                                    modifier = Modifier.padding(end = 4.dp)
                                )
                            }
                        )

                        Spacer(Modifier.width(8.dp))

                        val sendEnabled = draftMessage.isNotBlank() && !isRateLimited && selectedChannel != null
                        IconButton(
                            onClick = { viewModel.sendMessage() },
                            enabled = sendEnabled
                        ) {
                            Icon(
                                imageVector = Icons.Default.Send,
                                contentDescription = "Send",
                                tint = if (sendEnabled) Gold else TextDim
                            )
                        }
                    }
                }
            }
        }
    }

    // ── Reaction picker dialog ────────────────────────────────────────────────
    if (reactionTargetMessage != null) {
        AlertDialog(
            onDismissRequest = { reactionTargetMessage = null },
            containerColor = BackgroundCard,
            title = {
                Text("Add Reaction", color = TextPrimary, fontWeight = FontWeight.Bold)
            },
            text = {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    reactionEmojis.forEach { emoji ->
                        Text(
                            text = emoji,
                            fontSize = 28.sp,
                            modifier = Modifier
                                .clickable {
                                    reactionTargetMessage?.let { msg ->
                                        viewModel.addReaction(msg, emoji)
                                    }
                                    reactionTargetMessage = null
                                }
                                .padding(8.dp)
                        )
                    }
                }
            },
            confirmButton = {},
            dismissButton = {
                TextButton(onClick = { reactionTargetMessage = null }) {
                    Text("Cancel", color = TextSecondary)
                }
            }
        )
    }
}

// ─── Channel Drawer Item ──────────────────────────────────────────────────────

@Composable
private fun ChannelDrawerItem(
    channel: Channel,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .background(if (isSelected) Gold.copy(alpha = 0.12f) else Color.Transparent)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "#${channel.name}",
            color = if (isSelected) Gold else TextPrimary,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            modifier = Modifier.weight(1f)
        )

        // Unread dot if channel has recent messages and is not selected
        if (channel.lastMessageAt != null && !isSelected) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(Gold, CircleShape)
            )
            Spacer(Modifier.width(8.dp))
        }

        Text(
            text = "${channel.memberCount}",
            color = TextDim,
            fontSize = 11.sp
        )
    }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MessageBubble(
    message: ChatMessage,
    isOwnMessage: Boolean,
    onLongPress: () -> Unit
) {
    if (isOwnMessage) {
        // Right-aligned gold bubble
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            Column(horizontalAlignment = Alignment.End) {
                Box(
                    modifier = Modifier
                        .widthIn(max = 280.dp)
                        .clip(
                            RoundedCornerShape(
                                topStart = 16.dp, topEnd = 4.dp,
                                bottomStart = 16.dp, bottomEnd = 16.dp
                            )
                        )
                        .background(Gold.copy(alpha = 0.85f))
                        .combinedClickable(onClick = {}, onLongClick = onLongPress)
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(text = message.content, color = Color.Black, fontSize = 14.sp)
                }
                MessageReactions(message.reactionSummary)
            }
        }
    } else {
        // Left-aligned card bubble with avatar + username
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            // Avatar initials circle
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(BackgroundSurface)
                    .border(1.dp, BorderColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                if (message.userAvatarUrl != null) {
                    AsyncImage(
                        model = message.userAvatarUrl,
                        contentDescription = "Avatar",
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                    )
                } else {
                    Text(
                        text = message.userFullName.take(1).uppercase(),
                        color = Gold,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }
            }

            Spacer(Modifier.width(8.dp))

            Column {
                // Username + tier badge row
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = message.userFullName,
                        color = TextPrimary,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 12.sp
                    )
                    Spacer(Modifier.width(6.dp))
                    TierBadge(tier = message.userTier)
                }

                Spacer(Modifier.height(3.dp))

                val bubbleShape = RoundedCornerShape(
                    topStart = 4.dp, topEnd = 16.dp,
                    bottomStart = 16.dp, bottomEnd = 16.dp
                )
                Box(
                    modifier = Modifier
                        .widthIn(max = 280.dp)
                        .clip(bubbleShape)
                        .background(BackgroundCard)
                        .border(1.dp, BorderColor, bubbleShape)
                        .combinedClickable(onClick = {}, onLongClick = onLongPress)
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Text(text = message.content, color = TextPrimary, fontSize = 14.sp)
                }
                MessageReactions(message.reactionSummary)
            }
        }
    }
}

// ─── Reaction Pills Row ───────────────────────────────────────────────────────

@Composable
private fun MessageReactions(reactionSummary: Map<String, Int>?) {
    if (reactionSummary.isNullOrEmpty()) return
    Spacer(Modifier.height(3.dp))
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        reactionSummary.entries.take(5).forEach { (emoji, count) ->
            Row(
                modifier = Modifier
                    .background(BackgroundSurface, RoundedCornerShape(12.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = emoji, fontSize = 12.sp)
                Spacer(Modifier.width(3.dp))
                Text(text = "$count", color = TextSecondary, fontSize = 11.sp)
            }
        }
    }
}
