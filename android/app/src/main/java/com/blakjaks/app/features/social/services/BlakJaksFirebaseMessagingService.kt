package com.blakjaks.app.features.social.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlin.random.Random

// ─── Notification Channel IDs ─────────────────────────────────────────────────

private const val CHANNEL_SOCIAL = "social_messages"
private const val CHANNEL_COMP = "comp_awards"
private const val CHANNEL_ORDER = "order_updates"
private const val CHANNEL_SYSTEM = "system"

private const val TAG = "FCM"

class BlakJaksFirebaseMessagingService : FirebaseMessagingService() {

    // ─── Token ────────────────────────────────────────────────────────────────

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // TODO: Enqueue a WorkManager OneTimeWorkRequest to send token to backend
        //       via ApiClient.updatePushToken once WorkManager dependency is wired.
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "New FCM token received (debug only)")
        }
    }

    // ─── Message Received ────────────────────────────────────────────────────

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        // Ensure notification channels exist (Android 8+)
        createNotificationChannels()

        val data = remoteMessage.data
        val type = data["type"] ?: ""

        val channelId = when (type) {
            "chat_message" -> CHANNEL_SOCIAL
            "comp_award" -> CHANNEL_COMP
            "order_update" -> CHANNEL_ORDER
            else -> CHANNEL_SYSTEM
        }

        // Title / body — prefer notification payload, fall back to data map
        val title = remoteMessage.notification?.title
            ?: data["title"]
            ?: defaultTitle(type)

        val body = remoteMessage.notification?.body
            ?: data["body"]
            ?: ""

        showNotification(channelId, title, body)
    }

    // ─── Notification Channel Setup ───────────────────────────────────────────

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channels = listOf(
            NotificationChannel(
                CHANNEL_SOCIAL,
                "Social Messages",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = "BlakJaks chat messages and mentions" },

            NotificationChannel(
                CHANNEL_COMP,
                "Comp Awards",
                NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Comp earned and milestone notifications" },

            NotificationChannel(
                CHANNEL_ORDER,
                "Order Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = "Order status and shipping updates" },

            NotificationChannel(
                CHANNEL_SYSTEM,
                "System",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "System and admin announcements" }
        )

        channels.forEach { manager.createNotificationChannel(it) }
    }

    // ─── Show Notification ────────────────────────────────────────────────────

    private fun showNotification(channelId: String, title: String, body: String) {
        val notificationId = Random.nextInt(1000, 99999)

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(
                when (channelId) {
                    CHANNEL_COMP -> NotificationCompat.PRIORITY_HIGH
                    CHANNEL_SYSTEM -> NotificationCompat.PRIORITY_LOW
                    else -> NotificationCompat.PRIORITY_DEFAULT
                }
            )
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(this).notify(notificationId, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS permission not granted — silently ignore
            Log.w(TAG, "POST_NOTIFICATIONS permission not granted; notification suppressed.")
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private fun defaultTitle(type: String): String = when (type) {
        "chat_message" -> "New Message"
        "comp_award" -> "Comp Earned!"
        "order_update" -> "Order Update"
        else -> "BlakJaks"
    }
}
