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

  testWidgets('renders custom fallbackBuilder when error occurs',
      (WidgetTester tester) async {
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

    expect(
        find.textContaining(
            'Custom Fallback UI: Exception: Test build failure inside BuggyWidget'),
        findsOneWidget);

    FlutterError.onError = originalOnError;
  });

  testWidgets('invokes onError logging callback when an error is caught',
      (WidgetTester tester) async {
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
    expect(caughtDetails!.error.toString(),
        contains('Test build failure inside BuggyWidget'));
    expect(caughtDetails!.stackTrace, isNotNull);

    FlutterError.onError = originalOnError;
  });

  testWidgets('allows self-healing retry when reset callback is triggered',
      (WidgetTester tester) async {
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

    shouldFail = false;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered state!'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);

    FlutterError.onError = originalOnError;
  });

  testWidgets(
      'isolates error so neighboring widgets continue operating normally',
      (WidgetTester tester) async {
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

  testWidgets('resets state via ErrorBoundaryController',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    final controller = ErrorBoundaryController();
    bool shouldFail = true;

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
    await tester.pump();

    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    shouldFail = false;
    controller.reset();
    await tester.pumpAndSettle();

    expect(find.text('Controller Recovered State'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);

    FlutterError.onError = originalOnError;
  });

  testWidgets('inherits fallbackBuilder and onError from GlobalErrorBoundaryConfig',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    FlutterErrorBoundaryDetails? globalLoggedDetails;

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
    await tester.pump();

    expect(
        find.textContaining(
            'Global Fallback UI: Exception: Test build failure inside BuggyWidget'),
        findsOneWidget);
    expect(globalLoggedDetails, isNotNull);
    expect(globalLoggedDetails!.error.toString(),
        contains('Test build failure inside BuggyWidget'));

    FlutterError.onError = originalOnError;
  });

  testWidgets('respects shouldCatch predicate filter',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorBoundary(
          shouldCatch: (details) {
            // Ignore IgnorableException
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
    await tester.pump();

    // Since shouldCatch returned false, fallback builder is not used by the error boundary
    expect(find.text('Caught Error Fallback'), findsNothing);

    FlutterError.onError = originalOnError;
  });

  testWidgets('executes auto-retry mechanism when AutoRetryConfig is provided',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    int buildCount = 0;

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

    expect(find.byType(DefaultErrorFallback), findsOneWidget);

    // Fast-forward time for auto-retry
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.text('Success on build 2'), findsOneWidget);
    expect(find.byType(DefaultErrorFallback), findsNothing);

    FlutterError.onError = originalOnError;
  });

  testWidgets('renders Debug Details in DefaultErrorFallback when showDebugDetails is true',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

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
    await tester.pump();

    expect(find.byType(DefaultErrorFallback), findsOneWidget);
    expect(find.text('Debug Details'), findsOneWidget);

    FlutterError.onError = originalOnError;
  });
}
