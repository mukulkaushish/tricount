# 12 — Analytics Interface

> Event names are pattern examples.

## Goals
1. **Decouple from features** — no feature imports Sentry/Mixpanel/Firebase directly.
2. **Swap providers via DI only** — no code changes.
3. **Composite** — fan out to multiple providers.
4. **Type-safe events** — no raw strings scattered across the codebase.
5. **NoOp in dev** — zero analytics overhead in debug.

## Interface segregation

### `EventTracker`
| Method | Purpose |
|---|---|
| `trackEvent(AnalyticsEvent)` | log named event |
| `trackScreen(String)` | log screen view |

### `CrashReporter`
| Method | Purpose |
|---|---|
| `recordError(error, stack, {fatal})` | report crash |
| `recordMessage(msg, {extras})` | breadcrumb |
| `setContext(key, value)` | context for next crash |

### `UserIdentifier`
| Method | Purpose |
|---|---|
| `identifyUser(id, {traits})` | set identity |
| `resetUser()` | clear on logout |

### Combined
```dart
abstract class AnalyticsService implements EventTracker, CrashReporter, UserIdentifier {
  Future<void> initialize();
}
```

## Event taxonomy

### `AnalyticsEvent`
| Field | Type | Purpose |
|---|---|---|
| `name` | `String` | snake_case |
| `properties` | `Map<String, dynamic>` | params |
| `category` | `EventCategory` | enum |

### `EventCategory`
`navigation`, `engagement`, `reading`, `settings`, `auth`, `error`, `performance`.

### Predefined events

| Name | Category | Properties |
|---|---|---|
| `book_opened` | engagement | `book_id`, `source` (library/search/deeplink) |
| `chapter_read` | reading | `book_id`, `chapter_index`, `time_spent_seconds` |
| `reading_session_started` | reading | `book_id`, `chapter_index` |
| `reading_session_ended` | reading | `book_id`, `pages_read`, `duration_seconds` |
| `bookmark_added`/`removed` | engagement | `book_id`, `chapter_id` |
| `search_performed` | engagement | `query`, `results_count` |
| `theme_changed` | settings | `palette_id`, `mode` |
| `font_scale_changed` | settings | `scale`, `direction` |
| `login_success` | auth | `method` |
| `login_failure` | auth | `method`, `error_type` |
| `app_launch` | performance | `cold_start`, `duration_ms` |

## Adapters

Each implements `AnalyticsService` wrapping a specific SDK.

### `SentryAdapter`
| AnalyticsService | Sentry SDK |
|---|---|
| `initialize()` | `Sentry.init()` with DSN |
| `trackEvent` | `Sentry.addBreadcrumb()` |
| `trackScreen` | `Sentry.addBreadcrumb(category: 'navigation')` |
| `recordError` | `Sentry.captureException()` |
| `recordMessage` | `Sentry.captureMessage()` |
| `identifyUser` | `Sentry.configureScope(user:)` |
| `resetUser` | `Sentry.configureScope(user: null)` |

### `MixpanelAdapter`
| AnalyticsService | Mixpanel SDK |
|---|---|
| `initialize` | `Mixpanel.init(token)` |
| `trackEvent` | `mixpanel.track(name, properties)` |
| `trackScreen` | `mixpanel.track('screen_view', {screen: name})` |
| `recordError` | `mixpanel.track('error', {message})` |
| `identifyUser` | `mixpanel.identify(id)` |
| `resetUser` | `mixpanel.reset()` |

### `FirebaseAdapter`
| AnalyticsService | Firebase SDK |
|---|---|
| `initialize` | `Firebase.initializeApp()` |
| `trackEvent` | `FirebaseAnalytics.logEvent()` |
| `trackScreen` | `logEvent(name: 'screen_view', parameters: {'screen_name': name})` |
| `recordError` | `FirebaseCrashlytics.recordError()` |
| `identifyUser` | `FirebaseAnalytics.setUserId()` |

### `NoOpAdapter`
All methods empty. Dev + tests.

## `CompositeAnalyticsService` (`composite_analytics.dart`)

Holds `List<AnalyticsService>`. On every method, iterates and calls each. **Catches adapter exceptions** (one failing doesn't break others). Logs adapter failures via `AppLogger`.

### DI registration by env

| Env | Adapters |
|---|---|
| development | `[NoOpAdapter]` |
| staging | `[SentryAdapter]` |
| production | `[SentryAdapter, MixpanelAdapter, FirebaseAdapter]` |

## BLoC integration

Analytics fired **never from widgets**. Only from:
1. **BLoC event handlers** — after successful state transitions.
2. **Route observer** — auto_route's `AutoRouteObserver` for screen tracking.
3. **Global error handlers** — `FlutterError.onError`, `PlatformDispatcher.onError`.

Screen tracking details → `09_NAVIGATION_DEEP_LINKING.md#screen-tracking`.
