package com.blakjaks.app.features.insights

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.network.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// ─── InsightsTab Enum ────────────────────────────────────────────────────────

enum class InsightsTab {
    OVERVIEW, TREASURY, SYSTEMS, COMPS, PARTNERS
}

// ─── InsightsViewModel ────────────────────────────────────────────────────────
// Manages all 5 Insights sub-pages. Loaded on demand via selectTab().
// Mirrors iOS InsightsViewModel.swift exactly — Koin DI (no Hilt).

class InsightsViewModel(
    private val apiClient: ApiClientInterface
) : ViewModel() {

    // ─── Data State ──────────────────────────────────────────────────────────

    private val _overview = MutableStateFlow<InsightsOverview?>(null)
    val overview: StateFlow<InsightsOverview?> = _overview.asStateFlow()

    private val _treasury = MutableStateFlow<InsightsTreasury?>(null)
    val treasury: StateFlow<InsightsTreasury?> = _treasury.asStateFlow()

    private val _systems = MutableStateFlow<InsightsSystems?>(null)
    val systems: StateFlow<InsightsSystems?> = _systems.asStateFlow()

    private val _comps = MutableStateFlow<InsightsComps?>(null)
    val comps: StateFlow<InsightsComps?> = _comps.asStateFlow()

    private val _partners = MutableStateFlow<InsightsPartners?>(null)
    val partners: StateFlow<InsightsPartners?> = _partners.asStateFlow()

    private val _activityFeed = MutableStateFlow<List<ActivityFeedItem>?>(null)
    val activityFeed: StateFlow<List<ActivityFeedItem>?> = _activityFeed.asStateFlow()

    // ─── Loading / Error ─────────────────────────────────────────────────────

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // ─── Tab Selection ───────────────────────────────────────────────────────

    val selectedTab = MutableStateFlow(InsightsTab.OVERVIEW)

    // ─── Init ────────────────────────────────────────────────────────────────

    init {
        loadOverview()
        loadActivityFeed()
    }

    // ─── Load Methods ────────────────────────────────────────────────────────

    fun loadOverview() {
        if (_overview.value != null) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _overview.value = apiClient.getInsightsOverview()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load overview"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadTreasury() {
        if (_treasury.value != null) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _treasury.value = apiClient.getInsightsTreasury()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load treasury"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadSystems() {
        if (_systems.value != null) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _systems.value = apiClient.getInsightsSystems()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load systems"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadComps() {
        if (_comps.value != null) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _comps.value = apiClient.getInsightsComps()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load comps"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadPartners() {
        if (_partners.value != null) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _partners.value = apiClient.getInsightsPartners()
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load partners"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadActivityFeed() {
        if (_activityFeed.value != null) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _activityFeed.value = apiClient.getInsightsFeed(limit = 20, offset = 0)
            } catch (e: Exception) {
                _error.value = e.message ?: "Failed to load activity feed"
            } finally {
                _isLoading.value = false
            }
        }
    }

    // ─── Tab / Navigation ────────────────────────────────────────────────────

    fun selectTab(tab: InsightsTab) {
        selectedTab.value = tab
        when (tab) {
            InsightsTab.OVERVIEW -> loadOverview()
            InsightsTab.TREASURY -> loadTreasury()
            InsightsTab.SYSTEMS  -> loadSystems()
            InsightsTab.COMPS    -> loadComps()
            InsightsTab.PARTNERS -> loadPartners()
        }
    }

    // ─── Refresh — clears all cached data and reloads current tab ────────────

    fun refresh() {
        _overview.value = null
        _treasury.value = null
        _systems.value = null
        _comps.value = null
        _partners.value = null
        _activityFeed.value = null
        loadOverview()
        loadActivityFeed()
    }

    fun clearError() {
        _error.value = null
    }
}
