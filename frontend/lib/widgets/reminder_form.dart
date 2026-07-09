import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../theme.dart';

class ReminderForm extends StatefulWidget {
  final Reminder? reminder; // If editing

  const ReminderForm({super.key, this.reminder});

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleTextController;
  late TextEditingController _nameTextController;
  late TextEditingController _phoneController;
  late TextEditingController _msgController;

  String _eventType = 'task';
  DateTime _remindDate = DateTime.now();
  TimeOfDay _remindTime = TimeOfDay.now();
  String _reminderType = 'sms';
  String _sendOption = 'auto';
  String _notificationSound = 'default';
  String _repeatOption = 'none';
  int? _assignedTo;

  // Templates map for auto populating
  final Map<String, String> _templates = {
    'task': 'Hi {name}, this is a reminder for your task: {title}. Please make sure it is completed. Thanks!',
    'birthday': 'Happy Birthday, {name}! 🎂 Wishing you a wonderful year ahead filled with love, laughter, and success. Have an amazing day!',
    'anniversary': 'Happy Anniversary, {name}! 💖 Wishing you another year of love, happiness, and beautiful memories together.',
    'fee': 'Dear {name}, this is a friendly reminder that your outstanding fee is due. Please clear it at your earliest convenience. Thank you. 💵',
    'custom': 'Hi {name}, this is a quick reminder for your upcoming schedule. Please check. 🔔',
  };

  Future<void> _loadCustomTemplates(ReminderProvider provider) async {
    for (final eventType in ['task', 'birthday', 'anniversary', 'fee', 'custom']) {
      final custom = await provider.getTemplate(eventType);
      if (custom != null) {
        _templates[eventType] = custom;
      }
    }
    // Update default template if this is a new reminder
    if (widget.reminder == null) {
      _updateMessageTemplate();
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _titleTextController = TextEditingController(text: widget.reminder?.title ?? '');
    _nameTextController = TextEditingController(text: widget.reminder?.recipientName ?? '');
    
    // Pre-populate country code if this is a new reminder and it is not empty
    final provider = Provider.of<ReminderProvider>(context, listen: false);
    String initialPhone = widget.reminder?.recipientPhone ?? '';
    if (initialPhone.isEmpty && provider.defaultCountryCode.isNotEmpty) {
      initialPhone = provider.defaultCountryCode;
    }
    _phoneController = TextEditingController(text: initialPhone);
    
    _msgController = TextEditingController(text: widget.reminder?.messageTemplate ?? '');

    if (widget.reminder != null) {
      final rem = widget.reminder!;
      _eventType = rem.eventType;
      _reminderType = rem.reminderType;
      _sendOption = rem.sendOption;
      _notificationSound = rem.notificationSound;
      _repeatOption = rem.repeatOption;
      _assignedTo = rem.assignedTo;
      
      try {
        _remindDate = DateFormat('yyyy-MM-dd').parse(rem.remindDate);
      } catch (_) {}
      
      try {
        final timeParts = rem.remindTime.split(':');
        _remindTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } catch (_) {}
    } else {
      // Set initial message template
      _updateMessageTemplate();
    }

    _loadCustomTemplates(provider);
  }

  @override
  void dispose() {
    _titleTextController.dispose();
    _nameTextController.dispose();
    _phoneController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _updateMessageTemplate() {
    String name = _nameTextController.text.trim();
    if (name.isEmpty) name = 'Name';
    
    final template = _templates[_eventType] ?? '';
    _msgController.text = template.replaceAll('{name}', name);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _remindDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _remindDate) {
      setState(() {
        _remindDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _remindTime,
    );
    if (picked != null && picked != _remindTime) {
      setState(() {
        _remindTime = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);

    // Format fields
    final dateStr = DateFormat('yyyy-MM-dd').format(_remindDate);
    final hourStr = _remindTime.hour.toString().padLeft(2, '0');
    final minStr = _remindTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minStr';

    final recipientName = _reminderType == 'notification' && _nameTextController.text.trim().isEmpty
        ? 'Me'
        : _nameTextController.text.trim();
    final recipientPhone = _reminderType == 'notification' && _phoneController.text.trim().isEmpty
        ? 'Self'
        : _phoneController.text.trim();

    final reminderData = Reminder(
      id: widget.reminder?.id,
      title: _titleTextController.text.trim(),
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      eventType: _eventType,
      remindDate: dateStr,
      remindTime: timeStr,
      messageTemplate: _msgController.text.trim(),
      reminderType: _reminderType,
      audioUrl: null,
      sendOption: _sendOption,
      status: widget.reminder?.status ?? 'scheduled',
      notificationSound: _notificationSound,
      userId: widget.reminder?.userId ?? provider.currentUserId,
      assignedTo: _assignedTo,
      assignedBy: widget.reminder?.assignedBy ?? (_assignedTo != null ? provider.currentUserId : null),
      repeatOption: _repeatOption,
    );

    Future<void> action;
    if (widget.reminder != null) {
      action = provider.updateReminder(reminderData);
    } else {
      action = provider.addReminder(reminderData);
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    action.then((_) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(widget.reminder != null 
              ? 'Reminder updated successfully' 
              : 'Reminder scheduled successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }).catchError((err) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $err'),
          backgroundColor: AppTheme.danger,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;
    final provider = Provider.of<ReminderProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Reminder' : 'New Event Reminder',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              Divider(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0x11FFFFFF) : const Color(0xFFD6D4EB),
                height: 20,
              ),
              
              // Event Type Choice Chip
              // Event Type Choice Chip
              Text(
                'Event Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip('task', '📝 Task'),
                  _buildTypeChip('birthday', '🎂 Birthday'),
                  _buildTypeChip('anniversary', '💖 Anniversary'),
                  _buildTypeChip('fee', '💵 Fee'),
                  _buildTypeChip('custom', '🔔 Custom'),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleTextController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'e.g. John\'s 30th Birthday',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Name & Phone
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameTextController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (_) {
                        if (!isEdit) _updateMessageTemplate();
                      },
                      validator: (value) {
                        if (_reminderType == 'notification') return null;
                        return value == null || value.trim().isEmpty ? 'Name is required' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        hintText: '+1234567890',
                      ),
                      validator: (value) {
                        if (_reminderType == 'notification') return null;
                        return value == null || value.trim().isEmpty ? 'Phone is required' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date & Time Picker Buttons
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.bgCardLight.withOpacity(0.5)
                              : AppTheme.bgCardLightModeAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0x11FFFFFF)
                                : const Color(0xFFD6D4EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 20, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : Colors.black54,
                                  ),
                                ),
                                Text(DateFormat('d MMM, yyyy').format(_remindDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.bgCardLight.withOpacity(0.5)
                              : AppTheme.bgCardLightModeAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0x11FFFFFF)
                                : const Color(0xFFD6D4EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : Colors.black54,
                                  ),
                                ),
                                Text(_remindTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Assign To (only visible if there are team members)
              if (provider.teamMembers.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  value: _assignedTo,
                  decoration: const InputDecoration(
                    labelText: 'Assign Task To',
                    prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Myself'),
                    ),
                    ...provider.teamMembers.map((member) {
                      return DropdownMenuItem<int?>(
                        value: member['id'] as int,
                        child: Text(member['name'] ?? ''),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _assignedTo = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Repeat Options dropdown
              DropdownButtonFormField<String>(
                value: _repeatOption,
                decoration: const InputDecoration(
                  labelText: 'Repeat Option',
                  prefixIcon: Icon(Icons.replay_circle_filled_rounded),
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None (One-time)')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _repeatOption = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Reminder Type (SMS / WhatsApp / Call / Notification)
              Text(
                'Reminder Method',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0x11FFFFFF)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMethodIcon('sms', Icons.sms_rounded, 'SMS'),
                    _buildMethodIcon('whatsapp', Icons.chat_bubble_rounded, 'WhatsApp'),
                    _buildMethodIcon('call', Icons.phone_rounded, 'Call'),
                    _buildMethodIcon('notification', Icons.notifications_active_rounded, 'App Notification'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notification Sound setting
              DropdownButtonFormField<String>(
                value: _notificationSound,
                decoration: const InputDecoration(
                  labelText: 'Notification Sound Setting',
                  prefixIcon: Icon(Icons.music_note),
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: const [
                  DropdownMenuItem(
                    value: 'default',
                    child: Text('Default Notification Sound'),
                  ),
                  DropdownMenuItem(
                    value: 'ringtone',
                    child: Text('Device Ringtone (Phone Ring)'),
                  ),
                  DropdownMenuItem(
                    value: 'alarm',
                    child: Text('Device Alarm Sound'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _notificationSound = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Message Template Area
              TextFormField(
                controller: _msgController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reminder Message Template',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Icon(Icons.message),
                  ),
                  hintText: 'Enter the message content...',
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Message template is required' : null,
              ),
              const SizedBox(height: 20),

              // Sending Workflow Option (Auto-Send / Requires Approval)
              Text(
                'Sending Flow',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      selected: _sendOption == 'auto',
                      title: 'Auto Send',
                      subtitle: 'Direct dispatch',
                      icon: Icons.bolt,
                      onTap: () => setState(() => _sendOption = 'auto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChoiceCard(
                      selected: _sendOption == 'approval',
                      title: 'Approval',
                      subtitle: 'Prompt first',
                      icon: Icons.verified_user,
                      onTap: () => setState(() => _sendOption = 'approval'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(isEdit ? 'Update Schedule' : 'Schedule Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _eventType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _eventType = type;
          _updateMessageTemplate();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (isDark ? const Color(0x11FFFFFF) : const Color(0xFFD6D4EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppTheme.textSecondary : Colors.black54),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : (isDark ? const Color(0x11FFFFFF) : const Color(0xFFD6D4EB)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : (isDark ? AppTheme.textSecondary : Colors.black54), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? (isDark ? Colors.white : Colors.black87) : theme.colorScheme.onSurface)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? AppTheme.textSecondary : Colors.black54)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMethodIcon(String type, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _reminderType == type;
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        setState(() {
          _reminderType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primary
                  : (isDark ? Colors.white54 : Colors.black54),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.primary)
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
