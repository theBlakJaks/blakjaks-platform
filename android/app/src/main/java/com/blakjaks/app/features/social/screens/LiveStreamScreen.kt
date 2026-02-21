package com.blakjaks.app.features.social.screens

import android.view.ViewGroup
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import androidx.navigation.NavController
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.social.SocialViewModel
import org.koin.androidx.compose.koinViewModel

// TODO: Wire to real HLS stream URL in production

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LiveStreamScreen(navController: NavController) {
    val viewModel: SocialViewModel = koinViewModel()
    val currentLiveStream by viewModel.currentLiveStream.collectAsState()

    val context = LocalContext.current
    val streamUrl = currentLiveStream?.streamUrl
        ?: "https://stream.blakjaks.com/live/hls/main.m3u8" // stub URL

    // Create ExoPlayer and release on dispose
    val exoPlayer = remember {
        ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(streamUrl))
            prepare()
            playWhenReady = true
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            exoPlayer.release()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        // Player view (16:9 at top)
        AndroidView(
            factory = {
                PlayerView(it).apply {
                    player = exoPlayer
                    layoutParams = ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                    useController = true
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .align(Alignment.TopCenter)
        )

        // Header overlay — back button + title + LIVE badge
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopStart)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { navController.popBackStack() }) {
                    Icon(
                        imageVector = Icons.Default.ArrowBack,
                        contentDescription = "Back",
                        tint = Color.White
                    )
                }

                Spacer(Modifier.weight(1f))

                // LIVE badge
                if (currentLiveStream?.isLive == true) {
                    Text(
                        text = "LIVE",
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .background(Color.Red, RoundedCornerShape(4.dp))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "${currentLiveStream?.viewerCount ?: 0} watching",
                        color = Color.White.copy(alpha = 0.85f),
                        fontSize = 12.sp
                    )
                }
            }
        }

        // Stream title overlay at bottom of video area
        currentLiveStream?.let { stream ->
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.TopStart)
                    .padding(top = (9f / 16f * 1000).dp), // approximate — places below 16:9 video
                color = Color.Transparent
            ) {
                // Title shown below video
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomStart)
                    .background(BackgroundPrimary)
                    .padding(16.dp)
            ) {
                Text(
                    text = stream.title,
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = stream.host,
                    color = TextSecondary,
                    fontSize = 14.sp
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    text = "Live chat available in the Social Hub channel.",
                    color = TextDim,
                    fontSize = 12.sp
                )
            }
        }
    }
}
