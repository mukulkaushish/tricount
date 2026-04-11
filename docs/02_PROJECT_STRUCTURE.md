# 02 - Project Structure

## Barrel File Convention

Every folder that contains 2+ public Dart files **must** have a barrel file. Barrel files:

- Are named after the folder (e.g., `core/extensions/extensions.dart`)
- Export all public files in that folder
- Are the **only** file imported by other modules (never import individual files across module boundaries)
- **Do NOT** re-export third-party packages
- **Do NOT** re-export generated files (`*.g.dart`, `*.gr.dart`)

### Why Barrel Files

1. **Single import per module**: `import 'package:reading_app/core/core.dart';` instead of 5 separate imports
2. **Controlled public API**: Only what's exported in the barrel is public
3. **Refactoring safety**: Move/rename internal files without breaking imports across modules
4. **Enforced by lint**: `always_use_package_imports` + barrel convention = clean dependency graph

### Barrel File Rules

| Rule | Detail |
|------|--------|
| One barrel per folder with 2+ public files | Named `<folder_name>.dart` |
| Top-level module barrel aggregates sub-barrels | `core/core.dart` exports `extensions/extensions.dart`, `network/network.dart`, etc. |
| Feature barrels export only the public surface | Domain entities + repository interfaces, NOT implementation details |
| Never import a file that lives behind another barrel directly | Always go through the barrel |
| Barrel files contain ONLY `export` statements | No classes, no functions, no logic |

---

## Complete Directory Tree

> Barrel files marked with `# BARREL` annotation.

```
lib/
├── main.dart                              # Entry point (minimal - calls bootstrap)
├── app.dart                               # MaterialApp.router with theme & connectivity
├── bootstrap.dart                         # DI initialization, environment setup
│
├── core/
│   ├── core.dart                          # BARREL - exports all core sub-modules
│   │
│   ├── constants/
│   │   ├── constants.dart                 # BARREL
│   │   ├── api_constants.dart             # Base URLs, endpoints, timeouts
│   │   ├── app_constants.dart             # App-wide magic numbers, durations
│   │   ├── storage_keys.dart              # Keys for secure storage & prefs
│   │   └── asset_paths.dart               # Asset path constants
│   │
│   ├── di/
│   │   ├── di.dart                        # BARREL
│   │   ├── injection_container.dart       # GetIt setup - registers all dependencies
│   │   ├── network_module.dart            # Dio, interceptors, HttpClient → DioHttpClient
│   │   ├── storage_module.dart            # Drift DB, secure storage registration
│   │   ├── analytics_module.dart          # Analytics service registration
│   │   └── feature_module.dart            # Feature-level repos, usecases, blocs
│   │
│   ├── error/
│   │   ├── error.dart                     # BARREL
│   │   └── app_exception.dart             # Sealed class - single error type for Either returns
│   │
│   ├── extensions/
│   │   ├── extensions.dart                # BARREL
│   │   ├── build_context_extensions.dart  # context.colorScheme, context.textTheme, context.appColors
│   │   ├── string_extensions.dart         # capitalize, toBookId, truncate
│   │   ├── datetime_extensions.dart       # toReadableDate, timeAgo
│   │   ├── num_extensions.dart            # toDuration, toFileSize
│   │   └── iterable_extensions.dart       # separatedBy, groupBy
│   │
│   ├── json/
│   │   ├── json.dart                      # BARREL
│   │   ├── json_parser.dart               # JsonParser mixin
│   │   └── codable.dart                   # JsonCodable interface
│   │
│   ├── logging/
│   │   ├── logging.dart                   # BARREL
│   │   ├── app_logger.dart                # Abstract logger interface
│   │   ├── pretty_logger.dart             # Console logger with formatting
│   │   └── log_level.dart                 # Enum: verbose, debug, info, warn, error
│   │
│   ├── network/
│   │   ├── network.dart                   # BARREL
│   │   ├── http_client.dart               # Abstract interface: request<T>, requestList<T>, requestEmpty
│   │   ├── dio_http_client.dart           # Dio implementation of HttpClient
│   │   ├── request_method.dart            # RequestMethod enum + extension
│   │   └── interceptors/
│   │       ├── interceptors.dart          # BARREL
│   │       ├── auth_interceptor.dart      # QueuedInterceptorsWrapper: token + 401 handling
│   │       ├── retry_interceptor.dart     # Exponential backoff retry
│   │       └── cache_interceptor.dart     # ETag / last-modified caching
│   │       # No logging_interceptor.dart — uses Dio's built-in LogInterceptor
│   │
│   ├── analytics/
│   │   ├── analytics.dart                 # BARREL
│   │   ├── analytics_service.dart         # Abstract: EventTracker, CrashReporter, UserIdentifier
│   │   ├── analytics_event.dart           # Typed event definitions
│   │   ├── composite_analytics.dart       # Fans out to multiple providers
│   │   └── adapters/
│   │       ├── adapters.dart              # BARREL
│   │       ├── sentry_adapter.dart        # Sentry implementation
│   │       ├── mixpanel_adapter.dart      # Mixpanel implementation
│   │       ├── firebase_adapter.dart      # Firebase Analytics implementation
│   │       └── noop_adapter.dart          # No-op for testing/debug
│   │
│   ├── connectivity/
│   │   ├── connectivity.dart              # BARREL
│   │   ├── connectivity_service.dart      # Concrete wrapper around connectivity_plus
│   │   └── connectivity_bloc/
│   │       ├── connectivity_bloc.dart     # Global connectivity BLoC (also barrel - exports event/state)
│   │       ├── connectivity_event.dart
│   │       └── connectivity_state.dart
│   │
│   ├── security/
│   │   ├── security.dart                  # BARREL
│   │   ├── secure_store.dart              # Abstract secure storage interface
│   │   ├── secure_storage_adapter.dart    # flutter_secure_storage implementation
│   │   └── token_provider.dart            # Token read/write/refresh interface
│   │
│   ├── storage/
│   │   ├── storage.dart                   # BARREL
│   │   ├── drift/
│   │   │   ├── drift.dart                 # BARREL
│   │   │   ├── app_database.dart          # Drift database definition
│   │   │   ├── app_database.g.dart        # Generated Drift code
│   │   │   ├── tables/
│   │   │   │   ├── tables.dart            # BARREL
│   │   │   │   ├── books_table.dart
│   │   │   │   ├── chapters_table.dart
│   │   │   │   ├── bookmarks_table.dart
│   │   │   │   └── reading_progress_table.dart
│   │   │   └── daos/
│   │   │       ├── daos.dart              # BARREL
│   │   │       ├── book_dao.dart
│   │   │       └── reading_dao.dart
│   │   └── cache/
│   │       └── cache_manager.dart         # TTL-based cache logic
│   │
│   └── theme/
│       ├── theme.dart                     # BARREL
│       ├── app_theme.dart                 # ThemeData factory from AppColorPalette
│       ├── app_color_palette.dart         # Color palette value object
│       ├── app_colors.dart                # All palettes (blue, violet, red, orange, pink)
│       ├── app_text_styles.dart           # Centralized typography definitions
│       ├── app_dimensions.dart            # Spacing, radius, elevation constants
│       ├── theme_bloc/
│       │   ├── theme_bloc.dart            # Manages theme mode + palette + font scale (also barrel)
│       │   ├── theme_event.dart
│       │   └── theme_state.dart
│       └── theme_extensions.dart          # BuildContext extensions for theme access
│
├── features/
│   ├── auth/
│   │   ├── auth.dart                      # BARREL - exports public surface only
│   │   ├── data/
│   │   │   ├── data.dart                  # BARREL
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── models.dart            # BARREL
│   │   │   │   ├── auth_token_model.dart
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── domain.dart                # BARREL
│   │   │   ├── entities/
│   │   │   │   ├── entities.dart          # BARREL
│   │   │   │   ├── auth_token.dart
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── usecases.dart          # BARREL
│   │   │       ├── login_usecase.dart
│   │   │       ├── logout_usecase.dart
│   │   │       └── refresh_token_usecase.dart
│   │   └── presentation/
│   │       ├── presentation.dart          # BARREL
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart         # Also barrel - exports event/state
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── pages.dart             # BARREL
│   │       │   ├── login_page.dart
│   │       │   └── splash_page.dart
│   │       └── widgets/
│   │           └── auth_form.dart
│   │
│   ├── library/
│   │   ├── library.dart                   # BARREL
│   │   ├── data/
│   │   │   ├── data.dart                  # BARREL
│   │   │   ├── datasources/
│   │   │   │   ├── library_remote_datasource.dart
│   │   │   │   └── library_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── models.dart            # BARREL
│   │   │   │   ├── book_model.dart
│   │   │   │   └── category_model.dart
│   │   │   └── repositories/
│   │   │       └── library_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── domain.dart                # BARREL
│   │   │   ├── entities/
│   │   │   │   ├── entities.dart          # BARREL
│   │   │   │   ├── book.dart
│   │   │   │   └── category.dart
│   │   │   ├── repositories/
│   │   │   │   └── library_repository.dart
│   │   │   └── usecases/
│   │   │       ├── usecases.dart          # BARREL
│   │   │       ├── get_books_usecase.dart
│   │   │       ├── get_book_detail_usecase.dart
│   │   │       └── search_books_usecase.dart
│   │   └── presentation/
│   │       ├── presentation.dart          # BARREL
│   │       ├── bloc/
│   │       │   ├── library_bloc.dart      # Also barrel
│   │       │   ├── library_event.dart
│   │       │   └── library_state.dart
│   │       ├── pages/
│   │       │   ├── pages.dart             # BARREL
│   │       │   ├── library_page.dart
│   │       │   └── book_detail_page.dart
│   │       └── widgets/
│   │           ├── widgets.dart           # BARREL
│   │           ├── book_card.dart
│   │           ├── book_grid.dart
│   │           └── search_bar.dart
│   │
│   ├── reader/
│   │   ├── reader.dart                    # BARREL
│   │   ├── data/
│   │   │   ├── data.dart                  # BARREL
│   │   │   ├── datasources/
│   │   │   │   ├── content_remote_datasource.dart
│   │   │   │   └── content_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── models.dart            # BARREL
│   │   │   │   ├── chapter_model.dart
│   │   │   │   ├── reading_progress_model.dart
│   │   │   │   └── bookmark_model.dart
│   │   │   └── repositories/
│   │   │       └── reader_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── domain.dart                # BARREL
│   │   │   ├── entities/
│   │   │   │   ├── entities.dart          # BARREL
│   │   │   │   ├── chapter.dart
│   │   │   │   ├── reading_progress.dart
│   │   │   │   └── bookmark.dart
│   │   │   ├── repositories/
│   │   │   │   └── reader_repository.dart
│   │   │   └── usecases/
│   │   │       ├── usecases.dart          # BARREL
│   │   │       ├── get_chapter_content_usecase.dart
│   │   │       ├── save_reading_progress_usecase.dart
│   │   │       ├── toggle_bookmark_usecase.dart
│   │   │       └── sync_progress_usecase.dart
│   │   └── presentation/
│   │       ├── presentation.dart          # BARREL
│   │       ├── bloc/
│   │       │   ├── reader_bloc.dart       # Also barrel
│   │       │   ├── reader_event.dart
│   │       │   └── reader_state.dart
│   │       ├── pages/
│   │       │   └── reader_page.dart
│   │       └── widgets/
│   │           ├── widgets.dart           # BARREL
│   │           ├── reader_content.dart
│   │           ├── reader_controls.dart
│   │           ├── chapter_navigation.dart
│   │           └── bookmark_button.dart
│   │
│   └── settings/
│       ├── settings.dart                  # BARREL
│       ├── data/
│       │   ├── data.dart                  # BARREL
│       │   ├── models/
│       │   │   └── user_preferences_model.dart
│       │   └── repositories/
│       │       └── settings_repository_impl.dart
│       ├── domain/
│       │   ├── domain.dart                # BARREL
│       │   ├── entities/
│       │   │   └── user_preferences.dart
│       │   ├── repositories/
│       │   │   └── settings_repository.dart
│       │   └── usecases/
│       │       ├── usecases.dart          # BARREL
│       │       ├── get_preferences_usecase.dart
│       │       ├── update_theme_usecase.dart
│       │       └── update_font_size_usecase.dart
│       └── presentation/
│           ├── presentation.dart          # BARREL
│           ├── bloc/
│           │   ├── settings_bloc.dart     # Also barrel
│           │   ├── settings_event.dart
│           │   └── settings_state.dart
│           ├── pages/
│           │   └── settings_page.dart
│           └── widgets/
│               ├── widgets.dart           # BARREL
│               ├── theme_picker.dart
│               ├── font_size_slider.dart
│               └── night_mode_toggle.dart
│
├── shared/
│   ├── shared.dart                        # BARREL
│   ├── models/
│   │   ├── models.dart                    # BARREL
│   │   └── empty_response.dart            # Const sentinel for void API responses
│   ├── widgets/
│   │   ├── widgets.dart                   # BARREL
│   │   ├── app_loading_page.dart
│   │   ├── app_error_page.dart
│   │   ├── app_scaffold.dart
│   │   ├── connectivity_banner.dart
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_image.dart
│   │   ├── shimmer_loading.dart           # Custom, no package
│   │   └── adaptive_layout.dart
│   └── mixins/
│       ├── mixins.dart                    # BARREL
│       └── safe_state_mixin.dart
│
└── router/
    ├── router.dart                        # BARREL
    ├── app_router.dart                    # @AutoRouterConfig annotated router
    ├── app_router.gr.dart                 # Generated route code (NOT in barrel)
    └── guards/
        ├── guards.dart                    # BARREL
        ├── auth_guard.dart
        └── connectivity_guard.dart
```

---

## Barrel File Examples

### Top-level core barrel: `lib/core/core.dart`

```dart
export 'constants/constants.dart';
export 'error/error.dart';
export 'extensions/extensions.dart';
export 'json/json.dart';
export 'logging/logging.dart';
export 'network/network.dart';
export 'analytics/analytics.dart';
export 'connectivity/connectivity.dart';
export 'security/security.dart';
export 'storage/storage.dart';
export 'theme/theme.dart';
```

### Sub-module barrel: `lib/core/network/network.dart`

```dart
export 'http_client.dart';
export 'dio_http_client.dart';
export 'request_method.dart';
export 'interceptors/interceptors.dart';
```

### Feature barrel: `lib/features/library/library.dart`

```dart
// Only export the public surface - what other modules need
export 'domain/domain.dart';
export 'presentation/presentation.dart';
// data/ is NOT exported - it's an implementation detail
```

### Import usage across the codebase

```dart
// WRONG - importing individual files across modules:
import 'package:reading_app/core/network/http_client.dart';
import 'package:reading_app/core/error/app_exception.dart';
import 'package:reading_app/core/extensions/string_extensions.dart';

// RIGHT - import through barrel:
import 'package:reading_app/core/core.dart';
```

---

## Test Directory Structure

```
test/
├── core/
│   ├── json/
│   │   └── json_parser_test.dart
│   ├── network/
│   │   ├── dio_http_client_test.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor_test.dart
│   │       ├── retry_interceptor_test.dart
│   │       └── cache_interceptor_test.dart
│   ├── theme/
│   │   └── theme_bloc_test.dart
│   └── extensions/
│       └── string_extensions_test.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── login_usecase_test.dart
│   │   └── presentation/
│   │       └── auth_bloc_test.dart
│   ├── library/
│   │   ├── data/
│   │   │   └── library_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── get_books_usecase_test.dart
│   │   └── presentation/
│   │       └── library_bloc_test.dart
│   └── reader/
│       ├── data/
│       │   └── reader_repository_impl_test.dart
│       ├── domain/
│       │   └── get_chapter_content_usecase_test.dart
│       └── presentation/
│           └── reader_bloc_test.dart
│
├── shared/
│   └── widgets/
│       ├── app_loading_page_test.dart
│       ├── app_error_page_test.dart
│       └── connectivity_banner_test.dart
│
├── fixtures/
│   ├── book_response.json
│   ├── chapter_response.json
│   └── auth_response.json
│
├── helpers/
│   ├── test_helpers.dart
│   ├── pump_app.dart
│   └── mock_generators.dart
│
└── integration/
    └── reading_flow_test.dart
```

---

## File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Barrel files | `<folder_name>.dart` | `network.dart`, `widgets.dart` |
| Pages | `*_page.dart` | `reader_page.dart` |
| Widgets | descriptive name | `book_card.dart` |
| BLoC | `*_bloc.dart` | `library_bloc.dart` |
| Events | `*_event.dart` | `library_event.dart` |
| States | `*_state.dart` | `library_state.dart` |
| Models (DTO) | `*_model.dart` | `book_model.dart` |
| Entities | plain name | `book.dart` |
| Repositories (abstract) | `*_repository.dart` | `library_repository.dart` |
| Repositories (impl) | `*_repository_impl.dart` | `library_repository_impl.dart` |
| Use cases | `*_usecase.dart` | `get_books_usecase.dart` |
| Extensions | `*_extensions.dart` | `string_extensions.dart` |
| Interceptors | `*_interceptor.dart` | `auth_interceptor.dart` |
| Tests | `*_test.dart` | `library_bloc_test.dart` |

---

## Generated Files

Auto-generated files - commit them, but **never** export from barrel files:

| File | Generator | Command |
|------|-----------|---------|
| `*.g.dart` | Drift | `dart run build_runner build` |
| `*.gr.dart` | auto_route | `dart run build_runner build` |
