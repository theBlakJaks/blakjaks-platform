package com.blakjaks.app.core.storage

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_prefs")

class UserPreferences(private val context: Context) {

    companion object {
        val BIOMETRIC_ENABLED = booleanPreferencesKey("biometric_enabled")
        val LANGUAGE = stringPreferencesKey("language")
        val AGE_VERIFIED = booleanPreferencesKey("age_verified")
        val BIOMETRIC_ENROLLED = booleanPreferencesKey("biometric_enrolled")
    }

    val isBiometricEnabled: Flow<Boolean> = context.dataStore.data.map { it[BIOMETRIC_ENABLED] ?: false }
    val language: Flow<String> = context.dataStore.data.map { it[LANGUAGE] ?: "en" }
    val isAgeVerified: Flow<Boolean> = context.dataStore.data.map { it[AGE_VERIFIED] ?: false }
    val isBiometricEnrolled: Flow<Boolean> = context.dataStore.data.map { it[BIOMETRIC_ENROLLED] ?: false }

    suspend fun setBiometricEnabled(enabled: Boolean) = context.dataStore.edit { it[BIOMETRIC_ENABLED] = enabled }
    suspend fun setLanguage(lang: String) = context.dataStore.edit { it[LANGUAGE] = lang }
    suspend fun setAgeVerified(verified: Boolean) = context.dataStore.edit { it[AGE_VERIFIED] = verified }
    suspend fun setBiometricEnrolled(enrolled: Boolean) = context.dataStore.edit { it[BIOMETRIC_ENROLLED] = enrolled }
}
