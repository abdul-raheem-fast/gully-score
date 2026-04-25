import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Admin user list from app store (seeded + registered users).
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = AppStore.of(context).users;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final user = users[i];
          return ListTile(
            tileColor: C.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(user.email, style: TextStyle(fontSize: 12, color: C.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: C.gLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: C.g1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
