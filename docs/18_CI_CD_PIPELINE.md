# 18 - CI/CD Pipeline

## Purpose

This document describes the recommended CI/CD setup for the target architecture. The repository does not currently include these workflows; add them as the codebase matures.

## Minimum First Step

Before introducing release automation, add a simple CI workflow in `.github/workflows/ci.yml` that:

- checks out the code
- installs Flutter
- runs `flutter pub get`
- runs `dart format --set-exit-if-changed .`
- runs `flutter analyze`
- runs `flutter test`

This is the first workflow the repository should adopt.

## Recommended Workflow Set

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push and pull request | Formatting, analysis, tests, and build verification |
| `release.yml` | Version tag or manual dispatch | Release builds and optional store deployment |
| `nightly.yml` | Scheduled run | Longer-running checks, outdated dependencies, optional profiling |

## CI Workflow Guidance

### Recommended Triggers

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

Expand branch patterns only when the team needs them.

### Recommended Jobs

1. `format-and-analyze`
2. `test`
3. `build-android`
4. `build-ios` when macOS runners are justified

### Recommended Checks

- formatting
- static analysis
- unit and widget tests
- integration tests once they exist
- at least one release-mode or release-like build verification job before shipping

## Workflow Hygiene

### Concurrency

Use workflow or job concurrency so stale runs are cancelled when a branch receives new commits. This keeps feedback fast and prevents wasting CI minutes on obsolete runs.

### Dependency Caching

Use GitHub Actions dependency caching where it meaningfully reduces setup time, but keep cache keys scoped and predictable.

### Artifact Handling

- upload coverage or test reports when they help review
- upload release artifacts only from trusted branches, tags, or protected environments
- keep retention conservative to avoid unnecessary storage growth

## Suggested CI Shape

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

Then define jobs for checkout, Flutter setup, dependency install, analysis, tests, and build verification.

## Release Workflow Guidance

Add `release.yml` only after:

- the app produces meaningful release artifacts
- signing strategy is documented
- secrets management is ready
- rollback expectations are clear

Recommended release checks:

- tagged version matches `pubspec.yaml`
- release build succeeds
- required secrets are present
- optional deployment steps are limited to protected environments

## Nightly Workflow Guidance

Use a scheduled workflow for:

- full test suite runs that are too expensive for every PR
- `flutter pub outdated`
- release smoke builds
- optional performance or benchmark runs once the app has stable critical paths

## Branch Protection Recommendations

- require pull requests for `main`
- require passing CI checks
- require at least one review when the team size justifies it
- dismiss stale approvals on new pushes for important branches

## Local Parity

Document local equivalents for CI checks in `README.md` or a future `Makefile` / `scripts/` directory:

- `format`
- `analyze`
- `test`
- `build`

Local parity reduces “works on my machine” drift and makes CI failures easier to reproduce.
