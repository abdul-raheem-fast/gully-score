import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_models.dart';
import '../models/player_models.dart';
import '../models/scoring_models.dart';

class SupabaseService {
  const SupabaseService._();

  /// Use for new rows when `matches.id` is a Postgres `uuid` (PostgREST rejects `m_…` style ids).
  static String newMatchId() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  static bool _isUuidString(String id) {
    final u = id.trim().toLowerCase();
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    ).hasMatch(u);
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;

  static String? getCurrentUserRole() =>
      currentUser?.userMetadata?['app_role']?.toString();

  static String? getCurrentUserName() =>
      currentUser?.userMetadata?['name']?.toString();

  static Future<String?> fetchCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final response = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = response?['role']?.toString();
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {}
    return getCurrentUserRole();
  }

  static Future<Map<String, dynamic>> fetchCurrentUserStatus() async {
    final user = currentUser;
    if (user == null) {
      return {'role': null, 'is_blocked': false};
    }
    try {
      final response = await client
          .from('profiles')
          .select('role,is_blocked')
          .eq('id', user.id)
          .maybeSingle();
      if (response != null) {
        return {
          'role': response['role']?.toString() ?? getCurrentUserRole(),
          'is_blocked': (response['is_blocked'] as bool?) ?? false,
        };
      }
    } catch (_) {}
    return {
      'role': getCurrentUserRole(),
      'is_blocked': false,
    };
  }

  static Future<void> signOut() => client.auth.signOut();

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? 'http://localhost:3000/' : 'io.supabase.gullyscore://login-callback',
    );
  }

  static Future<void> sendMagicLink(String email) {
    return client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
      emailRedirectTo: kIsWeb ? 'http://localhost:3000/' : 'io.supabase.gullyscore://login-callback',
    );
  }

  static Future<void> sendPasswordResetOtp(String email) {
    return client.auth.resetPasswordForEmail(
      email.trim(),
    );
  }

  static Future<AuthResponse> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
    await client.auth.updateUser(UserAttributes(password: newPassword));
    return response;
  }

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

  static Future<void> updateAdminProfile({
    required String userId,
    required String name,
    required String organization,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('No authenticated user found.');
    }

    final attributes = UserAttributes(
      data: {
        'name': name.trim(),
        'organization': organization.trim(),
      },
    );

    await client.auth.updateUser(attributes);

    await upsertUserProfile(
      userId: userId,
      email: currentUser.email ?? '',
      name: name,
      role: currentUser.userMetadata?['app_role']?.toString() ?? 'admin',
      organization: organization.isEmpty ? null : organization,
    );
  }

  static Future<List<Map<String, dynamic>>> fetchProfiles() async {
    try {
      final response = await client.functions.invoke(
        'admin-manage',
        body: {'action': 'list_profiles'},
      );
      if (response.data is Map) {
        final payload = response.data as Map<String, dynamic>;
        final rows = payload['profiles'];
        if (rows is List) {
          return List<Map<String, dynamic>>.from(rows);
        }
      }
    } catch (_) {}

    // Fallback to self-profile if admin listing is not available or fails.
    final List<Map<String, dynamic>> responseSelf = await client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return responseSelf;
  }

  static Future<Map<String, dynamic>> fetchCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return {};
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .limit(1);
      final rows = List<Map<String, dynamic>>.from(response);
      if (rows.isEmpty) {
        return {
          'name': getCurrentUserName() ?? '',
          'email': user.email ?? '',
          'playing_role': user.userMetadata?['playing_role']?.toString() ?? '',
          'phone': '',
          'organization': '',
        };
      }
      return rows.first;
    } catch (_) {
      return {
        'name': getCurrentUserName() ?? '',
        'email': user.email ?? '',
        'playing_role': user.userMetadata?['playing_role']?.toString() ?? '',
        'phone': '',
        'organization': '',
      };
    }
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

  static Future<List<AdminMatch>> fetchAdminMatches({int limit = 40}) async {
    final List<Map<String, dynamic>> rows = await client
        .from('matches')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final matches = rows.map(_rowToAdminMatch).toList();
    if (matches.isEmpty) return matches;

    final matchIds =
        matches.map((m) => m.id).where((id) => _isUuidString(id)).toList();
    if (matchIds.isEmpty) return matches;

    final inningsResp = await client
        .from('innings')
        .select('id,match_id,innings_no,batting_team,total_runs,wickets')
        .inFilter('match_id', matchIds)
        .order('innings_no', ascending: true);
    final inningsRows = List<Map<String, dynamic>>.from(inningsResp);
    final byMatch = <String, List<Map<String, dynamic>>>{};
    for (final row in inningsRows) {
      final id = row['match_id']?.toString();
      if (id == null || id.isEmpty) continue;
      byMatch.putIfAbsent(id, () => <Map<String, dynamic>>[]).add(row);
    }

    final inningsIds = inningsRows
        .map((r) => r['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final ballEventsByInningsId = <String, List<Map<String, dynamic>>>{};
    if (inningsIds.isNotEmpty) {
      final ballEventsResp = await client
          .from('ball_events')
          .select('innings_id,runs_off_bat,extra_runs,wicket_type')
          .inFilter('innings_id', inningsIds);
      for (final row in List<Map<String, dynamic>>.from(ballEventsResp)) {
        final innId = row['innings_id']?.toString() ?? '';
        if (innId.isEmpty) continue;
        ballEventsByInningsId
            .putIfAbsent(innId, () => <Map<String, dynamic>>[])
            .add(row);
      }
    }

    return matches.map((m) {
      final innings = byMatch[m.id] ?? const [];
      return _mergeInningsIntoMatch(
        m,
        innings,
        ballEventsByInningsId: ballEventsByInningsId,
      );
    }).toList();
  }

  static Future<AdminMatch?> fetchMatchById(String matchId) async {
    final id = matchId.trim();
    if (id.isEmpty) return null;
    // Avoid GET …&id=eq.m_… which returns 400 when the column is uuid.
    if (_isUuidString(id)) {
      try {
        final response =
            await client.from('matches').select().eq('id', id).limit(1);
        final rows = List<Map<String, dynamic>>.from(response);
        if (rows.isNotEmpty) {
          final base = _rowToAdminMatch(rows.first);
          final innings = await fetchInnings(id);
          final balls = await fetchBallsByMatch(id);
          return _mergeInningsIntoMatch(
            base,
            innings,
            ballsByInningsNo: _ballsByInningsNo(balls),
          );
        }
      } catch (_) {}
    }
    try {
      final all = await fetchAdminMatches();
      for (final m in all) {
        if (m.id == id || m.id.toLowerCase() == id.toLowerCase()) return m;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> tryFetchInnings(String matchId) async {
    try {
      return await fetchInnings(matchId.trim());
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> tryFetchBallsByMatch(
    String matchId,
  ) async {
    try {
      return await fetchBallsByMatch(matchId.trim());
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> tryFetchPlayersByMatch(
    String matchId,
  ) async {
    try {
      return await fetchPlayersByMatch(matchId.trim());
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBallsByMatch(
    String matchId,
  ) async {
    final mid = matchId.trim();
    if (!_isUuidString(mid)) return [];

    // 1. Fetch all innings for this match.
    final inningsResp = await client
        .from('innings')
        .select('id,innings_no')
        .eq('match_id', mid)
        .order('innings_no', ascending: true);
    final inningsRows = List<Map<String, dynamic>>.from(inningsResp);
    if (inningsRows.isEmpty) return [];

    // 2. Batch-fetch all ball events for all innings in one query.
    final List<String> inningsIds = inningsRows
        .map((r) => r['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (inningsIds.isEmpty) return [];

    final List<Map<String, dynamic>> eventsResp = await client
        .from('ball_events')
        .select()
        .inFilter('innings_id', inningsIds)
        .order('over_no', ascending: true)
        .order('ball_no', ascending: true)
        .order('created_at', ascending: true);

    // 3. Map innings_no back to events for client UI.
    final Map<String, int> idToNo = {};
    for (final r in inningsRows) {
      final id = r['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        idToNo[id] = (r['innings_no'] as num?)?.toInt() ?? 1;
      }
    }

    return eventsResp.map((row) {
      final innId = row['innings_id']?.toString() ?? '';
      return {
        ...row,
        'innings_no': idToNo[innId] ?? 1,
        'is_wicket': ((row['wicket_type'] as String?)?.trim().isNotEmpty ?? false),
      };
    }).toList();
  }

  static Future<void> updateAdminMatch(AdminMatch match) async {
    await client.from('matches').update({
      'title': '${match.teamA} vs ${match.teamB}',
      'team_a_name': match.teamA,
      'team_b_name': match.teamB,
      'venue': match.venue,
      'match_date': _toDateString(match.date),
      'status': _toDbStatus(match.status),
      if (match.overs != null) 'overs_per_innings': match.overs,
    }).eq('id', match.id);
  }

  /// Upsert a match row so save works for both brand-new and existing matches.
  static Future<void> upsertAdminMatch(AdminMatch match) async {
    await client.from('matches').upsert({
      'id': match.id,
      'title': '${match.teamA} vs ${match.teamB}',
      'team_a_name': match.teamA,
      'team_b_name': match.teamB,
      'venue': match.venue,
      'match_date': _toDateString(match.date),
      'status': _toDbStatus(match.status),
      if (match.overs != null) 'overs_per_innings': match.overs,
      // Helps list ordering when this is the first write for the id.
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  static Future<void> createMatch(MatchSetup setup) async {
    // Upsert so repeated writes for the same match id do not fail with 409 conflict.
    await client.from('matches').upsert({
      'id': setup.id,
      'title': '${setup.teamA} vs ${setup.teamB}',
      'team_a_name': setup.teamA,
      'team_b_name': setup.teamB,
      'venue': setup.venue,
      'match_date': _toDateString(setup.date),
      'overs_per_innings': setup.overs,
      'toss_winner': setup.tossWinner,
      'toss_decision': setup.electedTo == 'field' ? 'bowl' : setup.electedTo,
      'status': 'live',
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  static Future<void> createInnings(InningsState innings, String matchId) async {
    await client.from('innings').insert({
      'match_id': matchId,
      'innings_no': innings.inningsNo,
      'batting_team': innings.battingTeam,
      'bowling_team': innings.bowlingTeam,
      'total_runs': innings.totalRuns,
      'wickets': innings.totalWickets,
      'balls_bowled': innings.legalBalls,
      'extras': innings.balls.fold(0, (sum, b) => sum + b.extraRuns),
      'is_completed': false,
    });
  }

  static Future<void> createBall(Ball ball, String matchId, int inningsNo) async {
    var inningsId = await _findInningsId(matchId, inningsNo);
    if (inningsId == null) {
      // The innings row can lag briefly right after match start.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      inningsId = await _findInningsId(matchId, inningsNo);
    }
    if (inningsId == null) return;
    await client.from('ball_events').insert({
      'innings_id': inningsId,
      'over_no': ball.overNo,
      'ball_no': ball.ballNo,
      'runs_off_bat': ball.runsOffBat,
      'extra_runs': ball.extraRuns,
      'extra_type': ball.extraType,
      'striker_name': ball.strikerName,
      'non_striker_name': ball.nonStrikerName,
      'bowler_name': ball.bowlerName,
      'wicket_type': ball.wicketType,
      'wicket_player_name': ball.wicketPlayerName,
      'commentary': ball.commentary,
    });
  }

  static Future<void> updateInningsSummary(
    InningsState innings,
    String matchId, {
    bool? isCompleted,
  }) async {
    await client
        .from('innings')
        .update({
          'total_runs': innings.totalRuns,
          'wickets': innings.totalWickets,
          'balls_bowled': innings.legalBalls,
          'extras': innings.balls.fold(0, (sum, b) => sum + b.extraRuns),
          if (isCompleted != null) 'is_completed': isCompleted,
        })
        .eq('match_id', matchId)
        .eq('innings_no', innings.inningsNo);
  }

  static Future<List<AdminTeam>> fetchAdminTeams() async {
    final List<Map<String, dynamic>> teamsRows = await client
      .from('teams')
      .select('id,name,abbreviation,captain_name');
    // Limit players/matches fetch to avoid hitting row limits or 429s as the DB grows.
    final List<Map<String, dynamic>> players = await client.from('team_players').select().limit(1000);
    final List<Map<String, dynamic>> matches = await client
      .from('matches')
      .select('id,team_a_name,team_b_name')
      .order('created_at', ascending: false)
      .limit(100);

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
    for (final row in teamsRows) {
      final teamName = (row['name'] as String?)?.trim() ?? '';
      if (teamName.isEmpty) continue;
      final members = buckets[teamName] ?? const <Map<String, dynamic>>[];
      teams.add(
        AdminTeam(
          id: (row['id'] as String?) ?? '',
          name: teamName,
          abbreviation: (row['abbreviation'] as String?) ?? _abbreviation(teamName),
          captain: (row['captain_name'] as String?) ?? 'Unknown',
          playerCount: members.length,
          matchCount: matchCountByTeam[teamName] ?? 0,
        ),
      );
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
              id: '',
              name: teamName,
              abbreviation: _abbreviation(teamName),
              captain: 'TBD',
              playerCount: 0,
              matchCount: matchCountByTeam[teamName] ?? 0,
            ),
          );
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

  /// Roster row counts from `team_players` (official team registry).
  static Future<Map<String, int>> _teamRosterCountsByName() async {
    try {
      final response = await client.from('team_players').select('team_name');
      final rows = List<Map<String, dynamic>>.from(response);
      final out = <String, int>{};
      for (final r in rows) {
        final t = (r['team_name'] as String?)?.trim() ?? '';
        if (t.isEmpty) continue;
        out[t] = (out[t] ?? 0) + 1;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Teams defined in `public.teams` (may exist without any `matches` / `players` rows).
  static Future<List<TeamInfo>> fetchTeamsRegistry() async {
    try {
      final teamsResp = await client
          .from('teams')
          .select('id,name,abbreviation,captain_name')
          .order('name');
      final teamsRows = List<Map<String, dynamic>>.from(teamsResp);
      if (teamsRows.isEmpty) return [];
      final counts = await _teamRosterCountsByName();
      final list = <TeamInfo>[];
      for (final row in teamsRows) {
        final name = (row['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;
        final abbrRaw = (row['abbreviation'] as String?)?.trim() ?? '';
        final abbr = abbrRaw.isNotEmpty ? abbrRaw : _abbreviation(name);
        final cap = (row['captain_name'] as String?)?.trim() ?? '';
        list.add(
          TeamInfo(
            id: row['id']?.toString() ?? name,
            name: name,
            abbreviation: abbr,
            captain: cap.isNotEmpty ? cap : 'Captain',
            playerCount: counts[name] ?? 0,
            matchCount: 0,
          ),
        );
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Discoverable teams: match-derived list merged with `public.teams` (deduped by name).
  static Future<List<TeamInfo>> fetchTeamsCatalog() async {
    final legacy = await fetchTeams();
    final registry = await fetchTeamsRegistry();
    final byName = <String, TeamInfo>{};
    for (final t in legacy) {
      byName[t.name] = t;
    }
    for (final t in registry) {
      final existing = byName[t.name];
      if (existing != null) {
        byName[t.name] = TeamInfo(
          id: t.id,
          name: t.name,
          abbreviation: t.abbreviation.isNotEmpty ? t.abbreviation : existing.abbreviation,
          captain: t.captain != 'Captain' ? t.captain : existing.captain,
          playerCount: t.playerCount > 0 ? t.playerCount : existing.playerCount,
          matchCount: existing.matchCount,
        );
      } else {
        byName[t.name] = t;
      }
    }
    final merged = byName.values.toList();
    merged.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return merged;
  }

  /// Team names where the signed-in user's display name appears on `team_players`.
  static Future<List<String>> fetchTeamNamesWhereIAmRosterPlayer() async {
    final name = getCurrentUserName()?.trim();
    if (name == null || name.isEmpty) return [];
    try {
      final response = await client
          .from('team_players')
          .select('team_name')
          .eq('player_name', name);
      final rows = List<Map<String, dynamic>>.from(response);
      final out = <String>{};
      for (final r in rows) {
        final t = (r['team_name'] as String?)?.trim() ?? '';
        if (t.isNotEmpty) out.add(t);
      }
      return out.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (_) {
      return [];
    }
  }

  /// Ordered team squad from `team_players` with captain first.
  static Future<List<String>> fetchTeamSquad(String teamName) async {
    final normalized = teamName.trim();
    if (normalized.isEmpty) return [];
    try {
      final response = await client
          .from('team_players')
          .select('player_name,is_captain,joined_at')
          .eq('team_name', normalized)
          .order('is_captain', ascending: false)
          .order('joined_at', ascending: true);
      final rows = List<Map<String, dynamic>>.from(response);
      final seen = <String>{};
      final out = <String>[];
      for (final row in rows) {
        final name = (row['player_name'] as String?)?.trim() ?? '';
        if (name.isEmpty || seen.contains(name)) continue;
        seen.add(name);
        out.add(name);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Inserts `teams` and `team_players` rows (see `20260501_teams_table.sql`).
  static Future<void> createTeam({
    required String name,
    required String abbreviation,
    required String captainName,
    required List<TeamPlayerDetail> roster,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final teamName = name.trim();
    if (teamName.isEmpty) throw Exception('Team name required');

    if (roster.isEmpty) throw Exception('Add at least one player');

    final cap = captainName.trim();
    final captainResolved = cap.isNotEmpty ? cap : roster.first.name;

    await client.from('teams').insert({
      'name': teamName,
      'abbreviation': abbreviation.trim(),
      'captain_user_id': userId,
      'captain_name': captainResolved,
    });

    await client.from('team_players').insert(
      roster
          .map(
            (p) => {
              'team_name': teamName,
              'player_name': p.name,
              'role': p.role,
              'is_captain': p.name == captainResolved,
            },
          )
          .toList(),
    );
  }

  /// Apply for membership in [teamName]. Stores a row in `team_memberships`
  /// and fires a join_request notification to the team captain.
  static Future<void> applyToTeam({
    required String teamName,
    required String teamAbbreviation,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final playerName = getCurrentUserName()?.trim() ?? 'Unknown Player';
    final now = DateTime.now().toIso8601String();
    String? membershipId;

    try {
      // Try a plain insert first.
      final inserted = await client.from('team_memberships').insert({
        'user_id': userId,
        'team_name': teamName,
        'team_abbreviation': teamAbbreviation,
        'player_name': playerName,
        'status': 'pending',
        'applied_at': now,
      }).select('id');
      final rows = List<Map<String, dynamic>>.from(inserted);
      membershipId = rows.isNotEmpty ? rows.first['id']?.toString() : null;
    } catch (e) {
      // If it's a unique-violation (code 23505), update the existing row.
      final msg = e.toString();
      if (msg.contains('23505') || msg.contains('duplicate') || msg.contains('unique')) {
        await client
            .from('team_memberships')
            .update({
              'team_abbreviation': teamAbbreviation,
              'player_name': playerName,
              'status': 'pending',
              'applied_at': now,
            })
            .eq('user_id', userId)
            .eq('team_name', teamName);
        // fetch the row id for notification linking
        try {
          final rows = await client
              .from('team_memberships')
              .select('id')
              .eq('user_id', userId)
              .eq('team_name', teamName)
              .limit(1);
          final r = List<Map<String, dynamic>>.from(rows);
          membershipId = r.isNotEmpty ? r.first['id']?.toString() : null;
        } catch (_) {}
      } else {
        rethrow;
      }
    }

    // Send notification to the captain of this team.
    try {
      final captainRows = await client
          .from('teams')
          .select('captain_user_id')
          .eq('name', teamName)
          .limit(1);
      final cRows = List<Map<String, dynamic>>.from(captainRows);
      if (cRows.isNotEmpty) {
        final captainId = cRows.first['captain_user_id']?.toString();
        if (captainId != null && captainId.isNotEmpty) {
          await client.from('notifications').insert({
            'recipient_id': captainId,
            'sender_id': userId,
            'type': 'join_request',
            'team_name': teamName,
            'player_name': playerName,
            if (membershipId != null) 'membership_id': membershipId,
          });
        }
      }
    } catch (_) {
      // Notification failure must not block the apply action.
    }
  }

  /// Fetch all team_memberships rows for the currently signed-in player.
  static Future<List<TeamMembership>> fetchMyMemberships() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final list = <TeamMembership>[];

    try {
      // 1. Fetch teams where I am the captain
      final ownedResp = await client
          .from('teams')
          .select('id, name, abbreviation, created_at')
          .eq('captain_user_id', userId);
      final ownedRows = List<Map<String, dynamic>>.from(ownedResp);
      for (final row in ownedRows) {
        list.add(TeamMembership(
          id: 'owned_${row['id']}',
          teamId: row['id']?.toString() ?? '',
          teamName: (row['name'] as String?)?.trim() ?? 'Unknown Team',
          teamAbbreviation: (row['abbreviation'] as String?)?.trim() ?? 'TEAM',
          status: MembershipStatus.approved,
          appliedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              DateTime.now(),
        ));
      }

      // 2. Also check team_players where I am marked as captain by name
      final myName = getCurrentUserName()?.trim();
      if (myName != null && myName.isNotEmpty) {
        final rosterResp = await client
            .from('team_players')
            .select('team_name, teams(id, abbreviation, created_at)')
            .eq('player_name', myName)
            .eq('is_captain', true);
        final rosterRows = List<Map<String, dynamic>>.from(rosterResp);
        for (final row in rosterRows) {
          final tName = (row['team_name'] as String?)?.trim() ?? '';
          if (tName.isEmpty || list.any((m) => m.teamName == tName)) continue;

          final tData = row['teams'] as Map<String, dynamic>?;
          list.add(TeamMembership(
            id: 'roster_cap_${tData?['id'] ?? tName}',
            teamId: tData?['id']?.toString() ?? tName,
            teamName: tName,
            teamAbbreviation: (tData?['abbreviation'] as String?)?.trim() ?? '',
            status: MembershipStatus.approved,
            appliedAt: DateTime.tryParse(tData?['created_at']?.toString() ?? '') ??
                DateTime.now(),
          ));
        }
      }

      // 3. Fetch my membership records (applications, joins)
      final response = await client
          .from('team_memberships')
          .select()
          .eq('user_id', userId)
          .order('applied_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(response);
      for (final row in rows) {
        final tName = (row['team_name'] as String?)?.trim() ?? '';
        // Avoid duplicates if already added as owned
        if (list.any((m) => m.teamName == tName)) continue;

        final statusRaw = (row['status'] as String?) ?? 'pending';
        MembershipStatus status;
        switch (statusRaw) {
          case 'approved':
            status = MembershipStatus.approved;
            break;
          case 'rejected':
            status = MembershipStatus.rejected;
            break;
          case 'invited':
            status = MembershipStatus.invited;
            break;
          default:
            status = MembershipStatus.pending;
        }
        list.add(TeamMembership(
          id: row['id']?.toString() ?? '',
          teamId: row['team_name']?.toString() ?? '',
          teamName: tName,
          teamAbbreviation: (row['team_abbreviation'] as String?)?.trim() ?? '',
          status: status,
          appliedAt: DateTime.tryParse(row['applied_at']?.toString() ?? '') ??
              DateTime.now(),
        ));
      }
    } catch (_) {}

    return list..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
  }

  /// Fetch all team_memberships rows for admin (typically pending ones).
  static Future<List<TeamMembership>> fetchAdminMemberships() async {
    final response = await client
        .from('team_memberships')
        .select()
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
        case 'invited':
          status = MembershipStatus.invited;
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

  /// Returns team names where the current user is captain.
  static Future<List<String>> fetchCaptainTeams() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final names = <String>{};
    try {
      final response = await client
          .from('teams')
          .select('name')
          .eq('captain_user_id', userId);
      final rows = List<Map<String, dynamic>>.from(response);
      for (final r in rows) {
        final t = (r['name'] as String?)?.trim() ?? '';
        if (t.isNotEmpty) names.add(t);
      }
    } catch (_) {}
    return names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Returns pending join requests for teams where the current user is captain.
  /// Joins team_memberships with profiles so we get the player's name & email.
  static Future<List<Map<String, dynamic>>> fetchPendingRequestsForCaptain(
      List<String> captainTeams) async {
    if (captainTeams.isEmpty) return [];
    // 1. Fetch pending memberships for those teams.
    final response = await client
        .from('team_memberships')
        .select()
        .inFilter('team_name', captainTeams)
        .eq('status', 'pending')
        .order('applied_at', ascending: true);
    final rows = List<Map<String, dynamic>>.from(response);
    if (rows.isEmpty) return [];

    // 2. Batch-fetch profiles for all unique user_ids to avoid N+1 queries.
    final List<String> userIds = rows
        .map((r) => r['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, Map<String, String>> profilesMap = {};
    if (userIds.isNotEmpty) {
      try {
        final List<Map<String, dynamic>> profilesResp = await client
            .from('profiles')
            .select('id, name, email')
            .inFilter('id', userIds);
        for (final p in profilesResp) {
          final id = p['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            profilesMap[id] = {
              'name': (p['name'] as String?) ?? 'Unknown Player',
              'email': (p['email'] as String?) ?? '',
            };
          }
        }
      } catch (_) {}
    }

    // 3. Merge profile data back into membership rows.
    return rows.map((row) {
      final uid = row['user_id']?.toString() ?? '';
      final pData = profilesMap[uid];
      return {
        ...row,
        'player_name': pData?['name'] ?? 'Unknown Player',
        'user_email': pData?['email'] ?? '',
      };
    }).toList();
  }

  /// Approve or reject a membership request and notify the applicant.
  static Future<void> _invokeAdminManage(Map<String, dynamic> body) async {
    await client.functions.invoke('admin-manage', body: body);
  }

  static Future<void> deleteTeam(String teamId) async {
    await _invokeAdminManage({
      'action': 'delete_team',
      'teamId': teamId,
    });
  }

  static Future<void> blockUser(String userId) async {
    await _invokeAdminManage({
      'action': 'block_user',
      'userId': userId,
    });
  }

  static Future<void> unblockUser(String userId) async {
    await _invokeAdminManage({
      'action': 'unblock_user',
      'userId': userId,
    });
  }

  static Future<void> setUserRole({
    required String userId,
    required String role,
  }) async {
    await _invokeAdminManage({
      'action': 'set_user_role',
      'userId': userId,
      'role': role,
    });
  }
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

    // Send a notification to the applicant.
    try {
      final rows = await client
          .from('team_memberships')
          .select('user_id, team_name, player_name')
          .eq('id', id)
          .limit(1);
      final r = List<Map<String, dynamic>>.from(rows);
      if (r.isNotEmpty) {
        final applicantId = r.first['user_id']?.toString() ?? '';
        final teamName = r.first['team_name']?.toString() ?? '';
        final playerName = r.first['player_name']?.toString() ?? '';
        final captainId = currentUser?.id ?? '';
        if (applicantId.isNotEmpty) {
          await client.from('notifications').insert({
            'recipient_id': applicantId,
            'sender_id': captainId.isNotEmpty ? captainId : null,
            'type': status == 'approved' ? 'request_approved' : 'request_rejected',
            'team_name': teamName,
            'player_name': playerName,
            'membership_id': id,
          });
        }
      }
    } catch (_) {
      // Notification failure must not block the status update.
    }
  }

  // ── Notifications ────────────────────────────────────────────────

  /// Fetch all notifications for the current user, newest first.
  static Future<List<Map<String, dynamic>>> fetchMyNotifications() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      // Fetch notifications
      final response = await client
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(response);

      // Verify teams still exist for join_requests
      final teamNames = list
          .where((n) => n['team_name'] != null)
          .map((n) => n['team_name'].toString())
          .toSet();
      
      if (teamNames.isEmpty) return list;

      final teamCheck = await client
          .from('teams')
          .select('name')
          .inFilter('name', teamNames.toList());
      final existingTeams = List<Map<String, dynamic>>.from(teamCheck)
          .map((t) => t['name'].toString())
          .toSet();

      // Filter out notifications for non-existent teams if they are requests
      return list.where((n) {
        final t = n['team_name']?.toString() ?? '';
        final type = n['type']?.toString() ?? '';
        if (t.isNotEmpty && (type == 'join_request' || type == 'team_invitation')) {
          return existingTeams.contains(t);
        }
        return true;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteNotification(String id) async {
    await client.from('notifications').delete().eq('id', id);
  }

  /// Count unread notifications for the current user.
  static Future<int> fetchUnreadNotificationCount() async {
    final userId = currentUser?.id;
    if (userId == null) return 0;
    try {
      final response = await client
          .from('notifications')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);
      return List<Map<String, dynamic>>.from(response).length;
    } catch (_) {
      return 0;
    }
  }

  /// Mark a single notification as read.
  static Future<void> markNotificationRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  /// Mark all notifications for the current user as read.
  static Future<void> markAllNotificationsRead() async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  /// Check if the current user is already an approved member of ANY team.
  static Future<String?> checkIfUserInTeam() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    try {
      final response = await client
          .from('team_memberships')
          .select('team_name')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .limit(1);
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.isNotEmpty ? rows.first['team_name']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch all profiles that are not approved members of any team.
  static Future<List<Map<String, dynamic>>> fetchTeamlessPlayers() async {
    try {
      final response = await client.rpc('get_teamless_players');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      // Fallback if RPC fails: just fetch all profiles
      final resp = await client.from('profiles').select();
      return List<Map<String, dynamic>>.from(resp);
    }
  }

  /// Captain invites a player to join their team.
  static Future<void> invitePlayerToTeam({
    required String teamName,
    required String teamAbbreviation,
    required String targetUserId,
    required String targetPlayerName,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now().toIso8601String();
    
    // 1. Create/Update membership with 'invited' status
    final inserted = await client.from('team_memberships').upsert({
      'user_id': targetUserId,
      'team_name': teamName,
      'team_abbreviation': teamAbbreviation,
      'player_name': targetPlayerName,
      'status': 'invited',
      'applied_at': now,
    }, onConflict: 'user_id, team_name').select('id');
    
    final rows = List<Map<String, dynamic>>.from(inserted);
    final membershipId = rows.isNotEmpty ? rows.first['id']?.toString() : null;

    // 2. Send notification to the player
    final captainName = getCurrentUserName() ?? 'A Captain';
    await client.from('notifications').insert({
      'recipient_id': targetUserId,
      'sender_id': userId,
      'type': 'team_invitation', 
      'team_name': teamName,
      'player_name': captainName,
      if (membershipId != null) 'membership_id': membershipId,
    });
  }

  /// Fetch a team's saved roster (names + roles).
  static Future<List<TeamPlayerDetail>> fetchTeamRoster(String teamName) async {
    try {
      final response = await client.rpc('get_team_roster', params: {'t_name': teamName});
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map((r) => TeamPlayerDetail(
        name: r['player_name']?.toString() ?? '',
        role: r['role']?.toString() ?? 'Batsman',
        isCaptain: r['is_captain'] == true,
      )).toList();
    } catch (_) {
      // Fallback: direct query
      final response = await client.from('team_players').select().eq('team_name', teamName);
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map((r) => TeamPlayerDetail(
        name: r['player_name']?.toString() ?? '',
        role: r['role']?.toString() ?? 'Batsman',
        isCaptain: r['is_captain'] == true,
      )).toList();
    }
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
    final mid = matchId.trim();
    if (!_isUuidString(mid)) return [];
    final response = await client
        .from('players')
        .select()
        .eq('match_id', mid)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }


  static Future<List<Map<String, dynamic>>> fetchInnings(String matchId) async {
    final mid = matchId.trim();
    if (!_isUuidString(mid)) return [];
    final response = await client
        .from('innings')
        .select()
        .eq('match_id', mid)
        .order('innings_no', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<String?> _findInningsId(String matchId, int inningsNo) async {
    final response = await client
        .from('innings')
        .select('id')
        .eq('match_id', matchId)
        .eq('innings_no', inningsNo)
        .limit(1);
    final rows = List<Map<String, dynamic>>.from(response);
    if (rows.isEmpty) return null;
    final id = rows.first['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return id;
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
    final scoreA = '0/0';
    final scoreB = '0/0';

    return AdminMatch(
      id: row['id']?.toString() ?? '${teamA}_$teamB',
      teamA: teamA,
      teamB: teamB,
      scoreA: scoreA,
      scoreB: scoreB,
      venue: venue,
      date: parsedDate,
      status: _fromDbStatus((row['status'] as String?) ?? 'upcoming'),
      flagged: false,
      result: null,
      winner: null,
      overs: (row['overs_per_innings'] as num?)?.toInt(),
    );
  }

  static String _toDateString(DateTime dt) => dt.toIso8601String().split('T').first;

  static Map<int, List<Map<String, dynamic>>> _ballsByInningsNo(
    List<Map<String, dynamic>> balls,
  ) {
    final out = <int, List<Map<String, dynamic>>>{};
    for (final b in balls) {
      final no = (b['innings_no'] as num?)?.toInt() ?? 0;
      if (no <= 0) continue;
      out.putIfAbsent(no, () => <Map<String, dynamic>>[]).add(b);
    }
    return out;
  }

  static AdminMatch _mergeInningsIntoMatch(
    AdminMatch match,
    List<Map<String, dynamic>> inningsRows, {
    Map<String, List<Map<String, dynamic>>> ballEventsByInningsId = const {},
    Map<int, List<Map<String, dynamic>>> ballsByInningsNo = const {},
  }) {
    String scoreA = match.scoreA;
    String scoreB = match.scoreB;

    int? runsA;
    int? runsB;
    int? wktsA;
    int? wktsB;

    for (final row in inningsRows) {
      final batting = (row['batting_team'] as String?)?.trim() ?? '';
      final inningsNo = (row['innings_no'] as num?)?.toInt() ?? 0;
      var runs = (row['total_runs'] as num?)?.toInt() ?? 0;
      var wkts = (row['wickets'] as num?)?.toInt() ?? 0;
      final inningsId = row['id']?.toString() ?? '';

      final events =
          inningsId.isNotEmpty ? (ballEventsByInningsId[inningsId] ?? const []) : const <Map<String, dynamic>>[];
      final balls = ballsByInningsNo[inningsNo] ?? const <Map<String, dynamic>>[];
      if ((runs == 0 && wkts == 0) && (events.isNotEmpty || balls.isNotEmpty)) {
        if (events.isNotEmpty) {
          runs = events.fold<int>(
            0,
            (sum, e) =>
                sum +
                ((e['runs_off_bat'] as num?)?.toInt() ?? 0) +
                ((e['extra_runs'] as num?)?.toInt() ?? 0),
          );
          wkts = events
              .where((e) => ((e['wicket_type'] as String?)?.trim().isNotEmpty ?? false))
              .length;
        } else {
          runs = balls.fold<int>(
            0,
            (sum, b) =>
                sum +
                ((b['runs_off_bat'] as num?)?.toInt() ?? 0) +
                ((b['extra_runs'] as num?)?.toInt() ?? 0),
          );
          wkts = balls
              .where((b) => ((b['wicket_type'] as String?)?.trim().isNotEmpty ?? false))
              .length;
        }
      }

      final battingNorm = batting.toLowerCase();
      final teamANorm = match.teamA.trim().toLowerCase();
      final teamBNorm = match.teamB.trim().toLowerCase();
      if (battingNorm == teamANorm || (battingNorm.isEmpty && inningsNo == 1)) {
        runsA = runs;
        wktsA = wkts;
      } else if (battingNorm == teamBNorm || (battingNorm.isEmpty && inningsNo == 2)) {
        runsB = runs;
        wktsB = wkts;
      }
    }

    if (runsA != null) scoreA = '$runsA/${wktsA ?? 0}';
    if (runsB != null) scoreB = '$runsB/${wktsB ?? 0}';

    String? winner = match.winner;
    String? result = match.result;
    if (runsA != null && runsB != null) {
      if (runsA > runsB) {
        winner = match.teamA;
        result = '${match.teamA} won by ${runsA - runsB} runs';
      } else if (runsB > runsA) {
        winner = match.teamB;
        result = '${match.teamB} won by ${runsB - runsA} runs';
      } else {
        winner = '';
        result = 'Match Tied';
      }
    }

    return match.copyWith(
      scoreA: scoreA,
      scoreB: scoreB,
      winner: winner,
      result: result,
    );
  }

  static Ball ballFromRow(Map<String, dynamic> row, int id) {
    return Ball(
      id: id,
      overNo: (row['over_no'] as num?)?.toInt() ?? 0,
      ballNo: (row['ball_no'] as num?)?.toInt() ?? 0,
      runsOffBat: (row['runs_off_bat'] as num?)?.toInt() ?? 0,
      extraRuns: (row['extra_runs'] as num?)?.toInt() ?? 0,
      extraType: row['extra_type'] as String?,
      isWicket: row['is_wicket'] == true || (row['wicket_type'] != null && (row['wicket_type'] as String).isNotEmpty),
      wicketType: row['wicket_type'] as String?,
      wicketPlayerName: row['wicket_player_name'] as String?,
      strikerName: row['striker_name'] as String?,
      nonStrikerName: row['non_striker_name'] as String?,
      bowlerName: row['bowler_name'] as String?,
      commentary: row['commentary'] as String?,
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

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final t = name.trim();
    if (t.length >= 2) return t.substring(0, 2).toUpperCase();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  // ── Player Rankings ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchAllBallEvents() async {
    final response = await client
        .from('ball_events')
        .select('striker_name,bowler_name,runs_off_bat,wicket_type,wicket_player_name')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchAllPlayersRoster() async {
    final response = await client
        .from('players')
        .select('player_name,match_id,team_name')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Aggregates real per-player stats from ball_events and rosters.
  static Future<List<PlayerRanking>> fetchPlayerRankings() async {
    try {
      // 1. Profiles
      final profilesResp = await client
          .from('profiles')
          .select('id,name,email')
          .eq('role', 'player')
          .order('name');
      final profiles = List<Map<String, dynamic>>.from(profilesResp);

      // 2. Approved team memberships
      final memResp = await client
          .from('team_memberships')
          .select('user_id,team_name,status')
          .eq('status', 'approved');
      final memberships = List<Map<String, dynamic>>.from(memResp);

      // 3. Player roster (matches played)
      final roster = await fetchAllPlayersRoster();

      // 4. Ball events for batting / bowling / dismissals
      final ballEvents = await fetchAllBallEvents();

      // ── Build lookup maps ──
      final teamByUserId = <String, String>{};
      for (final row in memberships) {
        final uid = row['user_id']?.toString() ?? '';
        final tname = (row['team_name'] as String?)?.trim() ?? '';
        if (uid.isNotEmpty && tname.isNotEmpty) teamByUserId[uid] = tname;
      }

      final matchCountByName = <String, Set<String>>{};
      final teamByName = <String, String>{};
      for (final row in roster) {
        final name = (row['player_name'] as String?)?.trim() ?? '';
        final mid = (row['match_id'] as String?)?.trim() ?? '';
        final tname = (row['team_name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;
        if (mid.isNotEmpty) matchCountByName.putIfAbsent(name, () => <String>{}).add(mid);
        if (tname.isNotEmpty) teamByName[name] = tname;
      }

      // Batting aggregates
      final runsByName = <String, int>{};
      final ballsByName = <String, int>{};
      for (final row in ballEvents) {
        final striker = (row['striker_name'] as String?)?.trim() ?? '';
        if (striker.isEmpty) continue;
        final runs = (row['runs_off_bat'] as num?)?.toInt() ?? 0;
        runsByName[striker] = (runsByName[striker] ?? 0) + runs;
        ballsByName[striker] = (ballsByName[striker] ?? 0) + 1;
      }

      // Bowling wickets
      final wicketsByName = <String, int>{};
      for (final row in ballEvents) {
        final bowler = (row['bowler_name'] as String?)?.trim() ?? '';
        final wtype = (row['wicket_type'] as String?)?.trim() ?? '';
        if (bowler.isEmpty || wtype.isEmpty) continue;
        wicketsByName[bowler] = (wicketsByName[bowler] ?? 0) + 1;
      }

      // Dismissals
      final dismissalsByName = <String, int>{};
      for (final row in ballEvents) {
        final wtype = (row['wicket_type'] as String?)?.trim() ?? '';
        if (wtype.isEmpty) continue;
        final victim = (row['wicket_player_name'] as String?)?.trim() ?? '';
        if (victim.isEmpty) continue;
        dismissalsByName[victim] = (dismissalsByName[victim] ?? 0) + 1;
      }

      // Build rankings from profiles
      final rankings = <PlayerRanking>[];
      for (final profile in profiles) {
        final name = (profile['name'] as String?)?.trim() ?? '';
        final id = profile['id']?.toString() ?? '';
        if (name.isEmpty) continue;

        final teamName = teamByUserId[id] ?? teamByName[name] ?? '—';
        final matches = matchCountByName[name]?.length ?? 0;
        final runs = runsByName[name] ?? 0;
        final balls = ballsByName[name] ?? 0;
        final wickets = wicketsByName[name] ?? 0;
        final dismissals = dismissalsByName[name] ?? 0;

        final average = dismissals > 0
            ? double.parse((runs / dismissals).toStringAsFixed(1))
            : (runs > 0 ? double.parse(runs.toStringAsFixed(1)) : 0.0);
        final strikeRate = balls > 0
            ? double.parse(((runs / balls) * 100).toStringAsFixed(1))
            : 0.0;

        // Simple rating 0-10 based on normalized contributions
        final rating = _computeRating(
          runs: runs,
          average: average,
          strikeRate: strikeRate,
          wickets: wickets,
          matches: matches,
        );

        rankings.add(PlayerRanking(
          name: name,
          initials: _initials(name),
          teamName: teamName,
          matches: matches,
          runs: runs,
          average: average,
          strikeRate: strikeRate,
          wickets: wickets,
          rating: rating,
        ));
      }

      // Fallback: if no profiles, build from roster names
      if (rankings.isEmpty) {
        for (final entry in teamByName.entries) {
          final name = entry.key;
          if (rankings.any((r) => r.name.toLowerCase() == name.toLowerCase())) continue;
          final matches = matchCountByName[name]?.length ?? 0;
          final runs = runsByName[name] ?? 0;
          final balls = ballsByName[name] ?? 0;
          final wickets = wicketsByName[name] ?? 0;
          final dismissals = dismissalsByName[name] ?? 0;
          final average = dismissals > 0
              ? double.parse((runs / dismissals).toStringAsFixed(1))
              : 0.0;
          final strikeRate = balls > 0
              ? double.parse(((runs / balls) * 100).toStringAsFixed(1))
              : 0.0;
          final rating = _computeRating(
            runs: runs,
            average: average,
            strikeRate: strikeRate,
            wickets: wickets,
            matches: matches,
          );
          rankings.add(PlayerRanking(
            name: name,
            initials: _initials(name),
            teamName: entry.value,
            matches: matches,
            runs: runs,
            average: average,
            strikeRate: strikeRate,
            wickets: wickets,
            rating: rating,
          ));
        }
      }

      return rankings;
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Error fetching player rankings: $e');
      print('Stack trace: $stackTrace');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  static double _computeRating({
    required int runs,
    required double average,
    required double strikeRate,
    required int wickets,
    required int matches,
  }) {
    if (matches == 0) return 0.0;
    // Normalize each metric to roughly 0-10 scale
    final runsNorm = (runs / 100).clamp(0.0, 10.0);
    final avgNorm = (average / 10).clamp(0.0, 10.0);
    final srNorm = (strikeRate / 20).clamp(0.0, 10.0);
    final wktsNorm = (wickets / 5).clamp(0.0, 10.0);
    final matchesNorm = (matches / 5).clamp(0.0, 10.0);
    final raw = (runsNorm * 0.25) +
        (avgNorm * 0.25) +
        (srNorm * 0.15) +
        (wktsNorm * 0.15) +
        (matchesNorm * 0.20);
    return double.parse(raw.clamp(0.0, 10.0).toStringAsFixed(1));
  }

  /// Full player stats from database for the currently signed-in user.
  static Future<PlayerStatsSnapshot> fetchCurrentPlayerStats() async {
    final user = currentUser;
    final userId = user?.id;
    final fallback = const PlayerStatsSnapshot(
      matches: 0,
      runs: 0,
      average: 0,
      strikeRate: 0,
      wickets: 0,
      overallRating: 0,
      battingImpact: 0,
      consistency: 0,
      fielding: 0,
      sportsmanship: 0,
      recentFormRuns: <int>[],
    );
    if (userId == null) return fallback;

    final profileRows = await client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .limit(1);
    final profileList = List<Map<String, dynamic>>.from(profileRows);
    final playerName = (profileList.isNotEmpty
            ? (profileList.first['name'] as String?)?.trim()
            : null) ??
        getCurrentUserName()?.trim() ??
        '';
    if (playerName.isEmpty) return fallback;

    final rosterResp = await client
        .from('players')
        .select('match_id')
        .eq('player_name', playerName);
    final rosterRows = List<Map<String, dynamic>>.from(rosterResp);
    final matchIds = <String>{};
    for (final row in rosterRows) {
      final matchId = row['match_id']?.toString().trim() ?? '';
      if (matchId.isNotEmpty) matchIds.add(matchId);
    }
    final matches = matchIds.length;
    if (matchIds.isEmpty) return fallback;

    final inningsResp = await client
        .from('innings')
        .select('id,match_id,innings_no,is_completed')
        .inFilter('match_id', matchIds.toList());
    final inningsRows = List<Map<String, dynamic>>.from(inningsResp);
    final inningsById = <String, Map<String, dynamic>>{};
    for (final row in inningsRows) {
      final id = row['id']?.toString() ?? '';
      if (id.isNotEmpty) inningsById[id] = row;
    }

    final ballResp = inningsById.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await client
            .from('ball_events')
            .select(
                'innings_id,runs_off_bat,wicket_type,wicket_player_name,striker_name,bowler_name')
            .inFilter('innings_id', inningsById.keys.toList()));

    int totalRuns = 0;
    int totalBalls = 0;
    int dismissals = 0;
    int wickets = 0;
    final runsByMatch = <String, int>{};
    final wicketsByMatch = <String, int>{};
    final completedInningsByMatch = <String, int>{};

    for (final row in inningsRows) {
      final matchId = row['match_id']?.toString() ?? '';
      final isCompleted = row['is_completed'] == true;
      if (matchId.isNotEmpty && isCompleted) {
        completedInningsByMatch[matchId] =
            (completedInningsByMatch[matchId] ?? 0) + 1;
      }
    }

    int catches = 0;
    final runsList = <int>[];

    for (final e in ballResp) {
      final inningsId = e['innings_id']?.toString() ?? '';
      final innings = inningsById[inningsId];
      final matchId = innings?['match_id']?.toString() ?? '';
      final striker = (e['striker_name'] as String?)?.trim() ?? '';
      final bowler = (e['bowler_name'] as String?)?.trim() ?? '';
      final wicketType = (e['wicket_type'] as String?)?.trim() ?? '';
      final wicketPlayer = (e['wicket_player_name'] as String?)?.trim() ?? '';
      final runs = (e['runs_off_bat'] as num?)?.toInt() ?? 0;

      if (striker == playerName) {
        totalRuns += runs;
        totalBalls += 1;
        if (matchId.isNotEmpty) {
          runsByMatch[matchId] = (runsByMatch[matchId] ?? 0) + runs;
        }
      }
      if (wicketType.isNotEmpty && wicketPlayer == playerName) {
        if (wicketType.toLowerCase().contains('caught') || wicketType.toLowerCase().contains('stumped')) {
          catches += 1;
        } else {
          dismissals += 1;
        }
      }
      if (bowler == playerName && wicketType.isNotEmpty && !wicketType.toLowerCase().contains('run out')) {
        wickets += 1;
        if (matchId.isNotEmpty) {
          wicketsByMatch[matchId] = (wicketsByMatch[matchId] ?? 0) + 1;
        }
      }
    }

    // Dynamic Batting Impact: Strike rate (normalized around 150) + Runs per match
    final average = dismissals > 0 ? totalRuns / dismissals : totalRuns.toDouble();
    final strikeRate = totalBalls > 0 ? (totalRuns / totalBalls) * 100 : 0.0;
    
    // Penalize impact and consistency for very low match counts to make them "earned"
    final matchFactor = (matches / 5.0).clamp(0.4, 1.0);
    
    final battingImpact = (((strikeRate / 25) + (totalRuns / (matches * 15).clamp(1, 1000))) * matchFactor).clamp(0.0, 10.0);
    
    // Consistency: Based on runs variance and scores above 20
    final double scoresAbove20 = runsByMatch.values.where((v) => v >= 20).length.toDouble();
    final consistency = matches > 0 
        ? ((5.0 + (scoresAbove20 / matches * 5.0)) * matchFactor).clamp(0.0, 10.0) 
        : 0.0;
    
    // Fielding: Catches + participation
    final fielding = (5.0 + (catches * 1.2) + (matches * 0.1)).clamp(0.0, 10.0);
    
    // Sportsmanship: Baseline 7.5 + tiny experience factor
    final sportsmanship = matches > 0 ? (7.0 + (matches * 0.15).clamp(0.0, 2.5)) : 0.0;

    final overall = ((battingImpact * 0.35) +
            (consistency * 0.3) +
            (fielding * 0.25) +
            (sportsmanship * 0.1))
        .clamp(0.0, 10.0);

    final formEntries = runsByMatch.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final recentRuns = formEntries.map((e) => e.value).toList();
    if (recentRuns.length > 6) {
      recentRuns.removeRange(0, recentRuns.length - 6);
    }
    // Pad with -1 to indicate "no match" so UI can show empty slots
    while (recentRuns.length < 6) {
      recentRuns.insert(0, -1);
    }

    return PlayerStatsSnapshot(
      matches: matches,
      runs: totalRuns,
      average: double.parse(average.toStringAsFixed(1)),
      strikeRate: double.parse(strikeRate.toStringAsFixed(1)),
      wickets: wickets,
      overallRating: double.parse(overall.toStringAsFixed(1)),
      battingImpact: double.parse(battingImpact.toStringAsFixed(1)),
      consistency: double.parse(consistency.toStringAsFixed(1)),
      fielding: double.parse(fielding.toStringAsFixed(1)),
      sportsmanship: double.parse(sportsmanship.toStringAsFixed(1)),
      recentFormRuns: recentRuns,
    );
  }

  static Future<Map<String, dynamic>> fetchAdminDashboardStats() async {
    try {
      final users = await client.from('profiles').select('id');
      final teams = await client.from('teams').select('id');
      final matches = await client.from('matches').select('id');
      
      return {
        'total_users': users.length,
        'total_teams': teams.length,
        'total_matches': matches.length,
      };
    } catch (_) {
      return {
        'total_users': 0,
        'total_teams': 0,
        'total_matches': 0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAdminAuditLogs() async {
    try {
      final response = await client
          .from('admin_audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
