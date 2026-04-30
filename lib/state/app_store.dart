import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../models/player_models.dart';
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

  // In-memory sample data used by admin screens.
  static final List<AdminMatch> _seedMatches = [
    AdminMatch(
      id: 'm1',
      teamA: 'Alpha Blasters',
      teamB: 'Cricket Kings',
      scoreA: '125/6',
      scoreB: '110/8',
      venue: 'Model Town Ground',
      date: DateTime(2026, 3, 12, 19, 0),
      status: MatchStatus.live,
    ),
    AdminMatch(
      id: 'm2',
      teamA: 'City Champs',
      teamB: 'Valley Victors',
      scoreA: '0/0',
      scoreB: '0/0',
      venue: 'Greenfield Stadium',
      date: DateTime(2026, 3, 20, 16, 0),
      status: MatchStatus.upcoming,
    ),
    AdminMatch(
      id: 'm3',
      teamA: 'Rapid Rangers',
      teamB: 'Mighty Sixers',
      scoreA: '180/4',
      scoreB: '178/5',
      venue: 'Hilltop Arena',
      date: DateTime(2026, 2, 28, 18, 30),
      status: MatchStatus.completed,
    ),
    AdminMatch(
      id: 'm4',
      teamA: 'Storm Strikers',
      teamB: 'Emerald Eagles',
      scoreA: '0/0',
      scoreB: '0/0',
      venue: 'Riverfront Oval',
      date: DateTime(2026, 3, 26, 17, 0),
      status: MatchStatus.upcoming,
    ),
  ];

  final List<AdminMatch> _matches = List<AdminMatch>.from(_seedMatches);

  static const List<AdminTeam> _seedTeams = [
    const AdminTeam(
      id: 't1',
      name: 'Alpha Blasters',
      abbreviation: 'AB',
      captain: 'Ahmed Raza',
      playerCount: 11,
      matchCount: 23,
    ),
    const AdminTeam(
      id: 't2',
      name: 'City Champs',
      abbreviation: 'CC',
      captain: 'Sara Khan',
      playerCount: 12,
      matchCount: 19,
    ),
    const AdminTeam(
      id: 't3',
      name: 'River Riders',
      abbreviation: 'RR',
      captain: 'Bilal Ahmed',
      playerCount: 10,
      matchCount: 15,
    ),
    const AdminTeam(
      id: 't4',
      name: 'Storm Strikers',
      abbreviation: 'SS',
      captain: 'Zain Malik',
      playerCount: 14,
      matchCount: 21,
    ),
    const AdminTeam(
      id: 't5',
      name: 'Mighty Sixers',
      abbreviation: 'MS',
      captain: 'Hira Ali',
      playerCount: 13,
      matchCount: 18,
    ),
  ];

  final List<AdminTeam> _teams = List<AdminTeam>.from(_seedTeams);

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
          ..addAll(remoteMatches.isEmpty ? _seedMatches : remoteMatches);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        matchesLoadError = 'Using local data while backend is unavailable.';
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
          ..addAll(remoteTeams.isEmpty ? _seedTeams : remoteTeams);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        teamsLoadError = 'Using local teams while backend is unavailable.';
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

  @override
  Widget build(BuildContext context) => widget.child;

  UserRole _userRoleFromString(String? role) {
    if (role == UserRole.admin.name) return UserRole.admin;
    return UserRole.player;
  }
}
