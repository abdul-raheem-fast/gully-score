import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';
import '../models/player_models.dart';
import '../models/scoring_models.dart';

class SupabaseService {
  const SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;

  static String? getCurrentUserRole() =>
      currentUser?.userMetadata?['app_role']?.toString();

  static String? getCurrentUserName() =>
      currentUser?.userMetadata?['name']?.toString();

  static Future<void> signOut() => client.auth.signOut();

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String appRole,
  }) {
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'name': name.trim(),
        'app_role': appRole,
      },
    );
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String name,
    required String role,
    String? phone,
    String? playingRole,
    String? organization,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'email': email.trim().toLowerCase(),
      'name': name.trim(),
      'role': role,
      'phone': phone?.trim(),
      'playing_role': playingRole?.trim(),
      'organization': organization?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final response = await client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchReports() async {
    final response = await client
        .from('reports')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createReport({
    required String matchId,
    required String title,
    required String description,
    String severity = 'medium',
  }) async {
    await client.from('reports').insert({
      'match_id': matchId,
      'title': title.trim(),
      'description': description.trim(),
      'severity': severity,
      'status': 'open',
      'created_by': currentUser?.id,
    });
  }

  static Future<void> updateReportStatus({
    required String reportId,
    required String status,
  }) async {
    await client.from('reports').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  static Future<List<AdminMatch>> fetchAdminMatches() async {
    final response = await client
        .from('matches')
        .select()
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map(_rowToAdminMatch).toList();
  }

  static Future<void> updateAdminMatch(AdminMatch match) async {
    await client.from('matches').update({
      'team_a_name': match.teamA,
      'team_b_name': match.teamB,
      'venue': match.venue,
      'status': _toDbStatus(match.status),
    }).eq('id', match.id);
  }

  static Future<void> createMatch(MatchSetup setup) async {
    await client.from('matches').insert({
      'id': setup.id,
      'team_a_name': setup.teamA,
      'team_b_name': setup.teamB,
      'venue': setup.venue,
      'overs': setup.overs,
      'status': 'live',
      'created_at': setup.date.toIso8601String(),
    });
  }

  static Future<void> createInnings(InningsState innings, String matchId) async {
    await client.from('innings').insert({
      'match_id': matchId,
      'innings_no': innings.inningsNo,
      'batting_team': innings.battingTeam,
      'bowling_team': innings.bowlingTeam,
      'target_runs': innings.targetRuns,
      'target_overs': innings.targetOvers,
    });
  }

  static Future<void> createBall(Ball ball, String matchId, int inningsNo) async {
    await client.from('balls').insert({
      'match_id': matchId,
      'innings_no': inningsNo,
      'over_no': ball.overNo,
      'ball_no': ball.ballNo,
      'runs_off_bat': ball.runsOffBat,
      'extra_runs': ball.extraRuns,
      'extra_type': ball.extraType,
      'is_wicket': ball.isWicket,
      'wicket_type': ball.wicketType,
      'wicket_player_name': ball.wicketPlayerName,
      'commentary': ball.commentary,
    });
  }

  static Future<List<AdminTeam>> fetchAdminTeams() async {
    final playersResponse = await client.from('players').select();
    final matchesResponse = await client
        .from('matches')
        .select('id,team_a_name,team_b_name')
        .order('created_at', ascending: false);

    final players = List<Map<String, dynamic>>.from(playersResponse);
    final matches = List<Map<String, dynamic>>.from(matchesResponse);

    final matchCountByTeam = <String, int>{};
    for (final row in matches) {
      final teamA = (row['team_a_name'] as String?)?.trim();
      final teamB = (row['team_b_name'] as String?)?.trim();
      if (teamA != null && teamA.isNotEmpty) {
        matchCountByTeam[teamA] = (matchCountByTeam[teamA] ?? 0) + 1;
      }
      if (teamB != null && teamB.isNotEmpty) {
        matchCountByTeam[teamB] = (matchCountByTeam[teamB] ?? 0) + 1;
      }
    }

    final buckets = <String, List<Map<String, dynamic>>>{};
    for (final row in players) {
      final teamName = (row['team_name'] as String?)?.trim();
      if (teamName == null || teamName.isEmpty) continue;
      buckets.putIfAbsent(teamName, () => <Map<String, dynamic>>[]).add(row);
    }

    final teams = <AdminTeam>[];
    int idx = 1;
    for (final entry in buckets.entries) {
      final teamName = entry.key;
      final members = entry.value;
      final captainRow = members.firstWhere(
        (m) => m['is_captain'] == true,
        orElse: () => members.first,
      );
      final captainName = (captainRow['player_name'] as String?) ?? 'Unknown';
      teams.add(
        AdminTeam(
          id: 'team_$idx',
          name: teamName,
          abbreviation: _abbreviation(teamName),
          captain: captainName,
          playerCount: members.length,
          matchCount: matchCountByTeam[teamName] ?? 0,
        ),
      );
      idx++;
    }

    if (teams.isEmpty) {
      for (final row in matches) {
        final teamNames = [
          (row['team_a_name'] as String?)?.trim(),
          (row['team_b_name'] as String?)?.trim(),
        ].whereType<String>().where((e) => e.isNotEmpty);
        for (final teamName in teamNames) {
          if (teams.any((t) => t.name == teamName)) continue;
          teams.add(
            AdminTeam(
              id: 'team_$idx',
              name: teamName,
              abbreviation: _abbreviation(teamName),
              captain: 'TBD',
              playerCount: 0,
              matchCount: matchCountByTeam[teamName] ?? 0,
            ),
          );
          idx++;
        }
      }
    }

    teams.sort((a, b) => b.matchCount.compareTo(a.matchCount));
    return teams;
  }

  static Future<List<TeamInfo>> fetchTeams() async {
    // We re-use the players table aggregation logic to avoid a separate `teams` table.
    final teams = await fetchAdminTeams();
    return teams
        .map((t) => TeamInfo(
              id: t.id,
              name: t.name,
              abbreviation: t.abbreviation,
              captain: t.captain,
              playerCount: t.playerCount,
              matchCount: t.matchCount,
            ))
        .toList();
  }

  /// Apply for membership in [teamName]. Stores a row in `team_memberships`.
  /// Uses insert first; if a row already exists (conflict) it updates instead.
  static Future<void> applyToTeam({
    required String teamName,
    required String teamAbbreviation,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now().toIso8601String();
    try {
      // Try a plain insert first.
      await client.from('team_memberships').insert({
        'user_id': userId,
        'team_name': teamName,
        'team_abbreviation': teamAbbreviation,
        'status': 'pending',
        'applied_at': now,
      });
    } catch (e) {
      // If it's a unique-violation (code 23505), update the existing row.
      final msg = e.toString();
      if (msg.contains('23505') || msg.contains('duplicate') || msg.contains('unique')) {
        await client
            .from('team_memberships')
            .update({
              'team_abbreviation': teamAbbreviation,
              'status': 'pending',
              'applied_at': now,
            })
            .eq('user_id', userId)
            .eq('team_name', teamName);
      } else {
        rethrow;
      }
    }
  }

  /// Fetch all team_memberships rows for the currently signed-in player.
  static Future<List<TeamMembership>> fetchMyMemberships() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('team_memberships')
        .select()
        .eq('user_id', userId)
        .order('applied_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map((row) {
      final statusRaw = (row['status'] as String?) ?? 'pending';
      MembershipStatus status;
      switch (statusRaw) {
        case 'approved':
          status = MembershipStatus.approved;
          break;
        case 'rejected':
          status = MembershipStatus.rejected;
          break;
        default:
          status = MembershipStatus.pending;
      }
      return TeamMembership(
        id: row['id']?.toString() ?? '',
        teamId: row['team_name']?.toString() ?? '',
        teamName: row['team_name']?.toString() ?? '',
        teamAbbreviation: row['team_abbreviation']?.toString() ?? '',
        status: status,
        appliedAt: DateTime.tryParse(row['applied_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  /// Returns team names where the current user is recorded as captain
  /// in the `players` table.
  static Future<List<String>> fetchCaptainTeams() async {
    final userId = currentUser?.id;
    final userName = getCurrentUserName();
    if (userId == null || userName == null || userName.isEmpty) return [];
    final response = await client
        .from('players')
        .select('team_name')
        .eq('player_name', userName)
        .eq('is_captain', true);
    final rows = List<Map<String, dynamic>>.from(response);
    return rows
        .map((r) => (r['team_name'] as String?) ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Returns pending join requests for teams where the current user is captain.
  /// Joins team_memberships with profiles so we get the player's name & email.
  static Future<List<Map<String, dynamic>>> fetchPendingRequestsForCaptain(
      List<String> captainTeams) async {
    if (captainTeams.isEmpty) return [];
    // Fetch pending memberships for those teams.
    final response = await client
        .from('team_memberships')
        .select()
        .inFilter('team_name', captainTeams)
        .eq('status', 'pending')
        .order('applied_at', ascending: true);
    final rows = List<Map<String, dynamic>>.from(response);

    // Enrich with profile name/email for each row.
    final enriched = <Map<String, dynamic>>[];
    for (final row in rows) {
      final applicantId = row['user_id']?.toString() ?? '';
      String playerName = 'Unknown Player';
      String userEmail = '';
      try {
        final profiles = await client
            .from('profiles')
            .select('name, email')
            .eq('id', applicantId)
            .limit(1);
        final profileRows = List<Map<String, dynamic>>.from(profiles);
        if (profileRows.isNotEmpty) {
          playerName = (profileRows.first['name'] as String?) ?? playerName;
          userEmail = (profileRows.first['email'] as String?) ?? '';
        }
      } catch (_) {}
      enriched.add({
        ...row,
        'player_name': playerName,
        'user_email': userEmail,
      });
    }
    return enriched;
  }

  /// Approve or reject a membership request.
  static Future<void> updateMembershipStatus({
    required String id,
    required String status, // 'approved' | 'rejected'
  }) async {
    await client
        .from('team_memberships')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> addPlayer({
    required String matchId,
    required String teamName,
    required String playerName,
    bool isCaptain = false,
  }) async {
    if (isCaptain) {
      await client
          .from('players')
          .update({'is_captain': false})
          .eq('match_id', matchId)
          .eq('team_name', teamName);
    }
    await client.from('players').insert({
      'match_id': matchId,
      'team_name': teamName,
      'player_name': playerName,
      'is_captain': isCaptain,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchPlayersByMatch(
    String matchId,
  ) async {
    final response = await client
        .from('players')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<String> createInnings({
    required String matchId,
    required int inningsNo,
    required String battingTeam,
    required String bowlingTeam,
  }) async {
    final response = await client
        .from('innings')
        .insert({
          'match_id': matchId,
          'innings_no': inningsNo,
          'batting_team': battingTeam,
          'bowling_team': bowlingTeam,
        })
        .select('id')
        .single();
    return response['id'].toString();
  }

  static Future<List<Map<String, dynamic>>> fetchInnings(String matchId) async {
    final response = await client
        .from('innings')
        .select()
        .eq('match_id', matchId)
        .order('innings_no', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addBallEvent({
    required String inningsId,
    required int overNo,
    required int ballNo,
    int runsOffBat = 0,
    int extraRuns = 0,
    String? extraType,
    String? strikerName,
    String? nonStrikerName,
    String? bowlerName,
    String? commentary,
    String? wicketType,
    String? wicketPlayerName,
  }) async {
    await client.from('ball_events').insert({
      'innings_id': inningsId,
      'over_no': overNo,
      'ball_no': ballNo,
      'runs_off_bat': runsOffBat,
      'extra_runs': extraRuns,
      'extra_type': extraType,
      'striker_name': strikerName,
      'non_striker_name': nonStrikerName,
      'bowler_name': bowlerName,
      'commentary': commentary,
      'wicket_type': wicketType,
      'wicket_player_name': wicketPlayerName,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchBallEvents(
    String inningsId,
  ) async {
    final response = await client
        .from('ball_events')
        .select()
        .eq('innings_id', inningsId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static AdminMatch _rowToAdminMatch(Map<String, dynamic> row) {
    final teamA = (row['team_a_name'] as String?) ?? 'Team A';
    final teamB = (row['team_b_name'] as String?) ?? 'Team B';
    final venue = (row['venue'] as String?) ?? 'TBD';
    final matchDateRaw = row['match_date']?.toString();
    final createdAtRaw = row['created_at']?.toString();
    final parsedDate = DateTime.tryParse(matchDateRaw ?? '') ??
        DateTime.tryParse(createdAtRaw ?? '') ??
        DateTime.now();

    return AdminMatch(
      id: row['id']?.toString() ?? '${teamA}_$teamB',
      teamA: teamA,
      teamB: teamB,
      scoreA: '0/0',
      scoreB: '0/0',
      venue: venue,
      date: parsedDate,
      status: _fromDbStatus((row['status'] as String?) ?? 'upcoming'),
      flagged: false,
    );
  }

  static MatchStatus _fromDbStatus(String value) {
    switch (value) {
      case 'live':
        return MatchStatus.live;
      case 'completed':
        return MatchStatus.completed;
      default:
        return MatchStatus.upcoming;
    }
  }

  static String _toDbStatus(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return 'live';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.upcoming:
        return 'upcoming';
    }
  }

  static String _abbreviation(String teamName) {
    final letters = teamName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    if (letters.length >= 2) return letters;
    final cleaned = teamName.trim().toUpperCase();
    return cleaned.length >= 2 ? cleaned.substring(0, 2) : cleaned;
  }
}
