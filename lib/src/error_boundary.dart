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

  /// Optional name or identifier tag for this error boundary (useful for telemetry/logging).
  final String? name;

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

  /// Optional pre-retry asynchronous callback executed before resetting the error boundary.
  /// When active, a loading indicator is displayed in [DefaultErrorFallback].
  final FutureOr<void> Function()? onRetry;

  /// Optional cooldown duration to rate-limit manual retry button taps.
  final Duration? minRetryCooldown;

  /// Duration of the smooth transition between active child and fallback states.
  final Duration transitionDuration;

  /// Creates an [ErrorBoundary] widget.
  const ErrorBoundary({
    super.key,
    required this.child,
    this.name,
    this.fallbackBuilder,
    this.onError,
    this.controller,
    this.shouldCatch,
    this.autoRetryConfig,
    this.onRetry,
    this.minRetryCooldown,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorBoundaryDetails? _errorDetails;
  int _retryCount = 0;
  int _resetCounter = 0;
  Timer? _autoRetryTimer;
  Timer? _cooldownTimer;
  bool _isRetrying = false;
  bool _isCoolingDown = false;

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
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Resets the error boundary state and attempts to rebuild the child widget tree.
  void _reset() {
    _autoRetryTimer?.cancel();
    if (mounted) {
      setState(() {
        _resetCounter++;
        _errorDetails = null;
      });
    }
  }

  Future<void> _handleManualRetry(GlobalErrorBoundaryConfig? globalConfig) async {
    if (_isRetrying || _isCoolingDown) {
      return;
    }

    final cooldown = widget.minRetryCooldown ?? globalConfig?.minRetryCooldown;
    if (cooldown != null && cooldown > Duration.zero) {
      _cooldownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isCoolingDown = true;
        });
      }
      _cooldownTimer = Timer(cooldown, () {
        if (mounted) {
          setState(() {
            _isCoolingDown = false;
          });
        }
      });
    }

    final retryHook = widget.onRetry ?? globalConfig?.onRetry;
    if (retryHook != null) {
      if (mounted) {
        setState(() {
          _isRetrying = true;
        });
      }
      try {
        await retryHook();
      } catch (e, stack) {
        if (mounted) {
          final errorDetails = FlutterErrorBoundaryDetails(
            error: e,
            stackTrace: stack,
            name: widget.name,
          );
          widget.onError?.call(errorDetails);
          globalConfig?.onError?.call(errorDetails);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRetrying = false;
          });
        }
      }
    }

    _retryCount = 0; // Manual retry resets auto-retry count
    _reset();
  }

  FlutterErrorBoundaryDetails _createDetails(FlutterErrorDetails details) {
    return FlutterErrorBoundaryDetails(
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      informationCollector: details.informationCollector,
      name: widget.name,
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
      return builder(context, details, () => _handleManualRetry(globalConfig));
    }
    return DefaultErrorFallback(
      details: details,
      onRetry: () => _handleManualRetry(globalConfig),
      showDebugDetails: globalConfig?.showDebugDetails,
      isRetrying: _isRetrying,
      isCoolingDown: _isCoolingDown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalConfig = GlobalErrorBoundaryConfig.of(context);

    final Widget currentContent;
    if (_errorDetails != null) {
      currentContent = KeyedSubtree(
        key: const ValueKey('error_boundary_fallback'),
        child: _buildFallback(context, _errorDetails!),
      );
    } else {
      currentContent = KeyedSubtree(
        key: ValueKey('error_boundary_child_$_resetCounter'),
        child: ErrorWidgetBuilderInterceptor(
          onError: (details) {
            final boundaryDetails = _createDetails(details);
            final filter = widget.shouldCatch ?? globalConfig?.shouldCatch;
            if (filter != null && !filter(boundaryDetails)) {
              return ErrorWidget.withDetails(
                message: details.exception.toString(),
                error: details.exception is FlutterError
                    ? details.exception as FlutterError
                    : null,
              );
            }
            _handleError(boundaryDetails, globalConfig);
            return const SizedBox.shrink();
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
