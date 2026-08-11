import 'package:flutter/material.dart';
import 'default_error_widget.dart';
import 'error_details.dart';

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
/// displays a localized fallback UI.
class ErrorBoundary extends StatefulWidget {
  /// The widget tree protected by this error boundary.
  final Widget child;

  /// Optional builder to supply a custom fallback UI when an error occurs.
  /// If null, [DefaultErrorFallback] will be used.
  final ErrorBoundaryFallbackBuilder? fallbackBuilder;

  /// Optional callback invoked when an error is caught, useful for sending
  /// stack traces to monitoring services (e.g., Sentry, Firebase Crashlytics).
  final ErrorBoundaryLogCallback? onError;

  /// Creates an [ErrorBoundary] widget.
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorBoundaryDetails? _errorDetails;

  /// Resets the error boundary state and attempts to rebuild the child widget tree.
  void _reset() {
    setState(() {
      _errorDetails = null;
    });
  }

  FlutterErrorBoundaryDetails _createDetails(FlutterErrorDetails details) {
    return FlutterErrorBoundaryDetails(
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      informationCollector: details.informationCollector,
    );
  }

  void _handleError(FlutterErrorBoundaryDetails details) {
    if (mounted && _errorDetails?.error != details.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onError?.call(details);
          setState(() {
            _errorDetails = details;
          });
        }
      });
    }
  }

  Widget _buildFallback(
      BuildContext context, FlutterErrorBoundaryDetails details) {
    if (widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context, details, _reset);
    }
    return DefaultErrorFallback(
      details: details,
      onRetry: _reset,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return _buildFallback(context, _errorDetails!);
    }

    return ErrorWidgetBuilderInterceptor(
      onError: (details) {
        final boundaryDetails = _createDetails(details);
        _handleError(boundaryDetails);
        return _buildFallback(context, boundaryDetails);
      },
      child: widget.child,
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
