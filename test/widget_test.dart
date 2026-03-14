// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gullyscore/main.dart';
import 'package:gullyscore/screens/splash_screen.dart';

void main() {
  testWidgets('App launches and shows the splash screen',
      (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const GullyScoreApp());

    // The first screen should be the splash screen.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
