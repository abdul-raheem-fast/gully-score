import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/player_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../route_paths.dart';
import 'player_matches_screen.dart';
import 'player_stats_screen.dart';
import 'player_profile_screen.dart';
import 'my_teams_screen.dart';


class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _tab = 0;

  final _tabs = const [
    _DashboardTab(),
    PlayerMatchesScreen(),
    PlayerStatsScreen(),
    PlayerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.sports_cricket_outlined, Icons.sports_cricket, 'Matches'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              // Score FAB in centre gap
              if (i == 2) {
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => onTap(i),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: C.g1,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: C.g1.withAlpha(90),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            current == i
                                ? _items[i].activeIcon
                                : _items[i].icon,
                            color: C.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: current == i ? C.g1 : C.hint,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Expanded(
                child: _NavTile(
                  item: _items[i],
                  selected: current == i,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            selected ? item.activeIcon : item.icon,
            key: ValueKey(selected),
            color: selected ? C.g1 : C.hint,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        if (selected)
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: C.g1,
              shape: BoxShape.circle,
            ),
          )
        else
          Text(
            item.label,
            style: const TextStyle(fontSize: 10, color: C.hint),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DASHBOARD TAB
// ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final name = store.userName.isEmpty ? 'Player' : store.userName;
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    final live = _deriveLiveMatch(store);
    final recent = _deriveRecentMatches(store);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                                fontSize: 14,
                                color: C.grey,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: C.dark,
                                letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: C.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          size: 21, color: C.dark),
                    ),
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: C.g1,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                              color: C.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Live Match Card ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: _LiveMatchCard(match: live),
              ),
            ),

            // ── Quick Actions ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: _QuickActions(
                  onNewMatch: () => ScaffoldMessenger.of(context).showSnackBar(
                    _snack('New Match — coming soon'),
                  ),
                  onMyTeams: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyTeamsScreen()),
                  ),
                  onAnalytics: () =>
                      ScaffoldMessenger.of(context).showSnackBar(
                    _snack('Analytics — coming soon'),
                  ),
                  onRankings: () => ScaffoldMessenger.of(context).showSnackBar(
                    _snack('Rankings — coming soon'),
                  ),
                ),
              ),
            ),

            // ── Recent Matches header ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Matches',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: C.dark),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'View All',
                        style: TextStyle(
                            color: C.g2,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recent Match cards ──────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, i == recent.length - 1 ? 24 : 12),
                  child: _MatchCard(match: recent[i]),
                ),
                childCount: recent.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LiveMatch _deriveLiveMatch(AppStoreState store) {
    final liveMatch = store.matches
        .where((m) => m.status == MatchStatus.live)
        .cast<AdminMatch>()
        .toList();
    if (liveMatch.isNotEmpty) {
      final m = liveMatch.first;
      return LiveMatch(
        teamA: m.teamA,
        teamAbbr: _abbr(m.teamA),
        teamB: m.teamB,
        teamBAbbr: _abbr(m.teamB),
        scoreA: m.scoreA,
        scoreB: m.scoreB,
        oversA: 'Live',
        oversB: 'Live',
        targetOvers: 'TBD',
        chaseInfo: '${m.teamA} vs ${m.teamB} in progress',
      );
    }
    return const LiveMatch(
      teamA: 'No Live Match',
      teamAbbr: '--',
      teamB: 'Check Back Soon',
      teamBAbbr: '--',
      scoreA: '0/0',
      scoreB: '0/0',
      oversA: '0.0 Overs',
      oversB: '0.0 Overs',
      targetOvers: 'TBD',
      chaseInfo: 'No active match right now',
    );
  }

  List<PlayerMatch> _deriveRecentMatches(AppStoreState store) {
    final matches = store.matches.take(3).toList();
    if (matches.isEmpty) return const [];
    return matches.map((m) {
      final result =
          m.status == MatchStatus.completed ? MatchResult.won : MatchResult.draw;
      return PlayerMatch(
        id: m.id,
        myTeam: m.teamA,
        myTeamAbbr: _abbr(m.teamA),
        opponent: m.teamB,
        opponentAbbr: _abbr(m.teamB),
        myTeamScore: m.scoreA,
        opponentScore: m.scoreB,
        overs: 'TBD',
        result: result,
        summary: '${m.teamA} vs ${m.teamB} at ${m.venue}',
        date: m.date,
        format: 'League',
      );
    }).toList();
  }

  String _abbr(String team) {
    final words = team
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    if (words.length >= 2) return words;
    final cleaned = team.trim().toUpperCase();
    return cleaned.length >= 2 ? cleaned.substring(0, 2) : cleaned;
  }

  SnackBar _snack(String msg) => SnackBar(
        content: Text(msg),
        backgroundColor: C.g2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

// ─────────────────────────────────────────────────────────────
//  LIVE MATCH CARD
// ─────────────────────────────────────────────────────────────
class _LiveMatchCard extends StatefulWidget {
  final LiveMatch match;
  const _LiveMatchCard({required this.match});

  @override
  State<_LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<_LiveMatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5C20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: C.g1.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: LIVE MATCH  •  LIVE dot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE MATCH',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4),
              ),
              Row(children: [
                FadeTransition(
                  opacity: _blink,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF4444), shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE',
                    style: TextStyle(
                        color: Color(0xFFFF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ]),
            ],
          ),

          const SizedBox(height: 20),

          // Score row
          Row(
            children: [
              // Team A
              Expanded(
                child: Column(children: [
                  // Abbr circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text(m.teamAbbr,
                          style: const TextStyle(
                              color: C.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(m.teamA,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(m.scoreA,
                      style: const TextStyle(
                          color: C.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                  Text(m.oversA,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ]),
              ),

              // VS
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(children: [
                  const Text('VS',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(m.targetOvers,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ]),
              ),

              // Team B
              Expanded(
                child: Column(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text(m.teamBAbbr,
                          style: const TextStyle(
                              color: C.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(m.teamB,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(m.scoreB,
                      style: const TextStyle(
                          color: C.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                  Text(m.oversB,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ]),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chase info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.chaseInfo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: C.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  QUICK ACTIONS GRID
// ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onNewMatch, onMyTeams, onAnalytics, onRankings;
  const _QuickActions({
    required this.onNewMatch,
    required this.onMyTeams,
    required this.onAnalytics,
    required this.onRankings,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _QA(Icons.add_circle_outline_rounded, 'New\nMatch', onNewMatch),
      _QA(Icons.group_outlined, 'My\nTeams', onMyTeams),
      _QA(Icons.stacked_line_chart_rounded, 'Analytics', onAnalytics),
      _QA(Icons.star_border_rounded, 'Rankings', onRankings),
    ];
    return Row(
      children: items
          .map((q) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: q == items.last ? 0 : 10),
                  child: _QuickActionTile(item: q),
                ),
              ))
          .toList(),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QA(this.icon, this.label, this.onTap);
}

class _QuickActionTile extends StatefulWidget {
  final _QA item;
  const _QuickActionTile({required this.item});
  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.item.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: C.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: C.gLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child:
                  Icon(widget.item.icon, color: C.g2, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              widget.item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: C.dark,
                  height: 1.3),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RECENT MATCH CARD
// ─────────────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final PlayerMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final won = match.result == MatchResult.won;
    final resultColor = won ? C.g2 : const Color(0xFFD32F2F);
    final resultBg = won ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final resultLabel = won ? 'WON' : (match.result == MatchResult.lost ? 'LOST' : 'DRAW');
    final dateStr =
        '${_monthName(match.date.month)} ${match.date.day}, ${match.date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date / format row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dateStr  •  ${match.format}',
                style: const TextStyle(fontSize: 11.5, color: C.grey),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resultBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resultLabel,
                  style: TextStyle(
                      color: resultColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Teams row
          Row(
            children: [
              // My team
              _TeamChip(abbr: match.myTeamAbbr, name: match.myTeam),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('vs',
                    style: TextStyle(
                        color: C.hint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              // Scores
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(match.myTeamScore,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: C.dark)),
                  const SizedBox(height: 2),
                  Text(match.opponentScore,
                      style:
                          const TextStyle(fontSize: 12, color: C.grey)),
                ]),
              ),
              _TeamChip(abbr: match.opponentAbbr, name: match.opponent),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),

          // Summary
          Text(
            match.summary,
            style: TextStyle(
                color: resultColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][month];
}

class _TeamChip extends StatelessWidget {
  final String abbr, name;
  const _TeamChip({required this.abbr, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: C.gLight,
          shape: BoxShape.circle,
          border: Border.all(color: C.g2.withAlpha(60), width: 1.2),
        ),
        child: Center(
          child: Text(abbr,
              style: const TextStyle(
                  color: C.g2,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 6),
      Text(name,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: C.dark)),
    ]);
  }
}
