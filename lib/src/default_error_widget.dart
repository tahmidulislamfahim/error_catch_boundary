import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'error_details.dart';

/// Default fallback widget displayed when an exception occurs inside an [ErrorBoundary]
/// and no custom `fallbackBuilder` is provided.
class DefaultErrorFallback extends StatelessWidget {
  /// The error details intercepted by the boundary.
  final FlutterErrorBoundaryDetails details;

  /// Callback executed when the user taps the retry button.
  final VoidCallback onRetry;

  /// Controls whether debug details (stack trace & error message) are viewable.
  /// Defaults to [kDebugMode] if null.
  final bool? showDebugDetails;

  /// Whether an asynchronous retry operation is currently executing.
  final bool isRetrying;

  /// Whether the retry button is temporarily disabled due to cooldown rate-limiting.
  final bool isCoolingDown;

  /// Creates a [DefaultErrorFallback] instance.
  const DefaultErrorFallback({
    super.key,
    required this.details,
    required this.onRetry,
    this.showDebugDetails,
    this.isRetrying = false,
    this.isCoolingDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDebugModeEnabled = showDebugDetails ?? kDebugMode;
    final isActionDisabled = isRetrying || isCoolingDown;

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
              onPressed: isActionDisabled ? null : onRetry,
              icon: isRetrying
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onError,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(isRetrying ? 'Retrying...' : 'Retry'),
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
            if (isDebugModeEnabled) ...[
              const SizedBox(height: 12),
              Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    iconColor: contentColor,
                    collapsedIconColor: contentColor,
                    title: Text(
                      'Debug Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: contentColor,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          'Exception:\n${details.error}\n\nStack Trace:\n${details.stackTrace}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: contentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


