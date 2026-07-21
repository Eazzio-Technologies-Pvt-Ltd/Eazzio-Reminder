package com.example.eazzio_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("BootReceiver", "Received boot action: $action")

        if (Intent.ACTION_BOOT_COMPLETED == action ||
            Intent.ACTION_MY_PACKAGE_REPLACED == action ||
            "android.intent.action.QUICKBOOT_POWERON" == action ||
            "com.htc.intent.action.QUICKBOOT_POWERON" == action
        ) {
            rescheduleAllAlarms(context)
        }
    }

    private fun rescheduleAllAlarms(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val remindersSet = prefs.getStringSet("flutter.local_reminders", null) ?: return
            Log.d("BootReceiver", "Found ${remindersSet.size} local reminders in SharedPreferences")

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
            val now = System.currentTimeMillis()

            for (jsonStr in remindersSet) {
                try {
                    val obj = JSONObject(jsonStr)
                    val id = obj.optInt("id", -1)
                    val status = obj.optString("status", "")

                    if (id == -1 || status != "scheduled") continue

                    val dateStr = obj.optString("remind_date", "")
                    val timeStr = obj.optString("remind_time", "")
                    if (dateStr.isEmpty() || timeStr.isEmpty()) continue

                    val date = sdf.parse("$dateStr $timeStr") ?: continue
                    val scheduledMillis = date.time

                    if (scheduledMillis <= now) {
                        Log.d("BootReceiver", "Skipping past reminder ID $id ($dateStr $timeStr)")
                        continue
                    }

                    val title = obj.optString("title", "Reminder")
                    val messageTemplate = obj.optString("message_template", "")
                    val recipientName = obj.optString("recipient_name", "")
                    val note = if (messageTemplate.isNotEmpty()) messageTemplate else "Reminder for $recipientName is due."
                    val soundSetting = obj.optString("notification_sound", "default")
                    val reminderType = obj.optString("reminder_type", "")

                    var phone = ""
                    val recipientPhone = obj.optString("recipient_phone", "")
                    if (recipientPhone.startsWith("{") && recipientPhone.endsWith("}")) {
                        try {
                            val phoneJson = JSONObject(recipientPhone)
                            phone = phoneJson.optString("sms", "")
                        } catch (_: Exception) {}
                    } else {
                        phone = recipientPhone
                    }

                    val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("note", note)
                        putExtra("soundSetting", soundSetting)
                        putExtra("reminderType", reminderType)
                        putExtra("phone", phone)
                        putExtra("message", messageTemplate)
                    }

                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        id,
                        alarmIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val alarmClockInfo = AlarmManager.AlarmClockInfo(scheduledMillis, pendingIntent)
                        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    } else {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, scheduledMillis, pendingIntent)
                    }

                    Log.d("BootReceiver", "Successfully rescheduled alarm ID $id for $dateStr $timeStr ($scheduledMillis)")
                } catch (e: Exception) {
                    Log.e("BootReceiver", "Error parsing reminder JSON item: $e")
                }
            }
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error rescheduling alarms on boot: $e")
        }
    }
}
