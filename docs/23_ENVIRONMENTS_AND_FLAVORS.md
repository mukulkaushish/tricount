# 23 — Environments & Flavors

Keep environment handling simple. Avoid native Android/iOS customization until it solves a real packaging problem.

## Recommended order

### Step 1 — Dart-side environment config first

Start with a single Dart abstraction for environment values:
- API base URL
- analytics enablement
- debug-only UI flags
- environment label

Keeps the app cross-platform and avoids premature Android/Xcode setup.

**Sources of truth:**
- `String.fromEnvironment(...)`
- small injected environment/config object
- Flutter's `appFlavor` value once flavors are added

## When native flavors are worth adding

Add Android product flavors or iOS/macOS schemes **only when** you need:
- distinct app IDs / bundle IDs
- different display names or launcher icons
- separate signing / store-distribution tracks
- platform-specific build settings that can't be handled cleanly in Dart

**Inference:** if those packaging differences don't exist yet, a Dart-side environment model is the lower-maintenance starting point.

## Recommended environments

| Env | Purpose |
|---|---|
| `development` | local work, rapid iteration |
| `staging` | QA / preview validation |
| `production` | release builds |

## Commands

**Without native flavors:**
```bash
flutter run --dart-define=ENV=development
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=production
```

**After native flavors added:**
```bash
flutter run --flavor staging --dart-define=ENV=staging
flutter run --flavor production --dart-define=ENV=production
```

## Rules

- Do not scatter raw environment checks across the codebase.
- Keep one environment abstraction and inject it where needed.
- Prefer Dart-only config until native packaging differences are required.
- Add native flavor setup incrementally, never preemptively.
