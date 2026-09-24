import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Holds standardized exception details caught by an [ErrorBoundary].
class FlutterErrorBoundaryDetails {
  /// The caught exception or error object.
  final Object error;

  /// The stack trace associated with the caught error.
  final StackTrace stackTrace;

  /// Optional information collector containing contextual details from Flutter.
  final InformationCollector? informationCollector;

  /// Optional name or tag identifier of the [ErrorBoundary] that caught this error.
  final String? name;

  /// The precise timestamp when this error was captured.
  final DateTime timestamp;

  /// A unique, stable identifier for this error incident (useful for telemetry correlation).
  final String errorId;

  static int _idCounter = 0;

  static String _generateErrorId() {
    _idCounter++;
    final micros = DateTime.now().microsecondsSinceEpoch;
    final randomPart =
        math.Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'eb_${micros.toRadixString(16)}_$randomPart$_idCounter';
  }

  /// Creates details for an error caught within an [ErrorBoundary].
  FlutterErrorBoundaryDetails({
    required this.error,
    required this.stackTrace,
    this.informationCollector,
    this.name,
    DateTime? timestamp,
    String? errorId,
  })  : timestamp = timestamp ?? DateTime.now(),
        errorId = errorId ?? _generateErrorId();

  /// Constant constructor when all values including [timestamp] and [errorId] are known.
  const FlutterErrorBoundaryDetails.raw({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.errorId,
    this.informationCollector,
    this.name,
  });

  /// Creates a copy of this [FlutterErrorBoundaryDetails] with updated fields.
  FlutterErrorBoundaryDetails copyWith({
    Object? error,
    StackTrace? stackTrace,
    InformationCollector? informationCollector,
    String? name,
    DateTime? timestamp,
    String? errorId,
  }) {
    return FlutterErrorBoundaryDetails.raw(
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      informationCollector: informationCollector ?? this.informationCollector,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      errorId: errorId ?? this.errorId,
    );
  }

  @override
  String toString() {
    return 'FlutterErrorBoundaryDetails(id: $errorId, timestamp: $timestamp, name: $name, error: $error, stackTrace: $stackTrace)';
  }
}
