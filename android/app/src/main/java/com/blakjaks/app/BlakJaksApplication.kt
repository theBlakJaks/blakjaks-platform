package com.blakjaks.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

class BlakJaksApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        startKoin {
            androidContext(this@BlakJaksApplication)
            modules(appModule)
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannels(listOf(
                NotificationChannel("social_messages", "Chat Messages", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "New messages in social channels"
                },
                NotificationChannel("comp_awards", "Comp Awards", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "New comp awards and milestones"
                },
                NotificationChannel("order_updates", "Order Updates", NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "Order status updates"
                },
                NotificationChannel("system", "System", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "System notifications"
                },
            ))
        }
    }
}
