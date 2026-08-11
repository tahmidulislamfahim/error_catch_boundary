import 'package:flutter/material.dart';
import 'error_details.dart';

/// Default fallback widget displayed when an exception occurs inside an [ErrorBoundary]
/// and no custom `fallbackBuilder` is provided.
class DefaultErrorFallback extends StatelessWidget {
  /// The error details intercepted by the boundary.
  final FlutterErrorBoundaryDetails details;

  /// Callback executed when the user taps the retry button.
  final VoidCallback onRetry;

  /// Creates a [DefaultErrorFallback] instance.
  const DefaultErrorFallback({
    super.key,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = colorScheme.errorContainer;
    final contentColor = colorScheme.onErrorContainer;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: contentColor,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong in this section.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: contentColor,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
