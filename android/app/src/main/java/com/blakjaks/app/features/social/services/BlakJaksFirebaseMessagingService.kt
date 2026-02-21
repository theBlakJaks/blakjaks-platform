package com.blakjaks.app.features.social.services

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class BlakJaksFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // TODO (J6): Send token to backend via ApiClient.updatePushToken
        // viewModelScope is unavailable here — use WorkManager or a coroutine scope
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        // TODO (J6): Show local notification based on remoteMessage.notification and remoteMessage.data
        // Route to appropriate channel: social_messages, comp_awards, order_updates, system
    }
}
