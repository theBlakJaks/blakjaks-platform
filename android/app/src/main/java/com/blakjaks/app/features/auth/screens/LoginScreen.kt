package com.blakjaks.app.features.auth.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.text.input.*
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.SecondaryButton
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.auth.AuthViewModel
import com.blakjaks.app.features.auth.ValidationError
import com.blakjaks.app.navigation.Screen

@Composable
fun LoginScreen(navController: NavController, authViewModel: AuthViewModel = viewModel()) {
    val email by authViewModel.email.collectAsState()
    val password by authViewModel.password.collectAsState()
    val isLoading by authViewModel.isLoading.collectAsState()
    val error by authViewModel.error.collectAsState()

    if (error != null) {
        AlertDialog(
            onDismissRequest = { authViewModel.clearError() },
            title = { Text("Error") },
            text = { Text(error!!.message) },
            confirmButton = {
                TextButton(onClick = { authViewModel.clearError() }) {
                    Text("OK", color = Gold)
                }
            },
            containerColor = BackgroundCard,
            titleContentColor = TextPrimary,
            textContentColor = TextSecondary
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
            .verticalScroll(rememberScrollState())
            .padding(Layout.screenMargin),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(Spacing.xxl))

        Text("BlakJaks", style = MaterialTheme.typography.displayLarge, color = Gold)
        Spacer(Modifier.height(Spacing.sm))
        Text("Welcome Back", style = MaterialTheme.typography.titleLarge, color = TextPrimary)
        Text("Sign in to your account", style = MaterialTheme.typography.bodyMedium, color = TextSecondary)

        Spacer(Modifier.height(Spacing.xl))

        // Email field
        Column(modifier = Modifier.fillMaxWidth()) {
            Text("Email", style = MaterialTheme.typography.bodyMedium, color = TextSecondary)
            Spacer(Modifier.height(Spacing.xs))
            OutlinedTextField(
                value = email,
                onValueChange = { authViewModel.email.value = it },
                placeholder = { Text("you@example.com", color = TextDim) },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next
                ),
                singleLine = true,
                colors = outlinedTextFieldColors()
            )
        }

        Spacer(Modifier.height(Spacing.md))

        // Password field
        Column(modifier = Modifier.fillMaxWidth()) {
            Text("Password", style = MaterialTheme.typography.bodyMedium, color = TextSecondary)
            Spacer(Modifier.height(Spacing.xs))
            OutlinedTextField(
                value = password,
                onValueChange = { authViewModel.password.value = it },
                placeholder = { Text("Minimum 8 characters", color = TextDim) },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done
                ),
                singleLine = true,
                colors = outlinedTextFieldColors()
            )
        }

        // Forgot password
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            TextButton(onClick = { /* TODO: forgot password */ }) {
                Text("Forgot Password?", color = Gold, style = MaterialTheme.typography.labelSmall)
            }
        }

        Spacer(Modifier.height(Spacing.xl))

        GoldButton(text = "Sign In", isLoading = isLoading) {
            authViewModel.login {
                navController.navigate(Screen.Insights.route) { popUpTo(0) }
            }
        }

        Spacer(Modifier.height(Spacing.md))

        // Divider
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
        ) {
            HorizontalDivider(modifier = Modifier.weight(1f), color = BorderColor)
            Text("or", style = MaterialTheme.typography.bodyMedium, color = TextDim)
            HorizontalDivider(modifier = Modifier.weight(1f), color = BorderColor)
        }

        Spacer(Modifier.height(Spacing.md))

        SecondaryButton(text = "Sign in with Biometrics") {
            // Biometric login requires FragmentActivity — wired up in BiometricScreen
        }

        Spacer(Modifier.height(Spacing.sm))
        TextButton(onClick = { navController.navigate(Screen.Signup.route) }) {
            Text("Don't have an account? Sign Up", color = TextSecondary)
        }
        Spacer(Modifier.height(Spacing.lg))
    }
}

@Composable
fun outlinedTextFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = Gold,
    unfocusedBorderColor = BorderColor,
    focusedLabelColor = Gold,
    unfocusedLabelColor = TextSecondary,
    cursorColor = Gold,
    focusedTextColor = TextPrimary,
    unfocusedTextColor = TextPrimary
)
