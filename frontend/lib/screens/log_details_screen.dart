import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reminder.dart';
import '../theme.dart';

class LogDetailsScreen extends StatelessWidget {
  final ReminderLog log;

  const LogDetailsScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData eventIcon = Icons.notifications;
    Color eventColor = AppTheme.primary;
    if (log.eventType == 'birthday') {
      eventIcon = Icons.cake;
      eventColor = Colors.orange;
    } else if (log.eventType == 'anniversary') {
      eventIcon = Icons.favorite;
      eventColor = Colors.pink;
    } else if (log.eventType == 'fee') {
      eventIcon = Icons.monetization_on;
      eventColor = Colors.green;
    }

    Color statusColor = AppTheme.textSecondary;
    if (log.status == 'sent') {
      statusColor = AppTheme.success;
    } else if (log.status == 'failed') {
      statusColor = AppTheme.danger;
    } else if (log.status == 'rejected') {
      statusColor = AppTheme.textSecondary;
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
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Log Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 48), // Spacer to balance back button
            ],
          ),
          const SizedBox(height: 16),

          // Log Header Card
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
                        log.recipientName,
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
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            log.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
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

          // Details Section
          Text(
            'Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Divider(height: 16),
          
          _buildDetailRow(
            context,
            'Recipient',
            log.recipientPhone,
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: log.recipientPhone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number copied to clipboard')),
                );
              },
            ),
          ),
          _buildDetailRow(
            context,
            'Type',
            log.reminderType.toUpperCase(),
          ),
          _buildDetailRow(
            context,
            'Status',
            log.status.toUpperCase(),
            valueColor: statusColor,
          ),
          _buildDetailRow(
            context,
            'Sent At',
            log.sentAt,
          ),
          if (log.details != null && log.details!.isNotEmpty)
            _buildDetailRow(
              context,
              'Info / Error Details',
              log.details!,
            ),
          const SizedBox(height: 24),

          // View Message Button
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Dispatched Message'),
                  content: Text(log.details ?? 'Message successfully dispatched without errors.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'View Message',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor, Widget? trailing}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ]
            ],
          ),
        ],
      ),
    );
  }
}
