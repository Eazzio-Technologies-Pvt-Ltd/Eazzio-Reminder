import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder.dart';
import '../theme.dart';
import 'log_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'sent', 'failed', 'rejected'
  String _selectedType = 'all'; // 'all', 'whatsapp', 'call', 'sms', 'notification'

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
      _selectedType = 'all';
    });
  }

  void _confirmClearHistory(BuildContext context, ReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Outbox History?'),
        content: const Text(
          'Are you sure you want to permanently clear all records from your outbox logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.clearHistory().catchError((err) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear outbox: $err'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReminderProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter logs
    final filteredHistory = provider.history.where((log) {
      // 1. Pill Status Filter
      if (_selectedStatus == 'sent') {
        if (log.status != 'sent') return false;
      } else if (_selectedStatus == 'failed') {
        if (log.status != 'failed' && log.status != 'rejected') return false;
      } else if (_selectedStatus == 'pending') {
        if (log.status != 'pending_approval' && log.status != 'sending') return false;
      }

      // 2. Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final name = log.recipientName.toLowerCase();
        final phone = log.recipientPhone.toLowerCase();
        final status = log.status.toLowerCase();
        final type = log.reminderType.toLowerCase();
        final details = (log.details ?? '').toLowerCase();

        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            status.contains(_searchQuery) ||
            type.contains(_searchQuery) ||
            details.contains(_searchQuery);
      }

      return true;
    }).toList();

    // Stats calculations for filtered or general history
    final totalCount = provider.history.length;
    final sentCount = provider.history.where((h) => h.status == 'sent').length;
    final failedCount = provider.history.where((h) => h.status == 'failed' || h.status == 'rejected').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: provider.refreshAll,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width < 400 ? 12.0 : 24.0,
            right: MediaQuery.of(context).size.width < 400 ? 12.0 : 24.0,
            top: 32.0,
            bottom: 40.0,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Header
                  FadeInSlide(
                    delay: Duration.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Outbox & Logs Audit',
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
                            ),
                            if (provider.history.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _confirmClearHistory(context, provider),
                                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.danger),
                                label: const Text('Clear All', style: TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A comprehensive historical log of all dispatched reminders, calls, SMS and notifications.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppTheme.textSecondaryLightMode,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mini Stats Bar for History Page
                  FadeInSlide(
                    delay: const Duration(milliseconds: 100),
                    child: _buildHistoryStats(totalCount, sentCount, failedCount),
                  ),
                  const SizedBox(height: 24),

                  // Search and Filters Area
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: _buildFilterSection(isDark, theme),
                  ),
                  const SizedBox(height: 20),

                  // Active Filter Info & Logs List or Empty State
                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isNotEmpty || _selectedStatus != 'all' || _selectedType != 'all')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${filteredHistory.length} of $totalCount historical records',
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
                        if (filteredHistory.isEmpty)
                          _buildEmptyState(theme, isDark)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final log = filteredHistory[index];
                              return FadeInSlide(
                                delay: Duration(milliseconds: index * 50),
                                duration: const Duration(milliseconds: 350),
                                child: _buildHistoryRow(context, log),
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

  Widget _buildHistoryStats(int total, int sent, int failed) {
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
              isNarrow ? 'Total Outbox' : 'Total Outbox Logged',
              total.toString(),
              Icons.history,
              AppTheme.primaryGradient,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: item(
              isNarrow ? 'Successful' : 'Dispatched Successfully',
              sent.toString(),
              Icons.check_circle_outline,
              const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: item(
              isNarrow ? 'Failed' : 'Failed or Rejected',
              failed.toString(),
              Icons.error_outline,
              const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFEF4444)]),
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
            hintText: 'Search logs...',
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
              _buildFilterPill('sent', 'Sent', theme, isDark),
              _buildFilterPill('failed', 'Failed', theme, isDark),
              _buildFilterPill('pending', 'Pending', theme, isDark),
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
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'No matching logs found',
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

  Widget _buildHistoryRow(BuildContext context, ReminderLog log) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData eventIcon = Icons.notifications;
    Color eventColor = AppTheme.primary;
    if (log.eventType == 'birthday') {
      eventIcon = Icons.cake_rounded;
      eventColor = Colors.orange;
    } else if (log.eventType == 'anniversary') {
      eventIcon = Icons.favorite_rounded;
      eventColor = Colors.pink;
    } else if (log.eventType == 'fee') {
      eventIcon = Icons.monetization_on_rounded;
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
                builder: (context) => LogDetailsScreen(log: log),
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
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.recipientName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.recipientPhone,
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sent • $formattedTime',
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  _buildStatusBadge(log.status, statusColor, statusIcon),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
