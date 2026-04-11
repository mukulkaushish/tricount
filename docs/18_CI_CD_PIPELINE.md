# 18 - CI/CD Pipeline

## Overview

GitHub Actions is the primary CI/CD platform. Three workflows handle the full lifecycle:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push to any branch, PR to main | Lint, test, build verification |
| `release.yml` | Tag `v*` pushed | Build release artifacts, deploy |
| `nightly.yml` | Cron (daily 2am UTC) | Full test suite + coverage report |

---

## CI Workflow (`ci.yml`)

### Trigger

```yaml
on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main]
```

### Jobs

#### 1. Analyze

| Step | Command | Purpose |
|------|---------|---------|
| Checkout | `actions/checkout@v4` | Get code |
| Setup Flutter | `subosito/flutter-action@v2` | Install Flutter SDK |
| Get dependencies | `flutter pub get` | Install packages |
| Run code gen | `dart run build_runner build --delete-conflicting-outputs` | Generate code |
| Analyze | `flutter analyze` | Static analysis |
| Format check | `dart format --set-exit-if-changed .` | Formatting |

#### 2. Test

| Step | Command | Purpose |
|------|---------|---------|
| Checkout | `actions/checkout@v4` | Get code |
| Setup Flutter | `subosito/flutter-action@v2` | Install Flutter SDK |
| Get dependencies | `flutter pub get` | Install packages |
| Run code gen | `dart run build_runner build --delete-conflicting-outputs` | Generate code |
| Run tests | `flutter test --coverage` | Run all tests |
| Check coverage | Custom step: parse lcov, fail if < 80% | Coverage gate |
| Upload coverage | `codecov/codecov-action@v4` | Coverage report |

#### 3. Build (Android)

| Step | Command | Purpose |
|------|---------|---------|
| Checkout | `actions/checkout@v4` | Get code |
| Setup Java | `actions/setup-java@v4` (JDK 17) | Android build |
| Setup Flutter | `subosito/flutter-action@v2` | Install Flutter SDK |
| Get dependencies | `flutter pub get` | Install packages |
| Run code gen | `dart run build_runner build --delete-conflicting-outputs` | Generate code |
| Build APK | `flutter build apk --release --dart-define=ENV=staging` | Verify build |

#### 4. Build (iOS)

| Step | Command | Purpose |
|------|---------|---------|
| Runs on | `macos-latest` | macOS required for iOS |
| Checkout | `actions/checkout@v4` | Get code |
| Setup Flutter | `subosito/flutter-action@v2` | Install Flutter SDK |
| Get dependencies | `flutter pub get` | Install packages |
| Run code gen | `dart run build_runner build --delete-conflicting-outputs` | Generate code |
| Build iOS | `flutter build ios --release --no-codesign --dart-define=ENV=staging` | Verify build |

---

## Release Workflow (`release.yml`)

### Trigger

```yaml
on:
  push:
    tags: ['v*']
```

### Jobs

#### 1. Build Android Release

| Step | Details |
|------|---------|
| Decode keystore | Secrets: `ANDROID_KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD` |
| Build AAB | `flutter build appbundle --release --dart-define=ENV=production` |
| Upload artifact | `actions/upload-artifact@v4` |

#### 2. Build iOS Release

| Step | Details |
|------|---------|
| Setup certificates | Using `fastlane match` or manual provisioning profiles from secrets |
| Build IPA | `flutter build ipa --release --dart-define=ENV=production` |
| Upload artifact | `actions/upload-artifact@v4` |

#### 3. Deploy (optional)

| Target | Tool | Trigger |
|--------|------|---------|
| Google Play (internal) | `r0adkll/upload-google-play@v1` | Automatic on tag |
| TestFlight | `apple-actions/upload-testflight-build@v1` | Automatic on tag |
| Firebase App Distribution | `wzieba/Firebase-Distribution-Github-Action@v1` | Manual workflow_dispatch |

---

## Nightly Workflow (`nightly.yml`)

### Trigger

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
```

### Jobs

1. Full test suite with coverage
2. `flutter pub outdated` → annotate PR if packages need updates
3. `dart analyze` with strict mode
4. Build both platforms
5. Report results to Slack/email (optional)

---

## Secrets Required

| Secret | Used By | Purpose |
|--------|---------|---------|
| `ANDROID_KEYSTORE_BASE64` | Release | Signing keystore |
| `KEY_ALIAS` | Release | Keystore key alias |
| `KEY_PASSWORD` | Release | Key password |
| `STORE_PASSWORD` | Release | Keystore password |
| `APPLE_CERTIFICATE_BASE64` | Release | iOS signing certificate |
| `APPLE_PROVISIONING_PROFILE` | Release | iOS provisioning profile |
| `CODECOV_TOKEN` | CI | Coverage upload |
| `SENTRY_DSN` | Build | Sentry crash reporting |
| `SENTRY_AUTH_TOKEN` | Release | Sentry source maps upload |

---

## Branch Protection Rules (GitHub)

| Rule | Setting |
|------|---------|
| Require PR reviews | 1 reviewer minimum |
| Require status checks | `analyze`, `test`, `build-android` must pass |
| Require up-to-date branches | PR branch must be up to date with main |
| Dismiss stale reviews | On new push to PR |
| Restrict force push | On `main` branch |

---

## Version Strategy

| Format | Example | Where |
|--------|---------|-------|
| Semantic versioning | `1.2.3` | `pubspec.yaml` version field |
| Build number | `+45` | Auto-incremented by CI (run number) |
| Git tag | `v1.2.3` | Triggers release workflow |

CI overrides build number: `flutter build --build-number=${{ github.run_number }}`

---

## Local Development Scripts

These scripts should exist in a `Makefile` or `scripts/` directory:

| Command | Purpose |
|---------|---------|
| `make gen` | Run `build_runner build` |
| `make gen-watch` | Run `build_runner watch` |
| `make test` | Run all tests |
| `make test-coverage` | Run tests with coverage report |
| `make analyze` | Run `flutter analyze` |
| `make format` | Run `dart format .` |
| `make clean` | `flutter clean && flutter pub get` |
| `make ci` | Run full CI check locally (analyze + format + test) |
