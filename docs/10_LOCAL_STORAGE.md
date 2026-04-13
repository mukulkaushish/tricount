# 10 - Local Storage

> Table names, DAO examples, and cached entities in this document are samples that demonstrate the storage pattern.

## Storage Strategy Overview

| Storage Type | Technology | Purpose |
|-------------|-----------|---------|
| Structured relational data | **Drift** (SQLite) | Books, chapters, bookmarks, reading progress |
| Sensitive secrets | **flutter_secure_storage** | Auth tokens, API keys |
| Simple preferences | **SharedPreferences** | Theme settings, font scale, flags |
| HTTP cache | In-memory + Drift table | API response caching |

---

## Drift Database

### Design: No Abstract Interface

Drift's `AppDatabase` is used directly — no `LocalDatabase` abstract interface wrapping it.

**Why**: Unlike HTTP (where we swap `DioHttpClient` for mocks), Drift already provides:
- `.watch()` reactive streams on any query (built-in)
- DAO pattern for organized data access (built-in)
- In-memory database for tests (`NativeDatabase.memory()`)

An abstract interface would duplicate every DAO method signature for zero benefit. DAOs **are** the interface — mock them in tests with `mocktail`.

### Database Definition

**File**: `lib/core/storage/drift/app_database.dart`

**Database class**: `AppDatabase extends GeneratedDatabase`

**Tables**:

#### BooksTable

| Column | Dart Type | SQL Type | Constraints |
|--------|-----------|----------|-------------|
| `id` | `String` | `TEXT` | Primary key |
| `title` | `String` | `TEXT` | Not null |
| `author` | `String` | `TEXT` | Not null |
| `coverUrl` | `String?` | `TEXT` | Nullable |
| `description` | `String?` | `TEXT` | Nullable |
| `pageCount` | `int` | `INTEGER` | Not null |
| `rating` | `double?` | `REAL` | Nullable |
| `categories` | `String` | `TEXT` | JSON-encoded list |
| `publishedAt` | `DateTime` | `INTEGER` | Epoch millis |
| `isPremium` | `bool` | `INTEGER` | 0/1 |
| `cachedAt` | `DateTime` | `INTEGER` | When stored locally |

#### ChaptersTable

| Column | Dart Type | SQL Type | Constraints |
|--------|-----------|----------|-------------|
| `id` | `String` | `TEXT` | Primary key |
| `bookId` | `String` | `TEXT` | Foreign key → BooksTable |
| `index` | `int` | `INTEGER` | Not null |
| `title` | `String` | `TEXT` | Not null |
| `content` | `String` | `TEXT` | Full chapter text |
| `cachedAt` | `DateTime` | `INTEGER` | When stored locally |

#### BookmarksTable

| Column | Dart Type | SQL Type | Constraints |
|--------|-----------|----------|-------------|
| `id` | `String` | `TEXT` | Primary key (UUID) |
| `bookId` | `String` | `TEXT` | Foreign key → BooksTable |
| `chapterId` | `String` | `TEXT` | Foreign key → ChaptersTable |
| `position` | `int` | `INTEGER` | Character offset in chapter |
| `note` | `String?` | `TEXT` | Optional user note |
| `createdAt` | `DateTime` | `INTEGER` | Epoch millis |

#### ReadingProgressTable

| Column | Dart Type | SQL Type | Constraints |
|--------|-----------|----------|-------------|
| `bookId` | `String` | `TEXT` | Primary key |
| `chapterIndex` | `int` | `INTEGER` | Last read chapter |
| `scrollPosition` | `double` | `REAL` | Scroll offset in chapter |
| `percentage` | `double` | `REAL` | Overall book progress (0.0-1.0) |
| `updatedAt` | `DateTime` | `INTEGER` | Last update timestamp |

#### ApiCacheTable

| Column | Dart Type | SQL Type | Constraints |
|--------|-----------|----------|-------------|
| `url` | `String` | `TEXT` | Primary key (full URL with params) |
| `responseBody` | `String` | `TEXT` | JSON response body |
| `etag` | `String?` | `TEXT` | ETag header value |
| `lastModified` | `String?` | `TEXT` | Last-Modified header |
| `cachedAt` | `DateTime` | `INTEGER` | When cached |
| `ttlSeconds` | `int` | `INTEGER` | Time-to-live |

---

## DAOs (Data Access Objects)

### BookDao

**File**: `lib/core/storage/drift/daos/book_dao.dart`

| Method | Returns | Description |
|--------|---------|-------------|
| `getAllBooks()` | `Future<List<Book>>` | All cached books |
| `getBookById(String id)` | `Future<Book?>` | Single book by ID |
| `insertBook(Book book)` | `Future<void>` | Insert or replace |
| `insertBooks(List<Book> books)` | `Future<void>` | Batch insert |
| `deleteBook(String id)` | `Future<void>` | Remove from cache |
| `deleteStaleBooks(Duration maxAge)` | `Future<int>` | Clean old entries |
| `watchBooks()` | `Stream<List<Book>>` | Reactive stream of books |

### ReadingDao

**File**: `lib/core/storage/drift/daos/reading_dao.dart`

| Method | Returns | Description |
|--------|---------|-------------|
| `getProgress(String bookId)` | `Future<ReadingProgress?>` | Progress for a book |
| `saveProgress(ReadingProgress)` | `Future<void>` | Insert or update |
| `getBookmarks(String bookId)` | `Future<List<Bookmark>>` | All bookmarks for a book |
| `addBookmark(Bookmark)` | `Future<void>` | Add bookmark |
| `removeBookmark(String id)` | `Future<void>` | Delete bookmark |
| `watchProgress(String bookId)` | `Stream<ReadingProgress?>` | Reactive progress |

---

## Secure Storage

**File**: `lib/core/security/secure_store.dart` (interface)
**File**: `lib/core/security/secure_storage_adapter.dart` (implementation)

### SecureStore Interface

| Method | Returns | Purpose |
|--------|---------|---------|
| `read(String key)` | `Future<String?>` | Read encrypted value |
| `write(String key, String value)` | `Future<void>` | Write encrypted value |
| `delete(String key)` | `Future<void>` | Delete a key |
| `deleteAll()` | `Future<void>` | Clear all (logout) |
| `containsKey(String key)` | `Future<bool>` | Check existence |

### Stored Keys

| Key Constant | Value | Content |
|-------------|-------|---------|
| `StorageKeys.accessToken` | `"access_token"` | JWT access token |
| `StorageKeys.refreshToken` | `"refresh_token"` | JWT refresh token |
| `StorageKeys.tokenExpiry` | `"token_expiry"` | ISO 8601 expiry time |

### Platform Security

| Platform | Backing Store | Encryption |
|----------|--------------|------------|
| iOS | Keychain | Hardware-backed (Secure Enclave when available) |
| Android | EncryptedSharedPreferences | AES-256 with Android Keystore master key |

---

## SharedPreferences

Used for non-sensitive, simple key-value data:

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `theme_palette_id` | `String` | `"blue"` | Selected color palette |
| `theme_mode` | `String` | `"system"` | Light/dark/system |
| `font_scale` | `double` | `1.0` | Text size multiplier |
| `onboarding_complete` | `bool` | `false` | First-run flag |
| `last_sync_timestamp` | `String` | `null` | Last server sync time |

---

## Migration Strategy (Drift)

Drift supports schema migrations:

| Version | Changes |
|---------|---------|
| 1 | Initial schema: books, chapters, bookmarks, reading_progress |
| 2+ | Add new tables/columns as features grow |

**Migration rules**:
- Never delete columns in production - mark deprecated
- Add new columns as nullable or with defaults
- Test migrations with `SchemaVerifier` in tests
- Keep migration code in `app_database.dart` `migration` getter

---

## Cache Invalidation

| Data Type | TTL | Invalidation Trigger |
|-----------|-----|---------------------|
| Book list | 5 minutes | Pull-to-refresh, app foreground |
| Book detail | 30 minutes | Manual refresh |
| Chapter content | 24 hours | Never auto-invalidate (large payload) |
| Reading progress | No TTL | Synced on app foreground |
| API responses | Per Cache-Control header | ETag/Last-Modified revalidation |

**Stale data policy**: Show stale data immediately, refresh in background, update UI when fresh data arrives (stale-while-revalidate pattern).
