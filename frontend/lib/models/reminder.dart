class Reminder {
  final int? id;
  final String title;
  final String recipientName;
  final String recipientPhone;
  final String eventType; // 'birthday', 'anniversary', 'fee', 'custom', 'task'
  final String remindDate; // 'YYYY-MM-DD'
  final String remindTime; // 'HH:MM'
  final String messageTemplate;
  final String reminderType; // 'call', 'sms', 'notification', 'whatsapp'
  final String? audioUrl;
  final String sendOption; // 'auto', 'approval'
  final String status; // 'scheduled', 'pending_approval', 'sending', 'sent', 'failed', 'rejected', 'paused'
  final String notificationSound; // 'default', 'ringtone', 'alarm'
  final int? userId;
  final int? assignedTo;
  final int? assignedBy;
  final String repeatOption; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final String? createdAt;

  Reminder({
    this.id,
    required this.title,
    required this.recipientName,
    required this.recipientPhone,
    required this.eventType,
    required this.remindDate,
    required this.remindTime,
    required this.messageTemplate,
    required this.reminderType,
    this.audioUrl,
    required this.sendOption,
    required this.status,
    this.notificationSound = 'default',
    this.userId,
    this.assignedTo,
    this.assignedBy,
    this.repeatOption = 'none',
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as int?,
      title: json['title'] as String,
      recipientName: json['recipient_name'] as String,
      recipientPhone: json['recipient_phone'] as String,
      eventType: json['event_type'] as String,
      remindDate: json['remind_date'] as String,
      remindTime: json['remind_time'] as String,
      messageTemplate: json['message_template'] as String,
      reminderType: json['reminder_type'] as String,
      audioUrl: json['audio_url'] as String?,
      sendOption: json['send_option'] as String,
      status: json['status'] as String,
      notificationSound: json['notification_sound'] as String? ?? 'default',
      userId: json['user_id'] as int?,
      assignedTo: json['assigned_to'] as int?,
      assignedBy: json['assigned_by'] as int?,
      repeatOption: json['repeat_option'] as String? ?? 'none',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'event_type': eventType,
      'remind_date': remindDate,
      'remind_time': remindTime,
      'message_template': messageTemplate,
      'reminder_type': reminderType,
      'audio_url': audioUrl,
      'send_option': sendOption,
      'status': status,
      'notification_sound': notificationSound,
      if (userId != null) 'user_id': userId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (assignedBy != null) 'assigned_by': assignedBy,
      'repeat_option': repeatOption,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? recipientName,
    String? recipientPhone,
    String? eventType,
    String? remindDate,
    String? remindTime,
    String? messageTemplate,
    String? reminderType,
    String? audioUrl,
    String? sendOption,
    String? status,
    String? notificationSound,
    int? userId,
    int? assignedTo,
    int? assignedBy,
    String? repeatOption,
    String? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      eventType: eventType ?? this.eventType,
      remindDate: remindDate ?? this.remindDate,
      remindTime: remindTime ?? this.remindTime,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      reminderType: reminderType ?? this.reminderType,
      audioUrl: audioUrl ?? this.audioUrl,
      sendOption: sendOption ?? this.sendOption,
      status: status ?? this.status,
      notificationSound: notificationSound ?? this.notificationSound,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      repeatOption: repeatOption ?? this.repeatOption,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReminderLog {
  final int id;
  final int? reminderId;
  final String recipientName;
  final String recipientPhone;
  final String reminderType;
  final String eventType;
  final String status;
  final String? details;
  final String sentAt;

  ReminderLog({
    required this.id,
    this.reminderId,
    required this.recipientName,
    required this.recipientPhone,
    required this.reminderType,
    required this.eventType,
    required this.status,
    this.details,
    required this.sentAt,
  });

  factory ReminderLog.fromJson(Map<String, dynamic> json) {
    return ReminderLog(
      id: json['id'] as int,
      reminderId: json['reminder_id'] as int?,
      recipientName: json['recipient_name'] as String,
      recipientPhone: json['recipient_phone'] as String,
      reminderType: json['reminder_type'] as String,
      eventType: json['event_type'] as String,
      status: json['status'] as String,
      details: json['details'] as String?,
      sentAt: json['sent_at'] as String,
    );
  }
}
