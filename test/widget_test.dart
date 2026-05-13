// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lets_chat/main.dart';
import 'package:lets_chat/firebase_options.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(const LetsChatApp());

    // The splash screen schedules a delayed navigation. Let timers complete.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // App is mostly UI-driven and doesn't include the default counter.
    // A basic smoke test is enough: ensure it shows the app shell.
    expect(find.text("Let's Chat"), findsWidgets);
  });
}
