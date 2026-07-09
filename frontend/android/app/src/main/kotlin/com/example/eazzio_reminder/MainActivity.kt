package com.example.eazzio_reminder

import android.Manifest
import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.telephony.SmsManager
import android.text.TextUtils
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.eazzio_reminder/native_send"
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val SMS_PERMISSION_CODE = 101
    
    private val RINGTONE_PICKER_REQUEST_CODE = 999
    private var pendingRingtoneResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRingtone" -> {
                    pendingRingtoneResult = result
                    try {
                        val intent = Intent(android.media.RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_TYPE, android.media.RingtoneManager.TYPE_NOTIFICATION or android.media.RingtoneManager.TYPE_RINGTONE)
                            putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Reminder Sound")
                            putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(android.media.RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)
                        }
                        startActivityForResult(intent, RINGTONE_PICKER_REQUEST_CODE)
                    } catch (e: Exception) {
                        result.error("PICKER_ERROR", e.message, null)
                        pendingRingtoneResult = null
                    }
                }
                "hasSmsPermission" -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.SEND_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                }
                "requestSmsPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.SEND_SMS),
                            SMS_PERMISSION_CODE
                        )
                    }
                }
                "sendSMS" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    if (phone != null && message != null) {
                        val sent = sendDirectSMS(phone, message)
                        if (sent) {
                            result.success(true)
                        } else {
                            result.error("SMS_FAILED", "Failed to send SMS programmatically", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone or message is null", null)
                    }
                }
                "isAccessibilityServiceEnabled" -> {
                    val enabled = isAccessibilityServiceEnabled(this, WhatsAppAccessibilityService::class.java)
                    result.success(enabled)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "markWhatsAppAutoSendPending" -> {
                    AutoSendTracker.setPending()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendDirectSMS(phone: String, message: String): Boolean {
        return try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                this.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            smsManager.sendTextMessage(phone, null, message, null, null)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context, serviceClass: Class<out AccessibilityService>): Boolean {
        val expectedComponentName = ComponentName(context, serviceClass)
        val enabledServicesSetting = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RINGTONE_PICKER_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                @Suppress("DEPRECATION")
                val uri = data.getParcelableExtra<android.net.Uri>(android.media.RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                if (uri != null) {
                    pendingRingtoneResult?.success(uri.toString())
                } else {
                    pendingRingtoneResult?.success("default")
                }
            } else {
                pendingRingtoneResult?.success("default")
            }
            pendingRingtoneResult = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
