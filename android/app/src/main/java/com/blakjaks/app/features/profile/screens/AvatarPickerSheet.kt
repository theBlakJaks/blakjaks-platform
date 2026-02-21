package com.blakjaks.app.features.profile.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.profile.ProfileViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AvatarPickerSheet(
    viewModel: ProfileViewModel,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var selectedUri by remember { mutableStateOf<Uri?>(null) }
    var isUploading by remember { mutableStateOf(false) }

    // Gallery picker launcher
    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        selectedUri = uri
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BackgroundCard,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Update Profile Photo",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp
            )

            Spacer(Modifier.height(20.dp))

            // Image preview
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(BackgroundSurface)
                    .border(2.dp, if (selectedUri != null) Gold else BorderColor,
                        androidx.compose.foundation.shape.CircleShape),
                contentAlignment = Alignment.Center
            ) {
                if (selectedUri != null) {
                    AsyncImage(
                        model = selectedUri,
                        contentDescription = "Preview",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Text(
                        text = "Preview",
                        color = TextDim,
                        fontSize = 13.sp
                    )
                }
            }

            Spacer(Modifier.height(24.dp))

            // Choose from Gallery button
            SecondaryButton(
                text = "Choose from Gallery",
                onClick = { galleryLauncher.launch("image/*") }
            )

            Spacer(Modifier.height(12.dp))

            // Upload button (enabled only when image selected)
            GoldButton(
                text = "Upload",
                isLoading = isUploading,
                isEnabled = selectedUri != null,
                onClick = {
                    val uri = selectedUri ?: return@GoldButton
                    isUploading = true
                    try {
                        val inputStream = context.contentResolver.openInputStream(uri)
                        val bytes = inputStream?.readBytes()
                        inputStream?.close()
                        if (bytes != null) {
                            viewModel.uploadAvatar(bytes)
                        }
                    } catch (_: Exception) {
                        // Handle read error gracefully
                    } finally {
                        isUploading = false
                        onDismiss()
                    }
                }
            )

            Spacer(Modifier.height(8.dp))

            TextButton(onClick = onDismiss) {
                Text("Cancel", color = TextSecondary)
            }
        }
    }
}
