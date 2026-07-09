import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../theme.dart';
import '../widgets/reminder_form.dart';

class ScheduleDetailsScreen extends StatelessWidget {
  final Reminder reminder;

  const ScheduleDetailsScreen({super.key, required this.reminder});

  void _openEditForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Navigator.of(context).pop(); // Close details sheet first
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: ReminderForm(reminder: reminder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<ReminderProvider>(context);
    
    // Find current status to handle live updates from provider
    final currentReminder = provider.reminders.firstWhere(
      (r) => r.id == reminder.id,
      orElse: () => reminder,
    );

    final isWhatsApp = currentReminder.reminderType == 'whatsapp';
    final isCall = currentReminder.reminderType == 'call';
    final isNotification = currentReminder.reminderType == 'notification';
    final isActive = currentReminder.status == 'scheduled' || currentReminder.status == 'pending_approval';

    IconData eventIcon = Icons.notifications;
    Color eventColor = AppTheme.primary;
    if (currentReminder.eventType == 'birthday') {
      eventIcon = Icons.cake;
      eventColor = Colors.orange;
    } else if (currentReminder.eventType == 'anniversary') {
      eventIcon = Icons.favorite;
      eventColor = Colors.pink;
    } else if (currentReminder.eventType == 'fee') {
      eventIcon = Icons.monetization_on;
      eventColor = Colors.green;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFD6D4EB),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // Header with Back/Close and Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Schedule Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                onPressed: () {
                  provider.deleteReminder(currentReminder.id!);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0x15FFFFFF) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: eventColor.withOpacity(0.12),
                  radius: 24,
                  child: Icon(eventIcon, color: eventColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentReminder.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.success : AppTheme.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'Active' : 'Paused',
                            style: TextStyle(
                              color: isActive ? AppTheme.success : AppTheme.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details List
          _buildDetailRow(
            context,
            Icons.access_time_filled_rounded,
            'Schedule Time',
            '${currentReminder.remindDate} at ${currentReminder.remindTime}',
          ),
          _buildDetailRow(
            context,
            Icons.next_plan_rounded,
            'Next Run',
            isActive ? 'Scheduled for matching trigger' : 'Suspended (Paused)',
          ),
          _buildDetailRow(
            context,
            isWhatsApp
                ? Icons.chat_bubble_rounded
                : (isCall ? Icons.phone_android_rounded : Icons.sms_rounded),
            'Type',
            currentReminder.reminderType.toUpperCase(),
          ),
          _buildDetailRow(
            context,
            Icons.repeat_rounded,
            'Repeat',
            currentReminder.sendOption == 'auto' ? 'Automatic Send' : 'Manual Approval Required',
          ),
          _buildDetailRow(
            context,
            Icons.message_rounded,
            'Message Template',
            currentReminder.messageTemplate,
          ),
          _buildDetailRow(
            context,
            Icons.person_pin_rounded,
            'Recipients',
            '${currentReminder.recipientName} (${currentReminder.recipientPhone})',
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditForm(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updated = currentReminder.copyWith(
                      status: isActive ? 'paused' : 'scheduled', // Use paused as state for paused/inactive status
                    );
                    provider.updateReminder(updated);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? const Color(0xFFD97706) : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                  label: Text(isActive ? 'Pause' : 'Resume'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
