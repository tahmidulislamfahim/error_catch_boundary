## 1.0.0

* Initial release of `flutter_error_boundary`.
* Catch subtree `build()` errors gracefully to prevent full-screen crashes.
* Default fallback UI with built-in retry functionality.
* Custom fallback UI builder (`fallbackBuilder`).
* Automated logging callback (`onError`) to integrate with monitoring services like Sentry and Firebase Crashlytics.
