# 02 - Project Structure

## Complete Directory Tree

```
lib/
├── main.dart                              # Entry point (minimal - calls bootstrap)
├── app.dart                               # MaterialApp.router with theme & connectivity
├── bootstrap.dart                         # DI initialization, environment setup
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart             # Base URLs, endpoints, timeouts
│   │   ├── app_constants.dart             # App-wide magic numbers, durations
│   │   ├── storage_keys.dart              # Keys for secure storage & prefs
│   │   └── asset_paths.dart               # Asset path constants
│   │
│   ├── di/
│   │   ├── injection_container.dart       # GetIt setup - registers all dependencies
│   │   ├── network_module.dart            # Dio, interceptors, ApiClient registration
│   │   ├── storage_module.dart            # Drift DB, secure storage registration
│   │   ├── analytics_module.dart          # Analytics service registration
│   │   └── feature_module.dart            # Feature-level repos, usecases, blocs
│   │
│   ├── error/
│   │   ├── app_exception.dart             # Base exception + typed subclasses
│   │   ├── failure.dart                   # Failure sealed class for Either returns
│   │   └── error_mapper.dart              # Maps exceptions to user-facing messages
│   │
│   ├── extensions/
│   │   ├── build_context_extensions.dart  # context.theme, context.colorScheme, etc.
│   │   ├── string_extensions.dart         # capitalize, toBookId, truncate
│   │   ├── datetime_extensions.dart       # toReadableDate, timeAgo
│   │   ├── num_extensions.dart            # toDuration, toFileSize
│   │   └── iterable_extensions.dart       # separatedBy, groupBy
│   │
│   ├── json/
│   │   ├── json_parser.dart              # JsonParser mixin (provided by user)
│   │   └── codable.dart                  # JsonCodable interface
│   │
│   ├── logging/
│   │   ├── app_logger.dart               # Abstract logger interface
│   │   ├── pretty_logger.dart            # Console logger with formatting
│   │   └── log_level.dart                # Enum: verbose, debug, info, warn, error
│   │
│   ├── network/
│   │   ├── api_client.dart               # Abstract HTTP client interface
│   │   ├── dio_client.dart               # Dio implementation of ApiClient
│   │   ├── api_response.dart             # Generic wrapper for API responses
│   │   ├── api_endpoints.dart            # Endpoint path builder
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart     # Attaches token, handles 401
│   │   │   ├── retry_interceptor.dart    # Exponential backoff retry
│   │   │   ├── cache_interceptor.dart    # ETag / last-modified caching
│   │   │   └── logging_interceptor.dart  # Request/response logging
│   │   └── strategies/
│   │       ├── retry_strategy.dart       # Retry policy interface
│   │       └── cache_strategy.dart       # Cache policy interface
│   │
│   ├── analytics/
│   │   ├── analytics_service.dart        # Abstract: EventTracker, CrashReporter, UserIdentifier
│   │   ├── analytics_event.dart          # Typed event definitions
│   │   ├── composite_analytics.dart      # Fans out to multiple providers
│   │   └── adapters/
│   │       ├── sentry_adapter.dart       # Sentry implementation
│   │       ├── mixpanel_adapter.dart     # Mixpanel implementation
│   │       ├── firebase_adapter.dart     # Firebase Analytics implementation
│   │       └── noop_adapter.dart         # No-op for testing/debug
│   │
│   ├── connectivity/
│   │   ├── connectivity_service.dart     # Abstract connectivity interface
│   │   ├── connectivity_adapter.dart     # connectivity_plus implementation
│   │   └── connectivity_bloc/
│   │       ├── connectivity_bloc.dart    # Global connectivity BLoC
│   │       ├── connectivity_event.dart
│   │       └── connectivity_state.dart
│   │
│   ├── security/
│   │   ├── secure_store.dart             # Abstract secure storage interface
│   │   ├── secure_storage_adapter.dart   # flutter_secure_storage implementation
│   │   └── token_provider.dart           # Token read/write/refresh interface
│   │
│   ├── storage/
│   │   ├── local_database.dart           # Abstract local DB interface
│   │   ├── drift/
│   │   │   ├── app_database.dart         # Drift database definition
│   │   │   ├── app_database.g.dart       # Generated Drift code
│   │   │   ├── tables/
│   │   │   │   ├── books_table.dart      # Books table definition
│   │   │   │   ├── chapters_table.dart   # Chapters table definition
│   │   │   │   ├── bookmarks_table.dart  # Bookmarks table definition
│   │   │   │   └── reading_progress_table.dart
│   │   │   └── daos/
│   │   │       ├── book_dao.dart         # Book data access object
│   │   │       └── reading_dao.dart      # Reading progress DAO
│   │   └── cache/
│   │       └── cache_manager.dart        # TTL-based cache logic
│   │
│   └── theme/
│       ├── app_theme.dart                # ThemeData factory from AppColorPalette
│       ├── app_color_palette.dart        # Color palette value object
│       ├── app_colors.dart               # All color palettes (blue, violet, red, orange, pink)
│       ├── app_text_styles.dart          # Centralized typography definitions
│       ├── app_dimensions.dart           # Spacing, radius, elevation constants
│       ├── theme_bloc/
│       │   ├── theme_bloc.dart           # Manages theme mode + palette + font scale
│       │   ├── theme_event.dart
│       │   └── theme_state.dart
│       └── theme_extensions.dart         # BuildContext extensions for theme access
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── auth_token_model.dart       # Implements JsonCodable
│   │   │   │   └── user_model.dart             # Implements JsonCodable
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── auth_token.dart
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart        # Abstract
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── logout_usecase.dart
│   │   │       └── refresh_token_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── splash_page.dart
│   │       └── widgets/
│   │           └── auth_form.dart
│   │
│   ├── library/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── library_remote_datasource.dart
│   │   │   │   └── library_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── book_model.dart
│   │   │   │   └── category_model.dart
│   │   │   └── repositories/
│   │   │       └── library_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── book.dart
│   │   │   │   └── category.dart
│   │   │   ├── repositories/
│   │   │   │   └── library_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_books_usecase.dart
│   │   │       ├── get_book_detail_usecase.dart
│   │   │       └── search_books_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── library_bloc.dart
│   │       │   ├── library_event.dart
│   │       │   └── library_state.dart
│   │       ├── pages/
│   │       │   ├── library_page.dart
│   │       │   └── book_detail_page.dart
│   │       └── widgets/
│   │           ├── book_card.dart
│   │           ├── book_grid.dart
│   │           └── search_bar.dart
│   │
│   ├── reader/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── content_remote_datasource.dart
│   │   │   │   └── content_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── chapter_model.dart
│   │   │   │   ├── reading_progress_model.dart
│   │   │   │   └── bookmark_model.dart
│   │   │   └── repositories/
│   │   │       └── reader_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── chapter.dart
│   │   │   │   ├── reading_progress.dart
│   │   │   │   └── bookmark.dart
│   │   │   ├── repositories/
│   │   │   │   └── reader_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_chapter_content_usecase.dart
│   │   │       ├── save_reading_progress_usecase.dart
│   │   │       ├── toggle_bookmark_usecase.dart
│   │   │       └── sync_progress_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── reader_bloc.dart
│   │       │   ├── reader_event.dart
│   │       │   └── reader_state.dart
│   │       ├── pages/
│   │       │   └── reader_page.dart
│   │       └── widgets/
│   │           ├── reader_content.dart
│   │           ├── reader_controls.dart       # Font size, night mode toggle
│   │           ├── chapter_navigation.dart
│   │           └── bookmark_button.dart
│   │
│   └── settings/
│       ├── data/
│       │   ├── models/
│       │   │   └── user_preferences_model.dart
│       │   └── repositories/
│       │       └── settings_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user_preferences.dart
│       │   ├── repositories/
│       │   │   └── settings_repository.dart
│       │   └── usecases/
│       │       ├── get_preferences_usecase.dart
│       │       ├── update_theme_usecase.dart
│       │       └── update_font_size_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── settings_bloc.dart
│           │   ├── settings_event.dart
│           │   └── settings_state.dart
│           ├── pages/
│           │   └── settings_page.dart
│           └── widgets/
│               ├── theme_picker.dart
│               ├── font_size_slider.dart
│               └── night_mode_toggle.dart
│
├── shared/
│   ├── widgets/
│   │   ├── app_loading_page.dart          # Full-screen loading indicator
│   │   ├── app_error_page.dart            # Full-screen error with retry
│   │   ├── app_scaffold.dart              # Base scaffold with connectivity banner
│   │   ├── connectivity_banner.dart       # "No internet" overlay banner
│   │   ├── app_button.dart                # Themed primary/secondary buttons
│   │   ├── app_text_field.dart            # Themed text input
│   │   ├── app_image.dart                 # Cached network image with placeholder
│   │   ├── shimmer_loading.dart           # Skeleton loading placeholder
│   │   └── adaptive_layout.dart           # Responsive breakpoint wrapper
│   └── mixins/
│       └── safe_state_mixin.dart          # Prevents setState after dispose
│
└── router/
    ├── app_router.dart                    # @AutoRouterConfig annotated router
    ├── app_router.gr.dart                 # Generated route code
    └── guards/
        ├── auth_guard.dart                # Redirects unauthenticated users
        └── connectivity_guard.dart        # Optional: blocks nav when offline
```

---

## Test Directory Structure

```
test/
├── core/
│   ├── json/
│   │   └── json_parser_test.dart
│   ├── network/
│   │   ├── dio_client_test.dart
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
├── fixtures/                              # JSON fixture files for tests
│   ├── book_response.json
│   ├── chapter_response.json
│   └── auth_response.json
│
├── helpers/
│   ├── test_helpers.dart                  # Common test setup utilities
│   ├── pump_app.dart                      # Wraps widget in MaterialApp for testing
│   └── mock_generators.dart               # Shared mock factories
│
└── integration/
    └── reading_flow_test.dart
```

---

## File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
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

These files are auto-generated and should be in `.gitignore` only if using build_runner on CI, otherwise commit them:

| File | Generator | Command |
|------|-----------|---------|
| `*.g.dart` | Drift, JSON | `dart run build_runner build` |
| `*.gr.dart` | auto_route | `dart run build_runner build` |
| `*.freezed.dart` | Freezed (if used for states) | `dart run build_runner build` |
| `*.mocks.dart` | Mockito | `dart run build_runner build` |
