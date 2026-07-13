import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reminder.dart';
import 'notification_service.dart';
import 'native_service.dart';

class LocalStorageService {
  static const String keyAppMode = 'app_mode';
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyThemeMode = 'theme_mode';
  static const String keyReminders = 'local_reminders';
  static const String keyLogs = 'local_logs';
  static const String keyLastId = 'local_last_id';

  // Settings operations
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyThemeMode) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyThemeMode, mode);
  }

  Future<String> getAppMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAppMode) ?? 'server';
  }

  Future<void> setAppMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAppMode, mode);
  }

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyApiBaseUrl) ?? 'https://eazzio-reminder.onrender.com/api';
  }

  Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyApiBaseUrl, url);
  }

  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhone = 'user_phone';
  static const String keyDefaultCountryCode = 'default_country_code';

  // Templates
  Future<String?> getTemplate(String eventType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('template_$eventType');
  }

  Future<void> setTemplate(String eventType, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('template_$eventType', value);
  }

  // Sounds
  Future<String> getNotificationSoundSetting(String eventType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sound_$eventType') ?? 'default';
  }

  Future<void> setNotificationSoundSetting(String eventType, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sound_$eventType', value);
  }

  // Country Code
  Future<String> getDefaultCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultCountryCode) ?? '+91';
  }

  Future<void> setDefaultCountryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDefaultCountryCode, code);
  }

  // Auth getters/setters
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(keyUserId);
    if (id == null) return null;
    return {
      'id': id,
      'name': prefs.getString(keyUserName) ?? '',
      'email': prefs.getString(keyUserEmail),
      'phone': prefs.getString(keyUserPhone),
    };
  }

  Future<void> setUserProfile(int id, String name, String? email, String? phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyUserId, id);
    await prefs.setString(keyUserName, name);
    if (email != null) await prefs.setString(keyUserEmail, email);
    else await prefs.remove(keyUserEmail);
    if (phone != null) await prefs.setString(keyUserPhone, phone);
    else await prefs.remove(keyUserPhone);
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserPhone);
  }

  // Standalone device sending settings
  // Twilio settings removed in favor of device SIM & WhatsApp

  // Reminders Local CRUD
  Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> remindersJson = prefs.getStringList(keyReminders) ?? [];
    
    final list = remindersJson.map((jsonStr) {
      return Reminder.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
    
    // Sort by date and time
    list.sort((a, b) {
      final dateCompare = a.remindDate.compareTo(b.remindDate);
      if (dateCompare != 0) return dateCompare;
      return a.remindTime.compareTo(b.remindTime);
    });
    
    return list;
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Reminder> list = await getReminders();
    
    final int nextId = (prefs.getInt(keyLastId) ?? 0) + 1;
    await prefs.setInt(keyLastId, nextId);
    
    final newReminder = reminder.copyWith(
      id: nextId,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    
    list.add(newReminder);
    await _saveRemindersList(prefs, list);
    return newReminder;
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    if (reminder.id == null) throw Exception('Reminder ID is required for update');
    final prefs = await SharedPreferences.getInstance();
    final List<Reminder> list = await getReminders();
    
    final index = list.indexWhere((r) => r.id == reminder.id);
    if (index == -1) throw Exception('Reminder not found');
    
    list[index] = reminder;
    await _saveRemindersList(prefs, list);
    return reminder;
  }

  Future<void> deleteReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Reminder> list = await getReminders();
    list.removeWhere((r) => r.id == id);
    await _saveRemindersList(prefs, list);
  }

  Future<void> _saveRemindersList(SharedPreferences prefs, List<Reminder> list) async {
    final List<String> jsonList = list.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(keyReminders, jsonList);
  }

  // Logs Local CR
  Future<List<ReminderLog>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> logsJson = prefs.getStringList(keyLogs) ?? [];
    
    final list = logsJson.map((jsonStr) {
      return ReminderLog.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
    
    // Sort descending by sentAt
    list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return list;
  }

  Future<void> createLog(ReminderLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ReminderLog> list = await getHistory();
    
    final logWithId = ReminderLog(
      id: DateTime.now().millisecondsSinceEpoch,
      reminderId: log.reminderId,
      recipientName: log.recipientName,
      recipientPhone: log.recipientPhone,
      reminderType: log.reminderType,
      eventType: log.eventType,
      status: log.status,
      details: log.details,
      sentAt: log.sentAt,
    );
    
    list.add(logWithId);
    
    final List<String> jsonList = list.map((l) => jsonEncode({
      'id': l.id,
      'reminder_id': l.reminderId,
      'recipient_name': l.recipientName,
      'recipient_phone': l.recipientPhone,
      'reminder_type': l.reminderType,
      'event_type': l.eventType,
      'status': l.status,
      'details': l.details,
      'sent_at': l.sentAt,
    })).toList();
    
    await prefs.setStringList(keyLogs, jsonList);
  }

  // Device Direct Dispatcher
  Future<Map<String, dynamic>> sendReminder(Reminder reminder) async {
    final phone = reminder.recipientPhone;
    final message = reminder.messageTemplate;

    try {
      bool launched = false;
      String details = '';

      if (reminder.reminderType == 'notification') {
        launched = true;
        details = 'Dispatched system notification successfully (Notification Only)';
      } else if (reminder.reminderType == 'sms') {
        // Send via SIM SMS
        final bool hasPermission = await NativeService.hasSmsPermission();
        if (hasPermission) {
          final bool success = await NativeService.sendDirectSMS(phone, message);
          if (success) {
            launched = true;
            details = 'Automatically sent background SMS directly to $phone';
          }
        }

        if (!launched) {
          final String encodedMsg = Uri.encodeComponent(message);
          final Uri smsUri = Uri.parse('sms:$phone?body=$encodedMsg');
          
          try {
            launched = await launchUrl(smsUri);
          } catch (e) {
            print('[LocalStorageService] Launch SMS failed, trying fallback: $e');
          }

          if (!launched) {
            if (await canLaunchUrl(smsUri)) {
              launched = await launchUrl(smsUri);
            }
          }

          if (!launched) {
            throw Exception('Could not launch SMS app intent');
          }

          details = 'Launched Device SMS (SIM) to $phone';
        }
      } else if (reminder.reminderType == 'call') {
        // Direct Phone Call
        final Uri callUri = Uri.parse('tel:$phone');
        try {
          launched = await launchUrl(callUri);
        } catch (e) {
          print('[LocalStorageService] Launch Call failed, trying fallback: $e');
        }

        if (!launched) {
          if (await canLaunchUrl(callUri)) {
            launched = await launchUrl(callUri);
          }
        }

        if (!launched) {
          throw Exception('Could not launch Dialer app intent');
        }

        details = 'Launched direct phone call to $phone';
      } else {
        // Send via WhatsApp
        // Clean phone number (keep only digits)
        final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
        final String encodedMsg = Uri.encodeComponent(message);
        final Uri waUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');
        
        final bool accEnabled = await NativeService.isAccessibilityServiceEnabled();
        if (accEnabled) {
          await NativeService.markWhatsAppAutoSendPending();
        }

        try {
          launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('[LocalStorageService] Launch WhatsApp failed, trying fallback: $e');
        }

        if (!launched) {
          if (await canLaunchUrl(waUri)) {
            launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
          }
        }

        if (!launched) {
          throw Exception('Could not launch WhatsApp intent');
        }

        if (accEnabled) {
          details = 'Automatically sent WhatsApp (via Accessibility Auto-Click) to $phone';
        } else {
          details = 'Launched WhatsApp Chat to $phone';
        }
      }

      // Update status to sent and write to logs
      final sentReminder = reminder.copyWith(status: 'sent');
      await updateReminder(sentReminder);
      
      await createLog(ReminderLog(
        id: 0,
        reminderId: reminder.id,
        recipientName: reminder.recipientName,
        recipientPhone: reminder.recipientPhone,
        reminderType: reminder.reminderType,
        eventType: reminder.eventType,
        status: 'sent',
        details: details,
        sentAt: DateTime.now().toUtc().toIso8601String(),
      ));

      // Show confirmation notification in the notification bar
      if (reminder.reminderType != 'notification') {
        String notifTitle = '';
        String notifBody = '';
        if (reminder.reminderType == 'sms') {
          notifTitle = 'SMS Dispatched';
          notifBody = 'SMS to ${reminder.recipientName} (${reminder.recipientPhone}) has been launched.';
        } else if (reminder.reminderType == 'call') {
          notifTitle = 'Call Initiated';
          notifBody = 'Call to ${reminder.recipientName} (${reminder.recipientPhone}) has been started.';
        } else if (reminder.reminderType == 'whatsapp') {
          notifTitle = 'WhatsApp Dispatched';
          notifBody = 'WhatsApp message to ${reminder.recipientName} has been opened.';
        }

        try {
          await NotificationService().showImmediateNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: notifTitle,
            body: notifBody,
            notificationSound: reminder.notificationSound,
          );
        } catch (ne) {
          print('[LocalStorageService] Failed to show dispatch notification: $ne');
        }
      }

      return {'success': true, 'details': details};
    } catch (e) {
      final errorMsg = 'Failed to dispatch: ${e.toString()}';
      await updateReminder(reminder.copyWith(status: 'failed'));
      await createLog(ReminderLog(
        id: 0,
        reminderId: reminder.id,
        recipientName: reminder.recipientName,
        recipientPhone: reminder.recipientPhone,
        reminderType: reminder.reminderType,
        eventType: reminder.eventType,
        status: 'failed',
        details: errorMsg,
        sentAt: DateTime.now().toUtc().toIso8601String(),
      ));

      // Show failure notification in the notification bar
      try {
        await NotificationService().showImmediateNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Dispatch Failed',
          body: 'Failed to send ${reminder.reminderType.toUpperCase()} reminder to ${reminder.recipientName}.',
          notificationSound: reminder.notificationSound,
        );
      } catch (ne) {
        print('[LocalStorageService] Failed to show failure notification: $ne');
      }

      return {'success': false, 'error': errorMsg};
    }
  }
}
