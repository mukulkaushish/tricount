# 00B - Project Status & Adoption Plan

## Why This Document Exists

The repository docs describe a production-ready Flutter architecture, but the codebase is currently much smaller than that target. This file keeps contributors aligned on what exists today, what is planned, and how to adopt the architecture safely.

## Current Repository State

At the time of writing:

- `lib/` only contains `main.dart`
- `pubspec.yaml` is still close to the default Flutter starter configuration
- no documented feature modules, networking stack, or CI workflows have been implemented yet

This means many docs in this folder describe the intended architecture, not completed code.

## Target Architecture

The target state is a layered, feature-first Flutter application with:

- clear separation between `presentation`, `domain`, `data`, and `core`
- package-import-only boundaries and barrel files
- typed error handling and centralized networking
- predictable state management
- CI, testing, performance, and release gates

According to Flutter's architecture recommendations, these patterns should be treated as adaptable recommendations rather than inflexible rules. Apply them in proportion to the app's size and complexity.

## How To Read The Docs

- `00A` defines coding and linting rules
- `01` through `24` describe the recommended target architecture
- `README.md`, `AGENTS.md`, and `CLAUDE.md` explain how to work in this repo day to day

If a doc describes a file that does not yet exist, treat it as a planned structure unless the current task requires adding it.

## Adoption Order

### Phase 1: Baseline Project Setup

1. Align `pubspec.yaml` with the dependency plan in `03`.
2. Replace starter linting with the rules from `00A`.
3. Create the top-level folder structure from `02`.
4. Add a useful `README.md` and CI basics.

### Phase 2: Core Infrastructure

1. Add app bootstrap and dependency injection.
2. Add theming, logging, error handling, and localization foundations.
3. Add networking and storage only when the first feature requires them.

### Phase 3: First Feature Slice

1. Implement one end-to-end feature through presentation, domain, and data.
2. Add tests for that slice before scaling the pattern further.
3. Use the example feature spec format from `19`, adapted to the actual product domain.

### Phase 4: Quality Gates

1. Add GitHub Actions workflows from `18`.
2. Add performance and release checks from `24`.
3. Add release automation only after the app can produce meaningful artifacts.

## Rules For Contributors

- Prefer incremental adoption over large architecture-only refactors.
- Do not assume a dependency or folder exists just because it appears in the docs.
- When current code and target docs disagree, document the gap and either:
  - implement the missing piece, or
  - narrow the doc so it clearly says "planned" or "recommended"

## Definition Of Done For Future Doc Updates

A doc update is complete when:

- it is clear whether the content describes current state or target state
- file paths and examples are either real or explicitly marked illustrative
- dependency advice does not conflict with the current repo setup
- new contributors can tell what to build next without guessing
