import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../route_paths.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {
    'total_users': 0,
    'total_teams': 0,
    'total_matches': 0,
  };
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final stats = await SupabaseService.fetchAdminDashboardStats();
    final logs = await SupabaseService.fetchAdminAuditLogs();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final name = store.userName.isNotEmpty ? store.userName : 'Admin User';
    final email = SupabaseService.currentUser?.email ?? 'admin@gullyscore.com';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Admin Hub', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.adminBlue))
          : RefreshIndicator(
              onRefresh: _refresh,
              color: C.adminBlue,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Profile Section ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                child: const Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, RoutePaths.adminEditProfile),
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Overview Section ──────────────────────────
                  _sectionTitle('Platform Overview'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Total Users',
                        count: _stats['total_users'].toString(),
                        icon: Icons.people_alt_rounded,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Total Teams',
                        count: _stats['total_teams'].toString(),
                        icon: Icons.shield_rounded,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    label: 'Matches Played',
                    count: _stats['total_matches'].toString(),
                    icon: Icons.sports_cricket_rounded,
                    color: Colors.green,
                    fullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // ── Management Section ──────────────────────────
                  _sectionTitle('Management'),
                  const SizedBox(height: 10),
                  _AdminTile(
                    label: 'Manage Users',
                    subtitle: 'Block/unblock players and admins',
                    icon: Icons.manage_accounts_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(context, RoutePaths.adminUsers),
                  ),
                  _AdminTile(
                    label: 'Manage Teams',
                    subtitle: 'Verify or disband teams',
                    icon: Icons.group_work_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, RoutePaths.adminTeams),
                  ),

                  const SizedBox(height: 24),

                  // ── Logs Section ───────────────────────────────
                  _sectionTitle('Recent Audit Logs'),
                  const SizedBox(height: 10),
                  if (_logs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No recent logs', style: TextStyle(color: C.grey)),
                      ),
                    )
                  else
                    ..._logs.take(5).map((log) => _LogTile(log: log)),

                  const SizedBox(height: 24),

                  // ── System Section ────────────────────────────
                  _sectionTitle('System'),
                  const SizedBox(height: 10),
                  _AdminTile(
                    label: 'Sign out',
                    subtitle: 'Return to login screen',
                    icon: Icons.logout_rounded,
                    color: Colors.red,
                    onTap: () async {
                      final store = AppStore.of(context);
                      await store.logout();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, RoutePaths.roleSelect, (r) => false);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: C.grey,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.dark)),
          Text(label, style: const TextStyle(fontSize: 12, color: C.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }
}

class _AdminTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: C.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: C.hint),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action']?.toString() ?? 'Action';
    final createdAt = DateTime.tryParse(log['created_at']?.toString() ?? '') ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: C.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: C.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.dark),
            ),
          ),
          Text(
            '${createdAt.day}/${createdAt.month}',
            style: const TextStyle(fontSize: 11, color: C.grey),
          ),
        ],
      ),
    );
  }
}