import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../theme.dart';
import 'custom_graphics.dart';

class ApprovalList extends StatelessWidget {
  const ApprovalList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReminderProvider>(context);
    final approvals = provider.pendingApprovals;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (approvals.isEmpty) {
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
            const NoApprovalsIllustration(),
            const SizedBox(height: 16),
            Text(
              'No Pending Approvals',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reminders requiring manual approval will appear here when they are scheduled to be sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppTheme.textSecondary : Colors.black54,
              ),
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
            const Icon(Icons.security, color: AppTheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Action Required (${approvals.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: approvals.length,
          itemBuilder: (context, index) {
            final reminder = approvals[index];
            return FadeInSlide(
              delay: Duration(milliseconds: index * 80),
              duration: const Duration(milliseconds: 350),
              child: _buildApprovalCard(context, reminder, provider),
            );
          },
        ),
      ],
    );
  }

  Widget _buildApprovalCard(BuildContext context, Reminder reminder, ReminderProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData eventIcon = Icons.notifications;
    Color eventColor = AppTheme.primary;
    
    if (reminder.eventType == 'birthday') {
      eventIcon = Icons.cake;
      eventColor = Colors.orange;
    } else if (reminder.eventType == 'anniversary') {
      eventIcon = Icons.favorite;
      eventColor = Colors.pink;
    } else if (reminder.eventType == 'fee') {
      eventIcon = Icons.monetization_on;
      eventColor = Colors.green;
    }

    final isWhatsApp = reminder.reminderType == 'whatsapp';
    final isCall = reminder.reminderType == 'call';

    Color boxBgColor = eventColor.withOpacity(0.04);
    Color boxBorderColor = eventColor.withOpacity(0.12);
    if (isDark) {
      boxBgColor = eventColor.withOpacity(0.07);
      boxBorderColor = eventColor.withOpacity(0.20);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: HoverContainer(
        scale: 1.012,
        drawBorder: false,
        defaultShadow: AppTheme.getCardShadow(color: eventColor, isDark: isDark, isHovered: false),
        hoverShadow: AppTheme.getCardShadow(color: eventColor, isDark: isDark, isHovered: true),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: eventColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: eventColor.withOpacity(0.1),
                              child: Icon(eventIcon, color: eventColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reminder.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isWhatsApp
                                            ? Icons.chat_bubble_outline
                                            : (isCall ? Icons.phone : Icons.sms),
                                        size: 14,
                                        color: isWhatsApp
                                            ? Colors.green
                                            : (isCall
                                                ? Colors.blue
                                                : (isDark ? AppTheme.textSecondary : Colors.black54)),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${reminder.recipientName} (${reminder.recipientPhone})',
                                          style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Needs Approval',
                                style: TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: boxBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: boxBorderColor, width: 1),
                          ),
                          child: Text(
                            reminder.messageTemplate,
                            style: TextStyle(fontSize: 13, height: 1.4, color: theme.colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () => provider.rejectReminder(reminder.id!),
                                icon: const Icon(Icons.close, size: 16, color: AppTheme.danger),
                                label: const Text('Dismiss', style: TextStyle(color: AppTheme.danger)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final callUri = Uri.parse('tel:${reminder.recipientPhone}');
                                  if (await canLaunchUrl(callUri)) {
                                    await launchUrl(callUri);
                                  }
                                },
                                icon: const Icon(Icons.phone, color: Colors.blue),
                                tooltip: 'Direct Call',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.06),
                                  padding: const EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.blue.withOpacity(0.15)),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final String encodedMsg = Uri.encodeComponent(reminder.messageTemplate);
                                  final Uri smsUri = Uri.parse('sms:${reminder.recipientPhone}?body=$encodedMsg');
                                  if (await canLaunchUrl(smsUri)) {
                                    await launchUrl(smsUri);
                                  }
                                },
                                icon: const Icon(Icons.sms, color: Colors.orange),
                                tooltip: 'Direct SMS',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.orange.withOpacity(0.06),
                                  padding: const EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.orange.withOpacity(0.15)),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (isWhatsApp) {
                                    try {
                                      // Directly approve in the database
                                      await provider.approveReminder(reminder.id!);
                                      
                                      // Construct WhatsApp Link
                                      final String encodedMsg = Uri.encodeComponent(reminder.messageTemplate);
                                      final Uri whatsappUri = Uri.parse('https://wa.me/${reminder.recipientPhone}?text=$encodedMsg');
                                      if (await canLaunchUrl(whatsappUri)) {
                                        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to approve reminder: $e'),
                                          backgroundColor: AppTheme.danger,
                                        ),
                                      );
                                    }
                                  } else {
                                    _showReviewSheet(context, reminder, provider);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isWhatsApp
                                      ? Colors.green
                                      : (isCall ? Colors.blue : AppTheme.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(
                                  isCall ? Icons.phone : Icons.send,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isWhatsApp
                                      ? 'Send WhatsApp'
                                      : (isCall ? 'Place Call' : 'Send SMS'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, Reminder reminder, ReminderProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isWhatsApp = reminder.reminderType == 'whatsapp';
        final isCall = reminder.reminderType == 'call';
        final actionColor = isWhatsApp
            ? Colors.green
            : (isCall ? Colors.blue : AppTheme.primary);
        
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFD6D4EB), width: 1),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Review & Dispatch Reminder',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? AppTheme.textSecondary : Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(color: Color(0x11FFFFFF), height: 20),
              
              // Recipient Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFD6D4EB)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: actionColor.withOpacity(0.1),
                      child: Icon(
                        isWhatsApp
                            ? Icons.chat_bubble
                            : (isCall ? Icons.phone : Icons.sms),
                        color: actionColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.recipientName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  reminder.recipientPhone,
                                  style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Call action
                              InkWell(
                                onTap: () async {
                                  final callUri = Uri.parse('tel:${reminder.recipientPhone}');
                                  if (await canLaunchUrl(callUri)) {
                                    await launchUrl(callUri);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.phone, size: 16, color: Colors.blue),
                                ),
                              ),
                              // SMS action
                              InkWell(
                                onTap: () async {
                                  final String encodedMsg = Uri.encodeComponent(reminder.messageTemplate);
                                  final Uri smsUri = Uri.parse('sms:${reminder.recipientPhone}?body=$encodedMsg');
                                  if (await canLaunchUrl(smsUri)) {
                                    await launchUrl(smsUri);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.sms, size: 16, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reminder.reminderType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: actionColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Message Box
              Text(
                'Message Content',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textSecondary : Colors.black54),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFD6D4EB)),
                ),
                child: Text(
                  reminder.messageTemplate,
                  style: TextStyle(fontSize: 14, height: 1.4, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0x22FFFFFF) : const Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        provider.approveReminder(reminder.id!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        isCall ? Icons.phone : Icons.send_to_mobile,
                        size: 18,
                      ),
                      label: Text(
                        isWhatsApp
                            ? 'Send WhatsApp'
                            : (isCall ? 'Place Call' : 'Send SMS (SIM)'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
