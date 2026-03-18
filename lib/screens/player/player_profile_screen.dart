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
          // ── Hero header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                // Avatar with glow ring
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white38, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: C.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(name,
                    style: const TextStyle(
                        color: C.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statBadge('🏏', 'Batsman'),
                    const SizedBox(width: 10),
                    Container(
                        width: 1, height: 14, color: Colors.white30),
                    const SizedBox(width: 10),
                    _statBadge('⭐', 'Street Stars'),
                    const SizedBox(width: 10),
                    Container(
                        width: 1, height: 14, color: Colors.white30),
                    const SizedBox(width: 10),
                    _statBadge('📍', 'Lahore'),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick stat pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickStat('347', 'Runs'),
                    _quickStat('12', 'Matches'),
                    _quickStat('58.2', 'Avg'),
                    _quickStat('2', 'Fifties'),
                  ],
                ),
              ]),
            ),
          ),

          // ── Profile info tiles ────────────────────────────────────
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
                  _tile(Icons.sports_cricket_outlined, 'Playing Role',
                      'Batsman'),
                  _tile(Icons.groups_2_outlined, 'Team', 'Street Stars'),
                  _tile(Icons.emoji_events_outlined, 'Jersey No.', '#10'),
                  _tile(Icons.location_on_outlined, 'City', 'Lahore, Pakistan'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'General', [
                  _tile(Icons.notifications_outlined, 'Notifications', 'On'),
                  _tile(Icons.shield_outlined, 'Privacy', 'Public profile'),
                  _tile(Icons.info_outline, 'App Version', '1.0.0'),
                ]),
                const SizedBox(height: 24),

                // ── Edit Profile button ──────────────────────────
                _HoverButton(
                  onTap: () {},
                  filled: true,
                  color: C.g2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit_outlined, color: C.white, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Profile',
                          style: TextStyle(
                              color: C.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Logout button ──────────────────────────────
                _HoverButton(
                  onTap: () {
                    store.logout();
                    Navigator.pushReplacementNamed(
                        context, RoutePaths.roleSelect);
                  },
                  filled: false,
                  color: Colors.red.shade400,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text('Log Out',
                          style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String emoji, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _quickStat(String value, String label) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: C.white, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: C.grey,
                  letterSpacing: 1.1)),
        ),
        ...children,
      ]),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return _HoverTile(icon: icon, label: label, value: value);
  }
}

// ── Hoverable press-down tile ─────────────────────────────────
class _HoverTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HoverTile(
      {required this.icon, required this.label, required this.value});

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: _hovered ? C.gLight.withAlpha(80) : Colors.transparent,
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hovered ? C.g2.withAlpha(25) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon,
                color: _hovered ? C.g2 : C.grey, size: 18),
          ),
          title: Text(widget.label,
              style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? C.g2 : C.grey,
                  fontWeight: FontWeight.w500)),
          trailing: Text(widget.value,
              style: const TextStyle(
                  fontSize: 13.5,
                  color: C.dark,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── Hoverable press-down button ────────────────────────────────
class _HoverButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool filled;
  final Color color;
  const _HoverButton(
      {required this.onTap,
      required this.child,
      required this.filled,
      required this.color});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap();
        },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: widget.filled
                  ? (_hovered
                      ? widget.color.withAlpha(220)
                      : widget.color)
                  : (_hovered ? widget.color.withAlpha(20) : Colors.transparent),
              border: Border.all(color: widget.color, width: 1.5),
              borderRadius: BorderRadius.circular(14),
              boxShadow: widget.filled && _hovered
                  ? [
                      BoxShadow(
                          color: widget.color.withAlpha(60),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
