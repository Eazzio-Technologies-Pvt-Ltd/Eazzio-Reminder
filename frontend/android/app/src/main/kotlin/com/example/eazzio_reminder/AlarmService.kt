package com.example.eazzio_reminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private val NOTIFICATION_ID = 8888
    private val CHANNEL_ID = "eazzio_alarm_service_channel"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val id = intent.getIntExtra("id", -1)
        val title = intent.getStringExtra("title") ?: "Reminder"
        val note = intent.getStringExtra("note") ?: "Your reminder is due"
        val soundSetting = intent.getStringExtra("soundSetting") ?: "default"
        val reminderType = intent.getStringExtra("reminderType") ?: ""
        val phone = intent.getStringExtra("phone") ?: ""
        val message = intent.getStringExtra("message") ?: ""

        Log.d("AlarmService", "Starting AlarmService: id=$id, title=$title, sound=$soundSetting, reminderType=$reminderType")

        // 1. Create Notification Channel
        createNotificationChannel()

        // 2. Setup PendingIntents for Dismiss and Snooze Actions
        val dismissIntent = Intent(this, AlarmActionReceiver::class.java).apply {
            action = "ACTION_DISMISS"
            putExtra("id", id)
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this,
            id * 10 + 1,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val snoozeIntent = Intent(this, AlarmActionReceiver::class.java).apply {
            action = "ACTION_SNOOZE"
            putExtra("id", id)
            putExtra("title", title)
            putExtra("note", note)
            putExtra("soundSetting", soundSetting)
            putExtra("reminderType", reminderType)
            putExtra("phone", phone)
            putExtra("message", message)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            this,
            id * 10 + 2,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Build PendingIntent for FullScreen display
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("reminder_id", id)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            id * 10 + 3,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Build Notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(note)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", dismissPendingIntent)
            .addAction(android.R.drawable.ic_popup_sync, "Snooze (5m)", snoozePendingIntent)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // 4. Play looping sound in background
        if (reminderType.contains("ringtone")) {
            playAlarmSound(soundSetting)
        }

        // 5. Send SMS if configured & permission is granted
        if (reminderType.contains("sms") && phone.isNotEmpty() && message.isNotEmpty()) {
            sendBackgroundSms(phone, message)
        }

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Eazzio Alarm Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for eazzio reminder alarms with looping sound"
                setSound(null, null) // Sound is played manually by MediaPlayer for custom looping
                enableVibration(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun playAlarmSound(soundSetting: String) {
        // Stop any currently running playback
        stopAlarmSound()

        val soundUri: Uri = when (soundSetting) {
            "ringtone" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            "alarm" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            "default" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            else -> {
                try {
                    Uri.parse(soundSetting)
                } catch (e: Exception) {
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                }
            }
        } ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

        try {
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmService, soundUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
            Log.d("AlarmService", "Playing alarm sound: $soundUri")
        } catch (e: Exception) {
            Log.e("AlarmService", "Failed to play custom sound setting, playing default alarm sound: $e")
            try {
                mediaPlayer = MediaPlayer().apply {
                    setDataSource(this@AlarmService, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    isLooping = true
                    prepare()
                    start()
                }
            } catch (fallbackEx: Exception) {
                Log.e("AlarmService", "Failed to play default alarm sound: $fallbackEx")
            }
        }
    }

    private fun stopAlarmSound() {
        mediaPlayer?.let {
            if (it.isPlaying) {
                it.stop()
            }
            it.release()
        }
        mediaPlayer = null
    }

    private fun sendBackgroundSms(phone: String, message: String) {
        val hasPermission = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED

        if (hasPermission) {
            try {
                val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    this.getSystemService(SmsManager::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getDefault()
                }
                smsManager.sendTextMessage(phone, null, message, null, null)
                Log.d("AlarmService", "SMS sent successfully to $phone")
            } catch (e: Exception) {
                Log.e("AlarmService", "Failed to send background SMS: $e")
            }
        } else {
            Log.w("AlarmService", "SMS sending skipped: permission SEND_SMS is denied")
        }
    }

    override fun onDestroy() {
        Log.d("AlarmService", "Destroying AlarmService")
        stopAlarmSound()
        super.onDestroy()
    }
}
