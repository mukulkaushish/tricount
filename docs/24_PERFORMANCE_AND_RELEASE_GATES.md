# 24 — Performance & Release Gates

## Purpose

Production apps need explicit quality gates for performance, not just correctness. This doc adds release-readiness checks beside testing and CI.

## Principles

- Profile in `profile` mode, not `debug`.
- Measure representative user flows on real devices before release.
- Prefer repeatable measurements over ad-hoc manual checks.
- Fail releases on clear regressions, not subjective impressions.

## Recommended gates

### 1. Startup
- Launches without visible jank on a representative mid-range device.
- First meaningful screen within team's agreed target.
- Expensive synchronous work moved out of first frame where possible.

### 2. Scrolling & animation
- Primary scroll surfaces stay smooth during normal usage.
- Animations within frame budget for common transitions.
- Images/gradients/shadows tested on lower-end hardware.

### 3. Network & data flows
- Loading states appear quickly and predictably.
- Offline + slow-network behaviors validated.
- Large payload parsing measured if done on client.

### 4. Release verification
- `flutter analyze` passes.
- Automated tests pass.
- Release build succeeds for target platforms.
- Basic smoke test on a real device before shipping.

## How to measure

### Manual profiling (early validation / UI-heavy work)
1. Run in profile mode.
2. Test on ≥ 1 physical device.
3. Inspect frame rendering, memory, CPU via DevTools.

### Repeatable profiling (before larger releases)
1. Create an integration test for a representative flow.
2. Record a performance timeline.
3. Save the result and compare across runs.

## Release checklist

- Analyze passes.
- Tests pass.
- `build_runner` outputs up to date if codegen is used.
- Release builds complete successfully.
- Performance smoke checks pass in profile mode.
- Crash reporting + analytics configured correctly for release env.
- Localization + accessibility regressions spot-checked.

## Tooling

- Flutter DevTools — frame, memory, CPU.
- Integration tests — repeatable critical-path profiling.
- GitHub Actions — build/test gates.
- Optional artifact upload for benchmark summaries at maturity.

## When to add hard CI gates

Add automated performance gates only after:
- App has a stable critical path worth benchmarking.
- ≥ 1 repeatable integration test flow exists.
- Team agrees on acceptable thresholds.

Before that, keep perf review as a release checklist item, not a blocking CI rule.
