import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/matches_list_screen.dart';
import '../screens/match_setup_screen.dart';
import '../screens/live_scoring_screen.dart';
import '../screens/scorecard_screen.dart';
import '../screens/match_feedback_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/player_analytics_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/main_navigation.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const main = '/main';
  static const home = '/home';
  static const matchesList = '/matches';
  static const matchSetup = '/match-setup';
  static const liveScoring = '/live-scoring';
  static const scorecard = '/scorecard';
  static const matchFeedback = '/match-feedback';
  static const leaderboard = '/leaderboard';
  static const playerAnalytics = '/player-analytics';
  static const profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen());
      case onboarding:
        return _slideRoute(const OnboardingScreen());
      case login:
        return _slideRoute(const LoginScreen());
      case signup:
        return _slideRoute(const SignupScreen());
      case forgotPassword:
        return _slideRoute(const ForgotPasswordScreen());
      case main:
        return _fadeRoute(const MainNavigation());
      case matchSetup:
        return _slideRoute(const MatchSetupScreen(), direction: AxisDirection.up);
      case liveScoring:
        return _slideRoute(const LiveScoringScreen());
      case scorecard:
        return _slideRoute(const ScorecardScreen());
      case matchFeedback:
        return _slideRoute(const MatchFeedbackScreen());
      case leaderboard:
        return _slideRoute(const LeaderboardScreen());
      case playerAnalytics:
        return _slideRoute(const PlayerAnalyticsScreen());
      default:
        return _fadeRoute(const SplashScreen());
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page, {AxisDirection direction = AxisDirection.left}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case AxisDirection.left:
            begin = const Offset(1.0, 0.0);
            break;
          case AxisDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          default:
            begin = const Offset(1.0, 0.0);
        }
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
