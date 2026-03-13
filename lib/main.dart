import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'state/app_store.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(AppStore(child: const GullyScoreApp()));
}

class GullyScoreApp extends StatelessWidget {
  const GullyScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GullyScore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/':            (_) => const SplashScreen(),
        '/onboarding':  (_) => const OnboardingScreen(),
        '/role-select': (_) => const RoleSelectScreen(),
        '/login':       (_) => const LoginScreen(),
        '/signup':      (_) => const SignUpScreen(),
        '/home':        (_) => const _PlaceholderHome(),
      },
    );
  }
}

// Temporary home placeholder — will be replaced in next step
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
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5C20)),
            ),
            const SizedBox(height: 8),
            Text(
              store.selectedRole == UserRole.admin ? '👑 Admin' : '🏏 Player',
              style:
                  const TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                store.logout();
                Navigator.pushReplacementNamed(context, '/role-select');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5C20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Log Out',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
