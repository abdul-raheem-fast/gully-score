import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Admin user list — Sprint 1 prototype (dummy data)
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const _rows = [
    ('Ali Hassan', 'ali@gullyscore.com', 'Active'),
    ('Saif Ahmed', 'saif@gullyscore.com', 'Active'),
    ('Kamran Shah', 'kamran@gullyscore.com', 'Active'),
    ('Zain M.', 'zain@gullyscore.com', 'Suspended'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final r = _rows[i];
          final ok = r.$3 == 'Active';
          return ListTile(
            tileColor: C.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(r.$2, style: TextStyle(fontSize: 12, color: C.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ok ? C.gLight : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ok ? C.g1 : Colors.red.shade700)),
            ),
          );
        },
      ),
    );
  }
}
