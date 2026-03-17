/// Models used exclusively by player-facing screens.

enum MatchResult { won, lost, draw }

class PlayerMatch {
  final String id;
  final String myTeam;
  final String myTeamAbbr;
  final String opponent;
  final String opponentAbbr;
  final String myTeamScore;
  final String opponentScore;
  final String overs;
  final MatchResult result;
  final String summary; // e.g. "Street Stars won by 23 runs"
  final DateTime date;
  final String format; // e.g. "T20", "10-Over"

  const PlayerMatch({
    required this.id,
    required this.myTeam,
    required this.myTeamAbbr,
    required this.opponent,
    required this.opponentAbbr,
    required this.myTeamScore,
    required this.opponentScore,
    required this.overs,
    required this.result,
    required this.summary,
    required this.date,
    required this.format,
  });
}

class LiveMatch {
  final String teamA;
  final String teamAbbr;
  final String teamB;
  final String teamBAbbr;
  final String scoreA;
  final String scoreB;
  final String oversA;
  final String oversB;
  final String targetOvers;
  final String chaseInfo; // "GW need 45 runs from 22 balls"

  const LiveMatch({
    required this.teamA,
    required this.teamAbbr,
    required this.teamB,
    required this.teamBAbbr,
    required this.scoreA,
    required this.scoreB,
    required this.oversA,
    required this.oversB,
    required this.targetOvers,
    required this.chaseInfo,
  });
}

class PlayerStats {
  final int matches;
  final int runs;
  final double average;
  final int wickets;
  final String bestBowling;
  final int fifties;
  final int hundreds;
  final double strikeRate;

  const PlayerStats({
    required this.matches,
    required this.runs,
    required this.average,
    required this.wickets,
    required this.bestBowling,
    required this.fifties,
    required this.hundreds,
    required this.strikeRate,
  });
}
