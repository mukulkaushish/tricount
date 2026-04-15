# CLAUDE.md

> **This file is the single source of truth for day-to-day work.** Read it fully before every task. The `docs/` folder holds deeper subsystem specs; consult them only when touching that subsystem.

---

## Project Identity

**Tricount** — a Flutter bill-splitting app. Package name: `tricount`.

---

## Current State (as of 2026-04-15)

**Phases 1–4 complete.** All layers, auth, navigation, and home tabs are live.

| Area | Location | Status |
|------|----------|--------|
| Clean Architecture (core, domain, data, presentation) | `lib/` | ✅ |
| Theming (8 palettes, light/dark, font scale) | `lib/core/theme/` | ✅ |
| Logging (`AppLogger`, `PrettyAppLogger`) | `lib/core/logging/` | ✅ |
| Error handling (11 `AppException` subtypes) | `lib/core/error/` | ✅ |
| Networking (`HttpClient`, `DioHttpClient`, `AuthInterceptor`) | `lib/core/network/` | ✅ |
| Security (`TokenProvider`, `SecureTokenProvider` w/ user info) | `lib/core/security/` | ✅ |
| DI (`GetIt` via `injection_container.dart`) | `lib/core/di/` | ✅ |
| Auth (login, register, forgot/reset, refresh, Google, Apple, **logout**) | `lib/features/auth/` | ✅ |
| Navigation (`auto_route` v11, `AuthGuard`, `SplashRoute→LoginRoute/HomeRoute`) | `lib/router/` | ✅ |
| Home tabs (Feed + Profile) | `lib/features/home/` | ✅ |
| Profile tab (avatar, name/email, palette/mode/font pickers, sign-out) | `lib/features/home/presentation/pages/profile_page.dart` | ✅ |

**Adopted packages** (all in `pubspec.yaml`):
`auto_route`, `bloc_concurrency`, `flutter_bloc`, `equatable`, `dio`, `fpdart`, `get_it`, `flutter_secure_storage`, `shared_preferences`, `flutter_svg`, `flutter_appauth`, `flutter_animate`, `gap`, `logger`

**Dev packages**: `auto_route_generator`, `build_runner`, `very_good_analysis`

**Known gaps / next up:**
- `auto_route` passkeys routes not wired
- `ProductionAppLogger` (structured logging for release builds) not implemented
- No GitHub Actions CI
- No tests yet (`bloc_test`, `mocktail` not added)
- Local database (Drift) not added

---

## Architecture (non-negotiable)

### Layer boundaries
```
presentation  →  domain + core only
domain        →  pure Dart, no Flutter imports
data          →  implements domain contracts, talks to APIs
core          →  shared infrastructure (network, theme, DI, logging, error)
```

### Dependency direction
- Widgets → BLoCs only
- BLoCs → Use Cases (never repositories directly)
- Use Cases → Repository interfaces
- Repositories → `HttpClient` interface (never Dio directly)
- Repository implementations → get `TokenProvider` injected for token persistence
- DI (`injection_container.dart`) wires everything; business code never references implementations

### Navigation (auto_route — live)
- Use `context.router.pushRoute(XxxRoute())`, `context.router.replaceAll([...])`, `context.maybePop()`
- Every page has `@RoutePage()` annotation
- Route table lives in `lib/router/app_router.dart`; generated code in `app_router.gr.dart`
- Run `dart run build_runner build --delete-conflicting-outputs` after adding a new `@RoutePage()`
- `AuthGuard` (token check) protects `HomeRoute` and its children
- Tab shell: `HomeRoute` → `AutoTabsScaffold` → `[FeedRoute, ProfileRoute]`

### Error handling
- All repos return `Either<AppException, T>`
- BLoCs fold the Either and emit typed states
- UI reads `exception.userMessage` — never raw exception strings

### Networking
- Use `HttpClient.request<T>()`, `requestList<T>()`, `requestEmpty()`
- Use `RequestMethod` enum
- Auth token refresh lives in `AuthInterceptor` (Dio interceptor), not in BLoC

---

## Coding Rules (enforced by `very_good_analysis`)

| Rule | Enforcement |
|------|-------------|
| `package:tricount/...` imports only — no relative `../` | `always_use_package_imports` |
| All parameters and locals are `final` | `prefer_final_parameters`, `prefer_final_locals` |
| `const` everywhere possible | `prefer_const_constructors` |
| Single quotes | `prefer_single_quotes` |
| No `print()` — use `AppLogger` | `avoid_print` |
| No magic numbers — use `AppDimensions` | convention |
| No inline `TextStyle`/`Color` — use `context.textTheme`, `context.colorScheme` | convention |
| Exhaustive switch on sealed/enum types (no `default:`) | `no_default_cases` |
| Max ~3 levels of widget nesting per `build()` — extract named widgets | convention |
| Trailing commas on multi-line argument lists | `dart format` |
| Cross-module imports via barrel files | `always_use_package_imports` |

### Import order (within a file)
1. `dart:` libraries
2. `package:flutter/` imports
3. `package:` third-party imports
4. `package:tricount/` project imports

### Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.dart` | `auth_bloc.dart` |
| Classes, enums | `PascalCase` | `AuthBloc`, `RequestMethod` |
| Variables, functions | `camelCase` | `fetchUser()` |
| Repository contract | `XxxRepository` | `AuthRepository` |
| Repository implementation | `RemoteXxxRepository` | `RemoteAuthRepository` |
| Data source | `DioXxxDataSource` | `DioAuthDataSource` |
| Use case | `<Verb><Noun>UseCase` | `LogoutUseCase` |
| BLoC | `<Feature>Bloc` | `AuthBloc` |
| Model (DTO) | `<Name>Model` | `AuthTokenModel` |
| Entity | `<Name>` | `AuthToken`, `User` |
| Page | `<Name>Page` | `LoginPage` |

Never use `Impl` as a suffix.

### Barrel files
- Every folder with ≥ 3 public Dart files **must** have `<folder_name>.dart`
- Barrel files contain `export` statements only
- Feature barrels (`auth.dart`, `home.dart`) export domain + presentation; **never** export `data/`
- Use the barrel for cross-module imports:
  ```dart
  import 'package:tricount/core/core.dart';
  import 'package:tricount/features/auth/auth.dart';
  ```

---

## Key File Locations

| What | File |
|------|------|
| DI wiring | `lib/core/di/injection_container.dart` |
| Router config | `lib/router/app_router.dart` |
| Generated routes | `lib/router/app_router.gr.dart` |
| Auth guard | `lib/router/guards/auth_guard.dart` |
| API endpoints | `lib/core/constants/api_constants.dart` |
| Color palettes (8) | `lib/core/theme/app_colors.dart` |
| Dimensions/spacing | `lib/core/theme/app_dimensions.dart` |
| Theme BLoC | `lib/core/theme/theme_bloc/` |
| Auth BLoC | `lib/features/auth/presentation/bloc/auth_bloc.dart` |
| Token + user info | `lib/core/security/secure_token_provider.dart` |
| Home tab shell | `lib/features/home/presentation/pages/home_page.dart` |
| Feed tab | `lib/features/home/presentation/pages/feed_page.dart` |
| Profile tab | `lib/features/home/presentation/pages/profile_page.dart` |

---

## Common Commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

Run `flutter analyze` and fix all issues before considering a task done. Only `info` items about line length are acceptable if the fix would make code less readable.

---

## Auth Screen UI Pattern (non-negotiable)

Every auth screen (`LoginPage`, `RegisterPage`, and any future auth page) **must** follow this exact structure. Read `login_page.dart` as the canonical reference before touching any auth UI.

### Structure
```
XxxPage (StatelessWidget)
└── BlocProvider → _XxxView

_XxxView (StatelessWidget)
└── BlocListener → KeyboardDismisser → Scaffold
    └── AdaptiveLayout(compact: _CompactXxxLayout(), expanded: _ExpandedXxxLayout())
```

### Compact layout (`_CompactXxxLayout`)
```
Stack
├── Positioned — gradient fills top 50% of screen height
├── Positioned — back button overlaid on gradient (only when page is not root)
└── SafeArea
    └── SingleChildScrollView(physics: AlwaysScrollableScrollPhysics)
        └── ConstrainedBox(minHeight: screenHeight - topPadding)
            └── Column(mainAxisAlignment: end)
                ├── SizedBox(height: 30% of screen) → Center(AuthBrandingSection())
                └── _FormCard  ← animated with flutter_animate slideY + fadeIn
```

### Expanded layout (`_ExpandedXxxLayout`)
```
Row
├── Expanded — gradient panel, SafeArea, Center(AuthBrandingSection())
└── Expanded — SafeArea, Center, SingleChildScrollView → form widgets
```

### Form card (`_FormCard`)
- Rounded top corners (`AppDimensions.r28`), surface color, shadow
- Drag handle pill at top center
- Title animates: `.animate().fadeIn(delay: 50.ms).slideY(begin: 0.1)`
- Card itself animates: `.animate().slideY(begin: 0.15).fadeIn(duration: 350.ms)`
- Form fields are extracted into a separate `_XxxForm` `StatefulWidget` (keeps controllers + focus nodes)
- `_XxxForm` is reused in both compact `_FormCard` and expanded right panel

### Rules
- `AdaptiveLayout` is **always** used — never a single layout for all screen sizes
- `flutter_animate` entrance animations are **always** applied on the form card and its title
- `AlwaysScrollableScrollPhysics` on the compact scroll view — keyboard must not break layout
- `KeyboardDismisser` wraps the `Scaffold` with `onTap` + `onPanUpdate` gestures
- `BlocListener` handles navigation and error snackbars; `BlocBuilder` handles loading state inside `_XxxForm`
- Gradient is `Positioned(height: size.height * 0.50)` — same as login; the form card's surface covers everything below; **never use `Positioned.fill`** (gradient bleeds into bottom system-bar area outside SafeArea)
- Back button: use `Scaffold(extendBodyBehindAppBar: true, appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, foregroundColor: scheme.onPrimary))` — the system back button is tinted white automatically, no custom `Positioned` button needed
- Never add a `Positioned` back button manually — double-`SafeArea` or topPadding double-offset bugs occur

---

## When to Read `docs/`

| Touching | Read |
|----------|------|
| Network layer, interceptors, HttpClient | `docs/06_NETWORKING_LAYER.md` |
| Auth flows, token storage, OAuth | `docs/20_SECURITY.md` |
| Navigation, guards, deep links | `docs/09_NAVIGATION_DEEP_LINKING.md` |
| Theming, palettes, AppTheme | `docs/05_THEMING_SYSTEM.md` |
| Responsive / adaptive layouts, breakpoints | `docs/25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md` |
| Animations, micro-interactions, performance budget | `docs/16_ANIMATIONS_TRANSITIONS.md` |
| Reusable shared widgets | `docs/15_REUSABLE_COMPONENTS.md` |
| Local database (Drift) | `docs/10_LOCAL_STORAGE.md` |
| State management patterns | `docs/08_STATE_MANAGEMENT.md` |
| Error handling, AppException | `docs/14_ERROR_HANDLING.md` |
| Logging, AppLogger | `docs/13_LOGGING_SYSTEM.md` |
| Accessibility, semantics | `docs/22_ACCESSIBILITY.md` |
| Adding a dependency | `docs/03_DEPENDENCY_MANIFEST.md` — add the package there too |
| CI / release gates | `docs/18_CI_CD_PIPELINE.md`, `docs/24_PERFORMANCE_AND_RELEASE_GATES.md` |

---

## Delivery Workflow

- If the user asks for phased screen delivery, implement one screen at a time.
- After each screen, run `flutter analyze` — zero errors required before reporting done.
- Wait for explicit approval before moving to the next screen.
- If the user asks for a standalone plan file without naming a folder, create it at the repository root.

---

## Documentation Maintenance

When adding a dependency to `pubspec.yaml`:
1. Add it to `docs/03_DEPENDENCY_MANIFEST.md` with area and reason
2. Update the relevant subsystem doc
3. Update `AppTheme.build()` and `docs/05_THEMING_SYSTEM.md` if the package adds a theme extension

When adding a `@RoutePage()`: re-run build_runner and update `app_router.dart` routes list.
