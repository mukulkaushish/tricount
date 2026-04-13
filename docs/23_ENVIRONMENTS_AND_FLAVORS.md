# 23 - Environments & Flavors

## Goal

Keep environment handling simple at the start, and avoid native Android/iOS customization until it solves a real packaging problem.

## Recommended Order

### Step 1: Use Dart-Side Environment Config First

Start with a single Dart abstraction for environment values such as:

- API base URL
- analytics enablement
- debug-only UI flags
- environment label

This keeps the app cross-platform and avoids premature Android/Xcode setup.

Example sources of truth:

- `String.fromEnvironment(...)`
- a small injected environment/config object
- Flutter's `appFlavor` value once flavors are added

## When Native Flavors Are Worth Adding

Add Android product flavors or iOS/macOS schemes only when you need differences such as:

- distinct app IDs / bundle IDs
- different display names or launcher icons
- separate signing or store-distribution tracks
- platform-specific build settings that cannot be handled cleanly in Dart

Inference from Flutter's flavor docs: if those packaging differences do not exist yet, a Dart-side environment model is usually the lower-maintenance starting point.

## Recommended Environments

| Environment | Purpose |
|-------------|---------|
| `development` | local work and rapid iteration |
| `staging` | QA / preview validation |
| `production` | release builds |

## Suggested Commands

Without native flavors:

```bash
flutter run --dart-define=ENV=development
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=production
```

After native flavors are added:

```bash
flutter run --flavor staging --dart-define=ENV=staging
flutter run --flavor production --dart-define=ENV=production
```

## Rules

- Do not scatter raw environment checks across the codebase.
- Keep one environment abstraction and inject it where needed.
- Prefer Dart-only configuration until native packaging differences are required.
- Add native flavor setup incrementally, not preemptively.
