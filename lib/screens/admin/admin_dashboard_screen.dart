import 'package:flutter/material.dart';
import '../../route_paths.dart';
import '../../theme/app_theme.dart';

/// Admin dashboard — updated layout (Sprint 1+)
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminDashboardLayout();
  }
}

class _AdminDashboardLayout extends StatefulWidget {
  const _AdminDashboardLayout();

  @override
  State<_AdminDashboardLayout> createState() => _AdminDashboardLayoutState();
}

class _AdminDashboardLayoutState extends State<_AdminDashboardLayout> {
  _AdminNav _selected = _AdminNav.dashboard;
  bool _sidebarVisible = true;

  void _navigate(_AdminNav nav) {
    setState(() => _selected = nav);

    switch (nav) {
      case _AdminNav.dashboard:
        // already here
        break;
      case _AdminNav.matches:
        Navigator.pushNamed(context, RoutePaths.adminMatches);
        break;
      case _AdminNav.teams:
        Navigator.pushNamed(context, RoutePaths.adminTeams);
        break;
      case _AdminNav.players:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Players screen coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case _AdminNav.users:
        Navigator.pushNamed(context, RoutePaths.adminUsers);
        break;
      case _AdminNav.settings:
        Navigator.pushNamed(context, RoutePaths.adminSettings);
        break;
      case _AdminNav.reports:
        Navigator.pushNamed(context, RoutePaths.adminReports);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final showSidebar = c.maxWidth >= 980;
        final showSidebarNow = showSidebar && _sidebarVisible;
        final horizPad = c.maxWidth < 520 ? 14.0 : 22.0;
        final topPad = c.maxWidth < 520 ? 12.0 : 16.0;
        final bottomPad = c.maxWidth < 520 ? 14.0 : 22.0;

        Widget buildBody(BuildContext scaffoldContext) {
          return Row(
            children: [
              if (showSidebarNow)
                SizedBox(
                  width: 264,
                  child: _Sidebar(
                    selected: _selected,
                    onSelect: _navigate,
                  ),
                ),
              Expanded(
                child: Container(
                  color: C.bg,
                  child: SafeArea(
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(horizPad, topPad, horizPad, bottomPad),
                      child: _DashboardBody(
                        onMenuTap: () {
                          if (showSidebar) {
                            setState(() => _sidebarVisible = !_sidebarVisible);
                          } else {
                            Scaffold.of(scaffoldContext).openDrawer();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (showSidebar) {
          return Scaffold(
            body: Builder(builder: (scaffoldContext) => buildBody(scaffoldContext)),
          );
        }

        return Scaffold(
          drawer: Drawer(
            child: _Sidebar(
              selected: _selected,
              onSelect: (nav) {
                Navigator.pop(context);
                _navigate(nav);
              },
            ),
          ),
          body: Builder(builder: (scaffoldContext) => buildBody(scaffoldContext)),
        );
      },
    );
  }
}

enum _AdminNav { dashboard, matches, teams, players, users, settings, reports }

class _Sidebar extends StatelessWidget {
  final _AdminNav selected;
  final ValueChanged<_AdminNav> onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.g1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'GullyScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Color(0xFFBFE0C1),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.10)),
            const SizedBox(height: 8),

            // Scrollable nav area (prevents bottom overflow on short heights).
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 6),
                  _sectionLabel('MAIN'),
                  _navItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    active: selected == _AdminNav.dashboard,
                    onTap: () => onSelect(_AdminNav.dashboard),
                  ),
                  _navItem(
                    icon: Icons.sports_cricket_outlined,
                    label: 'Matches',
                    active: selected == _AdminNav.matches,
                    onTap: () => onSelect(_AdminNav.matches),
                  ),
                  _navItem(
                    icon: Icons.groups_outlined,
                    label: 'Teams',
                    active: selected == _AdminNav.teams,
                    onTap: () => onSelect(_AdminNav.teams),
                  ),
                  _navItem(
                    icon: Icons.person_outline,
                    label: 'Players',
                    active: selected == _AdminNav.players,
                    onTap: () => onSelect(_AdminNav.players),
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel('SYSTEM'),
                  _navItem(
                    icon: Icons.people_outline,
                    label: 'Users',
                    active: selected == _AdminNav.users,
                    onTap: () => onSelect(_AdminNav.users),
                  ),
                  _navItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    active: selected == _AdminNav.settings,
                    onTap: () => onSelect(_AdminNav.settings),
                  ),
                  _navItem(
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    active: selected == _AdminNav.reports,
                    onTap: () => onSelect(_AdminNav.reports),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F3E16),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Super Admin',
                          style: TextStyle(
                            color: Color(0xFFBFE0C1),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final bg = active ? Colors.white.withOpacity(0.14) : Colors.transparent;
    final fg = active ? Colors.white : Colors.white.withOpacity(0.78);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF84E18B),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const _DashboardBody({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final oneColCards = w < 620;
        final twoColCards = w >= 620 && w < 980;
        final cardWidth = oneColCards
            ? double.infinity
            : twoColCards
                ? (w - 14) / 2
                : 220.0;
        final twoCol = c.maxWidth >= 980;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onMenuTap: onMenuTap),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _KpiCard(
                    title: 'Total users',
                    value: '2,841',
                    sub: '+12% this week',
                    accent: C.g2,
                    width: cardWidth,
                  ),
                  _KpiCard(
                    title: 'Matches\nplayed',
                    value: '24',
                    sub: '+3 today',
                    accent: C.g2,
                    width: cardWidth,
                  ),
                  _KpiCard(
                    title: 'Active teams',
                    value: '186',
                    sub: '+8 this month',
                    accent: C.g2,
                    width: cardWidth,
                  ),
                  _KpiCard(
                    title: 'Live matches',
                    value: '3',
                    sub: '2 ending soon',
                    accent: Colors.red.shade600,
                    width: cardWidth,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!twoCol) ...const [
                _RecentMatchesCard(),
                SizedBox(height: 14),
                _TopTeamsCard(),
              ] else
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _RecentMatchesCard()),
                    SizedBox(width: 14),
                    Expanded(child: _TopTeamsCard()),
                  ],
                ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const _TopBar({this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 560;
        final isMid = w < 860;

        final title = Text(
          'Dashboard overview',
          style: TextStyle(
            fontSize: isNarrow ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: C.dark,
          ),
          overflow: TextOverflow.ellipsis,
        );

        final searchField = TextField(
          decoration: InputDecoration(
            hintText: isNarrow ? 'Search' : 'Search...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        );

        return Row(
          children: [
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: title),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    if (isMid)
                      Expanded(child: searchField)
                    else
                      SizedBox(width: 280, child: searchField),
                  ],
                ],
              ),
            ),
            if (isNarrow)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _iconBubble(
                  icon: Icons.search,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                ),
              ),
            _iconBubble(
              icon: Icons.mail_outline,
              dotColor: Colors.red.shade600,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inbox coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _avatar(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile screen coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _iconBubble({
    required IconData icon,
    required VoidCallback onTap,
    Color? dotColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Icon(icon, color: C.grey),
          ),
        ),
        if (dotColor != null)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _avatar({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: C.g1, shape: BoxShape.circle),
        child: const Center(
          child: Text(
            'AD',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color accent;
  final double width;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.accent,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: C.grey, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.2)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 28)),
          const SizedBox(height: 6),
          Text(sub, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _RecentMatchesCard extends StatelessWidget {
  const _RecentMatchesCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'RECENT MATCHES',
      trailing: TextButton(
        onPressed: () => Navigator.pushNamed(context, RoutePaths.adminMatches),
        child: const Text('See all'),
      ),
      child: Column(
        children: const [
          _MatchRow(teamA: 'Tigers', teamB: 'Lions', status: _RowStatus.live),
          _MatchRow(teamA: 'Hawks', teamB: 'Bulls', status: _RowStatus.live),
          _MatchRow(teamA: 'Stars', teamB: 'Rovers', status: _RowStatus.tomorrow),
          _MatchRow(teamA: 'Kings', teamB: 'Riders', status: _RowStatus.done),
          _MatchRow(teamA: 'Panthers', teamB: 'Wolves', status: _RowStatus.done),
        ],
      ),
    );
  }
}

class _TopTeamsCard extends StatelessWidget {
  const _TopTeamsCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'TOP TEAMS',
      trailing: TextButton(
        onPressed: () => Navigator.pushNamed(context, RoutePaths.adminTeams),
        child: const Text('See all'),
      ),
      child: Column(
        children: const [
          _TeamRow(code: 'TG', name: 'Tigers', wins: '18W', color: Color(0xFF1A5C20)),
          _TeamRow(code: 'LN', name: 'Lions', wins: '15W', color: Color(0xFF1A5C20)),
          _TeamRow(code: 'HK', name: 'Hawks', wins: '13W', color: Color(0xFFFF6B00)),
          _TeamRow(code: 'ST', name: 'Stars', wins: '11W', color: Color(0xFF7E57C2)),
          _TeamRow(code: 'KG', name: 'Kings', wins: '9W', color: Color(0xFFE53935)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget trailing;
  final Widget child;
  const _Panel({required this.title, required this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(color: C.grey.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.1)),
              const Spacer(),
              trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

enum _RowStatus { live, tomorrow, done }

class _MatchRow extends StatelessWidget {
  final String teamA;
  final String teamB;
  final _RowStatus status;
  const _MatchRow({required this.teamA, required this.teamB, required this.status});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (status) {
      _RowStatus.live => const Color(0xFF2E7D32),
      _RowStatus.tomorrow => C.orange,
      _RowStatus.done => Colors.black.withOpacity(0.18),
    };
    final chip = switch (status) {
      _RowStatus.live => _pill('Live', const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      _RowStatus.tomorrow => _pill('Tomorrow', const Color(0xFFFF6B00), const Color(0xFFFFF3E0)),
      _RowStatus.done => _pill('Done', const Color(0xFF757575), const Color(0xFFF1F3F4)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$teamA vs $teamB',
              style: const TextStyle(color: C.dark, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          chip,
        ],
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String code;
  final String name;
  final String wins;
  final Color color;
  const _TeamRow({
    required this.code,
    required this.name,
    required this.wins,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(code, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: C.dark, fontWeight: FontWeight.w800)),
          ),
          Text(wins, style: const TextStyle(color: C.grey, fontWeight: FontWeight.w800)),
          const SizedBox(width: 14),
          Container(
            width: 92,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 62,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
