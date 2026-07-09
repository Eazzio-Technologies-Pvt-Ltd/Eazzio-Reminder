import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/reminder_provider.dart';
import '../theme.dart';
import '../widgets/custom_graphics.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReminderProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final members = provider.teamMembers;
    final incoming = provider.incomingRequests;
    final outgoing = provider.outgoingRequests;

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
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
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
                      Text(
                        'Team Management',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppTheme.textSecondaryLightMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Collaborate with colleagues and assign tasks directly to their reminder apps.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textSecondaryLightMode,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mode warning banner
                  if (provider.appMode == 'local')
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Collaboration is running in Demo mode because Standalone (Local) mode is active. Switch to Server-Connected mode in settings to connect with real users.',
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Search Section
                  Text(
                    'Add Team Members',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by Gmail/email ID...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                          onSubmitted: (val) => _performSearch(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _performSearch(_searchController.text),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Results
                  if (_isSearching)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  else if (_searchError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_searchError, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                    )
                  else if (_searchResults.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final userEmail = user['email'] ?? '';
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.12),
                              child: Text(user['name']?[0]?.toUpperCase() ?? 'U', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(user['name'] ?? ''),
                            subtitle: Text(userEmail),
                            trailing: ElevatedButton(
                              onPressed: () => _sendInvite(userEmail),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Invite'),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // Pending Requests Section
                  if (incoming.isNotEmpty || outgoing.isNotEmpty) ...[
                    Text(
                      'Pending Invites',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    // Incoming requests
                    ...incoming.map((req) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(req['name'] ?? ''),
                          subtitle: Text('Incoming request (${req['email'] ?? req['phone'] ?? ''})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: AppTheme.success),
                                onPressed: () => _respondRequest(req['id'], 'accepted'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.danger),
                                onPressed: () => _respondRequest(req['id'], 'rejected'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Outgoing requests
                    ...outgoing.map((req) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(req['name'] ?? ''),
                          subtitle: Text('Sent request (${req['email'] ?? req['phone'] ?? ''})'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ],

                  // Team members list
                  Text(
                    'My Team Members',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  if (members.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0x11FFFFFF) : Colors.black.withOpacity(0.05)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No team members yet', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Search by Gmail to invite team members and start assigning tasks.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: Text(
                                member['name']?[0]?.toUpperCase() ?? 'M',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(member['name'] ?? ''),
                            subtitle: Text(member['email'] ?? member['phone'] ?? ''),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Connected',
                                style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
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

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final provider = Provider.of<ReminderProvider>(context, listen: false);
      if (provider.appMode == 'local') {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() {
          _searchResults = [
            {'id': 102, 'name': 'Sagar Choubey', 'email': query.trim(), 'phone': '7200000000'}
          ];
          _isSearching = false;
        });
        return;
      }

      final apiBaseUrl = provider.apiBaseUrl;
      final uri = Uri.parse('$apiBaseUrl/users/search?query=${Uri.encodeComponent(query)}');
      final res = await http.get(uri);
      
      if (res.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(res.body) as List<dynamic>;
          _isSearching = false;
        });
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      setState(() {
        _searchError = 'User search failed or no user matches.';
        _isSearching = false;
      });
    }
  }

  void _sendInvite(String email) async {
    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (provider.appMode == 'local') {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Mock invite sent successfully! (Local mode)'), backgroundColor: AppTheme.success),
        );
        setState(() {
          _searchResults = [];
          _searchController.clear();
        });
        return;
      }

      await provider.sendTeamRequest(email);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Team invite sent successfully!'), backgroundColor: AppTheme.success),
      );
      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to invite user: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _respondRequest(int requestId, String status) async {
    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (provider.appMode == 'local') {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Mock request $status!'), backgroundColor: AppTheme.success),
        );
        return;
      }

      await provider.respondToTeamRequest(requestId, status);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Request successfully $status!'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to respond request: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }
}
