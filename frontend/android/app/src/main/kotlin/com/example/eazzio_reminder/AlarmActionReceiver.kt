package com.example.eazzio_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val id = intent.getIntExtra("id", -1)
        Log.d("AlarmActionReceiver", "Action received: $action for ID $id")

        // Stop the alarm service first
        val stopIntent = Intent(context, AlarmService::class.java)
        context.stopService(stopIntent)

        if (action == "ACTION_SNOOZE" && id != -1) {
            val title = intent.getStringExtra("title") ?: ""
            val note = intent.getStringExtra("note") ?: ""
            val soundSetting = intent.getStringExtra("soundSetting") ?: "default"
            val reminderType = intent.getStringExtra("reminderType") ?: ""
            val phone = intent.getStringExtra("phone") ?: ""
            val message = intent.getStringExtra("message") ?: ""

            // Snooze by scheduling the alarm 5 minutes later
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val snoozeIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("id", id)
                putExtra("title", title)
                putExtra("note", note)
                putExtra("soundSetting", soundSetting)
                putExtra("reminderType", reminderType)
                putExtra("phone", phone)
                putExtra("message", message)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Snooze interval is 5 minutes (300,000 milliseconds)
            val triggerTime = System.currentTimeMillis() + 5 * 60 * 1000

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
            Log.d("AlarmActionReceiver", "Snoozed alarm ID $id for 5 minutes")
        }
    }
}
