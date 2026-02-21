package com.blakjaks.app.features.auth

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.blakjaks.app.core.network.ApiClientInterface
import com.blakjaks.app.core.storage.TokenManager
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class AuthViewModel(
    private val apiClient: ApiClientInterface = MockApiClient(),
    private val tokenManager: TokenManager? = null
) : ViewModel() {

    // Input state
    var email = MutableStateFlow("")
    var password = MutableStateFlow("")
    var fullName = MutableStateFlow("")
    var dateOfBirth = MutableStateFlow(
        Calendar.getInstance().apply { add(Calendar.YEAR, -21) }.time
    )

    // UI state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<ValidationError?>(null)
    val error: StateFlow<ValidationError?> = _error.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(tokenManager?.hasCredentials() ?: false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    fun login(onSuccess: () -> Unit) {
        if (!validate(signup = false)) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                apiClient.login(email.value, password.value)
                _isLoggedIn.value = true
                onSuccess()
            } catch (e: Exception) {
                _error.value = ValidationError.NetworkError(e.message ?: "Login failed")
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun signup(onSuccess: () -> Unit) {
        if (!validate(signup = true)) return
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val dobString = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(dateOfBirth.value)
                apiClient.signup(email.value, password.value, fullName.value, dobString)
                _isLoggedIn.value = true
                onSuccess()
            } catch (e: Exception) {
                _error.value = ValidationError.NetworkError(e.message ?: "Signup failed")
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun logout(onComplete: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            try { apiClient.logout() } catch (_: Exception) {}
            tokenManager?.clearAll()
            _isLoggedIn.value = false
            _isLoading.value = false
            onComplete()
        }
    }

    fun loginWithBiometrics(activity: FragmentActivity, onSuccess: () -> Unit) {
        val biometricManager = BiometricManager.from(activity)
        if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)
            != BiometricManager.BIOMETRIC_SUCCESS) {
            _error.value = ValidationError.NetworkError("Biometrics not available")
            return
        }
        val prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    if (tokenManager?.hasCredentials() == true) {
                        _isLoggedIn.value = true
                        onSuccess()
                    }
                }
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    _error.value = ValidationError.NetworkError(errString.toString())
                }
            })
        prompt.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Sign in to BlakJaks")
                .setSubtitle("Use biometrics to authenticate")
                .setNegativeButtonText("Cancel")
                .build()
        )
    }

    val isOldEnough: Boolean
        get() {
            val dob = dateOfBirth.value
            val today = Calendar.getInstance()
            val birth = Calendar.getInstance().apply { time = dob }
            var age = today.get(Calendar.YEAR) - birth.get(Calendar.YEAR)
            if (today.get(Calendar.DAY_OF_YEAR) < birth.get(Calendar.DAY_OF_YEAR)) age--
            return age >= 21
        }

    private fun validate(signup: Boolean): Boolean {
        val e = email.value
        val p = password.value
        if (e.isEmpty() || !e.contains("@")) { _error.value = ValidationError.InvalidEmail; return false }
        if (p.length < 8) { _error.value = ValidationError.WeakPassword; return false }
        if (signup) {
            if (fullName.value.isBlank()) { _error.value = ValidationError.MissingFullName; return false }
            if (!isOldEnough) { _error.value = ValidationError.AgeRequirement; return false }
        }
        return true
    }

    fun clearError() { _error.value = null }
}

sealed class ValidationError(val message: String) {
    object InvalidEmail : ValidationError("Please enter a valid email address.")
    object WeakPassword : ValidationError("Password must be at least 8 characters.")
    object MissingFullName : ValidationError("Please enter your full name.")
    object AgeRequirement : ValidationError("You must be 21 or older to create an account.")
    class NetworkError(msg: String) : ValidationError(msg)
}
