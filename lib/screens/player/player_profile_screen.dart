import 'package:flutter/material.dart';
import '../../models/player_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../route_paths.dart';
import '../../services/supabase_service.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = SupabaseService.fetchCurrentUserProfile();
    // Force a refresh of memberships to ensure owned teams show up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppStore.of(context).refreshMyMemberships();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const <String, dynamic>{};
        final dbName = (profile['name'] as String?)?.trim() ?? '';
        final name = dbName.isNotEmpty
            ? dbName
            : (store.userName.isEmpty ? 'Player' : store.userName);
        final email =
            ((profile['email'] as String?)?.trim().isNotEmpty ?? false)
                ? (profile['email'] as String).trim()
                : (SupabaseService.currentUser?.email ?? '—');
        final phone = (profile['phone'] as String?)?.trim();
        final role = (profile['playing_role'] as String?)?.trim();
        final org = (profile['organization'] as String?)?.trim();
        final initials = name
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();

        return Scaffold(
          backgroundColor: C.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statBadge('🏏', role?.isNotEmpty == true ? role! : 'Player'),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 14, color: Colors.white30),
                        const SizedBox(width: 10),
                        _statBadge('📍', org?.isNotEmpty == true ? org! : 'Pakistan'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _quickStat('Live', 'DB'),
                        _quickStat(email == '—' ? '—' : 'Yes', 'Email'),
                        _quickStat(role?.isNotEmpty == true ? 'Set' : '—', 'Role'),
                        _quickStat(phone?.isNotEmpty == true ? 'Set' : '—', 'Phone'),
                      ],
                    ),
                  ]),
                ),
              ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _section(context, 'Account', [
                  _tile(Icons.person_outline, 'Full Name', name),
                  _tile(Icons.email_outlined, 'Email', email),
                  _tile(Icons.phone_outlined, 'Phone', phone?.isNotEmpty == true ? phone! : 'Not set'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'Cricket Profile', [
                  _tile(Icons.sports_cricket_outlined, 'Playing Role', role?.isNotEmpty == true ? role! : 'Not set'),
                  _tile(Icons.business_outlined, 'Organization', org?.isNotEmpty == true ? org! : 'Not set'),
                  _tile(Icons.verified_user_outlined, 'Profile Source', 'Supabase'),
                ]),
                const SizedBox(height: 16),

                // ── My Teams Section ──────────────────────────────────
                _MyTeamsSection(),

                const SizedBox(height: 16),
                _section(context, 'General', [
                  _tile(Icons.shield_outlined, 'Privacy', 'Public profile'),
                  _tile(Icons.info_outline, 'App Version', '1.0.0'),
                ]),
                const SizedBox(height: 24),

                const SizedBox(height: 12),
                _HoverButton(
                  onTap: () {
                    AppStore.of(context).logout();
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
      },
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
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
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

// ── My Teams Section ─────────────────────────────────────────────
class _MyTeamsSection extends StatefulWidget {
  @override
  State<_MyTeamsSection> createState() => _MyTeamsSectionState();
}

class _MyTeamsSectionState extends State<_MyTeamsSection> {
  bool _showBrowser = false;
  List<TeamInfo> _allTeams = [];
  bool _loadingTeams = false;
  String? _teamError;

  @override
  void initState() {
    super.initState();
    _loadAllTeams();
  }

  Future<void> _loadAllTeams() async {
    setState(() {
      _loadingTeams = true;
      _teamError = null;
    });
    try {
      final teams = await SupabaseService.fetchTeams();
      if (!mounted) return;
      // Fallback: map from store's AdminTeam list if empty
      if (teams.isEmpty && mounted) {
        final store = AppStore.of(context);
        final fallback = store.teams
            .map((t) => TeamInfo(
                  id: t.id,
                  name: t.name,
                  abbreviation: t.abbreviation,
                  captain: t.captain,
                  playerCount: t.playerCount,
                  matchCount: t.matchCount,
                ))
            .toList();
        setState(() => _allTeams = fallback);
      } else {
        setState(() => _allTeams = teams);
      }
    } catch (_) {
      if (!mounted) return;
      // Use local seed as fallback
      final store = AppStore.of(context);
      final fallback = store.teams
          .map((t) => TeamInfo(
                id: t.id,
                name: t.name,
                abbreviation: t.abbreviation,
                captain: t.captain,
                playerCount: t.playerCount,
                matchCount: t.matchCount,
              ))
          .toList();
      setState(() {
        _allTeams = fallback;
        _teamError = _allTeams.isEmpty ? 'Could not load teams.' : null;
      });
    } finally {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final memberships = store.myMemberships;
    final myTeams =
        memberships.where((m) => m.status == MembershipStatus.approved).toList();
    final pending =
        memberships.where((m) => m.status == MembershipStatus.pending).toList();

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
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text('MY TEAMS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: C.grey,
                        letterSpacing: 1.1)),
              ),
              if (store.isLoadingMemberships)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              _SmallButton(
                label: _showBrowser ? 'Hide Teams' : 'Browse Teams',
                icon: _showBrowser ? Icons.close : Icons.search,
                onTap: () => setState(() => _showBrowser = !_showBrowser),
              ),
            ],
          ),
        ),

        if (store.membershipsLoadError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(store.membershipsLoadError!,
                style:
                    const TextStyle(color: Colors.red, fontSize: 12)),
          ),

        // ── Approved teams ──
        if (myTeams.isEmpty && pending.isEmpty && !store.isLoadingMemberships)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(children: const [
              Icon(Icons.groups_2_outlined, color: C.hint, size: 18),
              SizedBox(width: 8),
              Text('Not part of any team yet.',
                  style: TextStyle(color: C.grey, fontSize: 13)),
            ]),
          ),

        ...myTeams.map((m) => _MembershipTile(membership: m)),

        // ── Pending applications ──
        if (pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('PENDING APPLICATIONS',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: C.hint,
                    letterSpacing: 1)),
          ),
          ...pending.map((m) => _MembershipTile(membership: m)),
        ],

        // ── Team browser ──
        if (_showBrowser) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('ALL TEAMS',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: C.hint,
                    letterSpacing: 1)),
          ),
          if (_loadingTeams)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: C.g2)),
            )
          else if (_teamError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(_teamError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            )
          else if (_allTeams.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('No teams available.',
                  style: TextStyle(color: C.grey, fontSize: 13)),
            )
          else
            ..._allTeams.map((team) {
              final alreadyApplied =
                  memberships.any((m) => m.teamName == team.name);
              return _TeamBrowserTile(
                team: team,
                alreadyApplied: alreadyApplied,
                onApply: alreadyApplied
                    ? null
                    : () async {
                        await store.applyToTeam(team);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Applied to ${team.name}! Waiting for approval.'),
                              backgroundColor: C.g2,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          setState(() {}); // refresh applied state
                        }
                      },
              );
            }),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 4),
      ]),
    );
  }
}

// ── Membership tile (my team / pending) ──────────────────────────
class _MembershipTile extends StatelessWidget {
  final TeamMembership membership;
  const _MembershipTile({required this.membership});

  @override
  Widget build(BuildContext context) {
    final isApproved = membership.status == MembershipStatus.approved;
    final isPending = membership.status == MembershipStatus.pending;

    final statusColor = isApproved
        ? const Color(0xFF2E7D32)
        : isPending
            ? const Color(0xFFF57C00)
            : Colors.red.shade600;

    final statusLabel =
        isApproved ? 'Member' : isPending ? 'Pending' : 'Rejected';
    final statusIcon = isApproved
        ? Icons.check_circle_outline
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.cancel_outlined;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: statusColor.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withAlpha(40), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          // Abbreviation badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [C.g2, const Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(membership.teamAbbreviation,
                  style: const TextStyle(
                      color: C.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(membership.teamName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.dark)),
              Text(
                  'Applied ${_formatDate(membership.appliedAt)}',
                  style: const TextStyle(fontSize: 11, color: C.grey)),
            ]),
          ),
          Row(children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(statusLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ── Team browser tile ────────────────────────────────────────────
class _TeamBrowserTile extends StatefulWidget {
  final TeamInfo team;
  final bool alreadyApplied;
  final Future<void> Function()? onApply;
  const _TeamBrowserTile(
      {required this.team,
      required this.alreadyApplied,
      required this.onApply});

  @override
  State<_TeamBrowserTile> createState() => _TeamBrowserTileState();
}

class _TeamBrowserTileState extends State<_TeamBrowserTile> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: C.gLight.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.gLight, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          // Abbreviation badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: C.g2.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.g2.withAlpha(40)),
            ),
            child: Center(
              child: Text(widget.team.abbreviation,
                  style: const TextStyle(
                      color: C.g2,
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.team.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.dark)),
              Text(
                  '${widget.team.playerCount} players · ${widget.team.matchCount} matches',
                  style: const TextStyle(fontSize: 11, color: C.grey)),
            ]),
          ),
          const SizedBox(width: 8),
          if (widget.alreadyApplied)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: C.g2.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.g2.withAlpha(40)),
              ),
              child: const Text('Applied',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: C.g2)),
            )
          else if (_applying)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: C.g2))
          else
            GestureDetector(
              onTap: () async {
                setState(() => _applying = true);
                await widget.onApply?.call();
                if (mounted) setState(() => _applying = false);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Apply',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: C.white)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Small inline button ──────────────────────────────────────────
class _SmallButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  State<_SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<_SmallButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? C.g2 : C.g2.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.g2.withAlpha(60)),
          ),
          child: Row(children: [
            Icon(widget.icon,
                size: 13, color: _hovered ? C.white : C.g2),
            const SizedBox(width: 4),
            Text(widget.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hovered ? C.white : C.g2)),
          ]),
        ),
      ),
    );
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
