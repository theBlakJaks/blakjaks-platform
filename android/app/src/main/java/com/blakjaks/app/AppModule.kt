package com.blakjaks.app

import com.blakjaks.app.core.network.ApiClient
import com.blakjaks.app.core.network.MockApiClient
import com.blakjaks.app.core.storage.TokenManager
import com.blakjaks.app.core.storage.UserPreferences
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module

val appModule = module {
    single { TokenManager(androidContext()) }
    single { UserPreferences(androidContext()) }
    // In production: replace MockApiClient with ApiClient(get())
    single<com.blakjaks.app.core.network.ApiClientInterface> { MockApiClient() }
}
