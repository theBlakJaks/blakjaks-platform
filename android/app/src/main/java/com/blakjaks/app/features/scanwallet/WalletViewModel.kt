package com.blakjaks.app.features.scanwallet

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// ─── WalletViewModel ──────────────────────────────────────────────────────────
// Owns the full wallet detail / Dwolla flow — separate from ScanWalletViewModel
// which owns scan UX and payout-choice-at-scan-time.
// Koin DI (no Hilt).

class WalletViewModel(
    private val apiClient: ApiClientInterface
) : ViewModel() {

    // ─── Core Wallet State ────────────────────────────────────────────────────

    private val _walletDetail = MutableStateFlow<WalletDetail?>(null)
    val walletDetail: StateFlow<WalletDetail?> = _walletDetail.asStateFlow()

    private val _transactions = MutableStateFlow<List<Transaction>>(emptyList())
    val transactions: StateFlow<List<Transaction>> = _transactions.asStateFlow()

    private val _dwollaFundingSources = MutableStateFlow<List<DwollaFundingSource>>(emptyList())
    val dwollaFundingSources: StateFlow<List<DwollaFundingSource>> = _dwollaFundingSources.asStateFlow()

    private val _pendingComps = MutableStateFlow<List<CompEarned>>(emptyList())
    val pendingComps: StateFlow<List<CompEarned>> = _pendingComps.asStateFlow()

    // ─── Loading / Status Flags ───────────────────────────────────────────────

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isWithdrawing = MutableStateFlow(false)
    val isWithdrawing: StateFlow<Boolean> = _isWithdrawing.asStateFlow()

    private val _isLinkingBank = MutableStateFlow(false)
    val isLinkingBank: StateFlow<Boolean> = _isLinkingBank.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _successMessage = MutableStateFlow<String?>(null)
    val successMessage: StateFlow<String?> = _successMessage.asStateFlow()

    // ─── Sheet Visibility ─────────────────────────────────────────────────────

    private val _showWithdrawSheet = MutableStateFlow(false)
    val showWithdrawSheet: StateFlow<Boolean> = _showWithdrawSheet.asStateFlow()

    private val _showLinkBankSheet = MutableStateFlow(false)
    val showLinkBankSheet: StateFlow<Boolean> = _showLinkBankSheet.asStateFlow()

    // ─── User-Entry State ─────────────────────────────────────────────────────

    val withdrawAmount = MutableStateFlow("")

    val selectedFundingSource = MutableStateFlow<DwollaFundingSource?>(null)

    // ─── Init ─────────────────────────────────────────────────────────────────

    init {
        loadWalletDetail()
        loadTransactions()
    }

    // ─── Load Wallet Detail ───────────────────────────────────────────────────

    fun loadWalletDetail() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val wallet = apiClient.getWallet()
                _walletDetail.value = wallet

                // Populate pending comps from wallet data.
                // The WalletDetail.linkedBankAccount gives us the primary funding source.
                // pendingComps are tracked from the comp scan flow. Since the API
                // currently doesn't return a comp list in WalletDetail, we populate
                // pendingComps from what the scan flow has surfaced (held via state).
                // A real API would return comp_list here; for now we keep existing list.

                // Update funding sources from wallet
                loadDwollaFundingSources()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load wallet"
            } finally {
                _isLoading.value = false
            }
        }
    }

    // ─── Load Transactions ────────────────────────────────────────────────────

    fun loadTransactions() {
        viewModelScope.launch {
            try {
                val txList = apiClient.getTransactions(limit = 20, offset = 0)
                _transactions.value = txList
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load transactions"
            }
        }
    }

    // ─── Load Dwolla Funding Sources ──────────────────────────────────────────
    // The ApiClientInterface does not expose a dedicated getDwollaFundingSources()
    // endpoint yet; we derive them from the wallet's linkedBankAccount field.
    // This method is ready to swap in a real API call when the endpoint is added.

    fun loadDwollaFundingSources() {
        viewModelScope.launch {
            try {
                val wallet = _walletDetail.value ?: apiClient.getWallet()
                val sources = mutableListOf<DwollaFundingSource>()
                wallet.linkedBankAccount?.let { sources.add(it) }
                _dwollaFundingSources.value = sources
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load funding sources"
            }
        }
    }

    // ─── Request Withdrawal ───────────────────────────────────────────────────

    fun requestWithdrawal(method: String) {
        val amount = withdrawAmount.value.toDoubleOrNull() ?: 0.0
        if (amount <= 0.0) {
            _error.value = "Please enter a valid withdrawal amount greater than zero."
            return
        }
        val currentBalance = _walletDetail.value?.compBalance ?: 0.0
        if (amount > currentBalance) {
            _error.value = "Withdrawal amount exceeds available comp balance."
            return
        }
        if (method == "bank" && selectedFundingSource.value == null) {
            _error.value = "Please select a bank account for withdrawal."
            return
        }

        val toAddress: String = when (method) {
            "crypto" -> "" // server uses the registered wallet_address
            "bank"   -> selectedFundingSource.value?.id ?: ""
            else     -> ""
        }

        viewModelScope.launch {
            _isWithdrawing.value = true
            try {
                apiClient.withdraw(
                    amount = amount,
                    toAddress = toAddress.ifEmpty { null },
                    method = method
                )
                _successMessage.value = when (method) {
                    "crypto" -> "Withdrawal of \$${"%.2f".format(amount)} to your MetaMask wallet is processing."
                    "bank"   -> "ACH transfer of \$${"%.2f".format(amount)} to ${selectedFundingSource.value?.name ?: "your bank"} initiated. Allow 1–2 business days."
                    else     -> "Withdrawal submitted."
                }
                withdrawAmount.value = ""
                selectedFundingSource.value = null
                _showWithdrawSheet.value = false
                // Reload to reflect updated balance
                loadWalletDetail()
                loadTransactions()
            } catch (e: Exception) {
                _error.value = e.message ?: "Withdrawal failed. Please try again."
            } finally {
                _isWithdrawing.value = false
            }
        }
    }

    // ─── Link Bank Account ────────────────────────────────────────────────────
    // Stub — Plaid / Dwolla bank-linking flow comes in a future polish pass.

    fun linkBankAccount() {
        viewModelScope.launch {
            _isLinkingBank.value = true
            try {
                _successMessage.value = "Bank link flow coming soon"
                _showLinkBankSheet.value = false
            } finally {
                _isLinkingBank.value = false
            }
        }
    }

    // ─── Sheet Controls ───────────────────────────────────────────────────────

    fun openWithdrawSheet() {
        _showWithdrawSheet.value = true
    }

    fun closeWithdrawSheet() {
        _showWithdrawSheet.value = false
    }

    fun openLinkBankSheet() {
        _showLinkBankSheet.value = true
    }

    fun closeLinkBankSheet() {
        _showLinkBankSheet.value = false
    }

    // ─── Pending Comp Helpers ─────────────────────────────────────────────────

    fun addPendingComp(comp: CompEarned) {
        val current = _pendingComps.value.toMutableList()
        if (current.none { it.id == comp.id }) {
            current.add(comp)
            _pendingComps.value = current
        }
    }

    fun removePendingComp(compId: String) {
        _pendingComps.value = _pendingComps.value.filter { it.id != compId }
    }

    // ─── Clear State ──────────────────────────────────────────────────────────

    fun clearError() {
        _error.value = null
    }

    fun clearSuccessMessage() {
        _successMessage.value = null
    }
}
