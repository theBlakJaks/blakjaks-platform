package com.blakjaks.app.features.auth.screens

import android.app.DatePickerDialog
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.*
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.auth.AuthViewModel
import com.blakjaks.app.navigation.Screen
import java.text.SimpleDateFormat
import java.util.*

// MARK: - SignupScreen
// Mirrors iOS SignupView.swift: name, email, password, confirm password,
// DOB date picker (21+ gate), T&C checkbox. Submit disabled until all valid.

@Composable
fun SignupScreen(navController: NavController, authViewModel: AuthViewModel = viewModel()) {
    val context = LocalContext.current

    val fullName by authViewModel.fullName.collectAsState()
    val email by authViewModel.email.collectAsState()
    val password by authViewModel.password.collectAsState()
    val dateOfBirth by authViewModel.dateOfBirth.collectAsState()
    val isLoading by authViewModel.isLoading.collectAsState()
    val error by authViewModel.error.collectAsState()

    var confirmPassword by remember { mutableStateOf("") }
    var agreedToTerms by remember { mutableStateOf(false) }

    // Derived state
    val passwordsMatch = confirmPassword.isEmpty() || password == confirmPassword
    val canSubmit = agreedToTerms
        && password == confirmPassword
        && confirmPassword.isNotEmpty()
        && authViewModel.isOldEnough
        && !isLoading

    val dobFormatted = remember(dateOfBirth) {
        SimpleDateFormat("MMM dd, yyyy", Locale.US).format(dateOfBirth)
    }

    // Date picker dialog — max date = 21 years ago
    val calendar = Calendar.getInstance()
    val maxDateCalendar = Calendar.getInstance().apply { add(Calendar.YEAR, -21) }
    val datePickerDialog = DatePickerDialog(
        context,
        { _, year, month, day ->
            val newCal = Calendar.getInstance().apply { set(year, month, day) }
            authViewModel.dateOfBirth.value = newCal.time
        },
        Calendar.getInstance().apply { time = dateOfBirth }.get(Calendar.YEAR),
        Calendar.getInstance().apply { time = dateOfBirth }.get(Calendar.MONTH),
        Calendar.getInstance().apply { time = dateOfBirth }.get(Calendar.DAY_OF_MONTH)
    ).apply {
        datePicker.maxDate = maxDateCalendar.timeInMillis
    }

    // Error dialog
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
        Spacer(Modifier.height(Spacing.xl))

        Text("Create Account", style = MaterialTheme.typography.titleLarge, color = TextPrimary)
        Spacer(Modifier.height(Spacing.xs))
        Text("Join the BlakJaks community", style = MaterialTheme.typography.bodyMedium, color = TextSecondary)

        Spacer(Modifier.height(Spacing.xl))

        // Full Name field
        SignupFieldLabel("Full Name") {
            OutlinedTextField(
                value = fullName,
                onValueChange = { authViewModel.fullName.value = it },
                placeholder = { Text("First Last", color = TextDim) },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Next,
                    capitalization = KeyboardCapitalization.Words
                ),
                singleLine = true,
                colors = outlinedTextFieldColors()
            )
        }

        Spacer(Modifier.height(Spacing.md))

        // Email field
        SignupFieldLabel("Email") {
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
        SignupFieldLabel("Password") {
            OutlinedTextField(
                value = password,
                onValueChange = { authViewModel.password.value = it },
                placeholder = { Text("Minimum 8 characters", color = TextDim) },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Next
                ),
                singleLine = true,
                colors = outlinedTextFieldColors()
            )
        }

        Spacer(Modifier.height(Spacing.md))

        // Confirm Password field
        SignupFieldLabel("Confirm Password") {
            OutlinedTextField(
                value = confirmPassword,
                onValueChange = { confirmPassword = it },
                placeholder = { Text("Re-enter password", color = TextDim) },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done
                ),
                singleLine = true,
                isError = !passwordsMatch,
                colors = outlinedTextFieldColors()
            )
        }

        // Password mismatch warning
        if (!passwordsMatch) {
            Spacer(Modifier.height(Spacing.xs))
            Text(
                text = "Passwords do not match.",
                color = Failure,
                style = MaterialTheme.typography.labelSmall,
                modifier = Modifier.fillMaxWidth()
            )
        }

        Spacer(Modifier.height(Spacing.md))

        // Date of Birth picker
        SignupFieldLabel("Date of Birth") {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BorderColor, RoundedCornerShape(Layout.buttonCornerRadius))
                    .clickable { datePickerDialog.show() }
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(dobFormatted, color = TextPrimary, style = MaterialTheme.typography.bodyLarge)
                Icon(
                    imageVector = Icons.Default.CalendarMonth,
                    contentDescription = "Select date",
                    tint = Gold
                )
            }
        }

        // Under-age warning
        if (!authViewModel.isOldEnough) {
            Spacer(Modifier.height(Spacing.xs))
            Text(
                text = "You must be 21 or older to create an account.",
                color = Failure,
                style = MaterialTheme.typography.labelSmall,
                modifier = Modifier.fillMaxWidth()
            )
        }

        Spacer(Modifier.height(Spacing.md))

        // Terms & Conditions checkbox
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
            verticalAlignment = Alignment.Top
        ) {
            IconButton(
                onClick = { agreedToTerms = !agreedToTerms },
                modifier = Modifier.size(28.dp)
            ) {
                Icon(
                    imageVector = if (agreedToTerms) Icons.Default.CheckBox else Icons.Default.CheckBoxOutlineBlank,
                    contentDescription = "Agree to terms",
                    tint = if (agreedToTerms) Gold else TextSecondary
                )
            }
            Text(
                text = "I agree to the Terms of Service and Privacy Policy. I confirm I am 21 or older.",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(Modifier.height(Spacing.xl))

        // Create Account button
        GoldButton(
            text = "Create Account",
            isLoading = isLoading,
            isEnabled = canSubmit,
            onClick = {
                authViewModel.signup {
                    navController.navigate(Screen.Biometric.route) {
                        popUpTo(Screen.Welcome.route) { inclusive = false }
                    }
                }
            }
        )

        Spacer(Modifier.height(Spacing.sm))
        TextButton(onClick = { navController.popBackStack() }) {
            Text("Already have an account? Sign In", color = TextSecondary)
        }
        Spacer(Modifier.height(Spacing.lg))
    }
}

@Composable
private fun SignupFieldLabel(label: String, content: @Composable () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary
        )
        Spacer(Modifier.height(Spacing.xs))
        content()
    }
}
