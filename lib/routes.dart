import 'package:flutter/material.dart';

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

/// Central app route definitions.
class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = _routeBuilders()[settings.name];
    if (builder == null) return null;

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
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

  static Map<String, WidgetBuilder> _routeBuilders() => {
        RoutePaths.splash: (_) => const SplashScreen(),
        RoutePaths.onboarding: (_) => const OnboardingScreen(),
        RoutePaths.roleSelect: (_) => const RoleSelectScreen(),
        RoutePaths.login: (_) => const LoginScreen(),
        RoutePaths.signup: (_) => const SignUpScreen(),
        RoutePaths.home: (_) => const PlayerHomeScreen(),
        RoutePaths.admin: (_) => const AdminDashboardScreen(),
        RoutePaths.adminUsers: (_) => const AdminUsersScreen(),
        RoutePaths.adminMatches: (_) => const AdminMatchesScreen(),
        RoutePaths.adminProfile: (_) => const AdminProfileScreen(),
        RoutePaths.adminTeams: (_) => const AdminTeamsScreen(),
        RoutePaths.adminReports: (_) => const AdminReportsScreen(),
        RoutePaths.adminSettings: (_) => const AdminSettingsScreen(),
      };
}

