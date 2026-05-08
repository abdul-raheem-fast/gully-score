import 'package:flutter/material.dart';

import '../../route_paths.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final currentUser = SupabaseService.currentUser;
    final name = store.userName.isNotEmpty
        ? store.userName
        : SupabaseService.getCurrentUserName() ?? 'Admin User';
    final email = currentUser?.email ?? 'admin@unknown.com';
    final role = SupabaseService.getCurrentUserRole() ?? 'admin';
    final organization = currentUser?.userMetadata?['organization']?.toString() ?? 'GullyScore';
    final initials = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: C.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: C.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Administrator',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _profileChip('Role', role.toUpperCase()),
                      const SizedBox(width: 10),
                      _profileChip('Org', organization),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _section('Account', [
                    _infoTile(Icons.person_outline, 'Name', name),
                    _infoTile(Icons.email_outlined, 'Email', email),
                    _infoTile(Icons.admin_panel_settings_outlined, 'Role', 'Admin'),
                    _infoTile(Icons.business_outlined, 'Organization', organization),
                  ]),
                  const SizedBox(height: 16),
                  _section('Access', [
                    _infoTile(Icons.shield_outlined, 'Admin level', 'Full access'),
                    _infoTile(Icons.security_outlined, 'Permissions', 'Manage matches, teams, users'),
                    _infoTile(Icons.settings_outlined, 'App version', '1.0.0'),
                  ]),
                  const SizedBox(height: 16),
                  _actionButton(
                    context,
                    label: 'Edit profile',
                    icon: Icons.edit_outlined,
                    filled: true,
                    onTap: () {
                      Navigator.pushNamed(context, RoutePaths.adminEditProfile);
                    },
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    context,
                    label: 'Sign out',
                    icon: Icons.logout,
                    filled: false,
                    color: Colors.red.shade600,
                    onTap: () async {
                      await store.logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, RoutePaths.roleSelect);
                    },
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: C.grey, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: C.gLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: C.g1, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: C.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(color: C.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool filled,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? (color ?? C.adminBlue) : C.white,
          foregroundColor: filled ? C.white : (color ?? C.adminBlue),
          side: filled
              ? null
              : BorderSide(color: color ?? C.adminBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
