// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Servio/src/app.dart';

void main() {
  testWidgets('App boots and renders root widget', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ServioApp()));
    await tester.pump(const Duration(milliseconds: 2600));

    // Smoke assertion: app root is mounted.
    expect(find.byType(ServioApp), findsOneWidget);
  });
}
