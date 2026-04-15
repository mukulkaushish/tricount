# 19 — Example Feature Specification

> Illustrative example. Use the template to document your real features. Content below is demo.

## Feature spec template

When creating a new feature, document it with:

### 1. API contract
- Endpoints with method, path, purpose, response shape.
- Pagination / filtering / sorting parameters.
- Required headers.

### 2. Data layer
- **Models**: JSON keys, types, required/optional, `JsonParser` method.
- **Repository**: methods with `Future<Either<AppException, T>>` signatures.
- **Data sources**: Remote (API) + local (Drift DAO) + cache strategy.

### 3. Domain layer
- **Entities**: pure Dart, immutable.
- **Use Cases**: one per business op, repo via constructor.
- **Repository interface**: abstract in `domain/repositories/`.

### 4. Presentation layer
- **BLoC/Cubit**: events table, state, transformer choices.
- **Page**: widget tree sketch, which `BlocBuilder`/`BlocSelector` wraps what.
- **WrappedRoute**: what providers the page injects via `wrappedRoute()`.

### 5. User flows
- Primary action step-by-step.
- Offline behavior + retry strategy.
- Deep link entry points (if applicable).

---

# Example: Content Reader Feature

> Target-architecture example — `auto_route` not yet adopted; treat snippets as planned.

## API integration

### Endpoints
| Endpoint | Method | Purpose | Response |
|---|---|---|---|
| `/v1/books` | GET | list books (paginated) | `{data: Book[], meta: Pagination}` |
| `/v1/books/:id` | GET | book detail | `{data: Book}` |
| `/v1/books/:id/chapters` | GET | chapter list | `{data: Chapter[]}` |
| `/v1/books/:id/chapters/:index` | GET | chapter content | `{data: ChapterContent}` |
| `/v1/user/progress` | GET | all reading progress | `{data: ReadingProgress[]}` |
| `/v1/user/progress/:bookId` | PUT | update progress | `{data: ReadingProgress}` |
| `/v1/user/bookmarks` | GET | all bookmarks | `{data: Bookmark[]}` |
| `/v1/user/bookmarks` | POST | create bookmark | `{data: Bookmark}` |
| `/v1/user/bookmarks/:id` | DELETE | delete bookmark | 204 No Content |

### Pagination
| Field | Type | Description |
|---|---|---|
| `page` | `int` | current (1-indexed) |
| `per_page` | `int` | items/page (default 20) |
| `total` | `int` | total items |
| `total_pages` | `int` | total pages |
| `has_more` | `bool` | more pages available |

### Headers
| Header | Value | Purpose |
|---|---|---|
| `Authorization` | `Bearer <token>` | auth (AuthInterceptor) |
| `Accept` | `application/json` | response format |
| `X-App-Version` | `1.0.0` | version tracking |
| `If-None-Match` | `<etag>` | cache validation (CacheInterceptor) |

## Reader page

### Route setup (WrappedRoute)
```dart
@RoutePage()
class ReaderPage extends StatelessWidget implements AutoRouteWrapper {
  final String bookId;
  final int chapterIndex;

  const ReaderPage({
    super.key,
    @PathParam('bookId') required this.bookId,
    @PathParam('chapterIndex') required this.chapterIndex,
  });

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider(
    create: (_) => sl<ReaderBloc>()
      ..add(ReaderChapterRequested(bookId: bookId, chapterIndex: chapterIndex)),
    child: this,
  );
}
```

### ReaderBloc

**Events:**
| Event | Payload | Trigger |
|---|---|---|
| `ReaderChapterRequested` | `bookId, chapterIndex` | page opened / chapter nav |
| `ReaderNextChapter` | — | "Next" button or swipe |
| `ReaderPreviousChapter` | — | "Previous" button or swipe |
| `ReaderBookmarkToggled` | — | bookmark tap |
| `ReaderProgressUpdated` | `scrollPosition` | scroll listener (debounced 2s) |
| `ReaderFontScaleChanged` | `double scale` | font slider |
| `ReaderThemeModeToggled` | — | night mode toggle |

**State fields:** `status` (`initial`/`loading`/`loaded`/`error`), `book: Book?`, `chapter: Chapter?`, `chapterIndex: int`, `totalChapters: int`, `isBookmarked: bool`, `progress: ReadingProgress?`, `exception: AppException?`.

## UI layout

```
Scaffold
├── AppBar (transparent, appears on tap)
│   ├── Back | Chapter title | Bookmark button
│
├── Body: GestureDetector (tap to toggle controls)
│   └── CustomScrollView → SliverPadding
│       └── SelectableText (chapter content, justified, scaled style)
│
└── BottomSheet (reader controls, appears on tap)
    ├── Chapter nav (prev/next + "Chapter 3 of 12")
    ├── Font size slider (0.8x – 1.4x)
    ├── Night mode toggle
    └── Progress bar (linear)
```

### Controls bar
| Control | Widget | Action |
|---|---|---|
| Prev | `IconButton(Icons.chevron_left)` | `ReaderPreviousChapter` |
| Chapter indicator | `Text("Chapter 3 of 12")` | info |
| Next | `IconButton(Icons.chevron_right)` | `ReaderNextChapter` |
| Font size | `Slider` | `ReaderFontScaleChanged` |
| Night mode | `Switch` | `ReaderThemeModeToggled` |
| Progress | `LinearProgressIndicator` | `progress.percentage` |

### Auto-hide
- Controls hidden by default during reading.
- Tap anywhere → toggle visibility.
- Auto-hide after 5 s of inactivity.
- Scroll → hide immediately.

## Progress tracking

| Trigger | Debounce | Destination |
|---|---|---|
| Scroll position changes | 2 s | local (Drift) immediately |
| Chapter changes | immediate | local + remote |
| App backgrounded | immediate | local + remote |
| Reader disposed | immediate | local + remote |

**Progress fields:** `bookId` (route), `chapterIndex` (state), `scrollPosition` (ScrollController), `percentage` (= `(chaptersRead + scrollFraction) / totalChapters`), `updatedAt` (`DateTime.now()`).

### Resume reading

When opening a book with progress:
1. Load progress from local DB (fast).
2. Navigate to `ReaderRoute(bookId, chapterIndex: progress.chapterIndex)`.
3. After content loads, scroll to `progress.scrollPosition`.
4. Fetch remote progress in background; use latest between local and remote.

## Bookmarking

**Fields:** `id` (UUID client-side), `bookId`, `chapterId`, `position` (char offset), `note` (optional, future), `createdAt`.

**Toggle logic:**
1. Tap bookmark button.
2. Check if bookmark exists at current position (chapterId).
3. Exists → delete (local + queue remote delete).
4. Not exists → create (local + queue remote create).
5. Update `isBookmarked` in ReaderState.

## Text features

**Font scaling** — slider 0.8×–1.4× in 0.05 increments; applied to reader text only (not controls UI); fires `ReaderFontScaleChanged` which delegates to `ThemeBloc`; persisted via SharedPreferences.

**Night mode** — toggle fires `ReaderThemeModeToggled` → toggles `ThemeBloc`; reader uses palette's `readerBackground`/`readerText` (darker than standard dark, optimized for sustained reading).

**Text selection** — `SelectableText` (or `.rich`); long-press to select; copy in toolbar; future: highlight + annotate.

## Offline reading

### Pre-caching
On book detail view:
1. Cache book metadata in Drift.
2. Pre-fetch + cache first 3 chapters.
3. Background-fetch remaining on Wi-Fi.

### Offline reader
1. Reader always checks local cache first.
2. Cached → display immediately.
3. Not cached + offline → "chapter not available offline" error.
4. Not cached + online → fetch, display, cache.

### Storage estimate
| Content | Avg size | Cached |
|---|---|---|
| Book metadata | ~2 KB | always |
| Chapter content | ~50 KB | eager first 3, lazy rest |
| Book cover | ~200 KB | via `cached_network_image` |
| Full book (~20 chapters) | ~1 MB | when user reads through |
