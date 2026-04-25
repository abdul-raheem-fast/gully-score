import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PlayerStatsScreen extends StatelessWidget {
  const PlayerStatsScreen({super.key});

  // Demo player stats
  static const _runs      = 1847;
  static const _average   = 38.4;
  static const _sr        = 142.6;
  static const _matches   = 52;
  static const _wickets   = 14;
  static const _fifties   = 11;
  static const _hundreds  = 2;
  static const _bestScore = '94';
  static const _bestBowl  = '3/18';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A5C20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Stats',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  const Text('Career Overview',
                      style: TextStyle(
                          color: C.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _heroStat('$_matches', 'Matches'),
                      _divider(),
                      _heroStat('$_runs', 'Total Runs'),
                      _divider(),
                      _heroStat('$_wickets', 'Wickets'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Batting section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _section(
                label: 'Batting',
                icon: Icons.sports_cricket,
                color: C.g2,
                stats: [
                  _StatRow('Runs', '$_runs'),
                  _StatRow('Average', '$_average'),
                  _StatRow('Strike Rate', '$_sr'),
                  _StatRow('Highest Score', _bestScore),
                  _StatRow('50s / 100s', '$_fifties / $_hundreds'),
                ],
              ),
            ),
          ),

          // Bowling section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _section(
                label: 'Bowling',
                icon: Icons.offline_bolt_outlined,
                color: C.orange,
                stats: [
                  _StatRow('Wickets', '$_wickets'),
                  _StatRow('Best Figures', _bestBowl),
                  _StatRow('Economy Rate', '6.8'),
                  _StatRow('Average', '22.4'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) => Column(children: [
        Text(value,
            style: const TextStyle(
                color: C.white,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
      ]);

  Widget _divider() => Container(
      height: 40, width: 1, color: Colors.white24);

  Widget _section({
    required String label,
    required IconData icon,
    required Color color,
    required List<_StatRow> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: C.dark)),
        ]),
        const SizedBox(height: 16),
        ...stats.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.label,
                      style:
                          const TextStyle(fontSize: 13.5, color: C.grey)),
                  Text(s.value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ],
              ),
            )),
      ]),
    );
  }
}

class _StatRow {
  final String label, value;
  const _StatRow(this.label, this.value);
}
