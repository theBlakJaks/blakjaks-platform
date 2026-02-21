package com.blakjaks.app.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.*
import com.blakjaks.app.core.theme.Gold
import com.blakjaks.app.core.theme.TextDim
import com.blakjaks.app.features.auth.screens.*
import com.blakjaks.app.features.insights.screens.InsightsMenuScreen
import com.blakjaks.app.features.scanwallet.screens.ScanWalletScreen
import com.blakjaks.app.features.shop.screens.ShopScreen
import com.blakjaks.app.features.social.screens.SocialHubScreen
import com.blakjaks.app.features.profile.screens.ProfileScreen

sealed class Screen(val route: String) {
    object Welcome : Screen("welcome")
    object Login : Screen("login")
    object Signup : Screen("signup")
    object AgeGate : Screen("age_gate")
    object Biometric : Screen("biometric")
    // Main tabs
    object Insights : Screen("insights")
    object Shop : Screen("shop")
    object ScanWallet : Screen("scan_wallet")
    object Social : Screen("social")
    object Profile : Screen("profile")
}

@Composable
fun BlakJaksNavHost(isLoggedIn: Boolean) {
    val navController = rememberNavController()

    if (!isLoggedIn) {
        // Auth graph
        NavHost(navController = navController, startDestination = Screen.Welcome.route) {
            composable(Screen.Welcome.route) {
                WelcomeScreen(navController = navController)
            }
            composable(Screen.Login.route) {
                LoginScreen(navController = navController)
            }
            composable(Screen.Signup.route) {
                SignupScreen(navController = navController)
            }
            composable(Screen.AgeGate.route) {
                AgeGateScreen(navController = navController)
            }
            composable(Screen.Biometric.route) {
                BiometricScreen(navController = navController)
            }
        }
    } else {
        // Main graph with bottom nav
        MainScaffold()
    }
}

@Composable
fun MainScaffold() {
    val navController = rememberNavController()
    val tabs = listOf(
        Triple(Screen.Insights.route, Icons.Default.BarChart, "Insights"),
        Triple(Screen.Shop.route, Icons.Default.ShoppingBag, "Shop"),
        Triple(Screen.ScanWallet.route, Icons.Default.QrCodeScanner, ""),
        Triple(Screen.Social.route, Icons.Default.Forum, "Social"),
        Triple(Screen.Profile.route, Icons.Default.Person, "Profile"),
    )
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            Box {
                NavigationBar(containerColor = com.blakjaks.app.core.theme.BackgroundCard) {
                    tabs.forEachIndexed { i, (route, icon, label) ->
                        if (i == 2) {
                            // Spacer for center FAB
                            NavigationBarItem(selected = false, onClick = {}, icon = {}, label = {}, enabled = false)
                        } else {
                            NavigationBarItem(
                                selected = currentRoute == route,
                                onClick = {
                                    navController.navigate(route) {
                                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                },
                                icon = { Icon(imageVector = icon, contentDescription = label) },
                                label = { Text(label) },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = Gold,
                                    selectedTextColor = Gold,
                                    indicatorColor = Gold.copy(alpha = 0.15f),
                                    unselectedIconColor = TextDim,
                                    unselectedTextColor = TextDim
                                )
                            )
                        }
                    }
                }
                // Center gold FAB
                FloatingActionButton(
                    onClick = {
                        navController.navigate(Screen.ScanWallet.route) {
                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true
                        }
                    },
                    containerColor = Gold,
                    contentColor = Color.Black,
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .offset(y = (-20).dp)
                        .size(60.dp)
                ) {
                    Icon(imageVector = Icons.Default.QrCodeScanner, contentDescription = "Scan")
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Insights.route,
            modifier = Modifier.padding(paddingValues)
        ) {
            composable(Screen.Insights.route) { InsightsMenuScreen(navController) }
            composable(Screen.Shop.route) { ShopScreen(navController) }
            composable(Screen.ScanWallet.route) { ScanWalletScreen(navController) }
            composable(Screen.Social.route) { SocialHubScreen(navController) }
            composable(Screen.Profile.route) { ProfileScreen(navController) }
        }
    }
}
