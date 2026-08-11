import 'package:flutter/foundation.dart';

/// A controller used to programmatically control and reset one or more [ErrorBoundary] widgets.
///
/// Pass an instance of [ErrorBoundaryController] to [ErrorBoundary.controller].
/// Calling [reset] will trigger a state reset and re-attempt subtree rendering for all
/// attached boundaries.
class ErrorBoundaryController extends ChangeNotifier {
  /// Resets all attached [ErrorBoundary] widgets, instructing them to clear
  /// caught error details and rebuild their child widget trees.
  void reset() {
    notifyListeners();
  }
}
