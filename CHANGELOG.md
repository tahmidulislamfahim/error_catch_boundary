## 1.3.1

* **`ErrorBoundaryStrings` & Localized Fallback UI**: Added `ErrorBoundaryStrings` data class to easily customize or translate default fallback text (message, retry buttons, debug header) across individual boundaries or app-wide via `GlobalErrorBoundaryConfig`.
* **Material-Independent Fallback**: Ensured `DefaultErrorFallback` safely renders inside `CupertinoApp` or widget trees without an ambient `Material` ancestor by wrapping in a root `Material` widget.
* **`ErrorBoundary.wrapCallback` & `ErrorBoundary.reportError`**: Added helper methods to reliably intercept synchronous and asynchronous exceptions in gesture callbacks (such as button `onPressed`) executing on the event loop outside the build zone.
* **Exponential Backoff Ceiling & Jitter (`AutoRetryConfig`)**: Added `maxDelay` cap and `jitterFactor` randomization to prevent indefinite doubling and avoid thundering-herd reconnect spikes during backend recovery.
* **Global Auto-Retry Inheritance**: `ErrorBoundary` widgets now automatically inherit `autoRetryConfig` from `GlobalErrorBoundaryConfig` when not configured locally.
* **`ErrorBoundaryController` State & Targeted Reset**: Added active error state queries (`hasError`, `errorCount`, `errors`, `failingBoundaryNames`), selective boundary reset by name (`reset(name: ...)` and `resetBoundary(...)`), and disposal safety against post-dispose invocation.
* **Incident Correlation (`errorId` & `timestamp`)**: Added unique incident `errorId` and `timestamp` fields to `FlutterErrorBoundaryDetails` for logging across telemetry tools.

## 1.3.0

* **`ErrorBoundary.async` & Zone Error Interception**: Added `ErrorBoundary.async` constructor (`catchAsync: true`) utilizing `runZonedGuarded` to intercept unhandled asynchronous exceptions in Futures, event callbacks, and async `initState` calls within the subtree.
* **Custom Transition Builders (`transitionBuilder`)**: Added `transitionBuilder` parameter to `ErrorBoundary` and `GlobalErrorBoundaryConfig` to support custom transition animations (`ScaleTransition`, `SlideTransition`, `FadeTransition`, etc.) between active child content and fallback UI.

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
