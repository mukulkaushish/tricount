# 10 — Local Storage

> Table names and examples are illustrative.

## Strategy

| Storage type | Tech | Purpose |
|---|---|---|
| Structured relational | **Drift** (SQLite) | books, chapters, bookmarks, reading progress |
| Sensitive secrets | **flutter_secure_storage** | tokens, API keys |
| Simple prefs | **SharedPreferences** | theme, font, flags |
| HTTP cache | in-memory + Drift table | API response caching |

## Drift

### No abstract interface

`AppDatabase` used directly — no `LocalDatabase` wrapper.

**Why:** unlike HTTP, Drift already provides:
- `.watch()` reactive streams on any query
- DAO pattern via `@DriftAccessor`
- In-memory test DB (`NativeDatabase.memory()`)
- `transaction(() async {...})`
- `UpdateCompanion` for partial row updates
- `SchemaVerifier` for migration testing

An abstract interface would duplicate every DAO signature for zero benefit. **DAOs are the interface** — mock with mocktail.

### Annotations
| Annotation | Purpose |
|---|---|
| `@DriftDatabase(tables: [...], daos: [...])` | DB class |
| `@DriftAccessor(tables: [...])` | DAO scoped to tables |

### Built-in patterns

| Feature | API | Use for |
|---|---|---|
| Reactive queries | `dao.watchBooks()` → `Stream<List<Book>>` | auto-updating UI |
| Transactions | `database.transaction(() async {...})` | atomic multi-table writes |
| Partial updates | `UpdateCompanion({field: Value(newVal)})` | update specific columns |
| Batch inserts | `database.batch((b) => b.insertAll(...))` | bulk writes |
| Custom SQL | `customSelect(sql, variables: [...])` | complex queries |
| Migration testing | `SchemaVerifier(database)` | verify in unit tests |

### DB definition (`lib/core/storage/drift/app_database.dart`)

`AppDatabase extends GeneratedDatabase`.

**BooksTable:**
| Column | Type | SQL | Constraints |
|---|---|---|---|
| `id` | `String` | TEXT | PK |
| `title` | `String` | TEXT | not null |
| `author` | `String` | TEXT | not null |
| `coverUrl` | `String?` | TEXT | nullable |
| `description` | `String?` | TEXT | nullable |
| `pageCount` | `int` | INTEGER | not null |
| `rating` | `double?` | REAL | nullable |
| `categories` | `String` | TEXT | JSON-encoded list |
| `publishedAt` | `DateTime` | INTEGER | epoch ms |
| `isPremium` | `bool` | INTEGER | 0/1 |
| `cachedAt` | `DateTime` | INTEGER | stored timestamp |

**ChaptersTable:** `id` (PK TEXT), `bookId` (FK→Books), `index` (INT), `title` (TEXT), `content` (TEXT), `cachedAt` (INT).

**BookmarksTable:** `id` (PK UUID TEXT), `bookId` (FK), `chapterId` (FK), `position` (INT char offset), `note` (TEXT nullable), `createdAt` (INT).

**ReadingProgressTable:** `bookId` (PK), `chapterIndex` (INT), `scrollPosition` (REAL), `percentage` (REAL 0-1), `updatedAt` (INT).

**ApiCacheTable:** `url` (PK full URL+params), `responseBody` (TEXT JSON), `etag` (TEXT nullable), `lastModified` (TEXT nullable), `cachedAt` (INT), `ttlSeconds` (INT).

## DAOs

### `BookDao`
| Method | Returns | Description |
|---|---|---|
| `getAllBooks()` | `Future<List<Book>>` | all cached |
| `getBookById(id)` | `Future<Book?>` | single |
| `insertBook(book)` | `Future<void>` | insert or replace |
| `insertBooks(books)` | `Future<void>` | batch |
| `deleteBook(id)` | `Future<void>` | remove |
| `deleteStaleBooks(maxAge)` | `Future<int>` | clean old entries |
| `watchBooks()` | `Stream<List<Book>>` | reactive |

### `ReadingDao`
| Method | Returns | Description |
|---|---|---|
| `getProgress(bookId)` | `Future<ReadingProgress?>` | progress for book |
| `saveProgress(p)` | `Future<void>` | insert or update |
| `getBookmarks(bookId)` | `Future<List<Bookmark>>` | all for book |
| `addBookmark(b)` | `Future<void>` | add |
| `removeBookmark(id)` | `Future<void>` | delete |
| `watchProgress(bookId)` | `Stream<ReadingProgress?>` | reactive |

## Secure storage

**`lib/core/security/secure_store.dart`** (iface), **`secure_storage_adapter.dart`** (impl).

| Method | Returns | Purpose |
|---|---|---|
| `read(key)` | `Future<String?>` | read encrypted |
| `write(key, value)` | `Future<void>` | write encrypted |
| `delete(key)` | `Future<void>` | remove |
| `deleteAll()` | `Future<void>` | clear all (logout) |
| `containsKey(key)` | `Future<bool>` | check |

Token keys, platform encryption, lifecycle → `20_SECURITY.md#secure-token-management`.

## SharedPreferences

| Key | Type | Default | Purpose |
|---|---|---|---|
| `theme_palette_id` | `String` | `"blue"` | selected palette |
| `theme_mode` | `String` | `"system"` | light/dark/system |
| `font_scale` | `double` | `1.0` | text size multiplier |
| `onboarding_complete` | `bool` | `false` | first-run flag |
| `last_sync_timestamp` | `String` | `null` | last server sync |

## Migrations (Drift)

| Version | Changes |
|---|---|
| 1 | initial: books, chapters, bookmarks, reading_progress |
| 2+ | add new tables/columns |

**Rules:**
- Never delete columns in production — mark deprecated.
- New columns as nullable or with defaults.
- Test with `SchemaVerifier`.
- Migration code in `app_database.dart` `migration` getter.

## Concurrency & transactions

Drift serializes DB ops automatically — concurrent reads/writes safe. Use explicit transactions when multiple writes must be atomic:

```dart
await database.transaction(() async {
  await bookmarkDao.deleteByBookId(bookId);
  await bookmarkDao.insertAll(newBookmarks);
  await progressDao.saveProgress(updatedProgress);
});
```

| Scenario | Pattern |
|---|---|
| Sync queue flush (delete+insert) | `transaction()` |
| Single row insert/update | no transaction needed |
| Batch insert (100+) | `batch((b) => b.insertAll(...))` |
| Read-then-write | `transaction()` to prevent stale reads |

## Cache invalidation

| Data | TTL | Invalidate on |
|---|---|---|
| Book list | 5 min | pull-to-refresh, app foreground |
| Book detail | 30 min | manual refresh |
| Chapter content | 24 h | never auto (large payload) |
| Reading progress | — | synced on app foreground |
| API responses | per `Cache-Control` | ETag/Last-Modified revalidation |

**Stale policy:** show stale immediately, refresh in background, update UI when fresh arrives (stale-while-revalidate).
