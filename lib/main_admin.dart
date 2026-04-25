import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'route_paths.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'state/app_store.dart';
import 'config/supabase_config.dart';

/// Admin-only app entry point.
/// Keeps admin routing/theme isolated from the player app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(AppStore(child: const AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GullyScore Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: RoutePaths.admin,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
