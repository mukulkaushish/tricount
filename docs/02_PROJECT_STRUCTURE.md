# 02 — Project Structure

> Feature names below are illustrative. Adapt to your domain.

## Barrel convention

Folder with **≥ 3 public Dart files** needs `<folder>.dart`. Rules:

| Rule | Detail |
|---|---|
| Named after folder | `core/extensions/extensions.dart` |
| Exports only | no classes, no functions, no logic |
| Only barrel crosses module boundaries | never import leaf files from other modules |
| Do NOT re-export third-party packages | |
| Do NOT export generated files | `*.g.dart`, `*.gr.dart` |
| Top-level barrel aggregates sub-barrels | `core/core.dart` exports `extensions/extensions.dart`, etc. |
| Feature barrels export only public surface | domain + presentation — NOT `data/` |
| Within same module | direct imports OK |

**Why:** one import per module; controlled public API; refactor-safe; lint-enforced (`always_use_package_imports`).

## Placement

- `core/` — cross-cutting infra, technical contracts
- `shared/` — reusable presentation-only widgets / UI helpers
- `features/` — feature `data/`/`domain/`/`presentation/`

`shared/` is **not** a catch-all for networking, repos, or domain types.

## Directory tree

```
lib/
├── main.dart                 # minimal; calls bootstrap
├── app.dart                  # MaterialApp.router + theme + connectivity
├── bootstrap.dart            # DI init, env setup
│
├── core/
│   ├── core.dart                               # BARREL
│   ├── constants/ (BARREL)  api_constants.dart, app_constants.dart, storage_keys.dart, asset_paths.dart
│   ├── di/       (BARREL)   injection_container.dart, network_module.dart, storage_module.dart, analytics_module.dart, feature_module.dart
│   ├── error/    (BARREL)   app_exception.dart          # sealed, the single error type for Either
│   ├── extensions/ (BARREL) build_context_extensions.dart, string_extensions.dart, datetime_extensions.dart, num_extensions.dart, iterable_extensions.dart
│   │                        # start only with extensions that remove repeated friction; add more once pain repeats
│   ├── logging/  (BARREL)   app_logger.dart (iface), pretty_app_logger.dart, production_app_logger.dart, log_level.dart
│   ├── network/  (BARREL)   empty_response.dart, http_client.dart (iface), dio_http_client.dart, json_parser.dart, request_method.dart
│   │   └── interceptors/ (BARREL) auth_interceptor.dart, retry_interceptor.dart, cache_interceptor.dart
│   │                              # NO logging_interceptor — use Dio's built-in LogInterceptor
│   ├── analytics/ (BARREL)  analytics_service.dart (iface), analytics_event.dart, composite_analytics.dart
│   │   └── adapters/ (BARREL) sentry_adapter.dart, mixpanel_adapter.dart, firebase_adapter.dart, noop_adapter.dart
│   ├── connectivity/ (BARREL) connectivity_service.dart  (concrete wrapper around connectivity_plus)
│   │   └── connectivity_bloc/ connectivity_bloc.dart (also barrel), _event.dart, _state.dart
│   ├── security/ (BARREL)   secure_store.dart (iface), secure_storage_adapter.dart, token_provider.dart
│   ├── storage/  (BARREL)
│   │   ├── drift/ (BARREL) app_database.dart, app_database.g.dart,
│   │   │   ├── tables/ (BARREL) books_table.dart, chapters_table.dart, bookmarks_table.dart, reading_progress_table.dart
│   │   │   └── daos/   (BARREL) book_dao.dart, reading_dao.dart
│   │   └── cache/ cache_manager.dart  # TTL cache
│   └── theme/ (BARREL) app_theme.dart, app_color_palette.dart, app_colors.dart, app_text_styles.dart, app_dimensions.dart, theme_extensions.dart
│       └── theme_bloc/ theme_bloc.dart (also barrel), _event.dart, _state.dart
│
├── features/
│   ├── auth/    auth.dart (BARREL — exports domain + presentation only)
│   │   ├── data/    (BARREL) datasources/auth_remote_datasource.dart, models/ (BARREL), repositories/auth_repository_impl.dart
│   │   ├── domain/  (BARREL) entities/ (BARREL), repositories/auth_repository.dart, usecases/ (BARREL) login/logout/refresh
│   │   └── presentation/ (BARREL) bloc/auth_bloc.dart (+ _event + _state), pages/ (BARREL), widgets/
│   ├── library/ …same layout… (models: book, category; usecases: get_books, get_book_detail, search_books)
│   ├── reader/  …(models: chapter, reading_progress, bookmark; usecases: get_chapter_content, save_reading_progress, toggle_bookmark, sync_progress)
│   └── settings/ …(cubit instead of bloc — direct methods, no events; usecases: get/update prefs/theme/font)
│
├── shared/ (BARREL)  # reusable presentation-only
│   ├── widgets/ (BARREL) app_loading_page.dart, app_error_page.dart, app_scaffold.dart, connectivity_banner.dart,
│   │                     app_image.dart (cached + shimmer + error), shimmer_loading.dart,
│   │                     adaptive_layout.dart  (optional; add only when breakpoints repeat)
│   └── mixins/ (BARREL) safe_state_mixin.dart
│
└── router/ (BARREL) app_router.dart, app_router.gr.dart (NOT in barrel)
    └── guards/ (BARREL) auth_guard.dart, connectivity_guard.dart
```

## Barrel examples

**`core/core.dart`:**
```dart
export 'constants/constants.dart';
export 'error/error.dart';
export 'extensions/extensions.dart';
export 'logging/logging.dart';
export 'network/network.dart';
export 'analytics/analytics.dart';
export 'connectivity/connectivity.dart';
export 'security/security.dart';
export 'storage/storage.dart';
export 'theme/theme.dart';
```

**`core/network/network.dart`:**
```dart
export 'empty_response.dart';
export 'http_client.dart';
export 'dio_http_client.dart';
export 'request_method.dart';
export 'interceptors/interceptors.dart';
```

**`features/library/library.dart`:**
```dart
export 'domain/domain.dart';
export 'presentation/presentation.dart';
// data/ NOT exported — implementation detail
```

**Usage:**
```dart
// ❌  import 'package:<app>/core/network/http_client.dart';
// ✅  import 'package:<app>/core/core.dart';
```

## Test layout

```
test/
├── core/
│   ├── json/json_parser_test.dart
│   ├── network/dio_http_client_test.dart + interceptors/*_test.dart
│   ├── theme/theme_bloc_test.dart
│   └── extensions/string_extensions_test.dart
├── features/<feature>/{data,domain,presentation}/*_test.dart
├── shared/widgets/*_test.dart
├── fixtures/      # JSON responses
├── helpers/       # test_helpers.dart, pump_app.dart, mock_generators.dart
└── integration/   # end-to-end flows
```

## File naming

| Type | Pattern | Example |
|---|---|---|
| Barrel | `<folder>.dart` | `network.dart` |
| Page | `*_page.dart` | `reader_page.dart` |
| BLoC / Event / State | `*_bloc.dart` / `*_event.dart` / `*_state.dart` | `library_bloc.dart` |
| Model (DTO) | `*_model.dart` | `book_model.dart` |
| Entity | plain name | `book.dart` |
| Repo (abstract) | `*_repository.dart` | `library_repository.dart` |
| Repo (impl) | `*_repository_impl.dart` | `library_repository_impl.dart` |
| Use case | `*_usecase.dart` | `get_books_usecase.dart` |
| Extension | `*_extensions.dart` | `string_extensions.dart` |
| Interceptor | `*_interceptor.dart` | `auth_interceptor.dart` |
| Test | `*_test.dart` | `library_bloc_test.dart` |

## Generated files
Commit them; never export from barrels.

| File | Generator | Command |
|---|---|---|
| `*.g.dart` | Drift | `dart run build_runner build` |
| `*.gr.dart` | auto_route | `dart run build_runner build` |
