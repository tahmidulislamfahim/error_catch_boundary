import 'package:flutter/foundation.dart';
import 'error_details.dart';

/// Internal registration representation connecting an [ErrorBoundary] instance
/// to its [ErrorBoundaryController].
class ErrorBoundaryRegistration {
  /// Resolves the current name/tag of the boundary.
  final String? Function() getName;

  /// Callback to reset the boundary's error state.
  final VoidCallback reset;

  /// Active error details for this boundary, or null if healthy.
  FlutterErrorBoundaryDetails? errorDetails;

  /// Creates a registration instance.
  ErrorBoundaryRegistration({
    required this.getName,
    required this.reset,
    this.errorDetails,
  });
}

/// A controller used to programmatically control, observe, and reset one or more [ErrorBoundary] widgets.
///
/// Pass an instance of [ErrorBoundaryController] to [ErrorBoundary.controller].
///
/// Features:
/// - Query active error states via [hasError], [errorCount], and [errors].
/// - Reset all boundaries via [reset()].
/// - Selectively reset a specific boundary by tag/name via [reset(name: ...)] or [resetBoundary(name)].
/// - Safe against post-disposal calls.
class ErrorBoundaryController extends ChangeNotifier {
  bool _isDisposed = false;
  final Set<ErrorBoundaryRegistration> _registrations = {};

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether any currently attached [ErrorBoundary] has an active error.
  bool get hasError => _registrations.any((r) => r.errorDetails != null);

  /// The number of currently attached [ErrorBoundary] widgets in an error state.
  int get errorCount =>
      _registrations.where((r) => r.errorDetails != null).length;

  /// The total number of [ErrorBoundary] widgets currently attached to this controller.
  int get attachedBoundaryCount => _registrations.length;

  /// A snapshot list of error details from all attached boundaries currently in an error state.
  List<FlutterErrorBoundaryDetails> get errors => _registrations
      .map((r) => r.errorDetails)
      .whereType<FlutterErrorBoundaryDetails>()
      .toList();

  /// A list of names for all attached boundaries currently in an error state.
  List<String> get failingBoundaryNames => _registrations
      .where((r) => r.errorDetails != null && r.getName() != null)
      .map((r) => r.getName()!)
      .toList();

  /// Resets attached [ErrorBoundary] widgets.
  ///
  /// If [name] is provided, only attached boundaries with a matching [ErrorBoundary.name]
  /// are reset. If [name] is null, all attached boundaries are reset.
  ///
  /// Calling [reset] after [dispose] is safely ignored and will not throw.
  void reset({String? name}) {
    if (_isDisposed) {
      return;
    }

    final targets = name == null
        ? List<ErrorBoundaryRegistration>.from(_registrations)
        : _registrations.where((r) => r.getName() == name).toList();

    for (final registration in targets) {
      registration.reset();
    }

    notifyListeners();
  }

  /// Convenience method to reset only the boundary with the specified [name].
  void resetBoundary(String name) {
    reset(name: name);
  }

  /// Registers an error boundary with this controller.
  void registerBoundary(ErrorBoundaryRegistration registration) {
    if (_isDisposed) return;
    _registrations.add(registration);
  }

  /// Unregisters an error boundary from this controller.
  void unregisterBoundary(ErrorBoundaryRegistration registration) {
    if (_isDisposed) return;
    _registrations.remove(registration);
  }

  /// Records an error for a registered boundary and notifies listeners.
  void reportError(
      ErrorBoundaryRegistration registration, FlutterErrorBoundaryDetails details) {
    if (_isDisposed) return;
    registration.errorDetails = details;
    notifyListeners();
  }

  /// Clears the error for a registered boundary and notifies listeners.
  void reportReset(ErrorBoundaryRegistration registration) {
    if (_isDisposed) return;
    if (registration.errorDetails != null) {
      registration.errorDetails = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _registrations.clear();
    super.dispose();
  }
}
