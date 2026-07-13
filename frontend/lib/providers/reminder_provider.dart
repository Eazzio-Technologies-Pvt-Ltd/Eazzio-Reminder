import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  final SocketService _socketService = SocketService();
  late ApiService _apiService;

  List<Reminder> _reminders = [];
  List<ReminderLog> _history = [];
  bool _isLoading = false;
  Timer? _localSchedulerTimer;
  
  // Callback for when a reminder is due in auto mode, prompting the UI to show an overlay
  Function(Reminder)? onAutoReminderDue;

  // Settings
  String _appMode = 'server';
  String _apiBaseUrl = 'https://eazzio-reminder.onrender.com/api';
  String _themeModeStr = 'dark';
  String _defaultCountryCode = '+91';

  // Auth profile state
  int? _currentUserId;
  String? _currentUserName;
  String? _currentUserEmail;
  String? _currentUserPhone;

  // Teams state
  List<dynamic> _teamMembers = [];
  List<dynamic> _incomingRequests = [];
  List<dynamic> _outgoingRequests = [];

  // Getters
  List<Reminder> get reminders => _reminders;
  List<ReminderLog> get history => _history;
  bool get isLoading => _isLoading;
  
  String get appMode => _appMode;
  String get apiBaseUrl => _apiBaseUrl;
  String get themeModeStr => _themeModeStr;
  ThemeMode get themeMode => _themeModeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
  String get defaultCountryCode => _defaultCountryCode;

  // Auth getters
  int? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserPhone => _currentUserPhone;
  bool get isAuthenticated => _currentUserId != null;

  // Teams getters
  List<dynamic> get teamMembers => _teamMembers;
  List<dynamic> get incomingRequests => _incomingRequests;
  List<dynamic> get outgoingRequests => _outgoingRequests;

  List<Reminder> get pendingApprovals => 
      _reminders.where((r) => r.status == 'pending_approval').toList();

  // Constructor
  ReminderProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load settings from Local Storage
    _appMode = 'server'; // Always in server mode
    _apiBaseUrl = await _localStorageService.getApiBaseUrl();
    _themeModeStr = await _localStorageService.getThemeMode();
    _defaultCountryCode = await _localStorageService.getDefaultCountryCode();

    // Load User Profile details
    final profile = await _localStorageService.getUserProfile();
    if (profile != null) {
      _currentUserId = profile['id'] as int?;
      _currentUserName = profile['name'] as String?;
      _currentUserEmail = profile['email'] as String?;
      _currentUserPhone = profile['phone'] as String?;
    }

    // 2. Initialize Notification Service
    await NotificationService().init();
    await NotificationService().requestPermissions();

    // 3. Initialize API Service with loaded URL
    _apiService = ApiService(baseUrl: _apiBaseUrl);

    // 3. Handle connections & timers based on App Mode
    _localSchedulerTimer?.cancel();
    _socketService.disconnect();

    if (_appMode == 'server') {
      // Setup WebSocket and Listen for Real-Time Events
      _socketService.connect(_apiBaseUrl);

      _socketService.onReminderCreated = (newReminderJson) {
        final newReminder = Reminder.fromJson(newReminderJson);
        if (!_reminders.any((r) => r.id == newReminder.id)) {
          _reminders.add(newReminder);
          notifyListeners();
          _syncAllNotifications();
        }
      };

      _socketService.onReminderUpdated = (updatedReminderJson) {
        final updatedReminder = Reminder.fromJson(updatedReminderJson);
        final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
        
        bool isDueAuto = false;
        if (updatedReminder.status == 'pending_approval' && updatedReminder.sendOption == 'auto') {
          if (index == -1 || _reminders[index].status != 'pending_approval') {
            isDueAuto = true;
          }
        }

        if (index != -1) {
          _reminders[index] = updatedReminder;
        } else {
          _reminders.add(updatedReminder);
        }

        // Show immediate local notification on device if transitioning to pending approval (due now)
        if (updatedReminder.status == 'pending_approval') {
          if (index == -1 || _reminders[index].status != 'pending_approval') {
            // Only show due-now notification if it requires manual approval (not auto-send)
            if (updatedReminder.sendOption != 'auto') {
              NotificationService().showImmediateNotification(
                id: updatedReminder.id!,
                title: 'Reminder Due Now!',
                body: 'Recipient: ${updatedReminder.recipientName} (${updatedReminder.recipientPhone})',
                notificationSound: updatedReminder.notificationSound,
              );
            }
          }
        }

        notifyListeners();
        _syncAllNotifications();

        if (isDueAuto) {
          // Auto send!
          approveReminder(updatedReminder.id!);
        }
      };

      _socketService.onReminderDeleted = (deletedId) {
        _reminders.removeWhere((r) => r.id == deletedId);
        notifyListeners();
        _syncAllNotifications();
      };

      _socketService.onLogsUpdated = () {
        fetchHistory();
      };
      
      // Handle team real-time updates
      _socketService.onTeamUpdate = () {
        fetchTeamData();
      };
    } else {
      // Local Mode: Start in-app scheduler (runs check every 30 seconds)
      _localSchedulerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_appMode == 'local') {
          checkAndProcessRemindersLocal();
        }
      });
      // Run first check immediately
      Timer(const Duration(seconds: 1), () {
        checkAndProcessRemindersLocal();
      });
    }

    // 4. Initial Load of Data
    await refreshAll();
  }

  // Update Settings from settings screen
  Future<void> updateSettings({
    required String appMode,
    required String apiBaseUrl,
    required String themeMode,
    required String defaultCountryCode,
  }) async {
    await _localStorageService.setAppMode(appMode);
    await _localStorageService.setApiBaseUrl(apiBaseUrl);
    await _localStorageService.setThemeMode(themeMode);
    await _localStorageService.setDefaultCountryCode(defaultCountryCode);

    // Re-run initialization to apply updates
    await _init();
  }

  // Toggle Theme between Light & Dark
  Future<void> toggleTheme() async {
    _themeModeStr = _themeModeStr == 'light' ? 'dark' : 'light';
    await _localStorageService.setThemeMode(_themeModeStr);
    notifyListeners();
  }

  // Fetch all reminders
  Future<void> fetchReminders() async {
    try {
      if (_appMode == 'local') {
        _reminders = await _localStorageService.getReminders();
      } else {
        _reminders = await _apiService.getReminders(userId: _currentUserId);
      }
      notifyListeners();
      _syncAllNotifications();
    } catch (e) {
      print('Error fetching reminders: $e');
    }
  }

  // Message template storage operations
  Future<String?> getTemplate(String eventType) async {
    return _localStorageService.getTemplate(eventType);
  }

  Future<void> saveTemplateSetting(String eventType, String template) async {
    await _localStorageService.setTemplate(eventType, template);
    notifyListeners();
  }

  // Notification sound settings operations
  Future<String> getNotificationSoundSetting(String eventType) async {
    return _localStorageService.getNotificationSoundSetting(eventType);
  }

  Future<void> saveSoundSetting(String eventType, String sound) async {
    await _localStorageService.setNotificationSoundSetting(eventType, sound);
    notifyListeners();
  }

  // Authentication operations
  Future<void> loginWithGoogle(String name, String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_appMode == 'local') {
        // Create mock local ID
        final localId = DateTime.now().millisecondsSinceEpoch;
        await _localStorageService.setUserProfile(localId, name, email, null);
        _currentUserId = localId;
        _currentUserName = name;
        _currentUserEmail = email;
        _currentUserPhone = null;
      } else {
        final profile = await _apiService.login(name, email, null);
        final id = profile['id'] as int;
        await _localStorageService.setUserProfile(id, name, email, null);
        _currentUserId = id;
        _currentUserName = name;
        _currentUserEmail = email;
        _currentUserPhone = null;
      }

      await refreshAll();
    } catch (e) {
      print('[Auth] Login with Google failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithPhone(String name, String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_appMode == 'local') {
        final localId = DateTime.now().millisecondsSinceEpoch;
        await _localStorageService.setUserProfile(localId, name, null, phone);
        _currentUserId = localId;
        _currentUserName = name;
        _currentUserEmail = null;
        _currentUserPhone = phone;
      } else {
        final profile = await _apiService.login(name, null, phone);
        final id = profile['id'] as int;
        await _localStorageService.setUserProfile(id, name, null, phone);
        _currentUserId = id;
        _currentUserName = name;
        _currentUserEmail = null;
        _currentUserPhone = phone;
      }

      await refreshAll();
    } catch (e) {
      print('[Auth] Login with Phone failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithCredentials(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_appMode == 'local') {
        final localId = DateTime.now().millisecondsSinceEpoch;
        final name = identifier.split('@').first;
        await _localStorageService.setUserProfile(localId, name, identifier.contains('@') ? identifier : null, identifier.contains('@') ? null : identifier);
        _currentUserId = localId;
        _currentUserName = name;
        _currentUserEmail = identifier.contains('@') ? identifier : null;
        _currentUserPhone = identifier.contains('@') ? null : identifier;
      } else {
        final profile = await _apiService.loginWithPassword(identifier, password);
        final id = profile['id'] as int;
        final name = profile['name'] as String;
        final email = profile['email'] as String?;
        final phone = profile['phone'] as String?;
        await _localStorageService.setUserProfile(id, name, email, phone);
        _currentUserId = id;
        _currentUserName = name;
        _currentUserEmail = email;
        _currentUserPhone = phone;
      }

      await refreshAll();
    } catch (e) {
      print('[Auth] Login with Credentials failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithCredentials(String name, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_appMode == 'local') {
        // Just mock a successful registration (no local storage/state login changes)
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // Register user on server without setting local user profile session
        await _apiService.signupWithPassword(name, phone, password);
      }
    } catch (e) {
      print('[Auth] Sign up failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String name,
    required String newPassword,
  }) async {
    try {
      if (_appMode == 'local') {
        final profile = await _localStorageService.getUserProfile();
        if (profile != null) {
          final localName = profile['name'] as String;
          final localPhone = profile['phone'] as String?;
          final localEmail = profile['email'] as String?;
          
          if (localName.toLowerCase() == name.toLowerCase() && 
              (localPhone == identifier || localEmail == identifier)) {
            return true;
          }
        }
        return false;
      } else {
        await _apiService.resetPassword(identifier, name, newPassword);
        return true;
      }
    } catch (e) {
      print('[Auth] Reset password failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _localStorageService.clearUserProfile();
    _currentUserId = null;
    _currentUserName = null;
    _currentUserEmail = null;
    _currentUserPhone = null;
    _teamMembers = [];
    _incomingRequests = [];
    _outgoingRequests = [];
    _reminders = [];
    _history = [];
    notifyListeners();
  }

  // Teams operations
  Future<void> fetchTeamData() async {
    if (_currentUserId == null || _appMode == 'local') return;

    try {
      final membersList = await _apiService.getTeamMembers(_currentUserId!);
      _teamMembers = membersList;

      final requests = await _apiService.getTeamRequests(_currentUserId!);
      _incomingRequests = requests['incoming'] ?? [];
      _outgoingRequests = requests['outgoing'] ?? [];

      notifyListeners();
    } catch (e) {
      print('[Teams] Error fetching team data: $e');
    }
  }

  Future<void> sendTeamRequest(String email) async {
    if (_currentUserId == null) throw Exception('User not logged in');
    if (_appMode == 'local') throw Exception('Teams features are only available in Server mode');

    try {
      await _apiService.sendTeamRequest(_currentUserId!, email);
      await fetchTeamData();
    } catch (e) {
      print('[Teams] Failed to send request: $e');
      rethrow;
    }
  }

  Future<void> respondToTeamRequest(int requestId, String status) async {
    if (_appMode == 'local') return;

    try {
      await _apiService.respondToTeamRequest(requestId, status);
      await fetchTeamData();
    } catch (e) {
      print('[Teams] Failed to respond to request: $e');
      rethrow;
    }
  }

  // Fetch history logs
  Future<void> fetchHistory() async {
    try {
      if (_appMode == 'local') {
        _history = await _localStorageService.getHistory();
      } else {
        _history = await _apiService.getHistory();
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  // Main reload command
  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.wait([
      fetchReminders(),
      fetchHistory(),
      fetchTeamData()
    ]);
    
    _isLoading = false;
    notifyListeners();
  }

  // Add a reminder
  Future<void> addReminder(Reminder reminder) async {
    try {
      if (_appMode == 'local') {
        final newReminder = await _localStorageService.createReminder(reminder);
        if (!_reminders.any((r) => r.id == newReminder.id)) {
          _reminders.add(newReminder);
          notifyListeners();
        }
        _syncAllNotifications();
        // Run scheduler check immediately to see if new event is already due
        checkAndProcessRemindersLocal();
      } else {
        final newReminder = await _apiService.createReminder(reminder);
        if (!_reminders.any((r) => r.id == newReminder.id)) {
          _reminders.add(newReminder);
          notifyListeners();
        }
        _syncAllNotifications();
      }
    } catch (e) {
      print('Error adding reminder: $e');
      rethrow;
    }
  }

  // Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    try {
      if (_appMode == 'local') {
        final updated = await _localStorageService.updateReminder(reminder);
        final index = _reminders.indexWhere((r) => r.id == updated.id);
        if (index != -1) {
          _reminders[index] = updated;
          notifyListeners();
        }
        _syncAllNotifications();
        checkAndProcessRemindersLocal();
      } else {
        final updated = await _apiService.updateReminder(reminder);
        final index = _reminders.indexWhere((r) => r.id == updated.id);
        if (index != -1) {
          _reminders[index] = updated;
          notifyListeners();
        }
        _syncAllNotifications();
      }
    } catch (e) {
      print('Error updating reminder: $e');
      rethrow;
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(int id) async {
    try {
      // Cancel native scheduled notification
      await NotificationService().cancelNotification(id);
      
      if (_appMode == 'local') {
        await _localStorageService.deleteReminder(id);
        _reminders.removeWhere((r) => r.id == id);
        notifyListeners();
      } else {
        await _apiService.deleteReminder(id);
        _reminders.removeWhere((r) => r.id == id);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting reminder: $e');
      rethrow;
    }
  }

  // Approve a reminder in the queue
  Future<void> approveReminder(int id) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return;

      final reminder = _reminders[index];

      // Temporarily mark as sending in UI
      _reminders[index] = reminder.copyWith(status: 'sending');
      notifyListeners();

      // Launch SMS or WhatsApp on device
      final result = await _localStorageService.sendReminder(reminder);

      if (_appMode == 'server') {
        if (result['success'] == true) {
          // Tell server it succeeded and mark status as sent
          await _apiService.approveReminder(id);
        } else {
          // Mark server reminder as failed
          await _apiService.updateReminder(reminder.copyWith(status: 'failed'));
        }
      }
      
      await refreshAll();
    } catch (e) {
      print('Error approving reminder: $e');
      await refreshAll();
      rethrow;
    }
  }

  // Reject/Dismiss a reminder in the queue
  Future<void> rejectReminder(int id) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return;

      if (_appMode == 'local') {
        final reminder = _reminders[index];
        final rejectedReminder = reminder.copyWith(status: 'rejected');
        await _localStorageService.updateReminder(rejectedReminder);
        
        // Log rejection
        await _localStorageService.createLog(ReminderLog(
          id: 0,
          reminderId: id,
          recipientName: reminder.recipientName,
          recipientPhone: reminder.recipientPhone,
          reminderType: reminder.reminderType,
          eventType: reminder.eventType,
          status: 'rejected',
          details: 'Rejected by user approval workflow',
          sentAt: DateTime.now().toUtc().toIso8601String(),
        ));
        
        _reminders[index] = rejectedReminder;
        notifyListeners();
        _syncAllNotifications();
        fetchHistory();
      } else {
        await _apiService.rejectReminder(id);
        _reminders[index] = _reminders[index].copyWith(status: 'rejected');
        notifyListeners();
        _syncAllNotifications();
      }
    } catch (e) {
      print('Error rejecting reminder: $e');
      rethrow;
    }
  }

  // Trigger background cron scheduler check immediately
  Future<void> triggerSchedulerCheck() async {
    try {
      if (_appMode == 'local') {
        await checkAndProcessRemindersLocal();
      } else {
        await _apiService.triggerScheduler();
        await refreshAll();
      }
    } catch (e) {
      print('Error triggering scheduler: $e');
      rethrow;
    }
  }

  // Run a test-send of a reminder instantly
  Future<void> testSendReminder(int id) async {
    try {
      if (_appMode == 'local') {
        final index = _reminders.indexWhere((r) => r.id == id);
        if (index != -1) {
          await _localStorageService.sendReminder(_reminders[index]);
          await refreshAll();
        }
      } else {
        await _apiService.testSendReminder(id);
      }
    } catch (e) {
      print('Error test-sending reminder: $e');
      rethrow;
    }
  }

  String _calculateNextDateLocal(String currentDateStr, String repeatOption) {
    try {
      final parts = currentDateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      DateTime next;
      switch (repeatOption) {
        case 'daily':
          next = date.add(const Duration(days: 1));
          break;
        case 'weekly':
          next = date.add(const Duration(days: 7));
          break;
        case 'monthly':
          next = DateTime(date.year, date.month + 1, date.day);
          break;
        case 'yearly':
          next = DateTime(date.year + 1, date.month, date.day);
          break;
        default:
          return currentDateStr;
      }
      final y = next.year;
      final m = next.month.toString().padLeft(2, '0');
      final d = next.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } catch (e) {
      print('Error calculating next date local: $e');
      return currentDateStr;
    }
  }

  // Standalone In-App Background Scheduler Check Routine
  Future<void> checkAndProcessRemindersLocal() async {
    print('[Local Scheduler] Running check for reminders...');
    final now = DateTime.now();
    
    // Format Date as YYYY-MM-DD
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final currentDateStr = '$year-$month-$day';

    // Format Time as HH:MM
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    final currentTimeStr = '$hours:$minutes';

    print('[Local Scheduler] Current time reference: $currentDateStr $currentTimeStr');

    try {
      final localReminders = await _localStorageService.getReminders();
      final pendingReminders = localReminders.where((r) {
        if (r.status != 'scheduled') return false;
        
        final dateCompare = r.remindDate.compareTo(currentDateStr);
        if (dateCompare < 0) {
          return true;
        } else if (dateCompare == 0) {
          return r.remindTime.compareTo(currentTimeStr) <= 0;
        }
        return false;
      }).toList();

      if (pendingReminders.isEmpty) {
        return;
      }

      print('[Local Scheduler] Processing ${pendingReminders.length} due reminders.');

      for (final reminder in pendingReminders) {
        final isRepeating = reminder.repeatOption != 'none';
        Reminder targetReminderForWorkflow = reminder;

        if (isRepeating) {
          // Calculate next date
          final nextDate = _calculateNextDateLocal(reminder.remindDate, reminder.repeatOption);
          
          // Reschedule original task in database
          final rescheduledOriginal = reminder.copyWith(remindDate: nextDate);
          await _localStorageService.updateReminder(rescheduledOriginal);
          print('[Local Scheduler] Repeating task ID ${reminder.id} rescheduled to $nextDate.');

          // Spawn a temporary copy representing the current run
          final occurrenceCopy = reminder.copyWith(
            id: null, // Will be generated by shared preferences / storage
            repeatOption: 'none',
            status: 'pending_approval',
          );
          final spawned = await _localStorageService.createReminder(occurrenceCopy);
          targetReminderForWorkflow = spawned;
          print('[Local Scheduler] Spawning copy ID ${spawned.id} for the current repeating task.');
        }

        if (targetReminderForWorkflow.sendOption == 'auto') {
          // AUTO SEND: Mark as pending_approval and dispatch immediately without user approval modal
          final approvalReminder = targetReminderForWorkflow.copyWith(status: 'pending_approval');
          await _localStorageService.updateReminder(approvalReminder);
          
          final idx = _reminders.indexWhere((r) => r.id == targetReminderForWorkflow.id);
          if (idx != -1) {
            _reminders[idx] = approvalReminder;
          }
          
          print('[Local Scheduler] Auto sending reminder ID ${targetReminderForWorkflow.id}...');
          approveReminder(targetReminderForWorkflow.id!);
        } else {
          // Require manual approval
          final approvalReminder = targetReminderForWorkflow.copyWith(status: 'pending_approval');
          await _localStorageService.updateReminder(approvalReminder);
          print('[Local Scheduler] Set reminder ID ${targetReminderForWorkflow.id} to pending approval.');

          // Show device system notification
          await NotificationService().showImmediateNotification(
            id: targetReminderForWorkflow.id!,
            title: 'Reminder Due Now!',
            body: 'Recipient: ${targetReminderForWorkflow.recipientName} (${targetReminderForWorkflow.recipientPhone})',
            notificationSound: targetReminderForWorkflow.notificationSound,
          );
        }
      }
      
      await refreshAll();
    } catch (e) {
      print('[Local Scheduler] Error processing local reminders: $e');
    }
  }

  // Notification scheduling helpers
  void _scheduleLocalNotification(Reminder reminder) {
    if (reminder.id == null) return;
    if (reminder.status != 'scheduled') {
      NotificationService().cancelNotification(reminder.id!);
      return;
    }

    try {
      final dateParts = reminder.remindDate.split('-');
      final timeParts = reminder.remindTime.split(':');
      final scheduledTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      NotificationService().scheduleNotification(
        id: reminder.id!,
        title: reminder.title,
        body: 'Reminder for ${reminder.recipientName} is due. Tap to view details.',
        scheduledDateTime: scheduledTime,
        payload: reminder.id.toString(),
        notificationSound: reminder.notificationSound,
      );
    } catch (e) {
      print('[Notification Sync] Failed to parse schedule time: $e');
    }
  }

  void _syncAllNotifications() {
    for (final r in _reminders) {
      if (r.status == 'scheduled') {
        _scheduleLocalNotification(r);
      } else {
        NotificationService().cancelNotification(r.id!);
      }
    }
  }

  // Snooze a reminder by reschedules it to X minutes in the future and sets status to scheduled
  Future<void> snoozeReminder(int id, {int minutes = 1}) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return;

      final reminder = _reminders[index];
      final newTime = DateTime.now().add(Duration(minutes: minutes));
      
      final dateStr = DateFormat('yyyy-MM-dd').format(newTime);
      final hourStr = newTime.hour.toString().padLeft(2, '0');
      final minStr = newTime.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minStr';

      final snoozedReminder = reminder.copyWith(
        remindDate: dateStr,
        remindTime: timeStr,
        status: 'scheduled',
      );

      // Cancel the current notification to prevent duplication
      await NotificationService().cancelNotification(id);

      await updateReminder(snoozedReminder);
    } catch (e) {
      print('Error snoozing reminder: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _localSchedulerTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}
