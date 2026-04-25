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
}
