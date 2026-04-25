import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';

class SupabaseService {
  const SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

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
