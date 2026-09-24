<p align="center">
  <img src="https://raw.githubusercontent.com/tahmidulislamfahim/error_catch_boundary/main/doc/images/package_logo.jpg" height="180" alt="error_catch_boundary logo" />
</p>

<p align="center">
  <a href="https://pub.dev/packages/error_catch_boundary"><img src="https://img.shields.io/pub/v/error_catch_boundary.svg" alt="Pub Package"></a>
  <a href="https://github.com/tahmidulislamfahim/error_catch_boundary/actions/workflows/test.yml"><img src="https://github.com/tahmidulislamfahim/error_catch_boundary/actions/workflows/test.yml/badge.svg" alt="CI"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

<p align="center">
  A React-inspired error boundary wrapper for Flutter that catches subtree <code>build()</code> errors locally, prevents full-screen red error boxes or blank app screens, and displays a customizable and localizable fallback UI with optional self-healing retry logic, programmatic controllers, global configs, auto-retries with jitter and backoff caps, async zone error interception, custom transition animations, boundary naming for telemetry, async retry hooks, and debug stack trace inspection.
</p>

---

## Key Features

- **Customizable & Localizable UI Fallback (`ErrorBoundaryStrings`):** Prevents a single failing widget from crashing the entire UI, with customizable and translatable copy across individual boundaries or app-wide.
- **Material-Independent Fallback:** Safe to use in `MaterialApp`, `CupertinoApp`, or custom widget hierarchies without throwing "No Material widget found".
- **Async & Zone Error Interception (`ErrorBoundary.async`):** Intercept unhandled asynchronous exceptions in Futures, microtasks, and async `initState` calls within the subtree.
- **Callback Exception Protection (`ErrorBoundary.wrapCallback`):** Safely trap synchronous and asynchronous exceptions in button callbacks (`onPressed`) and report them into the boundary.
- **Incident Correlation (`errorId` & `timestamp`):** Each caught incident receives a unique `errorId` and precise `timestamp` in `FlutterErrorBoundaryDetails` for logging across Sentry, Crashlytics, and analytics.
- **Production-Hardened Auto-Retries (`AutoRetryConfig`):** Exponential backoff with optional ceiling (`maxDelay`) and randomized jitter (`jitterFactor`) to prevent thundering-herd issues on backend recovery.
- **Rich Programmatic Controller (`ErrorBoundaryController`):** Inspect active error states (`hasError`, `errorCount`, `errors`, `failingBoundaryNames`), selectively reset named boundaries (`reset(name: ...)`), and safe against post-disposal invocation.
- **Global Configuration (`GlobalErrorBoundaryConfig`):** Set app-wide defaults for fallback builders, strings, automated retry policies, logging callbacks, and filters.
- **Custom Transition Animations (`transitionBuilder`):** Customize state transition animations (Scale, Slide, Fade, Flip) between child content and fallback UI.
- **Boundary Tagging (`name`):** Attach identifier names to boundaries for rich error telemetry.
- **Async Pre-Retry Hook (`onRetry`):** Asynchronously refresh providers or re-fetch data before rebuilding, complete with a fallback loading indicator.
- **Retry Cooldown (`minRetryCooldown`):** Rate-limit manual retry taps to prevent rapid infinite retry loops.
- **Zero External Dependencies:** Pure Flutter implementation utilizing native `ErrorWidget` interceptors.

---

## Getting Started

Add `error_catch_boundary` to your `pubspec.yaml`:

```yaml
dependencies:
  error_catch_boundary: ^1.3.1
```

Import the package in your Dart code:

```dart
import 'package:error_catch_boundary/error_catch_boundary.dart';
```

---

## Usage Examples

### 1. Async & Zone Error Interception (`ErrorBoundary.async`)

Catch unhandled asynchronous errors thrown outside the widget `build()` phase (e.g. inside `initState` async calls, microtasks, or Futures):

```dart
ErrorBoundary.async(
  name: 'AsyncFormBoundary',
  onError: (details) => logToSentry(details),
  child: const MyAsyncFormWidget(),
)
```

### 2. Protecting Button Callbacks (`ErrorBoundary.wrapCallback`)

Flutter button gestures execute on the event loop outside the build zone. Use `ErrorBoundary.wrapCallback` to catch synchronous and asynchronous button exceptions and report them directly to the nearest boundary:

```dart
ErrorBoundary(
  name: 'CheckoutActionBoundary',
  child: Builder(
    builder: (context) {
      return ElevatedButton(
        onPressed: ErrorBoundary.wrapCallback(context, () async {
          // Both synchronous throws and rejected Futures are caught by the boundary!
          await processPayment();
        }),
        child: const Text('Pay Now'),
      );
    },
  ),
)
```

You can also report any caught exception directly from any descendant context:

```dart
ErrorBoundary.reportError(context, exception, stackTrace);
```

---

### 3. Localizing and Customizing Fallback Copy (`ErrorBoundaryStrings`)

Customize or translate the default fallback UI copy without replacing the entire layout:

```dart
ErrorBoundary(
  strings: const ErrorBoundaryStrings(
    message: 'Se produjo un error en esta sección.',
    retryButton: 'Reintentar',
    retryingButton: 'Reintentando...',
    debugDetailsTitle: 'Detalles técnicos',
  ),
  child: const MyFeedWidget(),
)
```

---

### 4. Global App Configuration (`GlobalErrorBoundaryConfig`)

Set app-wide defaults for Sentry/Crashlytics logging, automated retries, localized copy, and debug details:

```dart
GlobalErrorBoundaryConfig(
  onError: (details) {
    Sentry.captureException(
      details.error,
      stackTrace: details.stackTrace,
      hint: Hint.withMap({
        'boundary': details.name ?? 'unknown',
        'errorId': details.errorId,
        'timestamp': details.timestamp.toIso8601String(),
      }),
    );
  },
  autoRetryConfig: const AutoRetryConfig(
    maxRetries: 2,
    retryInterval: Duration(seconds: 2),
    enableExponentialBackoff: true,
    maxDelay: Duration(seconds: 10),
    jitterFactor: 0.2, // +/- 20% jitter
  ),
  showDebugDetails: kDebugMode,
  child: MaterialApp(
    home: const HomeScreen(),
  ),
)
```

---

### 5. Programmatic Control & Error Observation (`ErrorBoundaryController`)

Inspect error states across attached boundaries, display a global notification badge, and selectively reset specific boundaries:

```dart
final controller = ErrorBoundaryController();

// Inside your UI
ErrorBoundary(
  name: 'FeedSection',
  controller: controller,
  child: const MyFeedWidget(),
)

// Observe error status
if (controller.hasError) {
  print('${controller.errorCount} section(s) failed: ${controller.failingBoundaryNames}');
}

// Reset only the FeedSection boundary
controller.resetBoundary('FeedSection');

// Or reset all attached boundaries
controller.reset();
```

---

### 6. Automated Retry Policy with Backoff Cap & Jitter (`AutoRetryConfig`)

Automatically retry failed subtrees with exponential backoff, a ceiling cap, and jitter to avoid thundering herd spikes:

```dart
ErrorBoundary(
  autoRetryConfig: const AutoRetryConfig(
    maxRetries: 3,
    retryInterval: Duration(seconds: 2),
    enableExponentialBackoff: true,
    maxDelay: Duration(seconds: 8), // Cap at 8 seconds
    jitterFactor: 0.2,               // +/- 20% randomized jitter
  ),
  child: MyAsyncDataCard(),
)
```

---

### 7. Custom Fallback UI

Provide a `fallbackBuilder` to display custom error UI tailored to your design system:

```dart
ErrorBoundary(
  fallbackBuilder: (context, details, reset) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load ${details.name ?? 'item'} (${details.errorId})'),
          ElevatedButton(
            onPressed: reset,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  },
  child: MyComplexCard(),
)
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
