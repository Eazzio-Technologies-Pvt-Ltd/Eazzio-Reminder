import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../theme.dart';
import '../widgets/custom_graphics.dart';
import '../widgets/reminder_form.dart';
import '../widgets/approval_list.dart';
import 'history_screen.dart';
import 'schedules_screen.dart';
import 'settings_screen.dart';
import 'teams_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Register the auto-dispatch callback once the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ReminderProvider>(context, listen: false);
      provider.onAutoReminderDue = _handleAutoReminderDue;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildTopAppBar(BuildContext context, ReminderProvider provider, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppTheme.bgCardLightModeAlt,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFD6D4EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppLogo(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.danger,
                ),
                tooltip: 'Logout',
                onPressed: () {
                  provider.logout().then((_) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAutoReminderDue(Reminder reminder) {
    if (!mounted) return;

    final isWhatsApp = reminder.reminderType == 'whatsapp';
    final isCall = reminder.reminderType == 'call';
    final isNotification = reminder.reminderType == 'notification';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color colorTheme = AppTheme.primary;
    if (isWhatsApp) {
      colorTheme = Colors.green;
    } else if (isCall) {
      colorTheme = Colors.blue;
    } else if (isNotification) {
      colorTheme = Colors.cyan;
    }

    // Premium active overlay prompt
    showDialog(
      context: context,
      barrierDismissible: false, // Must make active decision
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colorTheme.withOpacity(0.3), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Reminder Due Now!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipient: ${reminder.recipientName}',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
                ),
                child: Text(
                  reminder.messageTemplate,
                  style: TextStyle(fontSize: 13, height: 1.4, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isNotification
                        ? Icons.notifications_active
                        : (isWhatsApp
                            ? Icons.chat_bubble_outline
                            : (isCall ? Icons.phone : Icons.sms)),
                    size: 14,
                    color: colorTheme,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isNotification
                        ? 'Notification Alert'
                        : 'Dispatch via: ${reminder.reminderType.toUpperCase()} (${reminder.recipientPhone})',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorTheme,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // Left actions (Dismiss & Snooze)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    final provider = Provider.of<ReminderProvider>(context, listen: false);
                    provider.rejectReminder(reminder.id!);
                  },
                  child: const Text('Dismiss', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    final provider = Provider.of<ReminderProvider>(context, listen: false);
                    provider.snoozeReminder(reminder.id!, minutes: 1);
                  },
                  child: const Text('Snooze (1 min)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            // Right actions (Quick Phone / standard SMS / main dispatch)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (isNotification)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final provider = Provider.of<ReminderProvider>(context, listen: false);
                      provider.approveReminder(reminder.id!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTheme,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Mark Complete', style: TextStyle(fontSize: 12)),
                  )
                else ...[
                  IconButton(
                    onPressed: () async {
                      final Uri callUri = Uri.parse('tel:${reminder.recipientPhone}');
                      if (await canLaunchUrl(callUri)) {
                        await launchUrl(callUri);
                      }
                    },
                    icon: const Icon(Icons.phone, color: Colors.blue),
                    tooltip: 'Direct Call',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      side: const BorderSide(color: Colors.blue, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      padding: const EdgeInsets.all(8),
                      side: const BorderSide(color: Colors.orange, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final provider = Provider.of<ReminderProvider>(context, listen: false);
                      provider.approveReminder(reminder.id!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTheme,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      isWhatsApp
                          ? Icons.send_to_mobile
                          : (isCall ? Icons.phone : Icons.sms),
                      size: 14,
                    ),
                    label: Text(
                      isWhatsApp
                          ? 'WhatsApp'
                          : (isCall ? 'Place Call' : 'Send SMS'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          image: isDark
              ? const DecorationImage(
                  image: AssetImage('assets/images/app_background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.20,
                )
              : null,
        ),
        child: Column(
          children: [
            _buildTopAppBar(context, provider, isDark, theme),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _buildHomeTab(context, provider),
                  const SchedulesScreen(),
                  const HistoryScreen(),
                  const TeamsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppTheme.bgCardLightModeAlt,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0x11FFFFFF) : const Color(0xFFD6D4EB),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', isDark, theme),
              _buildNavItem(1, Icons.playlist_add_check_outlined, Icons.playlist_add_check, 'All Tasks', isDark, theme),
              _buildNavItem(2, Icons.assignment_outlined, Icons.assignment, 'Outbox', isDark, theme),
              _buildNavItem(3, Icons.people_outline, Icons.people, 'Teams', isDark, theme),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'add_reminder_fab',
              onPressed: () => _openReminderForm(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label, bool isDark, ThemeData theme) {
    final isSelected = _currentIndex == index;
    final selectedColor = AppTheme.primary;
    final unselectedColor = isDark ? AppTheme.textSecondary : Colors.black54;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countUpcoming(List<Reminder> reminders, String range) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return reminders.where((r) {
      if (r.status != 'scheduled') return false;
      try {
        final date = DateTime.parse(r.remindDate);
        if (range == 'tomorrow') {
          return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
        } else if (range == 'week') {
          return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && date.isBefore(endOfWeek);
        } else if (range == 'month') {
          return date.year == now.year && date.month == now.month;
        }
      } catch (_) {}
      return false;
    }).length;
  }

  int _countCompleted(List<ReminderLog> history, String range) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return history.where((h) {
      if (h.status != 'sent') return false;
      try {
        final date = DateTime.parse(h.sentAt);
        if (range == 'today') {
          return date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (range == 'week') {
          return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && date.isBefore(endOfWeek);
        } else if (range == 'month') {
          return date.year == now.year && date.month == now.month;
        }
      } catch (_) {}
      return false;
    }).length;
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textSecondary : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textSecondary : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, ReminderProvider provider) {
    final pendingAction = provider.reminders.where((r) => r.status == 'pending_approval').length;
    final scheduledCount = provider.reminders.where((r) => r.status == 'scheduled').length;

    final upcomingTomorrow = _countUpcoming(provider.reminders, 'tomorrow');
    final upcomingWeek = _countUpcoming(provider.reminders, 'week');
    final upcomingMonth = _countUpcoming(provider.reminders, 'month');

    final completedToday = _countCompleted(provider.history, 'today');
    final completedWeek = _countCompleted(provider.history, 'week');
    final completedMonth = _countCompleted(provider.history, 'month');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: provider.refreshAll,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 90.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Overview cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Pending Action',
                        value: pendingAction.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Scheduled Tasks',
                        value: scheduledCount.toString(),
                        icon: Icons.calendar_today_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                 // Upcoming Tasks stats
                Text(
                  'Upcoming Scheduled Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatMiniCard(
                        label: 'Tomorrow',
                        value: upcomingTomorrow.toString(),
                        icon: Icons.today_rounded,
                        color: Colors.orange,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatMiniCard(
                        label: 'This Week',
                        value: upcomingWeek.toString(),
                        icon: Icons.date_range_rounded,
                        color: Colors.cyan,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatMiniCard(
                        label: 'This Month',
                        value: upcomingMonth.toString(),
                        icon: Icons.calendar_month_rounded,
                        color: Colors.purple,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Completed Tasks stats
                Text(
                  'Completed Tasks Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatMiniCard(
                        label: 'Completed Today',
                        value: completedToday.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatMiniCard(
                        label: 'This Week',
                        value: completedWeek.toString(),
                        icon: Icons.playlist_add_check_rounded,
                        color: Colors.teal,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatMiniCard(
                        label: 'This Month',
                        value: completedMonth.toString(),
                        icon: Icons.assignment_turned_in_outlined,
                        color: Colors.blue,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 4. Approval Queue
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: const ApprovalList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingThemeButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const FloatingThemeButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Toggle Theme',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.black.withOpacity(0.3) 
              : Colors.white.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.12) 
                : Colors.black.withOpacity(0.06),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppTheme.primary).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return RotationTransition(
                      turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey<bool>(isDark),
                    color: isDark ? const Color(0xFFFCD34D) : AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
