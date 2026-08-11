import 'package:flutter/material.dart';
import 'package:error_catch_boundary/error_catch_boundary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets(
      'Example app launches, handles simulated UI build error, logs it, and recovers',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Suppress console error logging during expected test failure
    };

    try {
      // 1. Pump main app
      await tester.pumpWidget(const ErrorBoundaryExampleApp());

      // 2. Verify all 3 demo cards render normally initially
      expect(find.text('Item #1'), findsOneWidget);
      expect(find.text('Item #2'), findsOneWidget);
      expect(find.text('Item #3'), findsOneWidget);
      expect(find.text('No errors intercepted yet.'), findsOneWidget);

      // 3. Toggle switch to simulate build failure on Item #2
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Clear any pending exception recorded by the framework
      tester.takeException();

      // 4. Verify Item #1 and Item #3 are still operating normally (isolated!)
      expect(find.text('Item #1'), findsOneWidget);
      expect(find.text('Item #3'), findsOneWidget);

      // 5. Verify Item #2 crashed safely and displays DefaultErrorFallback with retry button
      expect(find.byType(DefaultErrorFallback), findsOneWidget);
      expect(
          find.text('Something went wrong in this section.'), findsOneWidget);

      // 6. Verify error logger stream updated with intercepted exception
      expect(
          find.textContaining(
              'Intercepted error: Exception: Uncaught render failure in Item #2'),
          findsOneWidget);

      // 7. Toggle switch back to healthy state
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // 8. Tap retry button on the error boundary
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // 9. Verify Item #2 has fully recovered and renders normally again!
      expect(find.text('Item #2'), findsOneWidget);
      expect(find.byType(DefaultErrorFallback), findsNothing);
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
