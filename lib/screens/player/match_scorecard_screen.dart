import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../models/scoring_models.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Pass [snapshot] when opening from a list so details still show if the DB row
/// is missing (RLS) or a single-row fetch fails.
class MatchScorecardRouteArgs {
  final String matchId;
  final AdminMatch? snapshot;
  const MatchScorecardRouteArgs({required this.matchId, this.snapshot});
}

/// Loads match metadata, innings, and ball-by-ball rows from Supabase.
class MatchScorecardScreen extends StatefulWidget {
  final String matchId;
  final AdminMatch? initialSnapshot;
  const MatchScorecardScreen({
    super.key,
    required this.matchId,
    this.initialSnapshot,
  });

  @override
  State<MatchScorecardScreen> createState() => _MatchScorecardScreenState();
}

class _MatchScorecardScreenState extends State<MatchScorecardScreen> {
  bool _loading = true;
  String? _error;
  AdminMatch? _match;
  bool _usedOfflineFallback = false;
  List<Map<String, dynamic>> _inningsRows = const [];
  List<Map<String, dynamic>> _ballRows = const [];
  List<Map<String, dynamic>> _playersRows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final id = widget.matchId.trim();
    try {
      AdminMatch? match = widget.initialSnapshot;
      if (match != null && match.id != id) match = null;

      final fromServer = await SupabaseService.fetchMatchById(id);
      var usedOfflineFallback = false;
      if (fromServer != null) {
        match = fromServer;
      } else {
        if (match == null && mounted) {
          for (final m in AppStore.of(context).matches) {
            if (m.id == id) {
              match = m;
              break;
            }
          }
        }
        usedOfflineFallback = match != null;
      }

      if (match == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = id.startsWith('m_')
                ? 'This match uses an old id format that does not match the database. Refresh matches on the dashboard, or open the match from the list after creating it again.'
                : 'Match not found in the database or you may not have permission to read it. Check Supabase Row Level Security on the matches table.';
          });
        }
        return;
      }
      // Related tables may fail under RLS or schema drift; still show match + whatever loaded.
      final innings = await SupabaseService.tryFetchInnings(id);
      final balls = await SupabaseService.tryFetchBallsByMatch(id);
      final players = await SupabaseService.tryFetchPlayersByMatch(id);
      if (!mounted) return;
      setState(() {
        _match = match;
        _usedOfflineFallback = usedOfflineFallback;
        _inningsRows = innings;
        _ballRows = balls;
        _playersRows = players;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not load this match. Check your connection and try again.\n\nDetails: $e';
      });
    }
  }

  Map<int, List<Map<String, dynamic>>> _ballsByInnings() {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final r in _ballRows) {
      final no = (r['innings_no'] as num?)?.toInt() ?? 1;
      map.putIfAbsent(no, () => []).add(r);
    }
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }

  Map<String, dynamic>? _metaForInnings(int inningsNo) {
    for (final r in _inningsRows) {
      if ((r['innings_no'] as num?)?.toInt() == inningsNo) return r;
    }
    return null;
  }

  String _statusLabel(MatchStatus s) {
    switch (s) {
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.upcoming:
        return 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.white,
        surfaceTintColor: C.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 8),
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
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: C.dark, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Match scorecard',
            style: TextStyle(
                color: C.dark, fontWeight: FontWeight.w800, fontSize: 18)),
        iconTheme: const IconThemeData(color: C.dark),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.g2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: C.grey)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final m = _match!;
    final dateStr =
        '${_mon(m.date.month)} ${m.date.day}, ${m.date.year}  •  ${_statusLabel(m.status)}';
    final grouped = _ballsByInnings();
    final inningsNos = grouped.keys.toList();

    return RefreshIndicator(
      color: C.g2,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5C20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m.teamA}  vs  ${m.teamB}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.venue,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    if (m.overs != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${m.overs} overs',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                    if (m.status == MatchStatus.completed &&
                        (m.result != null && m.result!.isNotEmpty)) ...[
                      const SizedBox(height: 14),
                      const Text('RESULT',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(
                        m.result!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: C.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: C.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.teamA,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: C.dark)),
                              const SizedBox(height: 4),
                              Text(m.scoreA,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: C.dark)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('vs',
                              style: TextStyle(
                                  color: C.hint,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m.teamB,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: C.dark)),
                              const SizedBox(height: 4),
                              Text(m.scoreB,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: C.dark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (m.winner != null && m.winner!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Winner: ${m.winner}',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: C.g2)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_usedOfflineFallback)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    'Loaded from your device list. The server did not return this row — check that the match exists in Supabase and that RLS allows select on matches.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade900, height: 1.35),
                  ),
                ),
              ),
            ),
          if (_playersRows.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Squads',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: C.dark)),
              ),
            ),
            SliverToBoxAdapter(child: _squadsCard(m)),
          ],
          if (inningsNos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    m.status == MatchStatus.upcoming
                        ? 'This match has not started yet. The scorecard will appear once scoring begins.'
                        : 'No ball-by-ball feed loaded (innings/balls may be blocked by database permissions or not synced). The summary above uses scores saved on the match row.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: C.grey, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            for (final innNo in inningsNos)
              ..._inningsSection(innNo, grouped[innNo]!),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _squadsCard(AdminMatch m) {
    final a = <String>[];
    final b = <String>[];
    for (final r in _playersRows) {
      final name = (r['player_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      final team = (r['team_name'] as String?)?.trim() ?? '';
      if (team == m.teamA) {
        a.add(name);
      } else if (team == m.teamB) {
        b.add(name);
      }
    }
    a.sort();
    b.sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.teamA,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: C.dark)),
            const SizedBox(height: 6),
            Text(
              a.isEmpty ? '—' : a.join(', '),
              style: const TextStyle(fontSize: 12.5, color: C.grey, height: 1.35),
            ),
            const SizedBox(height: 14),
            Text(m.teamB,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: C.dark)),
            const SizedBox(height: 6),
            Text(
              b.isEmpty ? '—' : b.join(', '),
              style: const TextStyle(fontSize: 12.5, color: C.grey, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _inningsSection(
      int inningsNo, List<Map<String, dynamic>> rows) {
    final meta = _metaForInnings(inningsNo);
    final batting = (meta?['batting_team'] as String?) ?? 'Batting side';
    final bowling = (meta?['bowling_team'] as String?) ?? 'Bowling side';
    final balls = <Ball>[];
    var id = 0;
    for (final r in rows) {
      id++;
      balls.add(SupabaseService.ballFromRow(r, id));
    }
    final inn = InningsState(
      inningsNo: inningsNo,
      battingTeam: batting,
      bowlingTeam: bowling,
      balls: balls,
      targetOvers: (meta?['target_overs'] as num?)?.toInt() ?? _match?.overs ?? 0,
      targetRuns: (meta?['target_runs'] as num?)?.toInt() ?? 0,
    );

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text(
            '${_ordinalInnings(inningsNo)} innings — $batting',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: C.dark),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withAlpha(13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs $bowling',
                    style: const TextStyle(fontSize: 12, color: C.grey)),
                const SizedBox(height: 8),
                Text(
                  '${inn.totalRuns}/${inn.totalWickets}  (${inn.oversText} ov)',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: C.dark),
                ),
                if (inn.targetRuns > 0)
                  Text(
                    'Target ${inn.targetRuns}',
                    style: const TextStyle(fontSize: 12, color: C.g2),
                  ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('Ball-by-ball',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: C.grey)),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: C.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < balls.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ballTile(balls[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _ballTile(Ball b) {
    final ov = '${b.overNo}.${b.ballNo}';
    final desc = _ballShortDesc(b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(ov,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: C.g2, fontSize: 13)),
          ),
          Expanded(
            child: Text(desc,
                style: const TextStyle(fontSize: 13, color: C.dark)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: C.gLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${b.totalRuns}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: C.dark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _ballShortDesc(Ball b) {
    if (b.isWicket) {
      final who = b.wicketPlayerName;
      final t = b.wicketType ?? 'wicket';
      if (who != null && who.isNotEmpty) return '$who — $t';
      return t;
    }
    if (b.extraType == 'wide') {
      return b.extraRuns > 1 ? 'Wide +${b.extraRuns - 1}' : 'Wide';
    }
    if (b.extraType == 'no_ball') {
      if (b.runsOffBat > 0) return 'No ball, ${b.runsOffBat} off bat';
      return 'No ball';
    }
    if (b.extraType == 'bye') return 'Bye${b.extraRuns > 0 ? ' ${b.extraRuns}' : ''}';
    if (b.extraType == 'leg_bye') {
      return 'Leg bye${b.extraRuns > 0 ? ' ${b.extraRuns}' : ''}';
    }
    return '${b.runsOffBat} run${b.runsOffBat == 1 ? '' : 's'}';
  }

  String _ordinalInnings(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  String _mon(int m) =>
      const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}
