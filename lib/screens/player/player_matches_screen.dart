import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/player_models.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class PlayerMatchesScreen extends StatefulWidget {
  const PlayerMatchesScreen({super.key});

  @override
  State<PlayerMatchesScreen> createState() => _PlayerMatchesScreenState();
}

class _PlayerMatchesScreenState extends State<PlayerMatchesScreen> {
  late final Future<List<PlayerMatch>> _matchesFuture = _loadMatches();

  static final _fallbackMatches = [
    PlayerMatch(
      id: 'p1',
      myTeam: 'Street Stars',
      myTeamAbbr: 'SS',
      opponent: 'Night Kings',
      opponentAbbr: 'NK',
      myTeamScore: '185/4 (20 ov)',
      opponentScore: '162/8 (20 ov)',
      overs: '20',
      result: MatchResult.won,
      summary: 'Street Stars won by 23 runs',
      date: DateTime(2026, 2, 27),
      format: 'T20',
    ),
    PlayerMatch(
      id: 'p2',
      myTeam: 'Street Stars',
      myTeamAbbr: 'SS',
      opponent: 'City Champs',
      opponentAbbr: 'CC',
      myTeamScore: '98/10 (9.2 ov)',
      opponentScore: '102/3 (10 ov)',
      overs: '10',
      result: MatchResult.lost,
      summary: 'City Champs won by 7 wickets',
      date: DateTime(2026, 2, 25),
      format: '10-Over',
    ),
    PlayerMatch(
      id: 'p3',
      myTeam: 'Street Stars',
      myTeamAbbr: 'SS',
      opponent: 'Valley Victors',
      opponentAbbr: 'VV',
      myTeamScore: '167/5 (20 ov)',
      opponentScore: '165/7 (20 ov)',
      overs: '20',
      result: MatchResult.won,
      summary: 'Street Stars won by 2 runs',
      date: DateTime(2026, 2, 20),
      format: 'T20',
    ),
    PlayerMatch(
      id: 'p4',
      myTeam: 'Street Stars',
      myTeamAbbr: 'SS',
      opponent: 'Rapid Rangers',
      opponentAbbr: 'RR',
      myTeamScore: '134/7 (20 ov)',
      opponentScore: '135/4 (19 ov)',
      overs: '20',
      result: MatchResult.lost,
      summary: 'Rapid Rangers won by 6 wickets',
      date: DateTime(2026, 2, 14),
      format: 'T20',
    ),
    PlayerMatch(
      id: 'p5',
      myTeam: 'Street Stars',
      myTeamAbbr: 'SS',
      opponent: 'Mighty Sixers',
      opponentAbbr: 'MS',
      myTeamScore: '202/3 (20 ov)',
      opponentScore: '188/6 (20 ov)',
      overs: '20',
      result: MatchResult.won,
      summary: 'Street Stars won by 14 runs',
      date: DateTime(2026, 2, 8),
      format: 'T20',
    ),
  ];

  Future<List<PlayerMatch>> _loadMatches() async {
    try {
      final adminMatches = await SupabaseService.fetchAdminMatches();
      if (adminMatches.isEmpty) return _fallbackMatches;
      return adminMatches.map((m) {
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
          summary: '${m.teamA} vs ${m.teamB} · ${m.venue}',
          date: m.date,
          format: 'League',
        );
      }).toList();
    } catch (_) {
      return _fallbackMatches;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlayerMatch>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        final matches = snapshot.data ?? _fallbackMatches;
        final won = matches.where((m) => m.result == MatchResult.won).length;
        final lost = matches.where((m) => m.result == MatchResult.lost).length;

        return Scaffold(
          backgroundColor: C.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: C.white,
                elevation: 0,
                surfaceTintColor: C.white,
                expandedHeight: 110,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Matches',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: C.dark)),
                      Text('${matches.length} played  •  $won won  •  $lost lost',
                          style: const TextStyle(
                              fontSize: 11,
                              color: C.grey,
                              fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MatchTile(match: matches[i]),
                    ),
                    childCount: matches.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
}

class _MatchTile extends StatelessWidget {
  final PlayerMatch match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final won = match.result == MatchResult.won;
    final resultColor = won ? C.g2 : const Color(0xFFD32F2F);
    final resultBg = won ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final dateStr =
        '${_mon(match.date.month)} ${match.date.day}, ${match.date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$dateStr  •  ${match.format}',
              style: const TextStyle(fontSize: 11.5, color: C.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: resultBg, borderRadius: BorderRadius.circular(8)),
            child: Text(won ? 'WON' : 'LOST',
                style: TextStyle(color: resultColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _chip(match.myTeamAbbr),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${match.myTeam}  vs  ${match.opponent}',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: C.dark)),
              const SizedBox(height: 2),
              Text('${match.myTeamScore}  –  ${match.opponentScore}',
                  style: const TextStyle(fontSize: 12, color: C.grey)),
            ]),
          ),
          _chip(match.opponentAbbr),
        ]),
        const SizedBox(height: 10),
        Text(match.summary,
            style: TextStyle(
                color: resultColor, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _chip(String abbr) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: C.gLight,
          shape: BoxShape.circle,
          border: Border.all(color: C.g2.withAlpha(60), width: 1.2),
        ),
        child: Center(
            child: Text(abbr,
                style: const TextStyle(
                    color: C.g2, fontSize: 10, fontWeight: FontWeight.w800))),
      );

  String _mon(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];
}
