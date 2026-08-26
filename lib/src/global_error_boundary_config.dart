import 'dart:async';
import 'package:flutter/material.dart';
import 'error_boundary.dart';
import 'error_details.dart';

/// Provides global default configurations for all descendant [ErrorBoundary] widgets.
class GlobalErrorBoundaryConfig extends InheritedWidget {
  /// Default custom fallback builder used if an [ErrorBoundary] has no local `fallbackBuilder`.
  final ErrorBoundaryFallbackBuilder? fallbackBuilder;

  /// Default logging callback executed whenever any descendant [ErrorBoundary] catches an exception.
  final ErrorBoundaryLogCallback? onError;

  /// Default error filter predicate. Returning false lets the exception propagate upward.
  final bool Function(FlutterErrorBoundaryDetails details)? shouldCatch;

  /// Default setting controlling whether stack traces are expanded in [DefaultErrorFallback].
  final bool? showDebugDetails;

  /// Default pre-retry asynchronous callback executed before resetting the error boundary.
  final FutureOr<void> Function()? onRetry;

  /// Default cooldown duration to rate-limit manual retry button taps.
  final Duration? minRetryCooldown;

  /// Creates a [GlobalErrorBoundaryConfig] widget.
  const GlobalErrorBoundaryConfig({
    super.key,
    required super.child,
    this.fallbackBuilder,
    this.onError,
    this.shouldCatch,
    this.showDebugDetails,
    this.onRetry,
    this.minRetryCooldown,
  });

  /// Obtains the closest [GlobalErrorBoundaryConfig] ancestor in the given [BuildContext].
  static GlobalErrorBoundaryConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlobalErrorBoundaryConfig>();
  }

  @override
  bool updateShouldNotify(GlobalErrorBoundaryConfig oldWidget) {
    return fallbackBuilder != oldWidget.fallbackBuilder ||
        onError != oldWidget.onError ||
        shouldCatch != oldWidget.shouldCatch ||
        showDebugDetails != oldWidget.showDebugDetails ||
        onRetry != oldWidget.onRetry ||
        minRetryCooldown != oldWidget.minRetryCooldown;
  }
}

