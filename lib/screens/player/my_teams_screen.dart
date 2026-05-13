import 'package:flutter/material.dart';
import '../../models/player_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../route_paths.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── All-teams browser ──
  List<TeamInfo> _allTeams = [];
  bool _loadingTeams = true;
  String? _teamsError;
  String _search = '';

  // ── Roster (team_players) ──
  List<String> _rosterTeamNames = [];
  bool _loadingRoster = true;

  // ── Captain panel ──
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loadingRequests = true;
  bool _isCaptain = false;

  int _unreadCount = 0;
  bool _membershipsBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAllTeams();
    _loadCaptainData();
    _loadRosterTeams();
    _loadUnreadCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_membershipsBootstrapped) return;
    _membershipsBootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppStore.of(context).refreshMyMemberships();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Data loaders ────────────────────────────────────────────
  Future<void> _loadAllTeams() async {
    setState(() {
      _loadingTeams = true;
      _teamsError = null;
    });
    try {
      final teams = await SupabaseService.fetchTeamsCatalog();
      if (!mounted) return;
      setState(() => _allTeams = teams);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allTeams = [];
        _teamsError = 'Could not load teams from server.';
      });
    } finally {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  Future<void> _loadCaptainData() async {
    setState(() => _loadingRequests = true);
    try {
      final captainTeams = await SupabaseService.fetchCaptainTeams();
      if (!mounted) return;
      final isCap = captainTeams.isNotEmpty;
      if (isCap) {
        final requests =
            await SupabaseService.fetchPendingRequestsForCaptain(captainTeams);
        if (!mounted) return;
        setState(() {
          _isCaptain = true;
          _pendingRequests = requests;
        });
      } else {
        setState(() {
          _isCaptain = false;
          _pendingRequests = [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _loadRosterTeams() async {
    setState(() => _loadingRoster = true);
    try {
      final names = await SupabaseService.fetchTeamNamesWhereIAmRosterPlayer();
      if (!mounted) return;
      setState(() => _rosterTeamNames = names);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRoster = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await SupabaseService.fetchUnreadNotificationCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _refreshMemberships() async {
    await AppStore.of(context).refreshMyMemberships();
  }

  Future<void> _openTeamSquadSheet(String teamName) async {
    final squad = await SupabaseService.fetchTeamSquad(teamName);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TeamSquadSheet(teamName: teamName, squad: squad),
    );
  }

  // ── Approve / Reject ─────────────────────────────────────────
  Future<void> _updateRequest(String id, String status) async {
    try {
      await SupabaseService.updateMembershipStatus(id: id, status: status);
      setState(() =>
          _pendingRequests.removeWhere((r) => r['id'].toString() == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          status == 'approved' ? '✅ Request approved!' : '❌ Request rejected.',
          status == 'approved' ? C.g2 : Colors.red.shade600,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snack('Action failed. Try again.', Colors.red.shade600));
      }
    }
  }

  SnackBar _snack(String msg, Color color) => SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final memberships = store.myMemberships;
    final approvedMemberships = memberships
        .where((m) => m.status == MembershipStatus.approved)
        .toList();
    final approvedNames = approvedMemberships.map((m) => m.teamName).toSet();
    final rosterOnly =
        _rosterTeamNames.where((n) => !approvedNames.contains(n)).toList();
    final applications = memberships
        .where((m) => m.status != MembershipStatus.approved)
        .toList();
    final myTeamsTabBadge = approvedMemberships.length + rosterOnly.length;

    return Scaffold(
      backgroundColor: C.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, RoutePaths.createTeam);
          if (created == true) {
            _loadCaptainData();
            _refreshMemberships();
            _loadAllTeams();
          }
        },
        backgroundColor: C.g2,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Team',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header: Back Button + Notifications ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: C.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: C.dark,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Notification bell with badge
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, RoutePaths.notifications);
                      if (!mounted) return;
                      _loadUnreadCount();
                      _loadCaptainData();
                      await _refreshMemberships();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: C.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Center(
                            child: Icon(Icons.notifications_outlined,
                                color: C.dark, size: 20),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Header: Title Card ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HeaderCard(count: myTeamsTabBadge),
            ),
            const SizedBox(height: 20),

            // ── Tab Bar ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabCtrl,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: C.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: C.g1,
                unselectedLabelColor: C.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('My Teams'),
                        if (myTeamsTabBadge > 0) ...[
                          const SizedBox(width: 6),
                          _Badge(myTeamsTabBadge.toString(), C.g1),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Discover'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Tab Content ──────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── Tab 1: My Teams ──
                  RefreshIndicator(
                    color: C.g2,
                    onRefresh: () async {
                      await _refreshMemberships();
                      await _loadRosterTeams();
                      await _loadCaptainData();
                    },
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        const _SectionHeader('Your teams'),
                        const SizedBox(height: 10),
                        if (store.isLoadingMemberships || _loadingRoster)
                          const _Loader()
                        else if (approvedMemberships.isEmpty && rosterOnly.isEmpty)
                          _EmptyHint(
                            icon: Icons.groups_2_outlined,
                            label: applications.any((m) =>
                                    m.status == MembershipStatus.pending)
                                ? 'No approved memberships yet. Pending applications are below.'
                                : 'You are not on a team yet. Open Discover to join one.',
                          )
                        else ...[
                          ...approvedMemberships
                              .map((m) => _MembershipCard(
                                    membership: m,
                                    onTap: () => _openTeamSquadSheet(m.teamName),
                                  )),
                          ...rosterOnly.map((n) => _RosterOnlyCard(
                                teamName: n,
                                onTap: () => _openTeamSquadSheet(n),
                              )),
                        ],
                        if (applications.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const _SectionHeader('Applications'),
                          const SizedBox(height: 10),
                          ...applications.map((m) => _MembershipCard(membership: m)),
                        ],
                        const SizedBox(height: 24),
                        if (_isCaptain) ...[
                          const _SectionHeader('Captain — pending requests'),
                          const SizedBox(height: 10),
                          if (_loadingRequests)
                            const _Loader()
                          else if (_pendingRequests.isEmpty)
                            const _EmptyHint(
                              icon: Icons.inbox_outlined,
                              label: 'No pending join requests for your team(s).',
                            )
                          else
                            ..._pendingRequests.map((r) => _RequestCard(
                                  request: r,
                                  onApprove: () =>
                                      _updateRequest(r['id'].toString(), 'approved'),
                                  onReject: () =>
                                      _updateRequest(r['id'].toString(), 'rejected'),
                                )),
                        ],
                      ],
                    ),
                  ),

                  // ── Tab 2: Discover ──
                  _BrowseTab(
                    allTeams: _allTeams,
                    memberships: memberships,
                    loading: _loadingTeams,
                    error: _teamsError,
                    search: _search,
                    onSearchChanged: (v) => setState(() => _search = v),
                    onApply: (team) async {
                      final messenger = ScaffoldMessenger.of(context);
                      await store.applyToTeam(team);
                      if (!mounted) return;
                      messenger.showSnackBar(_snack(
                        'Applied to ${team.name}! Waiting for captain approval.',
                        C.g2,
                      ));
                      setState(() {});
                    },
                    onRefresh: () async {
                      await _loadAllTeams();
                      await _refreshMemberships();
                    },
                    onTeamTap: (teamName) => _openTeamSquadSheet(teamName),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Browse & Apply Tab ───────────────────────────────────────────
class _BrowseTab extends StatelessWidget {
  final List<TeamInfo> allTeams;
  final List<TeamMembership> memberships;
  final bool loading;
  final String? error;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function(TeamInfo) onApply;
  final Future<void> Function() onRefresh;
  final void Function(String teamName) onTeamTap;

  const _BrowseTab({
    required this.allTeams,
    required this.memberships,
    required this.loading,
    this.error,
    required this.search,
    required this.onSearchChanged,
    required this.onApply,
    required this.onRefresh,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = search.isEmpty
        ? allTeams
        : allTeams
            .where((t) =>
                t.name.toLowerCase().contains(search.toLowerCase()) ||
                t.abbreviation.toLowerCase().contains(search.toLowerCase()))
            .toList();

    return RefreshIndicator(
      color: C.g2,
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search teams…',
                  prefixIcon: const Icon(Icons.search, color: C.grey),
                  filled: true,
                  fillColor: C.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          if (loading)
            const SliverFillRemaining(child: _Loader())
          else if (error != null && filtered.isEmpty)
            SliverFillRemaining(
                child: _EmptyHint(icon: Icons.error_outline, label: error!))
          else if (filtered.isEmpty)
            const SliverFillRemaining(
                child: _EmptyHint(
                    icon: Icons.search_off, label: 'No teams found.'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final team = filtered[i];
                    final applied =
                        memberships.any((m) => m.teamName == team.name);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TeamCard(
                        team: team,
                        alreadyApplied: applied,
                        onApply: applied ? null : () => onApply(team),
                        onTap: () => onTeamTap(team.name),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Individual team card in browser ─────────────────────────────
class _TeamCard extends StatefulWidget {
  final TeamInfo team;
  final bool alreadyApplied;
  final Future<void> Function()? onApply;
  final VoidCallback onTap;
  const _TeamCard(
      {required this.team,
      required this.alreadyApplied,
      required this.onApply,
      required this.onTap});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
        // Abbr badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(widget.team.abbreviation,
                style: const TextStyle(
                    color: C.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.team.name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: C.dark)),
            const SizedBox(height: 4),
            Row(children: [
              _Pill(Icons.person_outline, widget.team.captain),
              const SizedBox(width: 10),
              _Pill(Icons.sports_cricket_outlined,
                  '${widget.team.matchCount} matches'),
            ]),
            const SizedBox(height: 4),
            _Pill(
                Icons.group_outlined, '${widget.team.playerCount} players'),
          ]),
        ),
        const SizedBox(width: 10),
        // Action button
        if (widget.alreadyApplied)
          _AppliedChip()
        else if (_applying)
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: C.g2))
        else
          _ApplyButton(
            onTap: () async {
              setState(() => _applying = true);
              await widget.onApply?.call();
              if (mounted) setState(() => _applying = false);
            },
          ),
        ]),
      ),
    );
  }
}

// ── Membership card ──────────────────────────────────────────────
class _MembershipCard extends StatelessWidget {
  final TeamMembership membership;
  final VoidCallback? onTap;
  const _MembershipCard({required this.membership, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isApproved = membership.status == MembershipStatus.approved;
    final isPending = membership.status == MembershipStatus.pending;
    final statusColor = isApproved
        ? C.g2
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withAlpha(40)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(membership.teamAbbreviation,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
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
                'Applied ${_fmtDate(membership.appliedAt)}',
                style: const TextStyle(fontSize: 11, color: C.grey)),
          ]),
        ),
        Row(children: [
          Icon(statusIcon, size: 15, color: statusColor),
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

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/// Shown when the user's name is on `team_players` but there is no approved membership row.
class _RosterOnlyCard extends StatelessWidget {
  final String teamName;
  final VoidCallback? onTap;
  const _RosterOnlyCard({required this.teamName, this.onTap});

  @override
  Widget build(BuildContext context) {
    final abbr = _abbrFromTeamName(teamName);
    const color = Color(0xFF1565C0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(abbr,
                style: const TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(teamName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: C.dark)),
            Text(
              'Listed on team roster',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
            ),
          ]),
        ),
        Icon(Icons.list_alt_rounded, size: 18, color: Colors.blue.shade700),
        ]),
      ),
    );
  }
}

String _abbrFromTeamName(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  final t = name.trim();
  if (t.length >= 3) return t.substring(0, 3).toUpperCase();
  return t.toUpperCase();
}

// ── Captain request card ─────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  const _RequestCard(
      {required this.request,
      required this.onApprove,
      required this.onReject});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final playerName = (r['player_name'] as String?) ??
        (r['user_email'] as String?) ??
        'Unknown Player';
    final teamName = (r['team_name'] as String?) ?? '';
    final appliedAt = DateTime.tryParse(r['applied_at']?.toString() ?? '') ??
        DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF57C00).withAlpha(60)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline,
                color: Color(0xFFF57C00), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(playerName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.dark)),
              Text('Wants to join $teamName  •  ${_fmtDate(appliedAt)}',
                  style: const TextStyle(fontSize: 11, color: C.grey)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: C.g2)))
        else
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'Approve',
                icon: Icons.check_rounded,
                color: C.g2,
                filled: true,
                onTap: () async {
                  setState(() => _loading = true);
                  await widget.onApprove();
                  if (mounted) setState(() => _loading = false);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                label: 'Reject',
                icon: Icons.close_rounded,
                color: Colors.red.shade600,
                filled: false,
                onTap: () async {
                  setState(() => _loading = true);
                  await widget.onReject();
                  if (mounted) setState(() => _loading = false);
                },
              ),
            ),
          ]),
      ]),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _HeaderCard extends StatelessWidget {
  final int count;
  const _HeaderCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Teams',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0 
                        ? 'No teams yet' 
                        : count == 1 
                          ? '1 team joined' 
                          : '$count teams joined',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ───────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: C.grey,
          letterSpacing: 1.1));
}

class _Badge extends StatelessWidget {
  final String count;
  final Color color;
  const _Badge(this.count, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(20)),
        child: Text(count,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: C.grey),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, color: C.grey)),
        ],
      );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child: CircularProgressIndicator(strokeWidth: 2.5, color: C.g2)),
      );
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyHint({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: C.hint),
          const SizedBox(height: 12),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.grey, fontSize: 13)),
        ]),
      );
}

class _AppliedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: C.g2.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.g2.withAlpha(50)),
        ),
        child: const Text('Applied',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: C.g2)),
      );
}

class _ApplyButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ApplyButton({required this.onTap});
  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovered
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                    : [const Color(0xFF2E7D32), const Color(0xFF388E3C)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                          color: C.g2.withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: const Text('Apply',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: C.white)),
          ),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : color)),
          ]),
        ),
      );
}

class _TeamSquadSheet extends StatelessWidget {
  final String teamName;
  final List<String> squad;
  const _TeamSquadSheet({required this.teamName, required this.squad});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: C.hint,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: C.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${squad.length} players',
                        style: const TextStyle(
                          fontSize: 12,
                          color: C.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: squad.isEmpty
                ? const Center(
                    child: Text(
                      'No squad found for this team.',
                      style: TextStyle(color: C.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: squad.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final player = squad[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: C.g2.withAlpha(20),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: C.g2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                player,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: C.dark,
                                ),
                              ),
                            ),
                          ],
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
