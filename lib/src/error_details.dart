import 'package:flutter/foundation.dart';

/// Holds standardized exception details caught by an [ErrorBoundary].
class FlutterErrorBoundaryDetails {
  /// The caught exception or error object.
  final Object error;

  /// The stack trace associated with the caught error.
  final StackTrace stackTrace;

  /// Optional information collector containing contextual details from Flutter.
  final InformationCollector? informationCollector;

  /// Creates details for an error caught within an [ErrorBoundary].
  const FlutterErrorBoundaryDetails({
    required this.error,
    required this.stackTrace,
    this.informationCollector,
  });

  @override
  String toString() {
    return 'FlutterErrorBoundaryDetails(error: $error, stackTrace: $stackTrace)';
  }
}
