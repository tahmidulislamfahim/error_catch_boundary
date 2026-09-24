/// Localized or custom user-facing strings displayed in the fallback UI.
class ErrorBoundaryStrings {
  /// The main message displayed in the fallback card.
  final String message;

  /// The label for the retry button in its default state.
  final String retryButton;

  /// The label for the retry button while an asynchronous retry operation is in progress.
  final String retryingButton;

  /// The header label for the expandable debug details section.
  final String debugDetailsTitle;

  /// Creates an [ErrorBoundaryStrings] instance with optional string overrides.
  const ErrorBoundaryStrings({
    this.message = 'Something went wrong in this section.',
    this.retryButton = 'Retry',
    this.retryingButton = 'Retrying...',
    this.debugDetailsTitle = 'Debug Details',
  });

  /// Creates a copy of this [ErrorBoundaryStrings] with specified fields replaced.
  ErrorBoundaryStrings copyWith({
    String? message,
    String? retryButton,
    String? retryingButton,
    String? debugDetailsTitle,
  }) {
    return ErrorBoundaryStrings(
      message: message ?? this.message,
      retryButton: retryButton ?? this.retryButton,
      retryingButton: retryingButton ?? this.retryingButton,
      debugDetailsTitle: debugDetailsTitle ?? this.debugDetailsTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorBoundaryStrings &&
        other.message == message &&
        other.retryButton == retryButton &&
        other.retryingButton == retryingButton &&
        other.debugDetailsTitle == debugDetailsTitle;
  }

  @override
  int get hashCode => Object.hash(
        message,
        retryButton,
        retryingButton,
        debugDetailsTitle,
      );
}
