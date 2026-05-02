enum MatchStatus { live, upcoming, completed }

class AdminMatch {
  final String id;
  final String teamA;
  final String teamB;
  final String scoreA;
  final String scoreB;
  final String venue;
  final DateTime date;
  final MatchStatus status;
  final bool flagged;
  /// Human-readable result string, e.g. "Alpha won by 23 runs".
  final String? result;
  /// Name of the winning team (empty string = tie/not decided).
  final String? winner;
  /// Match overs limit when stored on the row (e.g. 20 for T20).
  final int? overs;

  const AdminMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.scoreA,
    required this.scoreB,
    required this.venue,
    required this.date,
    required this.status,
    this.flagged = false,
    this.result,
    this.winner,
    this.overs,
  });

  AdminMatch copyWith({
    String? id,
    String? teamA,
    String? teamB,
    String? scoreA,
    String? scoreB,
    String? venue,
    DateTime? date,
    MatchStatus? status,
    bool? flagged,
    String? result,
    String? winner,
    int? overs,
  }) {
    return AdminMatch(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      status: status ?? this.status,
      flagged: flagged ?? this.flagged,
      result: result ?? this.result,
      winner: winner ?? this.winner,
      overs: overs ?? this.overs,
    );
  }
}

class AdminTeam {
  final String id;
  final String name;
  final String abbreviation;
  final String captain;
  final int playerCount;
  final int matchCount;

  const AdminTeam({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.captain,
    required this.playerCount,
    required this.matchCount,
  });

  AdminTeam copyWith({
    String? id,
    String? name,
    String? abbreviation,
    String? captain,
    int? playerCount,
    int? matchCount,
  }) {
    return AdminTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      captain: captain ?? this.captain,
      playerCount: playerCount ?? this.playerCount,
      matchCount: matchCount ?? this.matchCount,
    );
  }
}
