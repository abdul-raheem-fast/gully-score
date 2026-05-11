import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../models/scoring_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/match_summary_widgets.dart';

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
        backgroundColor: const Color(0xFF1A5C20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Match Scorecard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (!_loading && _match != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _downloadPdf,
              tooltip: 'Download Scorecard PDF',
            ),
          const SizedBox(width: 8),
        ],
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
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      _buildHeader(),
                      const TabBar(
                        labelColor: C.g1,
                        unselectedLabelColor: C.grey,
                        indicatorColor: C.g1,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        tabs: [
                          Tab(text: 'SUMMARY'),
                          Tab(text: 'SCORECARD'),
                          Tab(text: 'COMMENTARY'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildSummaryTab(),
                            _buildScorecardTab(),
                            _buildCommentaryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _downloadPdf() async {
    final m = _match!;
    final grouped = _ballsByInnings();
    final innings = <InningsState>[];
    for (var entry in grouped.entries) {
      innings.add(_createInningsState(entry.key, entry.value));
    }
    final motm = MatchSummaryWidgets.calculateManOfTheMatch(innings);

    try {
      await PdfService.generateAndPrintScorecard(m, innings, motm);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildHeader() {
    final m = _match!;
    final result = m.result ?? (m.status == MatchStatus.completed ? 'Match Completed' : 'Match in Progress');
    
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A5C20),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _headerTeamScore(m.teamA, m.scoreA, true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('vs', style: TextStyle(color: Colors.white54, fontSize: 14)),
              ),
              _headerTeamScore(m.teamB, m.scoreB, false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${m.venue}  •  ${_mon(m.date.month)} ${m.date.day}, ${m.date.year}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _headerTeamScore(String name, String score, bool isLeft) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _abbreviation(name),
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  String _abbreviation(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.substring(0, name.length.clamp(0, 3)).toUpperCase();
  }

  Widget _buildSummaryTab() {
    final m = _match!;
    final grouped = _ballsByInnings();
    final innings = <InningsState>[];
    for (var entry in grouped.entries) {
      final inn = _createInningsState(entry.key, entry.value);
      innings.add(inn);
    }

    final motm = MatchSummaryWidgets.calculateManOfTheMatch(innings);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (m.status == MatchStatus.completed && motm.name != 'N/A')
          MatchSummaryWidgets.manOfTheMatch(motm),
        
        ...innings.map((inn) => _summaryInningsCard(inn)),
        
        const SizedBox(height: 16),
        if (_playersRows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('Squads', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark)),
          ),
          _squadsCard(m),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _summaryInningsCard(InningsState inn) {
    final topBat = (inn.batsmen..sort((a, b) => b.runs.compareTo(a.runs))).take(2).toList();
    final topBowl = (inn.bowlers..sort((a, b) => b.wicketsTaken.compareTo(a.wicketsTaken))).take(1).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(inn.battingTeam, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.dark)),
              Text('${inn.totalRuns}/${inn.totalWickets} (${inn.oversText})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: C.dark)),
            ],
          ),
          const Divider(height: 24),
          ...topBat.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, color: C.dark))),
                Text('${p.runs}(${p.ballsFaced})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
              ],
            ),
          )),
          if (topBowl.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(topBowl[0].name, style: const TextStyle(fontSize: 13, color: C.grey))),
                Text('${topBowl[0].wicketsTaken}/${topBowl[0].runsConceded}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScorecardTab() {
    final grouped = _ballsByInnings();
    if (grouped.isEmpty) {
      return const Center(child: Text('No scorecard data available', style: TextStyle(color: C.grey)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        for (var entry in grouped.entries)
          ..._detailedInningsSection(_createInningsState(entry.key, entry.value)),
      ],
    );
  }

  List<Widget> _detailedInningsSection(InningsState inn) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Text(
          '${_ordinalInnings(inn.inningsNo)} Innings — ${inn.battingTeam}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.dark),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            _tableHeader(['BATTER', 'R', 'B', '4s', '6s', 'SR']),
            ...inn.batsmen.map((p) => _batterRow(p)),
            const Divider(height: 1),
            _tableHeader(['BOWLER', 'O', 'R', 'W', 'Econ']),
            ...inn.bowlers.map((p) => _bowlerRow(p)),
            const SizedBox(height: 12),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _tableHeader(List<String> cols) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(cols[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: C.grey))),
          for (var i = 1; i < cols.length; i++)
            SizedBox(width: 40, child: Text(cols[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: C.grey))),
        ],
      ),
    );
  }

  Widget _batterRow(PlayerInMatch p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark)),
                if (p.isOut) Text(p.dismissal ?? 'out', style: const TextStyle(fontSize: 10, color: C.grey)),
              ],
            ),
          ),
          _cell('${p.runs}', bold: true),
          _cell('${p.ballsFaced}'),
          _cell('${p.fours}'),
          _cell('${p.sixes}'),
          _cell(p.strikeRate.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _bowlerRow(PlayerInMatch p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dark))),
          _cell(p.oversText),
          _cell('${p.runsConceded}'),
          _cell('${p.wicketsTaken}', bold: true),
          _cell(p.economy.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _cell(String txt, {bool bold = false}) {
    return SizedBox(
      width: 40,
      child: Text(
        txt,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: C.dark),
      ),
    );
  }

  Widget _buildCommentaryTab() {
    final grouped = _ballsByInnings();
    final allBalls = <Ball>[];
    for (var list in grouped.values) {
      allBalls.addAll(list.map((r) => SupabaseService.ballFromRow(r, 0)));
    }
    allBalls.sort((a, b) {
      if (a.overNo != b.overNo) return b.overNo.compareTo(a.overNo);
      return b.ballNo.compareTo(a.ballNo);
    });

    if (allBalls.isEmpty) {
      return const Center(child: Text('No commentary yet', style: TextStyle(color: C.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: allBalls.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _ballTile(allBalls[index]),
    );
  }

  InningsState _createInningsState(int inningsNo, List<Map<String, dynamic>> rows) {
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

    final Map<String, PlayerInMatch> batsmen = {};
    final Map<String, PlayerInMatch> bowlers = {};

    for (final b in balls) {
      if (b.strikerName != null) {
        final p = batsmen.putIfAbsent(b.strikerName!, () => PlayerInMatch(name: b.strikerName!));
        p.runs += b.runsOffBat;
        if (b.isLegal) p.ballsFaced++;
        if (b.runsOffBat == 4) p.fours++;
        if (b.runsOffBat == 6) p.sixes++;
      }
      if (b.bowlerName != null) {
        final p = bowlers.putIfAbsent(b.bowlerName!, () => PlayerInMatch(name: b.bowlerName!));
        p.runsConceded += b.totalRuns;
        if (b.isLegal) {
          p.ballsBowled++;
          if (p.ballsBowled >= 6) { p.oversBowled++; p.ballsBowled = 0; }
        }
        if (b.isWicket) p.wicketsTaken++;
      }
      if (b.isWicket && b.wicketPlayerName != null) {
        final p = batsmen.putIfAbsent(b.wicketPlayerName!, () => PlayerInMatch(name: b.wicketPlayerName!));
        p.isOut = true;
        p.dismissal = b.wicketType;
      }
    }
    inn.batsmen = batsmen.values.toList();
    inn.bowlers = bowlers.values.toList();
    return inn;
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
