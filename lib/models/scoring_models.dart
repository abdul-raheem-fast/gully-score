
/// Individual ball record used during live scoring.
class Ball {
  final int id;
  final int overNo;
  final int ballNo;
  final int runsOffBat;
  final int extraRuns;
  final String? extraType; // 'wide', 'no_ball', 'bye', 'leg_bye'
  final bool isWicket;
  final String? wicketType; // 'bowled', 'caught', 'run_out', 'stumped', 'lbw', 'hit_wicket'
  final String? wicketPlayerName;
  final String? commentary;

  const Ball({
    required this.id,
    required this.overNo,
    required this.ballNo,
    this.runsOffBat = 0,
    this.extraRuns = 0,
    this.extraType,
    this.isWicket = false,
    this.wicketType,
    this.wicketPlayerName,
    this.commentary,
  });

  /// Total runs conceded on this delivery (including extras).
  int get totalRuns => runsOffBat + extraRuns;

  /// Whether this counts as a legal delivery.
  bool get isLegal => extraType != 'wide' && extraType != 'no_ball';

  Ball copyWith({
    int? id,
    int? overNo,
    int? ballNo,
    int? runsOffBat,
    int? extraRuns,
    String? extraType,
    bool? isWicket,
    String? wicketType,
    String? wicketPlayerName,
    String? commentary,
  }) {
    return Ball(
      id: id ?? this.id,
      overNo: overNo ?? this.overNo,
      ballNo: ballNo ?? this.ballNo,
      runsOffBat: runsOffBat ?? this.runsOffBat,
      extraRuns: extraRuns ?? this.extraRuns,
      extraType: extraType ?? this.extraType,
      isWicket: isWicket ?? this.isWicket,
      wicketType: wicketType ?? this.wicketType,
      wicketPlayerName: wicketPlayerName ?? this.wicketPlayerName,
      commentary: commentary ?? this.commentary,
    );
  }
}

/// Player performance tracking inside a match.
class PlayerInMatch {
  final String name;
  int runs;
  int ballsFaced;
  int fours;
  int sixes;
  bool isOut;
  String? dismissal;

  // Bowling
  int oversBowled;
  int ballsBowled;
  int runsConceded;
  int wicketsTaken;
  int maidens;

  // Fielding
  int catches;
  int runOuts;
  int stumpings;

  bool isBatting;
  bool isBowling;

  PlayerInMatch({
    required this.name,
    this.runs = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.dismissal,
    this.oversBowled = 0,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.wicketsTaken = 0,
    this.maidens = 0,
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    this.isBatting = false,
    this.isBowling = false,
  });

  double get strikeRate => ballsFaced == 0 ? 0 : (runs / ballsFaced) * 100;
  double get economy => (oversBowled + ballsBowled / 6) == 0
      ? 0
      : runsConceded / (oversBowled + ballsBowled / 6);

  String get oversText => '$oversBowled.${ballsBowled % 6}';

  PlayerInMatch copy() {
    return PlayerInMatch(name: name)
      ..runs = runs
      ..ballsFaced = ballsFaced
      ..fours = fours
      ..sixes = sixes
      ..isOut = isOut
      ..dismissal = dismissal
      ..oversBowled = oversBowled
      ..ballsBowled = ballsBowled
      ..runsConceded = runsConceded
      ..wicketsTaken = wicketsTaken
      ..maidens = maidens
      ..catches = catches
      ..runOuts = runOuts
      ..stumpings = stumpings
      ..isBatting = isBatting
      ..isBowling = isBowling;
  }
}

/// One innings during a match.
class InningsState {
  final int inningsNo; // 1 or 2
  final String battingTeam;
  final String bowlingTeam;

  List<PlayerInMatch> batsmen;
  List<PlayerInMatch> bowlers;
  List<Ball> balls;

  int targetRuns; // if chasing (0 in first innings)
  int targetOvers;

  InningsState({
    required this.inningsNo,
    required this.battingTeam,
    required this.bowlingTeam,
    List<PlayerInMatch>? batsmen,
    List<PlayerInMatch>? bowlers,
    List<Ball>? balls,
    this.targetRuns = 0,
    this.targetOvers = 0,
  })  : batsmen = batsmen ?? [],
        bowlers = bowlers ?? [],
        balls = balls ?? [];

  int get totalRuns => balls.fold(0, (sum, b) => sum + b.totalRuns);
  int get totalWickets => balls.where((b) => b.isWicket).length;

  int get legalBalls {
    return balls.where((b) => b.isLegal).length;
  }

  int get oversCompleted => legalBalls ~/ 6;
  int get ballsInCurrentOver => legalBalls % 6;
  String get oversText => '$oversCompleted.${ballsInCurrentOver}';

  double get runRate {
    final completed = oversCompleted + ballsInCurrentOver / 6;
    if (completed == 0) return 0;
    return totalRuns / completed;
  }

  double get requiredRate {
    if (targetRuns == 0) return 0;
    final remainingRuns = targetRuns - totalRuns;
    final remainingBalls = (targetOvers * 6) - legalBalls;
    if (remainingBalls <= 0) return 0;
    return (remainingRuns / remainingBalls) * 6;
  }

  String get partnershipRuns {
    // Find last wicket fall ball, then sum runs since
    final wicketIndices = <int>[];
    for (var i = 0; i < balls.length; i++) {
      if (balls[i].isWicket) wicketIndices.add(i);
    }
    final startIdx = wicketIndices.isEmpty ? 0 : wicketIndices.last + 1;
    var pRuns = 0;
    for (var i = startIdx; i < balls.length; i++) {
      pRuns += balls[i].totalRuns;
    }
    return '$pRuns';
  }

  String get partnershipBalls {
    final wicketIndices = <int>[];
    for (var i = 0; i < balls.length; i++) {
      if (balls[i].isWicket) wicketIndices.add(i);
    }
    final startIdx = wicketIndices.isEmpty ? 0 : wicketIndices.last + 1;
    var pBalls = 0;
    for (var i = startIdx; i < balls.length; i++) {
      if (balls[i].isLegal) pBalls++;
    }
    return '$pBalls';
  }

  PlayerInMatch? get currentStriker {
    try {
      return batsmen.firstWhere((p) => p.isBatting && !p.isOut);
    } catch (_) {
      return null;
    }
  }

  PlayerInMatch? get currentNonStriker {
    try {
      final batting = batsmen.where((p) => p.isBatting && !p.isOut).toList();
      if (batting.length > 1) return batting[1];
      return null;
    } catch (_) {
      return null;
    }
  }

  PlayerInMatch? get currentBowler {
    try {
      return bowlers.firstWhere((p) => p.isBowling);
    } catch (_) {
      return null;
    }
  }

  InningsState copy() {
    return InningsState(
      inningsNo: inningsNo,
      battingTeam: battingTeam,
      bowlingTeam: bowlingTeam,
      batsmen: batsmen.map((e) => e.copy()).toList(),
      bowlers: bowlers.map((e) => e.copy()).toList(),
      balls: balls.map((e) => e.copyWith()).toList(),
      targetRuns: targetRuns,
      targetOvers: targetOvers,
    );
  }
}

/// Match setup data captured during the New Match wizard.
class MatchSetup {
  final String id;
  final String teamA;
  final String teamB;
  final String venue;
  final int overs;
  final String format; // 'T20', '10-Over', 'ODI', 'Test'
  final DateTime date;
  final String tossWinner;
  final String electedTo; // 'bat' or 'field'
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;

  const MatchSetup({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.venue,
    required this.overs,
    required this.format,
    required this.date,
    required this.tossWinner,
    required this.electedTo,
    required this.teamAPlayers,
    required this.teamBPlayers,
  });

  String get battingFirst =>
      (tossWinner == teamA && electedTo == 'bat') ||
              (tossWinner == teamB && electedTo == 'field')
          ? teamA
          : teamB;

  String get bowlingFirst => battingFirst == teamA ? teamB : teamA;

  MatchSetup copyWith({
    String? id,
    String? teamA,
    String? teamB,
    String? venue,
    int? overs,
    String? format,
    DateTime? date,
    String? tossWinner,
    String? electedTo,
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
  }) {
    return MatchSetup(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      venue: venue ?? this.venue,
      overs: overs ?? this.overs,
      format: format ?? this.format,
      date: date ?? this.date,
      tossWinner: tossWinner ?? this.tossWinner,
      electedTo: electedTo ?? this.electedTo,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
    );
  }
}

/// Full in-memory match scoring session.
class ScoringSession {
  final MatchSetup setup;
  InningsState? innings1;
  InningsState? innings2;
  int currentInningsNo;
  bool isCompleted;
  String? result;

  ScoringSession({
    required this.setup,
    this.innings1,
    this.innings2,
    this.currentInningsNo = 1,
    this.isCompleted = false,
    this.result,
  });

  InningsState? get currentInnings =>
      currentInningsNo == 1 ? innings1 : innings2;

  bool get isFirstInnings => currentInningsNo == 1;

  ScoringSession copy() {
    return ScoringSession(
      setup: setup,
      innings1: innings1?.copy(),
      innings2: innings2?.copy(),
      currentInningsNo: currentInningsNo,
      isCompleted: isCompleted,
      result: result,
    );
  }
}
