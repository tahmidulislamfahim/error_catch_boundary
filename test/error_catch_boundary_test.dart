import 'dart:math' as math;
import 'package:error_catch_boundary/error_catch_boundary.dart';
import 'package:flutter/cupertino.dart';
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

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
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

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retrying...'), findsOneWidget);

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

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryAttempts, equals(1));

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      expect(retryAttempts, equals(1));

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      shouldFail = false;

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryAttempts, equals(2));
      expect(find.text('Cooldown Recovered'), findsOneWidget);
    } finally {
      FlutterError.onError = originalOnError;
    }
  });

  testWidgets('ErrorBoundary.async intercepts unhandled asynchronous errors in child zone',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    FlutterErrorBoundaryDetails? caughtDetails;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary.async(
            onError: (details) {
              caughtDetails = details;
            },
            child: Builder(
              builder: (context) {
                Future.microtask(() {
                  throw Exception('Async microtask error inside zone');
                });
                return const Text('Async Child Content');
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(caughtDetails, isNotNull);
    expect(caughtDetails!.error.toString(),
        contains('Async microtask error inside zone'));
    expect(find.byType(DefaultErrorFallback), findsOneWidget);
  });

  testWidgets('uses custom transitionBuilder for AnimatedSwitcher state transitions',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    bool customTransitionUsed = false;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            transitionBuilder: (child, animation) {
              customTransitionUsed = true;
              return ScaleTransition(scale: animation, child: child);
            },
            child: const BuggyWidget(shouldThrow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(customTransitionUsed, isTrue);
    expect(find.byType(ScaleTransition), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsOneWidget);
  });

  test('AutoRetryConfig respects maxDelay cap and jitterFactor', () {
    const config = AutoRetryConfig(
      maxRetries: 5,
      retryInterval: Duration(seconds: 2),
      enableExponentialBackoff: true,
      maxDelay: Duration(seconds: 6),
      jitterFactor: 0.2,
    );

    // attempt 1: 2s (capped at 6s)
    // attempt 2: 4s (capped at 6s)
    // attempt 3: 8s -> capped at 6s
    final delayNoJitter = const AutoRetryConfig(
      maxRetries: 5,
      retryInterval: Duration(seconds: 2),
      enableExponentialBackoff: true,
      maxDelay: Duration(seconds: 6),
    ).getDelayForAttempt(3);
    expect(delayNoJitter, equals(const Duration(seconds: 6)));

    // With jitter with fixed Random seed
    final fixedRandom = math.Random(42);
    final delayWithJitter = config.getDelayForAttempt(3, fixedRandom);
    // Base delay 6s with +/- 20% jitter is between 4.8s and 6.0s (capped at 6s)
    expect(delayWithJitter.inMilliseconds, greaterThanOrEqualTo(4800));
    expect(delayWithJitter.inMilliseconds, lessThanOrEqualTo(6000));
  });

  test('FlutterErrorBoundaryDetails generates unique errorId and timestamp', () {
    final details1 = FlutterErrorBoundaryDetails(
      error: 'test error 1',
      stackTrace: StackTrace.current,
    );
    final details2 = FlutterErrorBoundaryDetails(
      error: 'test error 2',
      stackTrace: StackTrace.current,
    );

    expect(details1.errorId, isNotEmpty);
    expect(details2.errorId, isNotEmpty);
    expect(details1.errorId, isNot(equals(details2.errorId)));
    expect(details1.timestamp, isNotNull);
    expect(details1.toString(), contains(details1.errorId));
  });

  testWidgets('renders customizable and localized strings in DefaultErrorFallback',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    const customStrings = ErrorBoundaryStrings(
      message: 'Un error ha ocurrido en esta sección.',
      retryButton: 'Reintentar',
      retryingButton: 'Reintentando...',
      debugDetailsTitle: 'Detalles de depuración',
    );

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            strings: customStrings,
            child: BuggyWidget(shouldThrow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    expect(find.text('Un error ha ocurrido en esta sección.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('DefaultErrorFallback renders safely inside CupertinoApp without Material ancestor error',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    try {
      await tester.pumpWidget(
        const CupertinoApp(
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

  testWidgets('ErrorBoundary.wrapCallback catches a synchronous throw from onPressed',
      (tester) async {
    FlutterErrorBoundaryDetails? caughtDetails;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorBoundary(
          onError: (details) {
            caughtDetails = details;
          },
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: ErrorBoundary.wrapCallback(context, () {
                  throw Exception('sync onPressed error');
                }),
                child: const Text('Tap me'),
              );
            },
          ),
        ),
      ),
    ));

    expect(find.text('Tap me'), findsOneWidget);
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(caughtDetails, isNotNull);
    expect(caughtDetails!.error.toString(), contains('sync onPressed error'));
    expect(find.byType(DefaultErrorFallback), findsOneWidget);
  });

  testWidgets('ErrorBoundary.wrapCallback catches an asynchronous throw from onPressed',
      (tester) async {
    FlutterErrorBoundaryDetails? caughtDetails;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorBoundary(
          onError: (details) {
            caughtDetails = details;
          },
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: ErrorBoundary.wrapCallback(context, () async {
                  await Future<void>.delayed(const Duration(milliseconds: 10));
                  throw Exception('async onPressed error');
                }),
                child: const Text('Tap me async'),
              );
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Tap me async'));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(caughtDetails, isNotNull);
    expect(caughtDetails!.error.toString(), contains('async onPressed error'));
    expect(find.byType(DefaultErrorFallback), findsOneWidget);
  });

  testWidgets('inherits autoRetryConfig from GlobalErrorBoundaryConfig',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    int buildCount = 0;

    try {
      await tester.pumpWidget(
        GlobalErrorBoundaryConfig(
          autoRetryConfig: const AutoRetryConfig(
            maxRetries: 2,
            retryInterval: Duration(milliseconds: 100),
          ),
          child: MaterialApp(
            home: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  buildCount++;
                  if (buildCount == 1) {
                    throw Exception('First build failure');
                  }
                  return Text('Recovered on build $buildCount');
                },
              ),
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

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(buildCount, equals(2));
    expect(find.text('Recovered on build 2'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });

  testWidgets('ErrorBoundaryController tracks error states, supports targeted reset, and is disposal-safe',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    final controller = ErrorBoundaryController();
    bool failBoundaryA = true;
    bool failBoundaryB = true;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              ErrorBoundary(
                name: 'BoundaryA',
                controller: controller,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    if (failBoundaryA) throw Exception('Boundary A error');
                    return const Text('Boundary A OK');
                  },
                ),
              ),
              ErrorBoundary(
                name: 'BoundaryB',
                controller: controller,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    if (failBoundaryB) throw Exception('Boundary B error');
                    return const Text('Boundary B OK');
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    // Both boundaries should be in error state
    expect(controller.hasError, isTrue);
    expect(controller.errorCount, equals(2));
    expect(controller.failingBoundaryNames, containsAll(['BoundaryA', 'BoundaryB']));

    // Target reset only BoundaryA
    failBoundaryA = false;
    controller.resetBoundary('BoundaryA');
    await tester.pumpAndSettle();

    expect(find.text('Boundary A OK'), findsOneWidget);
    expect(controller.errorCount, equals(1));
    expect(controller.failingBoundaryNames, equals(['BoundaryB']));

    // Reset remaining boundaries
    failBoundaryB = false;
    controller.reset();
    await tester.pumpAndSettle();

    expect(find.text('Boundary B OK'), findsOneWidget);
    expect(controller.hasError, isFalse);
    expect(controller.errorCount, equals(0));

    // Post-disposal reset must not throw
    controller.dispose();
    expect(controller.isDisposed, isTrue);
    expect(() => controller.reset(), returnsNormally);
  });

  testWidgets('nested ErrorBoundary isolates errors to the inner boundary and recovers independently',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    bool failInner = true;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundary(
              name: 'OuterBoundary',
              child: Column(
                children: [
                  const Text('Outer Header'),
                  ErrorBoundary(
                    name: 'InnerBoundary',
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        if (failInner) throw Exception('Inner widget failure');
                        return const Text('Inner Content OK');
                      },
                    ),
                  ),
                  const Text('Outer Footer'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    // Outer boundary content is still visible
    expect(find.text('Outer Header'), findsOneWidget);
    expect(find.text('Outer Footer'), findsOneWidget);

    // Inner boundary shows fallback UI
    expect(find.byType(DefaultErrorFallback), findsOneWidget);
    expect(find.text('Inner Content OK'), findsNothing);

    // Retry inner boundary
    failInner = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    // Now inner is recovered and outer remains intact
    expect(find.text('Inner Content OK'), findsOneWidget);
    expect(find.text('Outer Header'), findsOneWidget);
    expect(find.text('Outer Footer'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);
  });
}
