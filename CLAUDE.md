# CLAUDE.md

> **Single source of truth.** Read this fully at the start of every task.  
> The `docs/` folder has deeper subsystem specs — consult them only when touching that specific subsystem.

---

## 1. Project Identity

**Tricount** — Flutter bill-splitting app. Package: `tricount`. Min SDK: `^3.11.4`.

---

## 2. Current State

**Phases 1–4 complete.** Zero analyzer issues on `main`/`feat-login`.

| Layer | Location | Notes |
|-------|----------|-------|
| Core infra | `lib/core/` | error, network, theme, DI, logging, security, extensions |
| Auth | `lib/features/auth/` | login, register (+confirm pw), forgot/OTP reset, Google, Apple, logout |
| Navigation | `lib/router/` | `auto_route` v11, `AuthGuard` |
| Home | `lib/features/home/` | Feed tab + Profile tab (`AutoTabsScaffold`) |
| Shared | `lib/shared/` | `AdaptiveLayout`, `KeyboardDismisser` |

**Packages in `pubspec.yaml`:**  
`auto_route`, `bloc_concurrency`, `flutter_bloc`, `equatable`, `dio`, `fpdart`, `get_it`, `flutter_secure_storage`, `shared_preferences`, `flutter_svg`, `flutter_appauth`, `flutter_animate`, `gap`, `logger`

**Dev:** `auto_route_generator`, `build_runner`, `very_good_analysis`

**Known gaps (next up):**
- `ProductionAppLogger` not implemented (only `PrettyAppLogger`)
- No unit/widget tests (`bloc_test`, `mocktail` not added)
- No GitHub Actions CI
- Drift local database not added

---

## 3. Architecture (non-negotiable)

```
presentation  →  domain + core
domain        →  pure Dart only (no Flutter imports)
data          →  implements domain contracts, calls APIs
core          →  shared infra (network, theme, DI, logging, error, extensions)
```

**Dependency rules:**
- Widgets → BLoCs only (never repositories, never use cases directly)
- BLoCs → Use Cases only (never repositories directly)
- Use Cases → Repository *interfaces* only
- Repositories → `HttpClient` interface (never `Dio` directly)
- `injection_container.dart` wires everything — business code never imports `Impl` classes

**Error handling:**
- Every repository returns `Either<AppException, T>` — no try/catch in BLoCs
- BLoC folds the Either and emits typed states
- UI reads `exception.userMessage` only — never `.message`

---

## 4. Coding Rules (enforced by `very_good_analysis`)

| Rule | Detail |
|------|--------|
| Package imports only | `package:tricount/...` — no relative `../` |
| `final` everywhere | All params, locals, and fields |
| `const` everywhere | All constructors and values that can be const |
| Single quotes | `'string'` not `"string"` |
| No `print()` | Use `logger.debug(...)`, `logger.error(...)` etc. |
| No magic numbers | Use `AppDimensions` constants always |
| No inline `TextStyle`/`Color`/`BoxDecoration` | Use `context.textTheme`, `context.colorScheme` |
| No `default:` in switch | Exhaustive switches on sealed/enum types |
| Max ~3 widget nesting levels | Extract named private widgets |
| Trailing commas | On all multi-line arg lists |
| Cross-module via barrels | `import 'package:tricount/core/core.dart'` not leaf files |

**Import order:**
```dart
import 'dart:...';                          // 1. dart: SDK
import 'package:flutter/...';               // 2. Flutter framework
import 'package:third_party/...';           // 3. Third-party packages
import 'package:tricount/...';              // 4. Project imports
```

**Naming:**

| Element | Pattern | Example |
|---------|---------|---------|
| Files | `snake_case.dart` | `auth_bloc.dart` |
| Classes / enums | `PascalCase` | `AuthBloc` |
| Repo contract | `XxxRepository` | `AuthRepository` |
| Repo impl | `RemoteXxxRepository` | `RemoteAuthRepository` |
| Data source | `DioXxxDataSource` | `DioAuthDataSource` |
| Use case | `<Verb><Noun>UseCase` | `LoginUseCase` |
| BLoC | `<Feature>Bloc` | `AuthBloc` |
| Model (DTO) | `<Name>Model` | `AuthTokenModel` |
| Entity | `<Name>` | `AuthToken`, `User` |
| Page | `<Name>Page` | `LoginPage` |

Never use `Impl` as suffix. Never use `Manager`, `Helper`, `Utils` as class names.

---

## 5. Barrel File Rules

- Every folder with **≥ 3** public Dart files **must** have `<folder_name>.dart`
- Barrel files contain `export` statements only — no code
- Feature barrels export `domain/` + `presentation/` — **never** `data/` (implementation detail)
- `core/core.dart` is the single import for all core types

```dart
// ✅ Correct
import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/auth.dart';

// ❌ Wrong — importing leaf files across modules
import 'package:tricount/core/network/http_client.dart';
import 'package:tricount/features/auth/data/repositories/remote_auth_repository.dart';
```

---

## 6. Key File Locations

| What | File |
|------|------|
| DI wiring (all registrations) | `lib/core/di/injection_container.dart` |
| API endpoint constants | `lib/core/constants/api_constants.dart` |
| All AppException subtypes | `lib/core/error/app_exception.dart` |
| HttpClient interface | `lib/core/network/http_client.dart` |
| JsonParser mixin | `lib/core/network/json_parser.dart` |
| AppDimensions (spacing, radius, animation) | `lib/core/theme/app_dimensions.dart` |
| AppTextStyles | `lib/core/theme/app_text_styles.dart` |
| AppTheme factory | `lib/core/theme/app_theme.dart` |
| Color palettes (8) | `lib/core/theme/app_colors.dart` |
| ThemeBloc | `lib/core/theme/theme_bloc/theme_bloc.dart` |
| TokenProvider + SecureTokenProvider | `lib/core/security/` |
| BuildContext extensions | `lib/core/extensions/build_context_extensions.dart` |
| Responsive extensions | `lib/core/extensions/responsive_extensions.dart` |
| String extensions (isValidEmail) | `lib/core/extensions/string_extensions.dart` |
| Router config | `lib/router/app_router.dart` |
| Generated routes | `lib/router/app_router.gr.dart` |
| Auth guard | `lib/router/guards/auth_guard.dart` |
| AuthBloc | `lib/features/auth/presentation/bloc/auth_bloc.dart` |
| Shared auth widgets | `lib/features/auth/presentation/widgets/` |
| Home tab shell | `lib/features/home/presentation/pages/home_page.dart` |

---

## 7. AppDimensions Reference

Always use these — never hardcode numbers.

```dart
// Spacing
s2, s4, s6, s8, s10, s12, s16, s20, s24, s28, s32, s40, s48, s56, s64, s72, s80, s96

// Radius
r4, r8, r12, r16, r20, r24, r28, r32, rFull (999)

// Components
buttonHeight = 52    inputHeight = 52    navBarHeight = 72
iconSm = 18         iconMd = 24          iconLg = 32
logoContainerSize = 72    logoContainerRadius = 20
spinnerSize = 22    spinnerStroke = 2.5

// Borders
borderThin = 1.5    dividerIOS = 0.5    dividerAndroid = 1

// Page
pagePaddingH = 24    pagePaddingV = 16

// Auth layout fractions
authGradientFraction = 0.50    authBrandingFraction = 0.30

// Breakpoints
breakpointMedium = 600    breakpointExpanded = 840    contentMaxWidth = 560

// Animation durations (ms) — use with flutter_animate's .ms or Duration(ms: ...)
animInstant = 150    animFast = 200    animNormal = 350
animSlow = 450       animBranding = 500

// Animation delays (ms)
delay1 = 50    delay2 = 100    delay3 = 150    delay4 = 200
delay5 = 250   delay6 = 300    delay7 = 350    delay8 = 400
```

---

## 8. Navigation

```dart
// Push (keeps back stack)
context.pushRoute(const RegisterRoute());

// Replace (no back button)
context.router.replaceAll([const HomeRoute()]);

// Pop
context.maybePop();

// Tab navigation (inside AutoTabsScaffold)
context.tabsRouter.setActiveIndex(1);
```

- Every page needs `@RoutePage()` annotation
- After adding a page: run `dart run build_runner build --delete-conflicting-outputs`
- Add the route to `app_router.dart` routes list
- Guard protected routes with `AuthGuard` in the router

---

## 9. BLoC Pattern

Every feature BLoC follows this structure:

```
lib/features/<feature>/presentation/bloc/
├── <feature>_bloc.dart    ← also exports event + state via `export`
├── <feature>_event.dart   ← sealed class hierarchy
└── <feature>_state.dart   ← sealed class hierarchy, extends Equatable
```

**Event pattern:**
```dart
sealed class XxxEvent { const XxxEvent(); }
final class XxxLoadRequested extends XxxEvent { const XxxLoadRequested(); }
```

**State pattern:**
```dart
sealed class XxxState extends Equatable {
  const XxxState();
  @override List<Object?> get props => [];
}
final class XxxInitial extends XxxState { const XxxInitial(); }
final class XxxLoading extends XxxState { const XxxLoading(); }
final class XxxLoaded extends XxxState {
  const XxxLoaded({required this.data});
  final MyEntity data;
  @override List<Object?> get props => [data];
}
final class XxxFailure extends XxxState {
  const XxxFailure({required this.exception});
  final AppException exception;
  String get message => exception.userMessage;
}
```

**BLoC handler:**
```dart
on<XxxLoadRequested>(_onLoad, transformer: droppable());

Future<void> _onLoad(XxxLoadRequested event, Emitter<XxxState> emit) async {
  emit(const XxxLoading());
  final result = await _useCase(id: event.id);
  result.fold(
    (exception) => emit(XxxFailure(exception: exception)),
    (data) => emit(XxxLoaded(data: data)),
  );
}
```

**UI consumption:**
```dart
BlocConsumer<XxxBloc, XxxState>(
  listener: (context, state) {
    if (state is XxxFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) => switch (state) {
    XxxInitial() => const SizedBox.shrink(),
    XxxLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    XxxLoaded(:final data) => _XxxContent(data: data),
    XxxFailure(:final exception) => _ErrorView(exception: exception),
  },
)
```

---

## 10. Adding a New API Endpoint

1. Add path constant to `lib/core/constants/api_constants.dart`
2. Add method to domain `XxxRepository` interface
3. Add method to `DioXxxDataSource` (interface + `DioXxx` impl in `data/datasources/`)
4. Implement in `RemoteXxxRepository` — use `httpClient.request<T>()` / `requestList<T>()` / `requestEmpty()`
5. Create `XxxUseCase` in `domain/usecases/`
6. Export from `usecases/usecases.dart` barrel
7. Register use case + repo in `injection_container.dart`
8. Add to BLoC constructor + handler

**Repository implementation pattern:**
```dart
@override
Future<Either<AppException, MyEntity>> getItem({required final String id}) =>
    _httpClient
        .request<MyModel>(
          '$myItemPath/$id',
          method: RequestMethod.get,
          fromJson: MyModel.fromJson,
          keyPath: 'data',          // if response is {"data": {...}}
        )
        .then((r) => r.map((m) => m.toDomain()));
```

**Model (DTO) pattern:**
```dart
final class MyModel {
  const MyModel({required this.id, required this.name});

  factory MyModel.fromJson(final Map<String, dynamic> json) => MyModel(
    id: JsonParser.parseString(json, 'id'),
    name: JsonParser.parseString(json, 'name'),
  );

  final String id;
  final String name;

  MyEntity toDomain() => MyEntity(id: id, name: name);
}
```

---

## 11. Adding a New Feature (Full Checklist)

```
lib/features/<feature>/
├── <feature>.dart                     ← BARREL (exports domain + presentation only)
├── data/
│   ├── data.dart                      ← internal barrel
│   ├── datasources/<feature>_remote_datasource.dart
│   ├── models/<name>_model.dart
│   └── repositories/remote_<feature>_repository.dart
├── domain/
│   ├── domain.dart                    ← BARREL
│   ├── entities/<name>.dart
│   ├── repositories/<feature>_repository.dart
│   └── usecases/
│       ├── usecases.dart              ← BARREL
│       └── <verb>_<noun>_usecase.dart
└── presentation/
    ├── presentation.dart              ← BARREL
    ├── bloc/
    │   ├── <feature>_bloc.dart        ← exports event + state
    │   ├── <feature>_event.dart
    │   └── <feature>_state.dart
    ├── pages/
    │   ├── pages.dart                 ← BARREL (if ≥ 3 pages)
    │   └── <feature>_page.dart        ← @RoutePage()
    └── widgets/
        ├── widgets.dart               ← BARREL (if ≥ 3 widgets)
        └── <name>_widget.dart
```

**Checklist:**
- [ ] Create folder structure above
- [ ] Define entity (pure Dart, `extends Equatable`)
- [ ] Define repository interface (abstract, returns `Either<AppException, T>`)
- [ ] Create model DTO with `fromJson` using `JsonParser` + `toDomain()`
- [ ] Implement `DioXxxDataSource` + `RemoteXxxRepository`
- [ ] Create use case(s) and barrel
- [ ] Create BLoC (event/state/bloc), use `bloc_concurrency droppable()` on handlers
- [ ] Create page with `@RoutePage()` + `AdaptiveLayout`
- [ ] Add route to `app_router.dart` and run `build_runner`
- [ ] Register datasource, repository, use case(s), BLoC in `injection_container.dart`
- [ ] Create barrels + update parent barrels
- [ ] Run `dart format . && flutter analyze` — zero issues required

---

## 12. Auth Screen UI Pattern

All auth screens follow this structure. Read `login_page.dart` as canonical reference.

```
XxxPage (StatelessWidget)
└── BlocProvider(create: (_) => sl<XxxBloc>())
    └── _XxxView (StatelessWidget)
        └── BlocListener (handles navigation + snackbars)
            └── KeyboardDismisser(gestures: [onTap, onPanUpdateDown, onPanUpdateUp])
                └── Scaffold(resizeToAvoidBottomInset: true, backgroundColor: surface)
                    └── AdaptiveLayout(
                          compact: _CompactXxxLayout(),
                          expanded: _ExpandedXxxLayout(),
                        )
```

**Compact layout** → `AuthCompactLayout(formCard: AuthFormCard(title: '...', child: _XxxForm()))`  
**Expanded layout** → `AuthExpandedLayout(title: '...', subtitle: '...', formContent: _XxxForm())`

**AppBar rules (transparent, floating over gradient):**
```dart
appBar: AppBar(
  backgroundColor: Colors.transparent,
  foregroundColor: context.colorScheme.onPrimary, // white arrow on gradient
  elevation: 0,
  scrolledUnderElevation: 0,
  forceMaterialTransparency: true,
  shape: const Border(), // removes iOS hairline on transparent AppBar
),
```

**Never:**
- Place a `Positioned` back button manually inside the Stack
- Skip `AdaptiveLayout` — even simple forms need compact + expanded variants
- Use `Positioned.fill` for gradient (bleeds into system bar area)

---

## 13. Shared Widgets in `lib/features/auth/presentation/widgets/`

| Widget | Purpose |
|--------|---------|
| `AuthBrandingSection` | App icon + name + tagline with entrance animations |
| `AuthFormCard` | Animated bottom-sheet card (compact layout); takes `title` + `child` |
| `AuthCompactLayout` | Full compact stack (gradient + branding + formCard) |
| `AuthExpandedLayout` | Two-panel tablet row (gradient left, form right); takes `title`, `subtitle`, `formContent` |
| `AuthForm` | Login credential form (email + password + social buttons) |
| `showForgotPasswordSheet` | Two-step OTP reset bottom sheet |

---

## 14. Theming Rules

```dart
// ✅ Use theme references
context.colorScheme.primary
context.colorScheme.surface
context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)

// ❌ Never inline colors or styles
Color(0xFF1234AB)
TextStyle(fontSize: 16, color: Colors.blue)
```

**ThemeBloc** manages palette + mode + font scale. To switch:
```dart
context.read<ThemeBloc>().add(ThemePaletteChanged(palette));
context.read<ThemeBloc>().add(ThemeModeChanged(ThemeMode.dark));
context.read<ThemeBloc>().add(FontScaleChanged(AppTextStyles.scaleL));
```

---

## 15. Responsive Layout

```dart
// Extensions (from core.dart)
context.isCompact      // < 600dp
context.isMedium       // 600–840dp
context.isExpanded     // ≥ 840dp
context.isLargeScreen  // ≥ 600dp
context.hingeFeature   // DisplayFeature? for foldables

// Widget
AdaptiveLayout(
  compact: const _PhoneLayout(),
  medium: const _TabletLayout(),   // optional, falls back to compact
  expanded: const _DesktopLayout(), // optional, falls back to medium then compact
)
```

Forms on expanded: always wrap in `ConstrainedBox(maxWidth: AppDimensions.contentMaxWidth)`.

---

## 16. Security & Token Flow

- Tokens stored in `flutter_secure_storage` via `SecureTokenProvider`
- `TokenProvider` exposes `accessToken`, `refreshToken`, `email`, `displayName` (sync)
- After any successful auth, call `tokenProvider.saveTokens()` + `saveUserInfo()` in repository
- `AuthInterceptor` attaches Bearer token + handles 401 with auto-refresh
- On logout: `tokenProvider.clearTokens()` then navigate to login

**SSO (Google/Apple) via `flutter_appauth`:**  
Configure `--dart-define=GOOGLE_CLIENT_ID=...`, `APPLE_SERVICE_ID=...`, `OAUTH_REDIRECT_URL=...`

---

## 17. Common Commands

```bash
dart format .
flutter analyze                                          # must be zero issues
dart run build_runner build --delete-conflicting-outputs # after adding @RoutePage
flutter test
flutter pub get
```

---

## 18. Pre-task Checklist

Before writing a single line of code:

1. Read this file fully
2. Read memory (check recent context)
3. Read the subsystem doc(s) from the table below **only if** touching that area
4. Plan: list every file to create/modify in dependency order
5. Flag any doc contradictions or architecture boundary violations before coding

| Touching | Read doc |
|----------|----------|
| Network / interceptors / HttpClient | `docs/06_NETWORKING_LAYER.md` |
| Auth / tokens / OAuth | `docs/20_SECURITY.md` |
| Navigation / guards / deep links | `docs/09_NAVIGATION_DEEP_LINKING.md` |
| Theme / palettes / AppTheme | `docs/05_THEMING_SYSTEM.md` |
| Responsive / adaptive / foldables | `docs/25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md` |
| Animations / transitions | `docs/16_ANIMATIONS_TRANSITIONS.md` |
| Shared widgets | `docs/15_REUSABLE_COMPONENTS.md` |
| Local database (Drift) | `docs/10_LOCAL_STORAGE.md` |
| State management (BLoC patterns) | `docs/08_STATE_MANAGEMENT.md` |
| Error handling / AppException | `docs/14_ERROR_HANDLING.md` |
| Logging / AppLogger | `docs/13_LOGGING_SYSTEM.md` |
| Accessibility / semantics | `docs/22_ACCESSIBILITY.md` |
| Adding a dependency | `docs/03_DEPENDENCY_MANIFEST.md` — update it too |
| CI / release | `docs/18_CI_CD_PIPELINE.md`, `docs/24_PERFORMANCE_AND_RELEASE_GATES.md` |

---

## 19. Post-task Checklist

- [ ] `dart format .` — no changes needed
- [ ] `flutter analyze` — **No issues found**
- [ ] New `@RoutePage()` → ran `build_runner`
- [ ] New dependency → updated `docs/03_DEPENDENCY_MANIFEST.md`
- [ ] New barrel added for any folder gaining its 3rd file
- [ ] No magic numbers, no inline styles, no relative imports
- [ ] `final` on all parameters, locals, and fields
