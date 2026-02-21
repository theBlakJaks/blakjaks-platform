package com.blakjaks.app

import com.blakjaks.app.features.auth.AuthViewModel
import com.blakjaks.app.features.auth.ValidationError
import com.blakjaks.app.mock.MockApiClient
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.Calendar

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private lateinit var viewModel: AuthViewModel

    @Before
    fun setUp() {
        viewModel = AuthViewModel(apiClient = MockApiClient())
    }

    @Test
    fun `login fails with invalid email`() = runTest {
        viewModel.email.value = "notanemail"
        viewModel.password.value = "password123"
        viewModel.login {}
        assertEquals(ValidationError.InvalidEmail.message, viewModel.error.value?.message)
    }

    @Test
    fun `login fails with short password`() = runTest {
        viewModel.email.value = "test@example.com"
        viewModel.password.value = "short"
        viewModel.login {}
        assertEquals(ValidationError.WeakPassword.message, viewModel.error.value?.message)
    }

    @Test
    fun `signup fails with missing full name`() = runTest {
        viewModel.email.value = "test@example.com"
        viewModel.password.value = "password123"
        viewModel.fullName.value = ""
        viewModel.dateOfBirth.value = Calendar.getInstance().apply { add(Calendar.YEAR, -25) }.time
        viewModel.signup {}
        assertEquals(ValidationError.MissingFullName.message, viewModel.error.value?.message)
    }

    @Test
    fun `signup fails with age under 21`() = runTest {
        viewModel.email.value = "test@example.com"
        viewModel.password.value = "password123"
        viewModel.fullName.value = "Test User"
        viewModel.dateOfBirth.value = Calendar.getInstance().apply { add(Calendar.YEAR, -18) }.time
        viewModel.signup {}
        assertEquals(ValidationError.AgeRequirement.message, viewModel.error.value?.message)
    }

    @Test
    fun `isOldEnough returns true for age 21`() = runTest {
        viewModel.dateOfBirth.value = Calendar.getInstance().apply { add(Calendar.YEAR, -21) }.time
        assertTrue(viewModel.isOldEnough)
    }

    @Test
    fun `isOldEnough returns false for age 20`() = runTest {
        viewModel.dateOfBirth.value = Calendar.getInstance().apply { add(Calendar.YEAR, -20) }.time
        assertFalse(viewModel.isOldEnough)
    }

    @Test
    fun `clearError sets error to null`() = runTest {
        viewModel.email.value = ""
        viewModel.login {}
        assertNotNull(viewModel.error.value)
        viewModel.clearError()
        assertNull(viewModel.error.value)
    }

    @Test
    fun `login succeeds with valid credentials`() = runTest {
        var success = false
        viewModel.email.value = "test@example.com"
        viewModel.password.value = "password123"
        viewModel.login { success = true }
        // Give coroutine time to complete
        kotlinx.coroutines.delay(100)
        assertTrue(success)
        assertNull(viewModel.error.value)
    }
}
