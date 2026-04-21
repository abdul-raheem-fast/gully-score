import 'package:flutter/material.dart';

import 'route_paths.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'state/app_store.dart';

/// Admin-only entry point (separate from the normal user app).
///

///
/// Example (from CLI):
///   flutter run -t lib/main_admin.dart
///
void main() {
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
