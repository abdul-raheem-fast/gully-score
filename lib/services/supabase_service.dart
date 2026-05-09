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
    final inningsResp = await client
        .from('innings')
        .select('id,innings_no')
        .eq('match_id', mid)
        .order('innings_no', ascending: true);
    final inningsRows = List<Map<String, dynamic>>.from(inningsResp);
    if (inningsRows.isEmpty) return [];

    final out = <Map<String, dynamic>>[];
    for (final inn in inningsRows) {
      final inningsId = inn['id']?.toString();
      final inningsNo = (inn['innings_no'] as num?)?.toInt() ?? 1;
      if (inningsId == null || inningsId.isEmpty) continue;
      final eventsResp = await client
          .from('ball_events')
          .select()
          .eq('innings_id', inningsId)
          .order('over_no', ascending: true)
          .order('ball_no', ascending: true)
          .order('created_at', ascending: true);
      final events = List<Map<String, dynamic>>.from(eventsResp);
      for (final row in events) {
        out.add({
          ...row,
          'innings_no': inningsNo,
          'is_wicket':
              ((row['wicket_type'] as String?)?.trim().isNotEmpty ?? false),
        });
      }
    }
    return out;
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

  /// Inserts `teams` and `team_players` rows (see `20260501_teams_table.sql`).
  static Future<void> createTeam({
    required String name,
    required String abbreviation,
    required String captainName,
    required List<String> playerNames,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final teamName = name.trim();
    if (teamName.isEmpty) throw Exception('Team name required');

    final cap = captainName.trim();
    final seen = <String>{};
    final roster = <String>[];

    void addPlayer(String raw) {
      final p = raw.trim();
      if (p.isEmpty || seen.contains(p)) return;
      seen.add(p);
      roster.add(p);
    }

    if (cap.isNotEmpty) addPlayer(cap);
    for (final p in playerNames) {
      addPlayer(p);
    }

    if (roster.isEmpty) throw Exception('Add at least one player');

    final captainResolved = cap.isNotEmpty ? cap : roster.first;

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
              'player_name': p,
              'is_captain': p == captainResolved,
            },
          )
          .toList(),
    );
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

  /// Returns team names where the current user is captain in `players` or in `teams`.
  static Future<List<String>> fetchCaptainTeams() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final names = <String>{};
    final userName = getCurrentUserName();
    if (userName != null && userName.isNotEmpty) {
      final response = await client
          .from('players')
          .select('team_name')
          .eq('player_name', userName)
          .eq('is_captain', true);
      final rows = List<Map<String, dynamic>>.from(response);
      for (final r in rows) {
        final t = (r['team_name'] as String?)?.trim() ?? '';
        if (t.isNotEmpty) names.add(t);
      }
    }
    try {
      final teamsResp = await client
          .from('teams')
          .select('name')
          .eq('captain_user_id', userId);
      for (final row in List<Map<String, dynamic>>.from(teamsResp)) {
        final n = (row['name'] as String?)?.trim() ?? '';
        if (n.isNotEmpty) names.add(n);
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
      isWicket: row['is_wicket'] == true,
      wicketType: row['wicket_type'] as String?,
      wicketPlayerName: row['wicket_player_name'] as String?,
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
}
