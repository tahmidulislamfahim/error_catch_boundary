import 'dart:async';
import 'package:flutter/material.dart';
import 'auto_retry_config.dart';
import 'default_error_widget.dart';
import 'error_boundary_controller.dart';
import 'error_details.dart';
import 'global_error_boundary_config.dart';

/// Signature for building a custom fallback UI when an error occurs inside [ErrorBoundary].
typedef ErrorBoundaryFallbackBuilder = Widget Function(
  BuildContext context,
  FlutterErrorBoundaryDetails details,
  VoidCallback reset,
);

/// Signature for logging errors caught by [ErrorBoundary].
typedef ErrorBoundaryLogCallback = void Function(
  FlutterErrorBoundaryDetails details,
);

/// A React-inspired error boundary wrapper for Flutter widgets.
///
/// [ErrorBoundary] catches render-tree and `build()` errors in its subtree,
/// prevents the entire app UI from crashing, logs errors via [onError], and
/// displays a localized fallback UI with optional self-healing retry, programmatic control,
/// error predicate filtering, and auto-retry capabilities.
class ErrorBoundary extends StatefulWidget {
  /// The widget tree protected by this error boundary.
  final Widget child;

  /// Optional builder to supply a custom fallback UI when an error occurs.
  /// If null, [GlobalErrorBoundaryConfig.fallbackBuilder] or [DefaultErrorFallback] will be used.
  final ErrorBoundaryFallbackBuilder? fallbackBuilder;

  /// Optional callback invoked when an error is caught, useful for sending
  /// stack traces to monitoring services (e.g., Sentry, Firebase Crashlytics).
  final ErrorBoundaryLogCallback? onError;

  /// Optional controller to programmatically trigger resets from outside the boundary.
  final ErrorBoundaryController? controller;

  /// Optional predicate callback to decide whether an error should be caught by this boundary.
  /// If this returns `false`, the boundary ignores the exception, allowing standard Flutter
  /// error handling to take over.
  final bool Function(FlutterErrorBoundaryDetails details)? shouldCatch;

  /// Optional configuration for automated retry attempts when an error occurs.
  final AutoRetryConfig? autoRetryConfig;

  /// Duration of the smooth transition between active child and fallback states.
  final Duration transitionDuration;

  /// Creates an [ErrorBoundary] widget.
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
    this.controller,
    this.shouldCatch,
    this.autoRetryConfig,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorBoundaryDetails? _errorDetails;
  int _retryCount = 0;
  Timer? _autoRetryTimer;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_reset);
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_reset);
      widget.controller?.addListener(_reset);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_reset);
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  /// Resets the error boundary state and attempts to rebuild the child widget tree.
  void _reset() {
    _autoRetryTimer?.cancel();
    if (mounted) {
      setState(() {
        _errorDetails = null;
      });
    }
  }

  FlutterErrorBoundaryDetails _createDetails(FlutterErrorDetails details) {
    return FlutterErrorBoundaryDetails(
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      informationCollector: details.informationCollector,
    );
  }

  void _handleError(
      FlutterErrorBoundaryDetails details, GlobalErrorBoundaryConfig? globalConfig) {
    final filter = widget.shouldCatch ?? globalConfig?.shouldCatch;
    if (filter != null && !filter(details)) {
      // Predicate returned false, do not intercept or catch
      return;
    }

    if (mounted && _errorDetails?.error != details.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onError?.call(details);
          globalConfig?.onError?.call(details);

          setState(() {
            _errorDetails = details;
          });

          _scheduleAutoRetry();
        }
      });
    }
  }

  void _scheduleAutoRetry() {
    final retryConfig = widget.autoRetryConfig;
    if (retryConfig != null && _retryCount < retryConfig.maxRetries) {
      _retryCount++;
      final delay = retryConfig.getDelayForAttempt(_retryCount);
      _autoRetryTimer?.cancel();
      _autoRetryTimer = Timer(delay, () {
        if (mounted) {
          _reset();
        }
      });
    }
  }

  Widget _buildFallback(
      BuildContext context, FlutterErrorBoundaryDetails details) {
    final globalConfig = GlobalErrorBoundaryConfig.of(context);
    final builder = widget.fallbackBuilder ?? globalConfig?.fallbackBuilder;

    if (builder != null) {
      return builder(context, details, _reset);
    }
    return DefaultErrorFallback(
      details: details,
      onRetry: () {
        _retryCount = 0; // Manual retry resets auto-retry count
        _reset();
      },
      showDebugDetails: globalConfig?.showDebugDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalConfig = GlobalErrorBoundaryConfig.of(context);

    final Widget currentContent;
    if (_errorDetails != null) {
      currentContent = KeyedSubtree(
        key: ValueKey('fallback_${_errorDetails.hashCode}'),
        child: _buildFallback(context, _errorDetails!),
      );
    } else {
      currentContent = KeyedSubtree(
        key: const ValueKey('child_content'),
        child: ErrorWidgetBuilderInterceptor(
          onError: (details) {
            final boundaryDetails = _createDetails(details);
            _handleError(boundaryDetails, globalConfig);
            return _buildFallback(context, boundaryDetails);
          },
          child: widget.child,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: widget.transitionDuration,
      child: currentContent,
    );
  }
}

/// Private helper widget to intercept `ErrorWidget.builder` during subtree build.
class ErrorWidgetBuilderInterceptor extends StatelessWidget {
  /// The child widget tree being protected.
  final Widget child;

  /// Callback executed when an error occurs during `child` build.
  final Widget Function(FlutterErrorDetails details) onError;

  /// Creates an [ErrorWidgetBuilderInterceptor].
  const ErrorWidgetBuilderInterceptor({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  StatelessElement createElement() {
    return ErrorWidgetBuilderInterceptorElement(this);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Element for [ErrorWidgetBuilderInterceptor] that safely overrides [ErrorWidget.builder]
/// for the duration of the rebuild pass and always restores the original builder.
class ErrorWidgetBuilderInterceptorElement extends StatelessElement {
  /// Creates an element for the given [ErrorWidgetBuilderInterceptor].
  ErrorWidgetBuilderInterceptorElement(
      ErrorWidgetBuilderInterceptor super.widget);

  @override
  void performRebuild() {
    final originalBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      ErrorWidget.builder = originalBuilder;
      final interceptorWidget = widget as ErrorWidgetBuilderInterceptor;
      return interceptorWidget.onError(details);
    };

    try {
      super.performRebuild();
    } finally {
      ErrorWidget.builder = originalBuilder;
    }
  }
}
