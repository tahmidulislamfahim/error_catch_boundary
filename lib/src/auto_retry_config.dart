/// Configuration settings for automated retry attempts inside an [ErrorBoundary].
class AutoRetryConfig {
  /// The maximum number of automatic retry attempts before staying on the fallback UI.
  final int maxRetries;

  /// The base delay duration between automatic retry attempts.
  final Duration retryInterval;

  /// Whether to use exponential backoff for successive retry intervals.
  ///
  /// If true, the delay doubles after each attempt (e.g. 2s, 4s, 8s...).
  final bool enableExponentialBackoff;

  /// Creates an [AutoRetryConfig] instance.
  const AutoRetryConfig({
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
    this.enableExponentialBackoff = false,
  }) : assert(maxRetries > 0, 'maxRetries must be greater than 0');

  /// Calculates the delay duration for a specific retry attempt index (1-indexed).
  Duration getDelayForAttempt(int attempt) {
    if (!enableExponentialBackoff || attempt <= 1) {
      return retryInterval;
    }
    final multiplier = 1 << (attempt - 1);
    return retryInterval * multiplier;
  }
}
