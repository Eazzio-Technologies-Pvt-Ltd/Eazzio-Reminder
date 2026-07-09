import 'package:flutter_test/flutter_test.dart';
import 'package:eazzio_reminder/models/reminder.dart';

void main() {
  test('Reminder model parses from JSON', () {
    final json = {
      'id': 1,
      'title': 'Test Reminder',
      'recipient_name': 'Alice',
      'recipient_phone': '+1234567890',
      'event_type': 'birthday',
      'remind_date': '2026-06-11',
      'remind_time': '10:00',
      'message_template': 'Happy Birthday!',
      'reminder_type': 'sms',
      'audio_url': null,
      'send_option': 'auto',
      'status': 'scheduled',
      'created_at': '2026-06-11T10:00:00Z',
    };

    final reminder = Reminder.fromJson(json);

    expect(reminder.id, 1);
    expect(reminder.title, 'Test Reminder');
    expect(reminder.recipientName, 'Alice');
    expect(reminder.recipientPhone, '+1234567890');
    expect(reminder.eventType, 'birthday');
    expect(reminder.remindDate, '2026-06-11');
    expect(reminder.remindTime, '10:00');
    expect(reminder.messageTemplate, 'Happy Birthday!');
    expect(reminder.reminderType, 'sms');
    expect(reminder.audioUrl, isNull);
    expect(reminder.sendOption, 'auto');
    expect(reminder.status, 'scheduled');
    expect(reminder.createdAt, '2026-06-11T10:00:00Z');
  });
}
