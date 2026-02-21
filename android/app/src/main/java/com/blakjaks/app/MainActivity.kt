package com.blakjaks.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.blakjaks.app.core.storage.TokenManager
import com.blakjaks.app.core.theme.BlakJaksTheme
import com.blakjaks.app.navigation.BlakJaksNavHost
import org.koin.android.ext.android.inject

class MainActivity : ComponentActivity() {
    private val tokenManager: TokenManager by inject()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BlakJaksTheme {
                BlakJaksNavHost(isLoggedIn = tokenManager.hasCredentials())
            }
        }
    }
}
