import 'package:error_catch_boundary/error_catch_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BuggyWidget extends StatelessWidget {
  final bool shouldThrow;
  final String errorMessage;

  const BuggyWidget({
    super.key,
    required this.shouldThrow,
    this.errorMessage = 'Test build failure inside BuggyWidget',
  });

  @override
  Widget build(BuildContext context) {
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
    return const Text('BuggyWidget Rendered Successfully');
  }
}

class IgnorableException implements Exception {
  final String message;
  IgnorableException(this.message);
  @override
  String toString() => 'IgnorableException: $message';
}

void main() {
  testWidgets('renders child widget normally when no error occurs',
      (WidgetTester tester) async {
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

  testWidgets(
      'catches build error and displays DefaultErrorFallback with retry button',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {};

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: BuggyWidget(shouldThrow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.byType(DefaultErrorFallback), findsOneWidget);
    expect(find.text('Something went wrong in this section.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders custom fallbackBuilder when error occurs',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    try {
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
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(
        find.textContaining(
            'Custom Fallback UI: Exception: Test build failure inside BuggyWidget'),
        findsOneWidget);
  });

  testWidgets('invokes onError logging callback when an error is caught',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    FlutterErrorBoundaryDetails? caughtDetails;

    try {
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
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(caughtDetails, isNotNull);
    expect(caughtDetails!.error.toString(),
        contains('Test build failure inside BuggyWidget'));
    expect(caughtDetails!.stackTrace, isNotNull);
  });

  testWidgets('allows self-healing retry when reset callback is triggered',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    bool shouldFail = true;

    try {
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
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    shouldFail = false;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered state!'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });

  testWidgets(
      'isolates error so neighboring widgets continue operating normally',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    try {
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
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.text('Healthy Neighbor Widget 1'), findsOneWidget);
    expect(find.text('Healthy Neighbor Widget 2'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsOneWidget);
  });

  testWidgets('resets state via ErrorBoundaryController',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    final controller = ErrorBoundaryController();
    bool shouldFail = true;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            controller: controller,
            child: StatefulBuilder(
              builder: (context, setState) {
                if (shouldFail) {
                  throw Exception('Controller test failure');
                }
                return const Text('Controller Recovered State');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    shouldFail = false;
    controller.reset();
    await tester.pumpAndSettle();

    expect(find.text('Controller Recovered State'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });

  testWidgets('inherits fallbackBuilder and onError from GlobalErrorBoundaryConfig',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    FlutterErrorBoundaryDetails? globalLoggedDetails;

    try {
      await tester.pumpWidget(
        GlobalErrorBoundaryConfig(
          onError: (details) {
            globalLoggedDetails = details;
          },
          fallbackBuilder: (context, details, reset) {
            return Text('Global Fallback UI: ${details.error}');
          },
          child: const MaterialApp(
            home: ErrorBoundary(
              child: BuggyWidget(shouldThrow: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(
        find.textContaining(
            'Global Fallback UI: Exception: Test build failure inside BuggyWidget'),
        findsOneWidget);
    expect(globalLoggedDetails, isNotNull);
    expect(globalLoggedDetails!.error.toString(),
        contains('Test build failure inside BuggyWidget'));
  });

  testWidgets('respects shouldCatch predicate filter',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            shouldCatch: (details) {
              return details.error is! IgnorableException;
            },
            fallbackBuilder: (context, details, reset) {
              return const Text('Caught Error Fallback');
            },
            child: Builder(
              builder: (context) {
                throw IgnorableException('Do not catch me');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.text('Caught Error Fallback'), findsNothing);
  });

  testWidgets('executes auto-retry mechanism when AutoRetryConfig is provided',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    int buildCount = 0;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            autoRetryConfig: const AutoRetryConfig(
              maxRetries: 2,
              retryInterval: Duration(milliseconds: 100),
            ),
            child: Builder(
              builder: (context) {
                buildCount++;
                if (buildCount == 1) {
                  throw Exception('First attempt failure');
                }
                return Text('Success on build $buildCount');
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    // Fast-forward time for auto-retry timer
    await tester.pump(const Duration(milliseconds: 150));
    // Pump the rebuild frame triggered by _reset()
    await tester.pump();
    // Pump to complete AnimatedSwitcher transition
    await tester.pump(const Duration(milliseconds: 300));

    expect(buildCount, equals(2));
    expect(find.text('Success on build 2'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });



  testWidgets('renders Debug Details in DefaultErrorFallback when showDebugDetails is true',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: GlobalErrorBoundaryConfig(
            showDebugDetails: true,
            child: ErrorBoundary(
              child: BuggyWidget(shouldThrow: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.byType(DefaultErrorFallback), findsOneWidget);
    expect(find.text('Debug Details'), findsOneWidget);
  });

  testWidgets('captures name parameter in FlutterErrorBoundaryDetails and onError callback',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    FlutterErrorBoundaryDetails? caughtDetails;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            name: 'DashboardAnalyticsBoundary',
            onError: (details) {
              caughtDetails = details;
            },
            child: const BuggyWidget(shouldThrow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(caughtDetails, isNotNull);
    expect(caughtDetails!.name, equals('DashboardAnalyticsBoundary'));
    expect(caughtDetails.toString(), contains('name: DashboardAnalyticsBoundary'));
  });

  testWidgets('executes async onRetry hook before resetting error boundary',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    bool shouldFail = true;
    bool onRetryHookExecuted = false;

    try {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: ErrorBoundary(
                onRetry: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  onRetryHookExecuted = true;
                  shouldFail = false;
                },
                child: StatefulBuilder(
                  builder: (context, childSetState) {
                    if (shouldFail) {
                      throw Exception('Async hook failure');
                    }
                    return const Text('Async Hook Recovered');
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.byType(DefaultErrorFallback), findsOneWidget);
    expect(onRetryHookExecuted, isFalse);

    // Tap retry button
    await tester.tap(find.text('Retry'));
    await tester.pump();

    // Verify loading indicator is displayed during async execution
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retrying...'), findsOneWidget);

    // Advance clock past the delay
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(onRetryHookExecuted, isTrue);
    expect(find.text('Async Hook Recovered'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });

  testWidgets('enforces minRetryCooldown rate-limiting on manual retry taps',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    int retryAttempts = 0;
    bool shouldFail = true;

    try {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: ErrorBoundary(
                minRetryCooldown: const Duration(milliseconds: 200),
                onRetry: () {
                  retryAttempts++;
                },
                child: StatefulBuilder(
                  builder: (context, childSetState) {
                    if (shouldFail) {
                      throw Exception('Cooldown test failure');
                    }
                    return const Text('Cooldown Recovered');
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DefaultErrorFallback), findsOneWidget);
      expect(retryAttempts, equals(0));

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryAttempts, equals(1));

      // Tap again immediately while cooling down (button is disabled)
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // retryAttempts should still be 1 (ignored due to cooldown)
      expect(retryAttempts, equals(1));

      // Advance past cooldown duration
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      shouldFail = false;

      // Tap again after cooldown
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryAttempts, equals(2));
      expect(find.text('Cooldown Recovered'), findsOneWidget);
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}




