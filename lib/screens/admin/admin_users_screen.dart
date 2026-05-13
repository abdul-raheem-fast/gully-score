import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Admin user list from app store (seeded + registered users).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final users = store.users;
    final currentUserId = SupabaseService.currentUser?.id ?? '';
    final visibleUsers = users.take(_visibleCount).toList();
    final hasMore = users.length > visibleUsers.length;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
        actions: [
          IconButton(
            onPressed: () async {
              await store.refreshUsers();
              if (!context.mounted) return;
              setState(() => _visibleCount = _pageSize);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Users refreshed')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.isLoadingUsers) const LinearProgressIndicator(minHeight: 2),
          if (store.usersLoadError != null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                store.usersLoadError!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleUsers.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i >= visibleUsers.length) {
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _visibleCount += _pageSize;
                        });
                      },
                      child: const Text('Load more'),
                    ),
                  );
                }
                final user = visibleUsers[i];
                return ListTile(
                  tileColor: C.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(user.name),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user.email}'),
                            const SizedBox(height: 8),
                            Text('Role: ${user.role.name.toUpperCase()}'),
                            const SizedBox(height: 16),
                            if (user.id.isNotEmpty && user.id != currentUserId)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final store = AppStore.of(context);
                                  Navigator.pop(context);

                                  final nextRole =
                                      user.role == UserRole.admin
                                          ? UserRole.player
                                          : UserRole.admin;
                                  try {
                                    await store.setUserRole(
                                      userId: user.id,
                                      role: nextRole,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Role updated to ${nextRole.name.toUpperCase()}.',
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Error updating role'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.admin_panel_settings,
                                    size: 18),
                                label: Text(
                                  user.role == UserRole.admin
                                      ? 'Remove Admin'
                                      : 'Make Admin',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            if (user.id.isNotEmpty && user.id != currentUserId)
                              const SizedBox(height: 10),
                            if (user.id.isNotEmpty && user.id != currentUserId)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final store = AppStore.of(context);
                                  Navigator.pop(context);

                                  final actionLabel = user.isBlocked
                                      ? 'Unblock user?'
                                      : 'Block user?';
                                  final actionText = user.isBlocked
                                      ? 'This will restore access for ${user.name}.'
                                      : 'This will block ${user.name} from the app.';
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(actionLabel),
                                      content: Text(actionText),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;

                                  try {
                                    if (user.isBlocked) {
                                      await store.unblockUser(user.id);
                                    } else {
                                      await store.blockUser(user.id);
                                    }
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          user.isBlocked
                                              ? 'User ${user.name} unblocked.'
                                              : 'User ${user.name} blocked.',
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Error updating user'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.block, size: 18),
                                label: Text(
                                  user.isBlocked
                                      ? 'Unblock User'
                                      : 'Block User',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: user.isBlocked
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close',
                                style: TextStyle(color: C.adminBlue)),
                          ),
                        ],
                      ),
                    );
                  },
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      if (user.isBlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'BLOCKED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    user.isBlocked ? 'Blocked' : user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isBlocked ? Colors.red : C.grey,
                      fontWeight: user.isBlocked ? FontWeight.w600 : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
