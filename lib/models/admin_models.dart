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
