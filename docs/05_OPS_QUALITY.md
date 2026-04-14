# 05 - Operations & Quality: Analytics, Testing & CI/CD

This document covers how we monitor, test, and deploy the application.

---

## 1. Analytics & Logging

We use a **Composite Pattern** for analytics to fan out events to multiple providers (Sentry, Mixpanel, Firebase) without leaking SDK dependencies into features.

### Interface
- **EventTracker**: Track named events (e.g., `book_opened`).
- **CrashReporter**: Record errors and breadcrumbs.
- **UserIdentifier**: Identify users and traits.

### Logging (AppLogger)
- **Development**: `PrettyAppLogger` for colorful console output.
- **Production**: `ProductionAppLogger` for structured logs that feed into the `CrashReporter`.
- **Policy**: Never log passwords, tokens, or PII.

---

## 2. Testing Strategy (The Pyramid)

| Type | Target | What it tests |
|------|--------|---------------|
| **Unit** | ~70% | BLoCs, Use Cases, Repos, Parsing, Logic. |
| **Widget** | ~20% | Page rendering, interactions, error/loading states. |
| **Integration** | ~10% | Full user flows and offline resilience. |

**Mocking**: Use `mocktail` for Mocks (interaction testing) and hand-written Fakes for deterministic data state.

---

## 3. CI/CD Pipeline

Every PR must pass the following gates in GitHub Actions:
1. **Format**: `dart format --set-exit-if-changed .`
2. **Analyze**: `flutter analyze` (Zero warnings allowed).
3. **Test**: `flutter test --coverage`.
4. **Build**: Verification that release builds succeed for Android/iOS.

---

## 4. Environments & Flavors

We start with **Dart-side environments** (`--dart-define=ENV=production`) before moving to native flavors.

| Environment | Purpose | Logging |
|-------------|---------|---------|
| **Development** | Local iteration | Verbose |
| **Staging** | QA / Preview | Info |
| **Production** | App Store / Play Store | Warning/Error |

---

## 5. Performance & Release Gates

Before any release, the following must be verified in **Profile Mode**:
- **Startup**: App reaches first frame within target budget.
- **Scrolling**: 60fps on primary lists/grids.
- **Memory**: No leaks during heavy navigation.
- **Gates**: All tests pass, analysis is clean, and a manual smoke test is performed on a real device.
