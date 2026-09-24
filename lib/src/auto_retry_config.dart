import 'dart:math' as math;

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

  /// Optional upper bound cap on the retry delay.
  ///
  /// When set, the delay calculated by exponential backoff will never exceed this ceiling.
  final Duration? maxDelay;

  /// Optional jitter factor between 0.0 and 1.0 (e.g., 0.2 for ±20% randomization).
  ///
  /// Jitter desynchronizes retry attempts across multiple boundaries or devices,
  /// preventing thundering-herd spikes on backends after widespread outages.
  /// Defaults to 0.0 (deterministic, no jitter).
  final double jitterFactor;

  /// Creates an [AutoRetryConfig] instance.
  const AutoRetryConfig({
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
    this.enableExponentialBackoff = false,
    this.maxDelay,
    this.jitterFactor = 0.0,
  })  : assert(maxRetries > 0, 'maxRetries must be greater than 0'),
        assert(jitterFactor >= 0.0 && jitterFactor <= 1.0,
            'jitterFactor must be between 0.0 and 1.0');

  /// Calculates the delay duration for a specific retry attempt index (1-indexed).
  ///
  /// Optionally accepts a [random] instance for deterministic testing of jitter calculations.
  Duration getDelayForAttempt(int attempt, [math.Random? random]) {
    Duration delay;
    if (!enableExponentialBackoff || attempt <= 1) {
      delay = retryInterval;
    } else {
      final multiplier = 1 << (attempt - 1);
      delay = retryInterval * multiplier;
    }

    if (maxDelay != null && delay > maxDelay!) {
      delay = maxDelay!;
    }

    if (jitterFactor > 0.0) {
      final rng = random ?? math.Random();
      final factor =
          (1.0 - jitterFactor) + (2 * jitterFactor * rng.nextDouble());
      final jitteredMicros = (delay.inMicroseconds * factor).round();
      delay = Duration(microseconds: math.max(0, jitteredMicros));

      if (maxDelay != null && delay > maxDelay!) {
        delay = maxDelay!;
      }
    }

    return delay;
  }
}
