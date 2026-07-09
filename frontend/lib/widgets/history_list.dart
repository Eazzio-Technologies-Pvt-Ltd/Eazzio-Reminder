import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../theme.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReminderProvider>(context);
    final history = provider.history;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0x11FFFFFF) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.15) 
                  : Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Sending History Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'A historical log of all automated or approved voice calls and SMS messages will populate here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Outbox & Logs Audit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimaryLightMode),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final log = history[index];
            return _buildHistoryRow(context, log);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryRow(BuildContext context, ReminderLog log) {
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
    IconData statusIcon = Icons.info;
    if (log.status == 'sent') {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle;
    } else if (log.status == 'failed') {
      statusColor = AppTheme.danger;
      statusIcon = Icons.error;
    } else if (log.status == 'rejected') {
      statusColor = AppTheme.textSecondary;
      statusIcon = Icons.cancel;
    }

    // Format ISO timestamp to local format
    String formattedTime = log.sentAt;
    try {
      final dateTime = DateTime.parse(log.sentAt).toLocal();
      formattedTime = DateFormat('dd MMM, yyyy  h:mm a').format(dateTime);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: HoverContainer(
        scale: 1.012,
        drawBorder: false,
        defaultShadow: AppTheme.getCardShadow(color: eventColor, isDark: isDark, isHovered: false),
        hoverShadow: AppTheme.getCardShadow(color: eventColor, isDark: isDark, isHovered: true),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                left: BorderSide(color: eventColor, width: 6),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 450;
            
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(eventIcon, color: eventColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            log.recipientName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                      _buildStatusBadge(log.status, statusColor, statusIcon),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(log.recipientPhone, style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        log.reminderType == 'whatsapp'
                            ? Icons.chat_bubble_outline
                            : (log.reminderType == 'call' ? Icons.phone : Icons.sms),
                        size: 12,
                        color: log.reminderType == 'whatsapp'
                            ? Colors.green
                            : (log.reminderType == 'call'
                                ? Colors.blue
                                : (isDark ? AppTheme.textSecondary : Colors.black54)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.reminderType.toUpperCase(),
                        style: TextStyle(
                          color: log.reminderType == 'whatsapp'
                              ? Colors.green
                              : (log.reminderType == 'call'
                                  ? Colors.blue
                                  : (isDark ? AppTheme.textSecondary : Colors.black54)),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(formattedTime, style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 11)),
                    ],
                  ),
                  if (log.details != null && log.details!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.details!,
                      style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 11, fontStyle: FontStyle.italic),
                    )
                  ]
                ],
              );
            }

            // Desktop wide layout
            return Row(
              children: [
                // Event badge
                CircleAvatar(
                  backgroundColor: eventColor.withOpacity(0.1),
                  radius: 18,
                  child: Icon(eventIcon, color: eventColor, size: 16),
                ),
                const SizedBox(width: 12),
                
                // Recipient Details
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.recipientName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        log.recipientPhone,
                        style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Mode (WhatsApp/SMS)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        log.reminderType == 'whatsapp'
                            ? Icons.chat_bubble_outline
                            : (log.reminderType == 'call' ? Icons.phone : Icons.sms),
                        size: 14,
                        color: log.reminderType == 'whatsapp'
                            ? Colors.green
                            : (log.reminderType == 'call'
                                ? Colors.blue
                                : (isDark ? AppTheme.textSecondary : Colors.black54)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        log.reminderType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: log.reminderType == 'whatsapp'
                              ? Colors.green
                              : (log.reminderType == 'call'
                                  ? Colors.blue
                                  : (isDark ? Colors.white70 : Colors.black87)),
                        ),
                      ),
                    ],
                  ),
                ),

                // DateTime
                Expanded(
                  flex: 3,
                  child: Text(
                    formattedTime,
                    style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 12),
                  ),
                ),

                // Status
                Expanded(
                  flex: 2,
                  child: _buildStatusBadge(log.status, statusColor, statusIcon),
                ),

                // Details
                if (log.details != null && log.details!.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: Text(
                      log.details!,
                      style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 11, fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
