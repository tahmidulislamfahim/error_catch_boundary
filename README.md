# error_catch_boundary

[![pub package](https://img.shields.io/pub/v/error_catch_boundary.svg)](https://pub.dev/packages/error_catch_boundary)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A React-inspired error boundary wrapper for Flutter that catches subtree `build()` errors locally, prevents full-screen red error boxes or blank app screens, and displays a localized fallback UI with optional self-healing retry logic.

---

## 🌟 Key Features

- 🛡️ **Localized UI Fallback:** Prevents a single failing widget (e.g., inside a feed or grid) from crashing the rest of the application UI.
- 🔄 **Self-Healing / Retry Support:** Provides a `reset()` callback so users can tap "Retry" to attempt rebuilding the failed subtree without restarting the app.
- 📊 **Automated Error Logging:** Passes caught exceptions, stack traces, and details directly to logging services like **Sentry**, **Firebase Crashlytics**, or custom loggers.
- 🎨 **Custom Fallback Builder:** Supply your own fallback UI or use the clean built-in `DefaultErrorFallback`.
- ⚡ **Zero External Dependencies:** Pure Flutter implementation utilizing native `ErrorWidget` interceptors.

---

## 🚀 Getting Started

Add `error_catch_boundary` to your `pubspec.yaml`:

```yaml
dependencies:
  error_catch_boundary: ^1.0.0
```

Import the package in your Dart code:

```dart
import 'package:error_catch_boundary/error_catch_boundary.dart';
```

---

## 💻 Usage Examples

### 1. Basic Usage (Default Fallback UI)

Wrap any widget that might throw an error during build:

```dart
ErrorBoundary(
  child: MyFeedItemWidget(item: item),
)
```

If `MyFeedItemWidget` throws an exception, only that feed item will display a warning card with a **Retry** button, while the rest of your app continues operating smoothly.

---

### 2. Custom Fallback UI

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

### 3. Automatic Error Logging (Sentry / Crashlytics)

Use the `onError` callback to log caught errors to remote telemetry services:

```dart
ErrorBoundary(
  onError: (details) {
    // Send stack trace and exception to Sentry
    Sentry.captureException(
      details.error,
      stackTrace: details.stackTrace,
    );

    // Or report to Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(
    //   details.error,
    //   details.stackTrace,
    //   reason: 'Caught by ErrorBoundary',
    // );
  },
  child: ProductDetailsWidget(),
)
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
