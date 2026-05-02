import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../models/player_models.dart';
import '../models/scoring_models.dart';
import '../services/supabase_service.dart';

enum UserRole { admin, player }

class AuthUser {
  final String email;
  final String password;
  final String name;
  final UserRole role;

  const AuthUser({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });
}

class AppStore extends StatefulWidget {
  final Widget child;
  const AppStore({super.key, required this.child});

  @override
  State<AppStore> createState() => AppStoreState();

  static AppStoreState of(BuildContext context) =>
      context.findAncestorStateOfType<AppStoreState>()!;
}

class AppStoreState extends State<AppStore> {
  UserRole? selectedRole;
  bool isLoggedIn = false;
  String userName = '';
  bool isLoadingMatches = false;
  String? matchesLoadError;
  bool isLoadingTeams = false;
  String? teamsLoadError;
  bool isLoadingUsers = false;
  String? usersLoadError;
  bool isLoadingMemberships = false;
  String? membershipsLoadError;

  final List<TeamMembership> _myMemberships = [];
  List<TeamMembership> get myMemberships => List.unmodifiable(_myMemberships);

  final List<AuthUser> _users = [];

  final List<AdminMatch> _matches = [];

  final List<AdminTeam> _teams = [];

  List<AdminMatch> get matches => List.unmodifiable(_matches);
  List<AdminTeam> get teams => List.unmodifiable(_teams);
  List<AuthUser> get users => List.unmodifiable(_users);

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _hydrateAuthSession();
    _hydrateMatches();
    _hydrateTeams();
    _hydrateUsers();
    _hydrateMyMemberships();
  }

  void _hydrateAuthSession() {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    final role = _userRoleFromString(
      user.userMetadata?['app_role']?.toString(),
    );
    final name = user.userMetadata?['name']?.toString().trim();
    setState(() {
      isLoggedIn = true;
      selectedRole = role;
      userName = (name == null || name.isEmpty) ? user.email ?? '' : name;
      if (user.email != null &&
          !_users.any((u) => u.email.toLowerCase() == user.email!.toLowerCase())) {
        _users.add(
          AuthUser(
            email: user.email!,
            password: '',
            name: userName,
            role: selectedRole ?? UserRole.player,
          ),
        );
      }
    });
  }

  Future<void> _hydrateMatches() async {
    setState(() {
      isLoadingMatches = true;
      matchesLoadError = null;
    });
    try {
      final remoteMatches = await SupabaseService.fetchAdminMatches();
      if (!mounted) return;
      setState(() {
        _matches
          ..clear()
          ..addAll(remoteMatches);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        matchesLoadError = 'Could not load matches from server.';
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoadingMatches = false);
    }
  }

  Future<void> refreshMatches() => _hydrateMatches();

  Future<void> _hydrateTeams() async {
    setState(() {
      isLoadingTeams = true;
      teamsLoadError = null;
    });
    try {
      final remoteTeams = await SupabaseService.fetchAdminTeams();
      if (!mounted) return;
      setState(() {
        _teams
          ..clear()
          ..addAll(remoteTeams);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        teamsLoadError = 'Could not load teams from server.';
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoadingTeams = false);
    }
  }

  Future<void> refreshTeams() => _hydrateTeams();

  Future<void> _hydrateUsers() async {
    setState(() {
      isLoadingUsers = true;
      usersLoadError = null;
    });
    try {
      final profiles = await SupabaseService.fetchProfiles();
      if (!mounted) return;
      final mapped = profiles.map((row) {
        final roleRaw = row['role']?.toString();
        final role = _userRoleFromString(roleRaw);
        return AuthUser(
          email: (row['email'] as String?) ?? '',
          password: '',
          name: (row['name'] as String?) ?? '',
          role: role,
        );
      }).toList();
      setState(() {
        _users
          ..clear()
          ..addAll(mapped);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        usersLoadError = 'Could not load users from backend.';
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoadingUsers = false);
    }
  }

  Future<void> refreshUsers() => _hydrateUsers();

  Future<void> _hydrateMyMemberships() async {
    setState(() {
      isLoadingMemberships = true;
      membershipsLoadError = null;
    });
    try {
      final memberships = await SupabaseService.fetchMyMemberships();
      if (!mounted) return;
      setState(() {
        _myMemberships
          ..clear()
          ..addAll(memberships);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        membershipsLoadError = 'Could not load team memberships.';
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoadingMemberships = false);
    }
  }

  Future<void> refreshMyMemberships() => _hydrateMyMemberships();

  /// Apply for a team. Optimistically inserts a pending record, then syncs.
  Future<void> applyToTeam(TeamInfo team) async {
    // Optimistic insert.
    final optimistic = TeamMembership(
      id: 'opt_${team.id}',
      teamId: team.id,
      teamName: team.name,
      teamAbbreviation: team.abbreviation,
      status: MembershipStatus.pending,
      appliedAt: DateTime.now(),
    );
    setState(() {
      // Remove any prior entry for this team.
      _myMemberships.removeWhere((m) => m.teamName == team.name);
      _myMemberships.insert(0, optimistic);
    });
    try {
      await SupabaseService.applyToTeam(
        teamName: team.name,
        teamAbbreviation: team.abbreviation,
      );
      // Refresh to get server-assigned id.
      await _hydrateMyMemberships();
    } catch (e) {
      if (!mounted) return;
      // Roll back optimistic update.
      setState(() {
        _myMemberships.removeWhere((m) => m.id == optimistic.id);
        membershipsLoadError = 'Failed to apply. Please try again.';
      });
    }
  }

  void setRole(UserRole role) => setState(() => selectedRole = role);

  void login(String name) => setState(() {
        isLoggedIn = true;
        userName = name;
      });

  void registerUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) {
    final normalizedEmail = _normalizeEmail(email);
    final existingIndex = _users.indexWhere(
      (u) => _normalizeEmail(u.email) == normalizedEmail && u.role == role,
    );
    final user = AuthUser(
      email: normalizedEmail,
      password: password,
      name: name.trim(),
      role: role,
    );

    setState(() {
      if (existingIndex >= 0) {
        _users[existingIndex] = user;
      } else {
        _users.add(user);
      }
    });
  }

  AuthUser? authenticate({
    required String email,
    required String password,
    required UserRole role,
  }) {
    final normalizedEmail = _normalizeEmail(email);
    try {
      return _users.firstWhere(
        (u) =>
            u.role == role &&
            _normalizeEmail(u.email) == normalizedEmail &&
            u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    setState(() {
      isLoggedIn = false;
      userName = '';
      selectedRole = null;
    });
  }

  Future<void> updateMatch(AdminMatch updated) async {
    final idx = _matches.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return;
    setState(() {
      _matches[idx] = updated;
    });
    try {
      await SupabaseService.updateAdminMatch(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        matchesLoadError = 'Match saved locally. Backend sync failed.';
      });
    }
  }

  Future<void> flagMatch(String matchId, {String? reason}) async {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx == -1) return;
    setState(() {
      // Keep flagging simple for now; reason can be persisted later.
      _matches[idx] = _matches[idx].copyWith(flagged: true);
    });
    try {
      await SupabaseService.createReport(
        matchId: matchId,
        title: 'Match flagged for review',
        description: reason?.trim().isEmpty ?? true
            ? 'Flagged by admin for manual review.'
            : reason!.trim(),
        severity: 'high',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        matchesLoadError = 'Flag saved locally. Backend report sync failed.';
      });
    }
  }

  void updateTeam(AdminTeam updated) {
    final idx = _teams.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    setState(() {
      _teams[idx] = updated;
    });
  }

  Future<void> addPlayerToTeam({
    required String teamName,
    required String playerName,
    bool isCaptain = false,
  }) async {
    final normalizedTeam = teamName.trim();
    final normalizedPlayer = playerName.trim();
    if (normalizedTeam.isEmpty || normalizedPlayer.isEmpty) return;

    AdminMatch? relatedMatch;
    for (final match in _matches) {
      if (match.teamA == normalizedTeam || match.teamB == normalizedTeam) {
        relatedMatch = match;
        break;
      }
    }
    relatedMatch ??= _matches.isNotEmpty ? _matches.first : null;

    if (relatedMatch == null) {
      setState(() {
        teamsLoadError = 'No match found to attach this player.';
      });
      return;
    }

    try {
      await SupabaseService.addPlayer(
        matchId: relatedMatch.id,
        teamName: normalizedTeam,
        playerName: normalizedPlayer,
        isCaptain: isCaptain,
      );
      await _hydrateTeams();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        teamsLoadError = 'Could not add player to backend.';
      });
    }
  }

  /// Convert a scoring session to AdminMatch and persist to both local state and DB.
  void saveScoringSession(ScoringSession session) {
    final innings1 = session.innings1;
    final innings2 = session.innings2;
    final scoreA = '${innings1?.totalRuns ?? 0}/${innings1?.totalWickets ?? 0}';
    final scoreB = '${innings2?.totalRuns ?? 0}/${innings2?.totalWickets ?? 0}';
    final match = AdminMatch(
      id: session.setup.id,
      teamA: session.setup.teamA,
      teamB: session.setup.teamB,
      scoreA: scoreA,
      scoreB: scoreB,
      venue: session.setup.venue,
      date: session.setup.date,
      status: session.isCompleted ? MatchStatus.completed : MatchStatus.live,
      result: session.result,
      winner: _deriveWinner(session),
    );
    setState(() {
      final idx = _matches.indexWhere((m) => m.id == match.id);
      if (idx >= 0) {
        _matches[idx] = match;
      } else {
        _matches.insert(0, match);
      }
    });
    // Persist to backend (fire-and-forget).
    SupabaseService.updateAdminMatch(match).catchError((_) {});
  }

  String? _deriveWinner(ScoringSession session) {
    if (!session.isCompleted) return null;
    final r1 = session.innings1?.totalRuns ?? 0;
    final r2 = session.innings2?.totalRuns ?? 0;
    if (r1 > r2) return session.setup.battingFirst;
    if (r2 > r1) return session.setup.bowlingFirst;
    return ''; // tie
  }

  @override
  Widget build(BuildContext context) => widget.child;

  UserRole _userRoleFromString(String? role) {
    if (role == UserRole.admin.name) return UserRole.admin;
    return UserRole.player;
  }
}
