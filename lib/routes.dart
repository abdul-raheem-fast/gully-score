import 'package:flutter/material.dart';

import 'route_paths.dart';
import 'state/app_store.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_matches_screen.dart';
import 'screens/admin/admin_teams_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

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
        RoutePaths.home: (_) => const _PlaceholderHome(),
        RoutePaths.admin: (_) => const AdminDashboardScreen(),
        RoutePaths.adminUsers: (_) => const AdminUsersScreen(),
        RoutePaths.adminMatches: (_) => const AdminMatchesScreen(),
        RoutePaths.adminTeams: (_) => const AdminTeamsScreen(),
      };
}

// Temporary home placeholder — keeps existing app flow while the full player home is built.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏏', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${store.userName.isEmpty ? "Player" : store.userName}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A5C20)),
            ),
            const SizedBox(height: 8),
            Text(
              store.selectedRole == UserRole.admin ? '👑 Admin' : '🏏 Player',
              style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),
            if (store.selectedRole == UserRole.admin)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RoutePaths.admin),
                  icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF1565C0)),
                  label: const Text('Open admin panel', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                store.logout();
                Navigator.pushReplacementNamed(context, RoutePaths.roleSelect);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5C20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
