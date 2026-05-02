import 'package:flutter/material.dart';

import 'models/scoring_models.dart';
import 'route_paths.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_matches_screen.dart';
import 'screens/admin/admin_profile_screen.dart';
import 'screens/admin/admin_reports_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/admin_teams_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/player/player_home_screen.dart';
import 'screens/player/new_match_screen.dart';
import 'screens/player/live_scoring_screen.dart';
import 'screens/player/match_scorecard_screen.dart';

/// Central app route definitions.
class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    Widget? page;
    switch (settings.name) {
      case RoutePaths.splash: page = const SplashScreen(); break;
      case RoutePaths.onboarding: page = const OnboardingScreen(); break;
      case RoutePaths.roleSelect: page = const RoleSelectScreen(); break;
      case RoutePaths.login: page = const LoginScreen(); break;
      case RoutePaths.signup: page = const SignUpScreen(); break;
      case RoutePaths.home: page = const PlayerHomeScreen(); break;
      case RoutePaths.admin: page = const AdminDashboardScreen(); break;
      case RoutePaths.adminUsers: page = const AdminUsersScreen(); break;
      case RoutePaths.adminMatches: page = const AdminMatchesScreen(); break;
      case RoutePaths.adminProfile: page = const AdminProfileScreen(); break;
      case RoutePaths.adminTeams: page = const AdminTeamsScreen(); break;
      case RoutePaths.adminReports: page = const AdminReportsScreen(); break;
      case RoutePaths.adminSettings: page = const AdminSettingsScreen(); break;
      case RoutePaths.newMatch: page = const NewMatchScreen(); break;
      case RoutePaths.liveScoring:
        final args = settings.arguments as ScoringSession?;
        page = args == null ? const PlayerHomeScreen() : LiveScoringScreen(session: args);
        break;
      case RoutePaths.matchScorecard:
        final raw = settings.arguments;
        if (raw is MatchScorecardRouteArgs &&
            raw.matchId.trim().isNotEmpty) {
          page = MatchScorecardScreen(
            matchId: raw.matchId.trim(),
            initialSnapshot: raw.snapshot,
          );
        } else if (raw is String && raw.trim().isNotEmpty) {
          page = MatchScorecardScreen(matchId: raw.trim());
        } else {
          page = const PlayerHomeScreen();
        }
        break;
    }
    if (page == null) return null;

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page!,
      transitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.1, 0), end: Offset.zero);
        final fade = Tween(begin: 0.0, end: 1.0);
        return SlideTransition(
          position: animation.drive(CurveTween(curve: Curves.easeOut)).drive(tween),
          child: FadeTransition(opacity: animation.drive(fade), child: child),
        );
      },
    );
  }
}

