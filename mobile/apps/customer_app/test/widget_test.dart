import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servio_customer/src/app.dart';

void main() {
  testWidgets('App boots and renders root widget', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ServioApp()));
    await tester.pump(const Duration(milliseconds: 2600));

    // Smoke assertion: app root is mounted.
    expect(find.byType(ServioApp), findsOneWidget);
  });
}
