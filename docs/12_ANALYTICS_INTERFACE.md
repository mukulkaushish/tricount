# 12 - Analytics Interface

> Event names and payload fields below are examples. Keep the structure, but rename events to match the product you are actually shipping.

## Design Goals

1. **Decouple analytics from features** - no feature code imports Sentry/Mixpanel/Firebase directly
2. **Swap providers without code changes** - add/remove analytics backends via DI only
3. **Composite pattern** - fan out events to multiple providers simultaneously
4. **Type-safe events** - no raw string event names scattered across codebase
5. **NoOp in development** - zero analytics overhead in debug builds

---

## Interface Segregation

Analytics is split into three focused interfaces:

### EventTracker

| Method | Signature | Purpose |
|--------|-----------|---------|
| `trackEvent` | `void trackEvent(AnalyticsEvent event)` | Log a named event with properties |
| `trackScreen` | `void trackScreen(String screenName)` | Log screen view |

### CrashReporter

| Method | Signature | Purpose |
|--------|-----------|---------|
| `recordError` | `void recordError(dynamic error, StackTrace? stack, {bool fatal})` | Report error/crash |
| `recordMessage` | `void recordMessage(String message, {Map<String, dynamic>? extras})` | Breadcrumb/message |
| `setContext` | `void setContext(String key, dynamic value)` | Add context for next crash |

### UserIdentifier

| Method | Signature | Purpose |
|--------|-----------|---------|
| `identifyUser` | `void identifyUser(String userId, {Map<String, dynamic>? traits})` | Set user identity |
| `resetUser` | `void resetUser()` | Clear identity on logout |

### AnalyticsService (Combined)

```
abstract class AnalyticsService implements EventTracker, CrashReporter, UserIdentifier {
  Future<void> initialize();
}
```

---

## Event Taxonomy

### AnalyticsEvent Class

| Field | Type | Purpose |
|-------|------|---------|
| `name` | `String` | Event name (snake_case) |
| `properties` | `Map<String, dynamic>` | Event parameters |
| `category` | `EventCategory` | Grouping enum |

### EventCategory Enum

| Category | Examples |
|----------|---------|
| `navigation` | Screen views, tab switches |
| `engagement` | Book opened, chapter read, bookmark added |
| `reading` | Reading started, reading completed, time spent |
| `settings` | Theme changed, font size changed, night mode toggled |
| `auth` | Login, logout, session expired |
| `error` | API error, parse error, timeout |
| `performance` | App launch time, page load time |

### Predefined Events

| Event Name | Category | Properties |
|-----------|----------|------------|
| `book_opened` | engagement | `book_id`, `source` (library/search/deeplink) |
| `chapter_read` | reading | `book_id`, `chapter_index`, `time_spent_seconds` |
| `reading_session_started` | reading | `book_id`, `chapter_index` |
| `reading_session_ended` | reading | `book_id`, `pages_read`, `duration_seconds` |
| `bookmark_added` | engagement | `book_id`, `chapter_id` |
| `bookmark_removed` | engagement | `book_id`, `chapter_id` |
| `search_performed` | engagement | `query`, `results_count` |
| `theme_changed` | settings | `palette_id`, `mode` |
| `font_scale_changed` | settings | `scale`, `direction` (increased/decreased) |
| `login_success` | auth | `method` |
| `login_failure` | auth | `method`, `error_type` |
| `app_launch` | performance | `cold_start`, `duration_ms` |

---

## Provider Adapters

### Adapter Interface

Each adapter implements `AnalyticsService` and wraps a specific SDK:

### SentryAdapter

**File**: `lib/core/analytics/adapters/sentry_adapter.dart`

| AnalyticsService Method | Sentry SDK Mapping |
|------------------------|--------------------|
| `initialize()` | `Sentry.init()` with DSN |
| `trackEvent(event)` | `Sentry.addBreadcrumb()` |
| `trackScreen(name)` | `Sentry.addBreadcrumb(category: 'navigation')` |
| `recordError(error, stack)` | `Sentry.captureException()` |
| `recordMessage(msg)` | `Sentry.captureMessage()` |
| `identifyUser(id)` | `Sentry.configureScope(user:)` |
| `resetUser()` | `Sentry.configureScope(user: null)` |

### MixpanelAdapter

**File**: `lib/core/analytics/adapters/mixpanel_adapter.dart`

| AnalyticsService Method | Mixpanel SDK Mapping |
|------------------------|--------------------|
| `initialize()` | `Mixpanel.init(token)` |
| `trackEvent(event)` | `mixpanel.track(event.name, properties)` |
| `trackScreen(name)` | `mixpanel.track('screen_view', {screen: name})` |
| `recordError(error)` | `mixpanel.track('error', {message: error})` |
| `identifyUser(id)` | `mixpanel.identify(id)` |
| `resetUser()` | `mixpanel.reset()` |

### FirebaseAdapter

**File**: `lib/core/analytics/adapters/firebase_adapter.dart`

| AnalyticsService Method | Firebase SDK Mapping |
|------------------------|--------------------|
| `initialize()` | `Firebase.initializeApp()` |
| `trackEvent(event)` | `FirebaseAnalytics.logEvent()` |
| `trackScreen(name)` | `FirebaseAnalytics.logEvent(name: 'screen_view', parameters: {'screen_name': name})` |
| `recordError(error)` | `FirebaseCrashlytics.recordError()` |
| `identifyUser(id)` | `FirebaseAnalytics.setUserId()` |

### NoOpAdapter

**File**: `lib/core/analytics/adapters/noop_adapter.dart`

All methods are empty. Used in development and testing.

---

## CompositeAnalyticsService

**File**: `lib/core/analytics/composite_analytics.dart`

Wraps multiple adapters and fans out every call:

| Behavior |
|----------|
| Holds a `List<AnalyticsService>` |
| On every method call, iterates and calls each adapter |
| Catches exceptions from individual adapters (one failing doesn't break others) |
| Logs adapter failures via `AppLogger` |

### DI Registration by Environment

| Environment | Adapters |
|-------------|----------|
| Development | `[NoOpAdapter]` |
| Staging | `[SentryAdapter]` |
| Production | `[SentryAdapter, MixpanelAdapter, FirebaseAdapter]` |

---

## BLoC Integration

Analytics events are NOT fired from widgets. They are fired from:

1. **BLoC event handlers** - after successful state transitions
2. **Route observer** - go_router `NavigatorObserver` for screen tracking
3. **Global error handlers** - `FlutterError.onError`, `PlatformDispatcher.onError`

### Screen Tracking via NavigatorObserver

Implementation details → [09_NAVIGATION_DEEP_LINKING.md](09_NAVIGATION_DEEP_LINKING.md#screen-tracking)
