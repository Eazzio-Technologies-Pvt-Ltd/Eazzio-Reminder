import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../theme.dart';
import '../widgets/reminder_form.dart';
import 'schedule_details_screen.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'scheduled', 'pending_approval'
  String _selectedEventType = 'all'; // 'all', 'birthday', 'anniversary', 'fee', 'custom'
  String _selectedChannel = 'all'; // 'all', 'whatsapp', 'call', 'sms', 'notification'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = 'all';
      _selectedEventType = 'all';
      _selectedChannel = 'all';
    });
  }

  void _openReminderForm(BuildContext context, [Reminder? reminder]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
    final provider = Provider.of<ReminderProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter list
    final filteredReminders = provider.reminders.where((reminder) {
      // 1. Pill Status Filter
      if (_selectedStatus == 'upcoming') {
        if (reminder.status != 'scheduled' && reminder.status != 'pending_approval' && reminder.status != 'sending') {
          return false;
        }
      } else if (_selectedStatus == 'completed') {
        if (reminder.status != 'sent') {
          return false;
        }
      } else if (_selectedStatus == 'paused') {
        if (reminder.status != 'rejected' && reminder.status != 'failed') {
          return false;
        }
      }

      // 2. Search Filter
      if (_searchQuery.isNotEmpty) {
        final title = reminder.title.toLowerCase();
        final name = reminder.recipientName.toLowerCase();
        final phone = reminder.recipientPhone.toLowerCase();
        final template = reminder.messageTemplate.toLowerCase();

        return title.contains(_searchQuery) ||
            name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            template.contains(_searchQuery);
      }

      return true;
    }).toList();

    // Stats
    final scheduledCount = provider.reminders.where((r) => r.status == 'scheduled').length;
    final pendingCount = provider.reminders.where((r) => r.status == 'pending_approval').length;
    final totalCount = provider.reminders.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: provider.refreshAll,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width < 400 ? 12.0 : 24.0,
            right: MediaQuery.of(context).size.width < 400 ? 12.0 : 24.0,
            top: 32.0,
            bottom: 90.0,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  FadeInSlide(
                    delay: Duration.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.cyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Scheduled Reminders Queue',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : AppTheme.textSecondaryLightMode,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track, search, filter and manage all your configured automated or manual dispatch events.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppTheme.textSecondaryLightMode,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats overview
                  FadeInSlide(
                    delay: const Duration(milliseconds: 100),
                    child: _buildQueueStats(totalCount, scheduledCount, pendingCount),
                  ),
                  const SizedBox(height: 24),

                  // Search and Filters Section
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: _buildFilterSection(isDark, theme),
                  ),
                  const SizedBox(height: 20),

                  // Active Filter Info & Reminder List or Empty State
                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isNotEmpty ||
                            _selectedStatus != 'all' ||
                            _selectedEventType != 'all' ||
                            _selectedChannel != 'all')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${filteredReminders.length} of $totalCount reminders',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.refresh, size: 14),
                                  label: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (filteredReminders.isEmpty)
                          _buildEmptyState(theme, isDark)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredReminders.length,
                            itemBuilder: (context, index) {
                              final reminder = filteredReminders[index];
                              return FadeInSlide(
                                delay: Duration(milliseconds: index * 50),
                                duration: const Duration(milliseconds: 350),
                                child: _buildReminderCard(context, reminder, provider),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueStats(int total, int scheduled, int pending) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 600;

      Widget item(String title, String val, IconData icon, Gradient grad) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final accentColor = grad is LinearGradient ? grad.colors.first : theme.colorScheme.primary;
        
        if (isNarrow) {
          return IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(11),
                        bottomLeft: Radius.circular(11),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: grad,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: Colors.white, size: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? AppTheme.textSecondary : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            val,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: grad,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppTheme.textSecondary : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                val,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
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
        );
      }

      return Row(
        children: [
          Expanded(
            child: item(
              isNarrow ? 'Total Queue' : 'Total Queue Size',
              total.toString(),
              Icons.queue_play_next,
              AppTheme.primaryGradient,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: item(
              isNarrow ? 'Active' : 'Schedules Active',
              scheduled.toString(),
              Icons.schedule,
              const LinearGradient(colors: [Colors.cyan, Color(0xFF06B6D4)]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: item(
              isNarrow ? 'Pending' : 'Pending Action',
              pending.toString(),
              Icons.pending_actions,
              const LinearGradient(colors: [AppTheme.secondary, Color(0xFFF43F5E)]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search schedules...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ),
        const SizedBox(height: 12),
        
        // Horizontal Pills
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterPill('all', 'All', theme, isDark),
              _buildFilterPill('upcoming', 'Upcoming', theme, isDark),
              _buildFilterPill('completed', 'Completed', theme, isDark),
              _buildFilterPill('paused', 'Paused', theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String statusKey, String label, ThemeData theme, bool isDark) {
    final isSelected = _selectedStatus == statusKey;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedStatus = statusKey;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEEDF8)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? const Color(0x11FFFFFF) : const Color(0xFFD6D4EB)),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLightMode),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0x11FFFFFF) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_send,
            size: 64,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'No matching reminders in queue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Try altering your search text or selecting a different tab filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset Filters', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, Reminder reminder, ReminderProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isWhatsApp = reminder.reminderType == 'whatsapp';
    final isCall = reminder.reminderType == 'call';
    final isPaused = reminder.status == 'paused';
    final isPendingApproval = reminder.status == 'pending_approval';
    final isActive = reminder.status == 'scheduled' || isPendingApproval;

    IconData eventIcon = Icons.notifications_active_rounded;
    Color eventColor = AppTheme.primary;
    if (reminder.eventType == 'birthday') {
      eventIcon = Icons.cake_rounded;
      eventColor = Colors.orange;
    } else if (reminder.eventType == 'anniversary') {
      eventIcon = Icons.favorite_rounded;
      eventColor = Colors.pink;
    } else if (reminder.eventType == 'fee') {
      eventIcon = Icons.monetization_on_rounded;
      eventColor = Colors.green;
    }

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
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFEEEDF8),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ScheduleDetailsScreen(reminder: reminder),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Leading Circle Icon
                  CircleAvatar(
                    backgroundColor: eventColor.withOpacity(0.12),
                    radius: 20,
                    child: Icon(eventIcon, color: eventColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  
                  // Title & Subtitle Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reminder.remindDate} at ${reminder.remindTime}',
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Status Active/Paused Dot Badge
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isPaused 
                                    ? Colors.amber 
                                    : (isPendingApproval ? Colors.orange : AppTheme.success),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPaused 
                                  ? 'Paused' 
                                  : (isPendingApproval ? 'Pending Action' : 'Active'),
                              style: TextStyle(
                                color: isPaused 
                                    ? Colors.amber 
                                    : (isPendingApproval ? Colors.orange : AppTheme.success),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Active/Paused Switch
                  Switch(
                    value: isActive,
                    activeColor: AppTheme.primary,
                    activeTrackColor: AppTheme.primary.withOpacity(0.38),
                    onChanged: (bool value) {
                      final updated = reminder.copyWith(
                        status: value ? 'scheduled' : 'paused', // Toggle status
                      );
                      provider.updateReminder(updated);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
