package com.blakjaks.app

import com.blakjaks.app.core.network.ApiClient
import com.blakjaks.app.mock.MockApiClient
import com.blakjaks.app.core.storage.TokenManager
import com.blakjaks.app.core.storage.UserPreferences
import com.blakjaks.app.features.auth.AuthViewModel
import com.blakjaks.app.features.insights.InsightsViewModel
import com.blakjaks.app.features.scanwallet.ScanWalletViewModel
import com.blakjaks.app.features.scanwallet.WalletViewModel
import com.blakjaks.app.features.shop.CartViewModel
import com.blakjaks.app.features.shop.ShopViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.dsl.module

val appModule = module {
    // ─── Singletons ───────────────────────────────────────────────────────────
    single { TokenManager(androidContext()) }
    single { UserPreferences(androidContext()) }
    // In production: replace MockApiClient with ApiClient(get())
    single<com.blakjaks.app.core.network.ApiClientInterface> { MockApiClient() }

    // ─── ViewModels ───────────────────────────────────────────────────────────
    viewModel { AuthViewModel(get()) }
    viewModel { WalletViewModel(get()) }
    viewModel { ScanWalletViewModel(get()) }
    viewModel { InsightsViewModel(get()) }
    viewModel { ShopViewModel(get()) }
    viewModel { CartViewModel(get()) }
}
