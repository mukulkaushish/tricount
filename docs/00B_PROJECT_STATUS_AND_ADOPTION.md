# 00B - Project Status & Adoption Plan

## Why This Document Exists

The repository docs describe a production-ready Flutter architecture, but the codebase is currently much smaller than that target. This file keeps contributors aligned on what exists today, what is planned, and how to adopt the architecture safely.

## Current Repository State

- `lib/` only contains `main.dart`
- `pubspec.yaml` is still close to the default Flutter starter configuration
- no documented feature modules, networking stack, or CI workflows have been implemented yet

**Active work (Phase 1 + partial Phase 2):**

The following is being built now as the first implementation slice:

| Area | Files being created | Status |
|------|---------------------|--------|
| Core theme layer | `lib/core/theme/` — `app_color_palette.dart`, `app_colors.dart` (3 palettes: teal, indigo, slate), `app_text_styles.dart`, `app_dimensions.dart`, `app_theme.dart`, `theme_extensions.dart`, `theme_bloc/` | In progress |
| Context extensions | `lib/core/extensions/build_context_extensions.dart` | In progress |
| App wiring | `lib/app.dart`, updated `lib/main.dart` | In progress |
| Auth — login screen | `lib/features/auth/presentation/pages/login_page.dart`, `auth_form.dart`, `auth_bloc/` (stub) | In progress |

This means many docs in this folder describe the intended architecture, not completed code. The theme system and login screen represent the first concrete adoption of these patterns.

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
2. Add environment and flavor strategy from `23`, starting with Dart-side config before native setup.
3. Add performance and release checks from `24`.
4. Add release automation only after the app can produce meaningful artifacts.

## Design Priorities

### Content Browsing: Grids Over Lists

**Grid layouts are the primary pattern** for displaying collections (bills, items, cards). Reasons:

1. **Responsive by nature** — automatically adapt column count by breakpoint without conditional layout code
2. **Space efficient** — use screen width effectively on phones, tablets, iPads, and foldables
3. **No custom wrappers** — use native `GridView.builder` + breakpoints from `AppDimensions`
4. **Accessible** — cards have adequate tap targets (48dp minimum) and semantic labels

**Lists are for:**
- Navigation items (navigation bar, menu)
- Long-form text-heavy content (conversations, chat history, feeds)
- Single-column browsing where items have variable structure

When a screen shows a browsable collection of similar items (bills, transactions, products), implement it as a grid. See [25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md § Grid Layouts](../docs/25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md#grid-layouts-primary-pattern-for-content-browsing) for implementation patterns.

## Rules For Contributors

- Prefer incremental adoption over large architecture-only refactors.
- Do not assume a dependency or folder exists just because it appears in the docs.
- When current code and target docs disagree, document the gap and either:
  - implement the missing piece, or
  - narrow the doc so it clearly says "planned" or "recommended"
- **Use grids (not lists) for content browsing** to ensure responsive layouts across all screen sizes by default.

## Definition Of Done For Future Doc Updates

A doc update is complete when:

- it is clear whether the content describes current state or target state
- file paths and examples are either real or explicitly marked illustrative
- dependency advice does not conflict with the current repo setup
- new contributors can tell what to build next without guessing
