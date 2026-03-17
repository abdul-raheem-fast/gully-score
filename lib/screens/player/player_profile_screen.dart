import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../route_paths.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final name = store.userName.isEmpty ? 'Player' : store.userName;
    final initials =
        name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Avatar + name header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A5C20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                // Avatar
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(30),
                    border: Border.all(color: Colors.white38, width: 2.5),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: C.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name,
                    style: const TextStyle(
                        color: C.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('🏏 Street Stars  •  Batsman',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ),

          // Profile info tiles
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _section(context, 'Account', [
                  _tile(Icons.person_outline, 'Full Name', name),
                  _tile(Icons.email_outlined, 'Email', 'player@gmail.com'),
                  _tile(Icons.phone_outlined, 'Phone', '+92 300 0000000'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'Cricket Profile', [
                  _tile(Icons.sports_cricket_outlined, 'Playing Role', 'Batsman'),
                  _tile(Icons.groups_2_outlined, 'Team', 'Street Stars'),
                  _tile(Icons.location_on_outlined, 'City', 'Lahore, Pakistan'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'General', [
                  _tile(Icons.notifications_outlined, 'Notifications', 'On'),
                  _tile(Icons.shield_outlined, 'Privacy', 'Public profile'),
                  _tile(Icons.info_outline, 'App Version', '1.0.0'),
                ]),
                const SizedBox(height: 24),

                // Logout
                GestureDetector(
                  onTap: () {
                    store.logout();
                    Navigator.pushReplacementNamed(
                        context, RoutePaths.roleSelect);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.red.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Log Out',
                              style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ]),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: C.grey,
                  letterSpacing: 0.8)),
        ),
        ...children,
      ]),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: C.g2, size: 21),
      title: Text(label,
          style: const TextStyle(
              fontSize: 13, color: C.grey, fontWeight: FontWeight.w400)),
      trailing: Text(value,
          style: const TextStyle(
              fontSize: 13.5,
              color: C.dark,
              fontWeight: FontWeight.w600)),
    );
  }
}
