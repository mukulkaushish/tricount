# 18 — CI/CD Pipeline

> Recommended setup for target architecture. Add as the codebase matures.

## Minimum first step

Before release automation, add `.github/workflows/ci.yml` that:
- checkouts code
- installs Flutter
- runs `flutter pub get`
- runs `dart format --set-exit-if-changed .`
- runs `flutter analyze`
- runs `flutter test`

This is the first workflow the repo should adopt.

## Recommended workflow set

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | push + PR | formatting, analysis, tests, build verification |
| `release.yml` | version tag / manual dispatch | release builds, optional store deployment |
| `nightly.yml` | scheduled | longer checks, outdated deps, profiling |

## CI workflow guidance

### Triggers
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```
Expand only when the team needs it.

### Jobs
1. `format-and-analyze`
2. `test`
3. `build-android`
4. `build-ios` when macOS runners are justified

### Checks
- formatting
- static analysis
- unit + widget tests
- integration tests once they exist
- at least one release-mode (or release-like) build verification before shipping

## Workflow hygiene

**Concurrency** — cancel stale runs on new commits to the same branch:
```yaml
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Dependency caching** — use GitHub Actions caching where it meaningfully reduces setup. Scope keys predictably.

**Artifact handling:**
- Upload coverage / test reports when useful for review.
- Upload release artifacts only from trusted branches, tags, or protected envs.
- Keep retention conservative.

## Suggested CI shape

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```
Define jobs for checkout, Flutter setup, deps install, analysis, tests, build verification.

## Release workflow guidance

Add `release.yml` only after:
- App produces meaningful release artifacts.
- Signing strategy documented.
- Secrets management ready.
- Rollback expectations clear.

**Recommended release checks:**
- Tagged version matches `pubspec.yaml`.
- Release build succeeds.
- Required secrets present.
- Optional deployment steps limited to protected environments.

## Nightly workflow guidance

Use a scheduled workflow for:
- Full test suite runs too expensive for every PR.
- `flutter pub outdated`.
- Release smoke builds.
- Optional performance / benchmark runs once stable.

## Branch protection

- Require PRs for `main`.
- Require passing CI.
- Require ≥ 1 review when team size justifies.
- Dismiss stale approvals on new pushes for important branches.

## Local parity

Document local equivalents in `README.md` or a `Makefile`/`scripts/`:
- `format`
- `analyze`
- `test`
- `build`

Local parity reduces "works on my machine" drift and makes CI failures reproducible.
