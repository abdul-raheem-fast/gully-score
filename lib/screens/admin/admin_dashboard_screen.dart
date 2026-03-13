import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'admin_users_screen.dart';
import 'admin_matches_screen.dart';
import 'admin_teams_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatCards(),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildRecentActivity(),
              const SizedBox(height: 24),
              _buildSystemHealth(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.notifications_outlined, color: AppColors.textPrimary)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
                boxShadow: [BoxShadow(color: const Color(0xFF7B1FA2).withOpacity(0.3), blurRadius: 12)],
              ),
              child: const Center(child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 24)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final stats = [
      {'title': 'Total Users', 'value': '2,847', 'change': '+12.5%', 'icon': Icons.people, 'color': AppColors.primary, 'bg': const Color(0xFFE8F5E9)},
      {'title': 'Active Matches', 'value': '23', 'change': '+3 today', 'icon': Icons.sports_cricket, 'color': AppColors.accent, 'bg': const Color(0xFFFFF3E0)},
      {'title': 'Teams', 'value': '186', 'change': '+8 this week', 'icon': Icons.groups, 'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD)},
      {'title': 'Revenue', 'value': 'Rs 45K', 'change': '+18.2%', 'icon': Icons.trending_up, 'color': const Color(0xFF7B1FA2), 'bg': const Color(0xFFF3E5F5)},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: stats.map((s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: s['bg'] as Color, borderRadius: BorderRadius.circular(12)),
                  child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                  child: Text(s['change'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['value'] as String, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: s['color'] as Color)),
                Text(s['title'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.people, 'label': 'Users', 'color': AppColors.primary, 'route': AdminUsersScreen()},
      {'icon': Icons.sports_cricket, 'label': 'Matches', 'color': AppColors.accent, 'route': AdminMatchesScreen()},
      {'icon': Icons.groups, 'label': 'Teams', 'color': const Color(0xFF1565C0), 'route': AdminTeamsScreen()},
      {'icon': Icons.flag, 'label': 'Reports', 'color': const Color(0xFF7B1FA2), 'route': null},
      {'icon': Icons.block, 'label': 'Ban User', 'color': AppColors.danger, 'route': null},
      {'icon': Icons.settings, 'label': 'Settings', 'color': AppColors.textSecondary, 'route': null},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: actions.map((a) => GestureDetector(
            onTap: () {
              if (a['route'] != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => a['route'] as Widget));
              }
            },
            child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (a['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(a['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'action': 'New user registered', 'detail': 'Hamza Ali joined Street Stars', 'time': '2 min ago', 'icon': Icons.person_add, 'color': AppColors.primary},
      {'action': 'Match completed', 'detail': 'SS vs GW - Street Stars won', 'time': '15 min ago', 'icon': Icons.sports_score, 'color': AppColors.accent},
      {'action': 'Team created', 'detail': 'Park XI registered with 11 players', 'time': '1 hour ago', 'icon': Icons.group_add, 'color': const Color(0xFF1565C0)},
      {'action': 'Report flagged', 'detail': 'Match #247 flagged for review', 'time': '3 hours ago', 'icon': Icons.flag, 'color': AppColors.danger},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: (a['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20),
                    ),
                    title: Text(a['action'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(a['detail'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Text(a['time'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (i < activities.length - 1) Divider(height: 1, indent: 72, color: AppColors.border.withOpacity(0.5)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _healthItem('Server', '99.8%', Icons.cloud_done, Colors.greenAccent),
                  _healthItem('Database', '98.5%', Icons.storage, Colors.greenAccent),
                  _healthItem('API', '99.9%', Icons.api, Colors.greenAccent),
                  _healthItem('CDN', '97.2%', Icons.public, Colors.amberAccent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _healthItem(String label, String value, IconData icon, Color statusColor) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: statusColor)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}
