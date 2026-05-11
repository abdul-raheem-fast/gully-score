import 'package:flutter/material.dart';
import '../models/scoring_models.dart';
import '../theme/app_theme.dart';

class MatchSummaryWidgets {
  static Widget manOfTheMatch(PlayerInMatch player) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MAN OF THE MATCH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: C.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _playerStatsSummary(player),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: C.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _playerStatsSummary(PlayerInMatch p) {
    List<String> stats = [];
    if (p.runs > 0) stats.add('${p.runs}(${p.ballsFaced})');
    if (p.wicketsTaken > 0) stats.add('${p.wicketsTaken}/${p.runsConceded}');
    if (p.catches > 0) stats.add('${p.catches} ct');
    return stats.join('  •  ');
  }

  static PlayerInMatch calculateManOfTheMatch(List<InningsState> innings) {
    Map<String, PlayerInMatch> playerMap = {};

    for (var inn in innings) {
      for (var b in inn.batsmen) {
        playerMap.putIfAbsent(b.name, () => b.copy());
        var p = playerMap[b.name]!;
        p.runs = b.runs;
        p.ballsFaced = b.ballsFaced;
        p.fours = b.fours;
        p.sixes = b.sixes;
      }
      for (var bw in inn.bowlers) {
        playerMap.putIfAbsent(bw.name, () => bw.copy());
        var p = playerMap[bw.name]!;
        p.runsConceded = bw.runsConceded;
        p.wicketsTaken = bw.wicketsTaken;
        p.oversBowled = bw.oversBowled;
        p.ballsBowled = bw.ballsBowled;
      }
      // Extract catches from ball events if possible
      for (var ball in inn.balls) {
        if (ball.isWicket && ball.wicketType == 'caught') {
          // We don't have catcher name in Ball model yet, but we could add it.
          // For now let's assume we don't have it or skip fielding for algorithm.
        }
      }
    }

    if (playerMap.isEmpty) return PlayerInMatch(name: 'N/A');

    PlayerInMatch? best;
    double bestPoints = -1;

    for (var p in playerMap.values) {
      double points = _calculatePoints(p);
      if (points > bestPoints) {
        bestPoints = points;
        best = p;
      }
    }

    return best ?? PlayerInMatch(name: 'N/A');
  }

  static double _calculatePoints(PlayerInMatch p) {
    double pts = 0;
    // Batting
    pts += p.runs;
    pts += p.fours * 1;
    pts += p.sixes * 2;
    if (p.runs >= 100) pts += 25;
    else if (p.runs >= 50) pts += 10;
    if (p.runs > 0 && p.strikeRate > 150) pts += 5;

    // Bowling
    pts += p.wicketsTaken * 25;
    if (p.wicketsTaken >= 5) pts += 25;
    else if (p.wicketsTaken >= 3) pts += 10;
    pts += p.maidens * 10;
    if (p.oversBowled > 0 && p.economy < 6) pts += 5;

    return pts;
  }
}
