package com.blakjaks.app.features.scanwallet

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// ─── ScanWalletViewModel ──────────────────────────────────────────────────────
// Owns all data for the center scan/wallet tab.
// Mirrors iOS ScanWalletViewModel.swift — Koin DI (no Hilt).

class ScanWalletViewModel(
    private val apiClient: ApiClientInterface
) : ViewModel() {

    // ─── Wallet & History ────────────────────────────────────────────────────

    private val _wallet = MutableStateFlow<WalletDetail?>(null)
    val wallet: StateFlow<WalletDetail?> = _wallet.asStateFlow()

    private val _scanHistory = MutableStateFlow<List<Scan>>(emptyList())
    val scanHistory: StateFlow<List<Scan>> = _scanHistory.asStateFlow()

    // ─── Current Scan Result ─────────────────────────────────────────────────

    private val _currentScanResult = MutableStateFlow<ScanResult?>(null)
    val currentScanResult: StateFlow<ScanResult?> = _currentScanResult.asStateFlow()

    // ─── Loading Flags ───────────────────────────────────────────────────────

    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning.asStateFlow()

    private val _isLoadingWallet = MutableStateFlow(false)
    val isLoadingWallet: StateFlow<Boolean> = _isLoadingWallet.asStateFlow()

    private val _isLoadingHistory = MutableStateFlow(false)
    val isLoadingHistory: StateFlow<Boolean> = _isLoadingHistory.asStateFlow()

    // ─── Error ───────────────────────────────────────────────────────────────

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // ─── Payout Choice Sheet ─────────────────────────────────────────────────

    private val _showPayoutChoiceSheet = MutableStateFlow(false)
    val showPayoutChoiceSheet: StateFlow<Boolean> = _showPayoutChoiceSheet.asStateFlow()

    private val _pendingChoiceComp = MutableStateFlow<CompEarned?>(null)
    val pendingChoiceComp: StateFlow<CompEarned?> = _pendingChoiceComp.asStateFlow()

    private val _isSubmittingPayoutChoice = MutableStateFlow(false)
    val isSubmittingPayoutChoice: StateFlow<Boolean> = _isSubmittingPayoutChoice.asStateFlow()

    // ─── Computed: Comp Balance ───────────────────────────────────────────────

    val compBalance: Double
        get() = _wallet.value?.compBalance ?: 0.0

    // ─── Init ────────────────────────────────────────────────────────────────

    init {
        loadWallet()
        loadScanHistory()
    }

    // ─── Load Wallet ─────────────────────────────────────────────────────────

    fun loadWallet() {
        viewModelScope.launch {
            _isLoadingWallet.value = true
            try {
                _wallet.value = apiClient.getWallet()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load wallet"
            } finally {
                _isLoadingWallet.value = false
            }
        }
    }

    // ─── Load Scan History ────────────────────────────────────────────────────

    fun loadScanHistory() {
        viewModelScope.launch {
            _isLoadingHistory.value = true
            try {
                _scanHistory.value = apiClient.getScanHistory(limit = 20, offset = 0)
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load scan history"
            } finally {
                _isLoadingHistory.value = false
            }
        }
    }

    // ─── Process QR Code ─────────────────────────────────────────────────────
    // Called when CameraX/ML Kit detects a barcode.

    fun processQrCode(rawValue: String) {
        if (_isScanning.value) return
        viewModelScope.launch {
            _isScanning.value = true
            try {
                val result = apiClient.submitScan(rawValue)
                _currentScanResult.value = result
                // If a comp was earned that requires payout choice, show the sheet
                val comp = result.compEarned
                if (comp != null && comp.requiresPayoutChoice) {
                    _pendingChoiceComp.value = comp
                    _showPayoutChoiceSheet.value = true
                }
                // Refresh wallet balance after scan
                loadWallet()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to process QR code"
            } finally {
                _isScanning.value = false
            }
        }
    }

    // ─── Submit Payout Choice ─────────────────────────────────────────────────

    fun submitPayoutChoice(compId: String, method: String) {
        viewModelScope.launch {
            _isSubmittingPayoutChoice.value = true
            try {
                apiClient.submitPayoutChoice(compId = compId, method = method)
                _showPayoutChoiceSheet.value = false
                _pendingChoiceComp.value = null
                loadWallet()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to submit payout choice"
            } finally {
                _isSubmittingPayoutChoice.value = false
            }
        }
    }

    // ─── Clear Scan Result ────────────────────────────────────────────────────

    fun clearScanResult() {
        _currentScanResult.value = null
    }

    // ─── Clear Error ──────────────────────────────────────────────────────────

    fun clearError() {
        _error.value = null
    }
}
