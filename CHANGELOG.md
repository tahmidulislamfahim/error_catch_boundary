## 1.2.0

* **Boundary Tagging & Names (`name`)**: Added `name` property to `ErrorBoundary` and `FlutterErrorBoundaryDetails` for enriched error telemetry and logging in Sentry, Firebase Crashlytics, and Datadog.
* **Asynchronous Pre-Retry Hook (`onRetry`)**: Added `onRetry` support to `ErrorBoundary` and `GlobalErrorBoundaryConfig` with built-in loading indicator on the fallback retry button while async operations (e.g. re-fetching data, refreshing state providers) complete.
* **Retry Cooldown & Rate-Limiting (`minRetryCooldown`)**: Added `minRetryCooldown` parameter to throttle and prevent rapid spamming of manual retry attempts.
* **Subtree Remount on Reset**: Enhanced `_ErrorBoundaryState` with automated subtree remount keying on resets to guarantee fresh rebuilds.

## 1.1.1


* Updated `LICENSE` to canonical SPDX MIT License formatting for pub.dev recognition.
* **`ErrorBoundaryController`**: Programmatic control to reset attached error boundaries from outside the widget tree.
* **`GlobalErrorBoundaryConfig`**: Inherited configuration widget providing app-wide default `fallbackBuilder`, `onError` logger callbacks, `shouldCatch` predicates, and `showDebugDetails` flags.
* **`AutoRetryConfig`**: Automated retries with customizable retry intervals, max retry limits, and optional exponential backoff.
* **Selective Error Filtering (`shouldCatch`)**: Filter predicate function allowing specific exception types to be caught while letting others bubble up.
* **Debug Stack Trace Inspector**: Expandable debug details view in `DefaultErrorFallback` (enabled automatically in `kDebugMode`).
* **Smooth UI Transitions**: Added `AnimatedSwitcher` support for seamless transitions between child content and fallback UIs.

## 1.1.0

* Feature release with `ErrorBoundaryController`, `GlobalErrorBoundaryConfig`, `AutoRetryConfig`, and debug stack trace inspector.

## 1.0.1

* Updated repository and homepage URL.
* Updated LICENSE formatting for pub.dev recognition.
* Code formatting improvements.

## 1.0.0

* Initial release of `error_catch_boundary`.
* Catch subtree `build()` errors gracefully to prevent full-screen crashes.
* Default fallback UI with built-in retry functionality.
* Custom fallback UI builder (`fallbackBuilder`).
* Automated logging callback (`onError`) to integrate with monitoring services like Sentry and Firebase Crashlytics.
