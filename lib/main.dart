import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'route_paths.dart';
import 'routes.dart';
import 'state/app_store.dart';

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
      initialRoute: RoutePaths.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
