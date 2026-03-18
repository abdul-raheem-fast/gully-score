import 'package:flutter/material.dart';

import '../models/admin_models.dart';

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

  // ── Hardcoded demo users ─────────────────────────────────────
  // These allow login without registering.  Credentials:
  //   Player  →  player@gmail.com  /  Player@123
  //   Admin   →  admin@gmail.com   /  Admin@123
  final List<AuthUser> _users = [
    const AuthUser(
      email: 'player@gmail.com',
      password: 'Player@123',
      name: 'Babar Azam',
      role: UserRole.player,
    ),
    const AuthUser(
      email: 'admin@gmail.com',
      password: 'Admin@123',
      name: 'Demo Admin',
      role: UserRole.admin,
    ),
  ];

  // In-memory demo data for admin screens.
  final List<AdminMatch> _matches = [
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

  final List<AdminTeam> _teams = [
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

  List<AdminMatch> get matches => List.unmodifiable(_matches);
  List<AdminTeam> get teams => List.unmodifiable(_teams);
  List<AuthUser> get users => List.unmodifiable(_users);

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
    final existingIndex = _users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase() && u.role == role,
    );
    final user = AuthUser(
      email: email.trim(),
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
    try {
      return _users.firstWhere(
        (u) =>
            u.role == role &&
            u.email.toLowerCase() == email.trim().toLowerCase() &&
            u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  void logout() => setState(() {
        isLoggedIn = false;
        userName = '';
        selectedRole = null;
      });

  void updateMatch(AdminMatch updated) {
    final idx = _matches.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return;
    setState(() {
      _matches[idx] = updated;
    });
  }

  void updateTeam(AdminTeam updated) {
    final idx = _teams.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    setState(() {
      _teams[idx] = updated;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
