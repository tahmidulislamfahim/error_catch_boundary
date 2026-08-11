# error_catch_boundary

[![pub package](https://img.shields.io/pub/v/error_catch_boundary.svg)](https://pub.dev/packages/error_catch_boundary)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A React-inspired error boundary wrapper for Flutter that catches subtree `build()` errors locally, prevents full-screen red error boxes or blank app screens, and displays a localized fallback UI with optional self-healing retry logic, programmatic controllers, global configs, auto-retries, and debug stack trace inspection.

---

## 🌟 Key Features

- 🛡️ **Localized UI Fallback:** Prevents a single failing widget from crashing the rest of the application UI.
- 🔄 **Self-Healing / Retry Support:** Provides a `reset()` callback so users can tap "Retry" to attempt rebuilding the failed subtree.
- 🎛️ **Programmatic Controller:** Reset error boundaries from external logic via `ErrorBoundaryController`.
- 🌐 **Global Configuration:** Wrap your app with `GlobalErrorBoundaryConfig` to supply app-wide logging, fallback UIs, and filters.
- ⏱️ **Automated Retries:** Self-heal transient errors automatically using `AutoRetryConfig` with exponential backoff support.
- 🎯 **Selective Error Filtering:** Pass a `shouldCatch` predicate to catch specific errors while letting others propagate up.
- 🐛 **Debug Inspector:** View expandable exception stack traces directly in the fallback UI during debug mode.
- 🎨 **Smooth Transitions:** Animated state changes between child and error UI via `AnimatedSwitcher`.
- ⚡ **Zero External Dependencies:** Pure Flutter implementation utilizing native `ErrorWidget` interceptors.

---

## 🚀 Getting Started

Add `error_catch_boundary` to your `pubspec.yaml`:

```yaml
dependencies:
  error_catch_boundary: ^1.1.1
```

Import the package in your Dart code:

```dart
import 'package:error_catch_boundary/error_catch_boundary.dart';
```

---

## 💻 Usage Examples

### 1. Global App Configuration (`GlobalErrorBoundaryConfig`)

Set app-wide defaults for Sentry/Crashlytics logging and debug details:

```dart
GlobalErrorBoundaryConfig(
  onError: (details) {
    Sentry.captureException(details.error, stackTrace: details.stackTrace);
  },
  showDebugDetails: kDebugMode,
  child: MaterialApp(
    home: const HomeScreen(),
  ),
)
```

---

### 2. Programmatic Control (`ErrorBoundaryController`)

Trigger resets across one or multiple boundaries from an AppBar button or refresh handler:

```dart
final controller = ErrorBoundaryController();

// Inside your UI
ErrorBoundary(
  controller: controller,
  child: MyFeedWidget(),
)

// Reset programmatically
controller.reset();
```

---

### 3. Automated Retry Policy (`AutoRetryConfig`)

Automatically attempt recovery up to 3 times with 2-second intervals:

```dart
ErrorBoundary(
  autoRetryConfig: const AutoRetryConfig(
    maxRetries: 3,
    retryInterval: Duration(seconds: 2),
    enableExponentialBackoff: true,
  ),
  child: MyAsyncDataCard(),
)
```

---

### 4. Selective Error Filtering (`shouldCatch`)

Catch UI build failures while letting severe network or auth exceptions bubble up:

```dart
ErrorBoundary(
  shouldCatch: (details) {
    // Only catch UI FormatExceptions, let UnauthenticatedException bubble up
    return details.error is! UnauthenticatedException;
  },
  child: MyProtectedWidget(),
)
```

---

### 5. Custom Fallback UI

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
          const Text('Failed to load item'),
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

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
