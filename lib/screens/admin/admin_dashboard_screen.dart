import 'package:flutter/material.dart';
import '../../route_paths.dart';
import '../../theme/app_theme.dart';

/// Admin dashboard — Sprint 1 prototype (Abdul Raheem)
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Admin panel'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile screen coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Overview', style: TextStyle(fontSize: 14, color: C.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(context, 'Users', '2.8K', C.adminBlue),
              const SizedBox(width: 12),
              _statCard(context, 'Matches', '24', C.g1),
              const SizedBox(width: 12),
              _statCard(context, 'Teams', '186', C.orange),
            ],
          ),
          const SizedBox(height: 28),
          Text('Manage', style: TextStyle(fontSize: 14, color: C.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _tile(context, Icons.people_outline, 'Users', 'View registered users', () {
            Navigator.pushNamed(context, RoutePaths.adminUsers);
          }),
          _tile(context, Icons.sports_cricket, 'Matches', 'Manage matches', () {
            Navigator.pushNamed(context, RoutePaths.adminMatches);
          }),
          _tile(context, Icons.groups_outlined, 'Teams', 'Manage teams', () {
            Navigator.pushNamed(context, RoutePaths.adminTeams);
          }),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: C.grey)),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: C.adminLight, child: Icon(icon, color: C.adminBlue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: C.grey)),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
