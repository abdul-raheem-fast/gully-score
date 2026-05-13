import 'package:flutter/material.dart';

import 'models/scoring_models.dart';
import 'route_paths.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_edit_profile_screen.dart';
import 'screens/admin/admin_inbox_screen.dart';
import 'screens/admin/admin_matches_screen.dart';
import 'screens/admin/admin_players_screen.dart';
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
import 'screens/player/ai_chat_screen.dart';
import 'screens/player/rankings_screen.dart';
import 'widgets/app_gates.dart';

/// Central app route definitions.
class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    Widget? page;
    switch (settings.name) {
      case RoutePaths.splash:
        page = const SplashScreen();
        break;
      case RoutePaths.onboarding:
        page = const OnboardingScreen();
        break;
      case RoutePaths.roleSelect:
        page = const RoleSelectScreen();
        break;
      case RoutePaths.login:
        page = const LoginScreen();
        break;
      case RoutePaths.signup:
        page = const SignUpScreen();
        break;
      case RoutePaths.forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case RoutePaths.otpReset:
        page = const OtpResetScreen();
        break;
      case RoutePaths.home:
        page = const MaintenanceGate(child: PlayerHomeScreen());
        break;
      case RoutePaths.admin:
        page = const AdminGate(child: AdminDashboardScreen());
        break;
      case RoutePaths.adminUsers:
        page = const AdminGate(child: AdminUsersScreen());
        break;
      case RoutePaths.adminPlayers:
        page = const AdminGate(child: AdminPlayersScreen());
        break;
      case RoutePaths.adminInbox:
        page = const AdminGate(child: AdminInboxScreen());
        break;
      case RoutePaths.adminMatches:
        page = const AdminGate(child: AdminMatchesScreen());
        break;
      case RoutePaths.adminProfile:
        page = const AdminGate(child: AdminProfileScreen());
        break;
      case RoutePaths.adminEditProfile:
        page = const AdminGate(child: AdminEditProfileScreen());
        break;
      case RoutePaths.adminTeams:
        page = const AdminGate(child: AdminTeamsScreen());
        break;
      case RoutePaths.adminReports:
        page = const AdminGate(child: AdminReportsScreen());
        break;
      case RoutePaths.adminSettings:
        page = const AdminGate(child: AdminSettingsScreen());
        break;
      case RoutePaths.adminAiChat:
        page = const AdminGate(child: AiChatScreen(isAdminView: true));
        break;
      case RoutePaths.newMatch:
        page = const MaintenanceGate(child: NewMatchScreen());
        break;
      case RoutePaths.aiChat:
        page = const MaintenanceGate(child: AiChatScreen());
        break;
      case RoutePaths.rankings:
        page = const MaintenanceGate(child: RankingsScreen());
        break;
      case RoutePaths.liveScoring:
        final args = settings.arguments as ScoringSession?;
        page = args == null
            ? const MaintenanceGate(child: PlayerHomeScreen())
            : MaintenanceGate(child: LiveScoringScreen(session: args));
        break;
      case RoutePaths.matchScorecard:
        final raw = settings.arguments;
        if (raw is MatchScorecardRouteArgs && raw.matchId.trim().isNotEmpty) {
          page = MaintenanceGate(
            child: MatchScorecardScreen(
              matchId: raw.matchId.trim(),
              initialSnapshot: raw.snapshot,
            ),
          );
        } else if (raw is String && raw.trim().isNotEmpty) {
          page = MaintenanceGate(
            child: MatchScorecardScreen(matchId: raw.trim()),
          );
        } else {
          page = const MaintenanceGate(child: PlayerHomeScreen());
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
          position:
              animation.drive(CurveTween(curve: Curves.easeOut)).drive(tween),
          child: FadeTransition(opacity: animation.drive(fade), child: child),
        );
      },
    );
  }
}
