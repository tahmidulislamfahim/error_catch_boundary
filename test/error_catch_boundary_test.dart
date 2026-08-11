import 'package:error_catch_boundary/error_catch_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BuggyWidget extends StatelessWidget {
  final bool shouldThrow;
  const BuggyWidget({super.key, required this.shouldThrow});

  @override
  Widget build(BuildContext context) {
    if (shouldThrow) {
      throw Exception('Test build failure inside BuggyWidget');
    }
    return const Text('BuggyWidget Rendered Successfully');
  }
}

void main() {
  testWidgets('renders child widget normally when no error occurs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorBoundary(
          child: Text('Normal Child Widget'),
        ),
      ),
    );

    expect(find.text('Normal Child Widget'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });

  testWidgets('catches build error and displays DefaultErrorFallback with retry button', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Suppress console error output for expected test error
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorBoundary(
          child: BuggyWidget(shouldThrow: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DefaultErrorFallback), findsOneWidget);
    expect(find.text('Something went wrong in this section.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    FlutterError.onError = originalOnError;
  });

  testWidgets('renders custom fallbackBuilder when error occurs', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          fallbackBuilder: (context, details, reset) {
            return Text('Custom Fallback UI: ${details.error}');
          },
          child: const BuggyWidget(shouldThrow: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Custom Fallback UI: Exception: Test build failure inside BuggyWidget'), findsOneWidget);

    FlutterError.onError = originalOnError;
  });

  testWidgets('invokes onError logging callback when an error is caught', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    FlutterErrorBoundaryDetails? caughtDetails;

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          onError: (details) {
            caughtDetails = details;
          },
          child: const BuggyWidget(shouldThrow: true),
        ),
      ),
    );
    await tester.pump();

    expect(caughtDetails, isNotNull);
    expect(caughtDetails!.error.toString(), contains('Test build failure inside BuggyWidget'));
    expect(caughtDetails!.stackTrace, isNotNull);

    FlutterError.onError = originalOnError;
  });

  testWidgets('allows self-healing retry when reset callback is triggered', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    bool shouldFail = true;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: ErrorBoundary(
              child: StatefulBuilder(
                builder: (context, childSetState) {
                  if (shouldFail) {
                    throw Exception('Failing phase');
                  }
                  return const Text('Recovered state!');
                },
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();

    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    // Change state so rebuild succeeds
    shouldFail = false;

    // Tap retry button
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered state!'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);

    FlutterError.onError = originalOnError;
  });

  testWidgets('isolates error so neighboring widgets continue operating normally', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Healthy Neighbor Widget 1'),
              ErrorBoundary(
                child: BuggyWidget(shouldThrow: true),
              ),
              Text('Healthy Neighbor Widget 2'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Healthy Neighbor Widget 1'), findsOneWidget);
    expect(find.text('Healthy Neighbor Widget 2'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    FlutterError.onError = originalOnError;
  });
}
