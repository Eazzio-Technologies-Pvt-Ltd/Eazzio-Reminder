import 'package:flutter/services.dart';

class NativeService {
  static const MethodChannel _channel = MethodChannel('com.example.eazzio_reminder/native_send');

  // Check if SMS direct permission is granted
  static Future<bool> hasSmsPermission() async {
    try {
      final bool hasPerm = await _channel.invokeMethod('hasSmsPermission');
      return hasPerm;
    } catch (e) {
      print('[NativeService] Error checking SMS permission: $e');
      return false;
    }
  }

  // Request SMS direct permission
  static Future<bool> requestSmsPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestSmsPermission');
      return granted;
    } catch (e) {
      print('[NativeService] Error requesting SMS permission: $e');
      return false;
    }
  }

  // Send Direct SMS programmatically (in background)
  static Future<bool> sendDirectSMS(String phone, String message) async {
    try {
      final bool success = await _channel.invokeMethod('sendSMS', {
        'phone': phone,
        'message': message,
      });
      return success;
    } catch (e) {
      print('[NativeService] Error sending direct SMS: $e');
      return false;
    }
  }

  // Check if Eazzio Accessibility Service is Enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool enabled = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return enabled;
    } catch (e) {
      print('[NativeService] Error checking Accessibility Service: $e');
      return false;
    }
  }

  // Open accessibility settings page
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('[NativeService] Error opening accessibility settings: $e');
    }
  }

  // Mark auto send pending for the accessibility clicker
  static Future<void> markWhatsAppAutoSendPending() async {
    try {
      await _channel.invokeMethod('markWhatsAppAutoSendPending');
    } catch (e) {
      print('[NativeService] Error marking WhatsApp auto send pending: $e');
    }
  }

  // Trigger system ringtone picker activity and return chosen sound URI
  static Future<String> pickRingtone() async {
    try {
      final String? selectedUri = await _channel.invokeMethod('pickRingtone');
      return selectedUri ?? 'default';
    } catch (e) {
      print('[NativeService] Error picking ringtone: $e');
      return 'default';
    }
  }
}
