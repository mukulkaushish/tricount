# 24 - Performance & Release Gates

## Purpose

Production-ready apps need explicit quality gates for performance, not just correctness. This document adds the missing release-readiness checks that should sit beside testing and CI.

## Guiding Principles

- Profile performance in `profile` mode, not `debug` mode.
- Measure representative user flows on real devices before release.
- Prefer repeatable measurements over ad-hoc manual checks.
- Fail releases on clear regressions, not subjective impressions.

## Recommended Performance Gates

### 1. Startup

- App launches without visible jank on a representative mid-range device
- First meaningful screen appears within the team’s agreed target
- Expensive synchronous work is moved out of first frame where possible

### 2. Scrolling And Animation

- Primary scrolling surfaces remain smooth during normal usage
- Animations stay within frame budget for common transitions
- Images, gradients, and shadows are tested on lower-end hardware

### 3. Network And Data Flows

- Loading states appear quickly and predictably
- Offline and slow-network behavior are validated
- Large payload parsing is measured if it happens on the client

### 4. Release Verification

- `flutter analyze` passes
- automated tests pass
- release build succeeds for target platforms
- basic smoke test is run on a real device before shipping

## How To Measure

### Manual Profiling

Use this for early validation and UI-heavy work:

1. Run the app in profile mode.
2. Test on at least one physical device.
3. Inspect frame rendering, memory, and CPU activity in DevTools.

### Repeatable Profiling

Use this before larger releases:

1. Create an integration test for a representative user flow.
2. Record a performance timeline.
3. Save the result and compare it across runs.

## Suggested Release Checklist

- analyze passes
- tests pass
- build_runner outputs are up to date if code generation is used
- release builds complete successfully
- performance smoke checks pass in profile mode
- crash reporting and analytics configuration are correct for the release environment
- localization and accessibility regressions have been spot-checked

## Tooling Recommendations

- Flutter DevTools for frame, memory, and CPU inspection
- integration tests for repeatable critical-path profiling
- GitHub Actions for build/test gates
- optional artifact upload for benchmark summaries when the project reaches that maturity

## When To Add Hard Gates In CI

Add automated performance gates after:

- the app has a stable critical path worth benchmarking
- there is at least one repeatable integration test flow
- the team agrees on acceptable thresholds

Before that point, keep performance review as a release checklist item rather than a blocking CI rule.
