package com.blakjaks.app.features.scanwallet.screens

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.navigation.NavController
import com.blakjaks.app.core.network.models.Transaction
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.scanwallet.ScanWalletViewModel
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import org.koin.androidx.compose.koinViewModel
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.concurrent.Executors

// ─── Sub-tab enum ────────────────────────────────────────────────────────────

private enum class ScanWalletTab { SCAN, WALLET }

// ─── ScanWalletScreen ─────────────────────────────────────────────────────────
// Center tab with two sub-tabs: SCAN (CameraX + ML Kit) and WALLET (balance +
// transaction history). Full implementation replacing stub.

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScanWalletScreen(navController: NavController) {
    val viewModel: ScanWalletViewModel = koinViewModel()
    var activeTab by remember { mutableStateOf(ScanWalletTab.SCAN) }

    val currentScanResult by viewModel.currentScanResult.collectAsState()
    val showPayoutChoiceSheet by viewModel.showPayoutChoiceSheet.collectAsState()
    val pendingComp by viewModel.pendingChoiceComp.collectAsState()
    val isSubmitting by viewModel.isSubmittingPayoutChoice.collectAsState()
    val error by viewModel.error.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // ─── Tab Row ──────────────────────────────────────────────────────
            TabRow(
                selectedTabIndex = activeTab.ordinal,
                containerColor = BackgroundCard,
                contentColor = Gold,
                indicator = { tabPositions ->
                    TabRowDefaults.SecondaryIndicator(
                        modifier = Modifier.tabIndicatorOffset(tabPositions[activeTab.ordinal]),
                        color = Gold
                    )
                }
            ) {
                Tab(
                    selected = activeTab == ScanWalletTab.SCAN,
                    onClick = { activeTab = ScanWalletTab.SCAN },
                    text = {
                        Text(
                            text = "Scan",
                            color = if (activeTab == ScanWalletTab.SCAN) Gold else TextDim,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                )
                Tab(
                    selected = activeTab == ScanWalletTab.WALLET,
                    onClick = { activeTab = ScanWalletTab.WALLET },
                    text = {
                        Text(
                            text = "Wallet",
                            color = if (activeTab == ScanWalletTab.WALLET) Gold else TextDim,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                )
            }

            // ─── Tab Content ──────────────────────────────────────────────────
            when (activeTab) {
                ScanWalletTab.SCAN   -> ScanTab(viewModel = viewModel)
                ScanWalletTab.WALLET -> WalletTab(viewModel = viewModel)
            }
        }

        // ─── Scan Result Bottom Sheet ─────────────────────────────────────────
        if (currentScanResult != null) {
            ScanResultSheet(
                scanResult = currentScanResult!!,
                onDismiss = { viewModel.clearScanResult() },
                onClaimComp = {
                    viewModel.clearScanResult()
                    // PayoutChoiceSheet will appear automatically via showPayoutChoiceSheet
                }
            )
        }

        // ─── Payout Choice Bottom Sheet ───────────────────────────────────────
        if (showPayoutChoiceSheet && pendingComp != null) {
            PayoutChoiceSheet(
                comp = pendingComp!!,
                isSubmitting = isSubmitting,
                onChoice = { method ->
                    pendingComp?.let { comp ->
                        viewModel.submitPayoutChoice(comp.id, method)
                    }
                },
                onDismiss = {
                    // Choosing "later" is handled via "later" method; dismiss = user taps away
                    viewModel.submitPayoutChoice(pendingComp?.id ?: "", "later")
                }
            )
        }
    }

    // ─── Error Snackbar ───────────────────────────────────────────────────────
    error?.let { msg ->
        LaunchedEffect(msg) {
            kotlinx.coroutines.delay(3000)
            viewModel.clearError()
        }
    }
}

// ─── ScanTab ──────────────────────────────────────────────────────────────────

@Composable
private fun ScanTab(viewModel: ScanWalletViewModel) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val isScanning by viewModel.isScanning.collectAsState()

    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
                    == PackageManager.PERMISSION_GRANTED
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasCameraPermission = granted
    }

    LaunchedEffect(Unit) {
        if (!hasCameraPermission) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        if (hasCameraPermission) {
            // ─── CameraX Preview ──────────────────────────────────────────────
            val cameraExecutor = remember { Executors.newSingleThreadExecutor() }
            var lastScannedValue by remember { mutableStateOf("") }

            AndroidView(
                factory = { ctx ->
                    val previewView = PreviewView(ctx)
                    val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                    cameraProviderFuture.addListener({
                        val cameraProvider = cameraProviderFuture.get()
                        val preview = Preview.Builder().build().also {
                            it.setSurfaceProvider(previewView.surfaceProvider)
                        }
                        val barcodeScanner = BarcodeScanning.getClient()
                        val imageAnalysis = ImageAnalysis.Builder()
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build()
                            .also { analysis ->
                                analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                                    val mediaImage = imageProxy.image
                                    if (mediaImage != null) {
                                        val inputImage = InputImage.fromMediaImage(
                                            mediaImage,
                                            imageProxy.imageInfo.rotationDegrees
                                        )
                                        barcodeScanner.process(inputImage)
                                            .addOnSuccessListener { barcodes ->
                                                for (barcode in barcodes) {
                                                    if (barcode.format == Barcode.FORMAT_QR_CODE) {
                                                        val raw = barcode.rawValue ?: continue
                                                        // Debounce: don't re-scan same code while processing
                                                        if (raw != lastScannedValue && !isScanning) {
                                                            lastScannedValue = raw
                                                            viewModel.processQrCode(raw)
                                                        }
                                                    }
                                                }
                                            }
                                            .addOnCompleteListener { imageProxy.close() }
                                    } else {
                                        imageProxy.close()
                                    }
                                }
                            }
                        try {
                            cameraProvider.unbindAll()
                            cameraProvider.bindToLifecycle(
                                lifecycleOwner,
                                CameraSelector.DEFAULT_BACK_CAMERA,
                                preview,
                                imageAnalysis
                            )
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }, ContextCompat.getMainExecutor(ctx))
                    previewView
                },
                modifier = Modifier.fillMaxSize()
            )

            // ─── Scan Frame Overlay (gold corner brackets) ────────────────────
            ScanFrameOverlay()

            // ─── Scanning indicator ───────────────────────────────────────────
            if (isScanning) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 80.dp)
                ) {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = BackgroundCard.copy(alpha = 0.85f)),
                        shape = RoundedCornerShape(24.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                color = Gold,
                                strokeWidth = 2.dp
                            )
                            Text(text = "Processing...", color = TextPrimary, fontSize = 14.sp)
                        }
                    }
                }
            }

        } else {
            // ─── Permission Denied State ──────────────────────────────────────
            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CameraAlt,
                    contentDescription = null,
                    tint = TextDim,
                    modifier = Modifier.size(64.dp)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Camera permission required to scan QR codes.",
                    color = TextSecondary,
                    fontSize = 14.sp
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { permissionLauncher.launch(Manifest.permission.CAMERA) },
                    colors = ButtonDefaults.buttonColors(containerColor = Gold, contentColor = Color.Black)
                ) {
                    Text("Grant Permission")
                }
            }
        }
    }
}

// ─── ScanFrameOverlay ─────────────────────────────────────────────────────────
// Draws gold corner brackets around the scan area using Canvas.

@Composable
private fun ScanFrameOverlay() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // Semi-transparent dark scrim around the scan area
        Box(
            modifier = Modifier
                .size(260.dp)
                .clip(RoundedCornerShape(4.dp))
        ) {
            // Gold corner brackets rendered as composable boxes
            // Top-left corner
            CornerBracket(Alignment.TopStart)
            // Top-right corner
            CornerBracket(Alignment.TopEnd)
            // Bottom-left corner
            CornerBracket(Alignment.BottomStart)
            // Bottom-right corner
            CornerBracket(Alignment.BottomEnd)
        }
        // Label below
        Box(
            modifier = Modifier
                .align(Alignment.Center)
                .offset(y = 150.dp)
        ) {
            Text(
                text = "Align QR code within the frame",
                color = Color.White,
                fontSize = 13.sp
            )
        }
    }
}

@Composable
private fun BoxScope.CornerBracket(alignment: Alignment) {
    val bracketSize = 24.dp
    val strokeWidth = 3.dp
    val offset = 0.dp

    Box(modifier = Modifier.align(alignment)) {
        // Horizontal arm
        Box(
            modifier = Modifier
                .width(bracketSize)
                .height(strokeWidth)
                .background(Gold)
        )
        // Vertical arm
        Box(
            modifier = Modifier
                .width(strokeWidth)
                .height(bracketSize)
                .background(Gold)
        )
    }
}

// ─── WalletTab ────────────────────────────────────────────────────────────────

@Composable
private fun WalletTab(viewModel: ScanWalletViewModel) {
    val wallet by viewModel.wallet.collectAsState()
    val scanHistory by viewModel.scanHistory.collectAsState()
    val isLoadingWallet by viewModel.isLoadingWallet.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary),
        contentPadding = PaddingValues(
            horizontal = Layout.screenMargin,
            vertical = Spacing.md
        ),
        verticalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        // ─── Comp Balance (large gold number) ─────────────────────────────────
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = BackgroundCard),
                shape = RoundedCornerShape(Layout.cardCornerRadius)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Layout.cardPadding),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Comp Balance",
                        color = TextSecondary,
                        fontSize = 14.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    if (isLoadingWallet) {
                        CircularProgressIndicator(color = Gold, modifier = Modifier.size(32.dp))
                    } else {
                        Text(
                            text = "$${"%,.2f".format(viewModel.compBalance)}",
                            color = Gold,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 44.sp
                        )
                    }
                    wallet?.let { w ->
                        Spacer(modifier = Modifier.height(Spacing.sm))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceAround
                        ) {
                            WalletStat(
                                label = "Available",
                                value = "$${"%,.2f".format(w.availableBalance)}"
                            )
                            WalletStat(
                                label = "Pending",
                                value = "$${"%,.2f".format(w.pendingBalance)}"
                            )
                        }
                        w.walletAddress?.let { addr ->
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = truncateWalletAddress(addr),
                                color = TextDim,
                                fontSize = 11.sp
                            )
                        }
                    }
                }
            }
        }

        // ─── Recent Scan History ──────────────────────────────────────────────
        item {
            Text(
                text = "Recent Scans",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp
            )
        }
        if (scanHistory.isEmpty()) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No scans yet.", color = TextSecondary)
                }
            }
        } else {
            items(scanHistory) { scan ->
                ScanHistoryRow(scan = scan)
            }
        }

        item { Spacer(modifier = Modifier.height(Spacing.xl)) }
    }
}

// ─── WalletStat ───────────────────────────────────────────────────────────────

@Composable
private fun WalletStat(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = value, color = TextPrimary, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
        Text(text = label, color = TextSecondary, fontSize = 11.sp)
    }
}

// ─── ScanHistoryRow ───────────────────────────────────────────────────────────

@Composable
private fun ScanHistoryRow(scan: com.blakjaks.app.core.network.models.Scan) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Default.QrCodeScanner,
                contentDescription = null,
                tint = Gold,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(Spacing.sm))
            Column {
                Text(
                    text = scan.productName,
                    color = TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = relativeTimeScan(scan.createdAt),
                    color = TextDim,
                    fontSize = 11.sp
                )
            }
        }
        Text(
            text = "+${"%.2f".format(scan.usdcEarned)}",
            color = Success,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp
        )
    }
}

// ─── Utility ─────────────────────────────────────────────────────────────────

private fun truncateWalletAddress(address: String): String =
    if (address.length > 12) "${address.take(6)}...${address.takeLast(4)}" else address

private fun relativeTimeScan(isoTimestamp: String): String {
    return try {
        val instant = Instant.parse(isoTimestamp)
        val now = Instant.now()
        val minutes = ChronoUnit.MINUTES.between(instant, now)
        when {
            minutes < 1    -> "just now"
            minutes < 60   -> "${minutes}m ago"
            minutes < 1440 -> "${minutes / 60}h ago"
            else           -> "${minutes / 1440}d ago"
        }
    } catch (e: Exception) {
        ""
    }
}
