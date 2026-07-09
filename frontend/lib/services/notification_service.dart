import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Timezone database
    tz.initializeTimeZones();
    _setupLocalTimeZone();

    // Android Initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/Darwin Initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
    debugPrint('[NotificationService] Local Notifications Initialized');
  }

  void _setupLocalTimeZone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetMinutes = offset.inMinutes;

      // 1. Try mapping by common offsets to standard IANA timezone names
      String? ianaName;
      switch (offsetMinutes) {
        case 0:
          ianaName = 'UTC';
          break;
        case 60:
          ianaName = 'Europe/Paris';
          break;
        case 120:
          ianaName = 'Europe/Cairo';
          break;
        case 180:
          ianaName = 'Europe/Moscow';
          break;
        case 240:
          ianaName = 'Asia/Dubai';
          break;
        case 300:
          ianaName = 'Asia/Karachi';
          break;
        case 330:
          ianaName = 'Asia/Kolkata';
          break;
        case 345:
          ianaName = 'Asia/Kathmandu';
          break;
        case 360:
          ianaName = 'Asia/Dhaka';
          break;
        case 420:
          ianaName = 'Asia/Bangkok';
          break;
        case 480:
          ianaName = 'Asia/Singapore';
          break;
        case 540:
          ianaName = 'Asia/Tokyo';
          break;
        case 570:
          ianaName = 'Australia/Adelaide';
          break;
        case 600:
          ianaName = 'Australia/Sydney';
          break;
        case -60:
          ianaName = 'Atlantic/Azores';
          break;
        case -120:
          ianaName = 'America/Noronha';
          break;
        case -180:
          ianaName = 'America/Sao_Paulo';
          break;
        case -210:
          ianaName = 'America/St_Johns';
          break;
        case -240:
          ianaName = 'America/New_York';
          break;
        case -300:
          ianaName = 'America/Chicago';
          break;
        case -360:
          ianaName = 'America/Denver';
          break;
        case -420:
          ianaName = 'America/Los_Angeles';
          break;
        case -480:
          ianaName = 'America/Anchorage';
          break;
        case -600:
          ianaName = 'Pacific/Honolulu';
          break;
      }

      if (ianaName != null) {
        tz.setLocalLocation(tz.getLocation(ianaName));
        debugPrint('[NotificationService] Local timezone set to $ianaName from offset');
        return;
      }

      // 2. Try default lookup by name
      final tzName = now.timeZoneName;
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[NotificationService] Local timezone set to $tzName from timeZoneName');
    } catch (e) {
      debugPrint('[NotificationService] Failed to set local timezone: $e. Falling back to Asia/Kolkata.');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  Future<bool> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('[NotificationService] Android post notifications permission granted: $granted');
      
      try {
        final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('[NotificationService] Android exact alarms permission granted: $exactAlarmGranted');
      } catch (e) {
        debugPrint('[NotificationService] Error requesting exact alarms permission: $e');
      }
      
      return granted ?? false;
    }
    
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[NotificationService] iOS notifications permission granted: $granted');
      return granted ?? false;
    }
    
    return false;
  }

  // Show immediate notification
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String notificationSound = 'default',
  }) async {
    String channelId;
    String channelName;
    AndroidNotificationSound? androidSound;
    AudioAttributesUsage? audioUsage;

    if (notificationSound.startsWith('content://') || notificationSound.startsWith('file://')) {
      final soundHash = notificationSound.hashCode.abs().toString();
      channelId = 'eazzio_reminders_custom_${soundHash}_channel_v12';
      channelName = 'Eazzio Reminders (Custom Sound)';
      androidSound = UriAndroidNotificationSound(notificationSound);
      audioUsage = AudioAttributesUsage.notificationRingtone;
    } else if (notificationSound == 'ringtone') {
      channelId = 'eazzio_reminders_ringtone_channel_v12';
      channelName = 'Eazzio Reminders (Ringtone)';
      androidSound = const UriAndroidNotificationSound('content://settings/system/ringtone');
      audioUsage = AudioAttributesUsage.notificationRingtone;
    } else if (notificationSound == 'alarm') {
      channelId = 'eazzio_reminders_alarm_channel_v12';
      channelName = 'Eazzio Reminders (Alarm)';
      androidSound = const UriAndroidNotificationSound('content://settings/system/alarm_alert');
      audioUsage = AudioAttributesUsage.alarm;
    } else {
      channelId = 'eazzio_reminders_default_channel_v12';
      channelName = 'Eazzio Reminders';
      androidSound = null; // Default notification sound
      audioUsage = AudioAttributesUsage.notification;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for scheduled and due reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: androidSound,
      audioAttributesUsage: audioUsage,
      enableVibration: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // Schedule notification at specific date & time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
    String notificationSound = 'default',
  }) async {
    // Prevent scheduling if the date/time is in the past
    if (scheduledDateTime.isBefore(DateTime.now())) {
      debugPrint('[NotificationService] Scheduled date $scheduledDateTime is in the past, skipping schedule');
      return;
    }

    String channelId;
    String channelName;
    AndroidNotificationSound? androidSound;
    AudioAttributesUsage? audioUsage;

    if (notificationSound.startsWith('content://') || notificationSound.startsWith('file://')) {
      final soundHash = notificationSound.hashCode.abs().toString();
      channelId = 'eazzio_scheduled_custom_${soundHash}_channel_v12';
      channelName = 'Eazzio Scheduled Reminders (Custom Sound)';
      androidSound = UriAndroidNotificationSound(notificationSound);
      audioUsage = AudioAttributesUsage.notificationRingtone;
    } else if (notificationSound == 'ringtone') {
      channelId = 'eazzio_scheduled_ringtone_channel_v12';
      channelName = 'Eazzio Scheduled Reminders (Ringtone)';
      androidSound = const UriAndroidNotificationSound('content://settings/system/ringtone');
      audioUsage = AudioAttributesUsage.notificationRingtone;
    } else if (notificationSound == 'alarm') {
      channelId = 'eazzio_scheduled_alarm_channel_v12';
      channelName = 'Eazzio Scheduled Reminders (Alarm)';
      androidSound = const UriAndroidNotificationSound('content://settings/system/alarm_alert');
      audioUsage = AudioAttributesUsage.alarm;
    } else {
      channelId = 'eazzio_scheduled_default_channel_v12';
      channelName = 'Eazzio Scheduled Reminders';
      androidSound = null; // Default
      audioUsage = AudioAttributesUsage.notification;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for upcoming scheduled reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: androidSound,
      audioAttributesUsage: audioUsage,
      enableVibration: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('[NotificationService] Scheduled notification ID $id for $tzScheduledTime');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling notification: $e. Retrying with approximate scheduling.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (err2) {
        debugPrint('[NotificationService] Secondary failure in scheduling: $err2');
      }
    }
  }

  // Cancel scheduled notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
    debugPrint('[NotificationService] Cancelled notification ID $id');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('[NotificationService] Cancelled all notifications');
  }
}
