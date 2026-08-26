<p align="center">
  <img src="https://raw.githubusercontent.com/tahmidulislamfahim/error_catch_boundary/main/doc/images/package_logo.jpg" height="180" alt="error_catch_boundary logo" />
</p>

<p align="center">
  <a href="https://pub.dev/packages/error_catch_boundary"><img src="https://img.shields.io/pub/v/error_catch_boundary.svg" alt="Pub Package"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

<p align="center">
  A React-inspired error boundary wrapper for Flutter that catches subtree <code>build()</code> errors locally, prevents full-screen red error boxes or blank app screens, and displays a localized fallback UI with optional self-healing retry logic, programmatic controllers, global configs, auto-retries, boundary naming for telemetry, async retry hooks, and debug stack trace inspection.
</p>

---


## 🌟 Key Features

- 🛡️ **Localized UI Fallback:** Prevents a single failing widget from crashing the rest of the application UI.
- 🏷️ **Boundary Tagging (`name`):** Attach identifier names to boundaries for rich error telemetry in Sentry / Firebase Crashlytics.
- ⏳ **Async Pre-Retry Hook (`onRetry`):** Asynchronously refresh providers or re-fetch data before rebuilding, complete with a fallback loading indicator.
- ⏱️ **Retry Cooldown (`minRetryCooldown`):** Rate-limit manual retry taps to prevent rapid infinite retry loops.
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
  error_catch_boundary: ^1.2.0
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
    Sentry.captureException(
      details.error,
      stackTrace: details.stackTrace,
      hint: Hint.withMap({'boundary': details.name ?? 'unknown'}),
    );
  },
  showDebugDetails: kDebugMode,
  child: MaterialApp(
    home: const HomeScreen(),
  ),
)
```

---

### 2. Boundary Naming & Telemetry (`name`)

Tag individual boundaries so error monitoring services report exact failing UI components:

```dart
ErrorBoundary(
  name: 'UserFeedSection',
  onError: (details) {
    debugPrint('Error caught in boundary: ${details.name}');
  },
  child: const UserFeedWidget(),
)
```

---

### 3. Asynchronous Pre-Retry Hook & Cooldown Rate-Limiting

Execute an asynchronous task (e.g., refresh a Riverpod/Bloc provider or re-fetch network data) before resetting, while displaying a loading spinner on the retry button:

```dart
ErrorBoundary(
  name: 'UserProfileCard',
  minRetryCooldown: const Duration(seconds: 2), // Rate-limit manual retries
  onRetry: () async {
    // Re-fetch data asynchronously before rebuilding
    await ref.refresh(userProfileProvider.future);
  },
  child: const UserProfileCard(),
)
```

---

### 4. Programmatic Control (`ErrorBoundaryController`)

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

### 5. Automated Retry Policy (`AutoRetryConfig`)

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

### 6. Selective Error Filtering (`shouldCatch`)

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
          Text('Failed to load ${details.name ?? 'item'}'),
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

