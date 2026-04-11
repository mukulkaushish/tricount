# 19 - Reading Feature Specification

## Overview

The reader is the core feature of the application. It displays long-form text content with user controls for font size, night mode, bookmarking, and progress tracking.

---

## Content API Integration

### Endpoints

| Endpoint | Method | Purpose | Response |
|----------|--------|---------|----------|
| `/v1/books` | GET | List books (paginated) | `{ data: Book[], meta: Pagination }` |
| `/v1/books/:id` | GET | Book detail | `{ data: Book }` |
| `/v1/books/:id/chapters` | GET | Chapter list | `{ data: Chapter[] }` |
| `/v1/books/:id/chapters/:index` | GET | Chapter content | `{ data: ChapterContent }` |
| `/v1/user/progress` | GET | All reading progress | `{ data: ReadingProgress[] }` |
| `/v1/user/progress/:bookId` | PUT | Update progress | `{ data: ReadingProgress }` |
| `/v1/user/bookmarks` | GET | All bookmarks | `{ data: Bookmark[] }` |
| `/v1/user/bookmarks` | POST | Create bookmark | `{ data: Bookmark }` |
| `/v1/user/bookmarks/:id` | DELETE | Delete bookmark | `204 No Content` |

### Pagination

| Field | Type | Description |
|-------|------|-------------|
| `page` | `int` | Current page (1-indexed) |
| `per_page` | `int` | Items per page (default 20) |
| `total` | `int` | Total items |
| `total_pages` | `int` | Total pages |
| `has_more` | `bool` | More pages available |

### Request Headers

| Header | Value | Purpose |
|--------|-------|---------|
| `Authorization` | `Bearer <token>` | Auth (via AuthInterceptor) |
| `Accept` | `application/json` | Response format |
| `X-App-Version` | `1.0.0` | Version tracking |
| `If-None-Match` | `<etag>` | Cache validation (via CacheInterceptor) |

---

## Reader Page Specification

### ReaderBloc

**Events**:

| Event | Payload | Trigger |
|-------|---------|---------|
| `ReaderChapterRequested` | `bookId, chapterIndex` | Page opened, chapter navigation |
| `ReaderNextChapter` | none | "Next" button or swipe |
| `ReaderPreviousChapter` | none | "Previous" button or swipe |
| `ReaderBookmarkToggled` | none | Bookmark button tap |
| `ReaderProgressUpdated` | `scrollPosition` | Scroll listener (debounced 2s) |
| `ReaderFontScaleChanged` | `double scale` | Font size slider |
| `ReaderThemeModeToggled` | none | Night mode toggle |

**State**:

| Field | Type | Description |
|-------|------|-------------|
| `status` | `ReaderStatus` | initial, loading, loaded, error |
| `book` | `Book?` | Current book metadata |
| `chapter` | `Chapter?` | Current chapter content |
| `chapterIndex` | `int` | Current chapter index |
| `totalChapters` | `int` | Total chapter count |
| `isBookmarked` | `bool` | Current position bookmarked |
| `progress` | `ReadingProgress?` | Saved reading position |
| `exception` | `AppException?` | Error details |

---

## Reader UI Layout

```
Scaffold
├── AppBar (transparent, appears on tap)
│   ├── Back button
│   ├── Chapter title
│   └── Bookmark button (filled/outlined)
│
├── Body: GestureDetector (tap to toggle controls)
│   └── CustomScrollView
│       └── SliverPadding
│           └── SelectableText (chapter content)
│               ├── style: reader text style (scaled)
│               └── textAlign: justified
│
└── BottomSheet (reader controls, appears on tap)
    ├── Chapter navigation (prev/next buttons + "Chapter 3 of 12")
    ├── Font size slider (0.8x - 1.4x)
    ├── Night mode toggle
    └── Progress bar (linear, shows % of book)
```

### Reading Controls Bar

| Control | Widget | Action |
|---------|--------|--------|
| Previous chapter | `IconButton(Icons.chevron_left)` | `ReaderPreviousChapter` event |
| Chapter indicator | `Text("Chapter 3 of 12")` | Informational |
| Next chapter | `IconButton(Icons.chevron_right)` | `ReaderNextChapter` event |
| Font size | `Slider` | `ReaderFontScaleChanged` event |
| Night mode | `Switch` | `ReaderThemeModeToggled` event |
| Progress | `LinearProgressIndicator` | Shows `progress.percentage` |

### Auto-Hide Behavior

- Controls overlay (AppBar + BottomSheet) hidden by default during reading
- Tap anywhere on content → toggle controls visibility
- Controls auto-hide after 5 seconds of no interaction
- Scroll → hide controls immediately

---

## Reading Progress Tracking

### When Progress is Saved

| Trigger | Debounce | Destination |
|---------|----------|-------------|
| Scroll position changes | 2 seconds | Local (Drift) immediately |
| Chapter changes | Immediate | Local + Remote |
| App goes to background | Immediate | Local + Remote |
| Reader page disposed | Immediate | Local + Remote |

### Progress Data

| Field | Source | Description |
|-------|--------|-------------|
| `bookId` | Route parameter | Which book |
| `chapterIndex` | Current state | Which chapter |
| `scrollPosition` | ScrollController | Pixel offset in chapter |
| `percentage` | Calculated | `(chaptersRead + scrollFraction) / totalChapters` |
| `updatedAt` | `DateTime.now()` | When saved |

### Resume Reading

When opening a book that has progress:
1. Load progress from local DB (fast)
2. Navigate to `ReaderRoute(bookId, chapterIndex: progress.chapterIndex)`
3. After content loads, scroll to `progress.scrollPosition`
4. Fetch remote progress in background, use latest between local and remote

---

## Bookmarking

### Bookmark Data

| Field | Description |
|-------|-------------|
| `id` | UUID generated client-side |
| `bookId` | Book reference |
| `chapterId` | Chapter reference |
| `position` | Character offset in chapter text |
| `note` | Optional user note (future feature) |
| `createdAt` | Timestamp |

### Toggle Logic

1. User taps bookmark button
2. Check if bookmark exists at current position (chapterId)
3. If exists → delete (local + queue remote delete)
4. If not exists → create (local + queue remote create)
5. Update `isBookmarked` in ReaderState

---

## Text Features

### Font Scaling

- Controlled by slider in reader controls
- Range: 0.8x to 1.4x in 0.05 increments
- Applied to reader text only (not controls UI)
- Fires `ReaderFontScaleChanged` which delegates to `ThemeBloc`
- Persisted via SharedPreferences

### Night Mode

- Toggle in reader controls
- Fires `ReaderThemeModeToggled` which toggles `ThemeBloc`
- Reader uses palette's `readerBackground` and `readerText` colors
- Darker than standard dark mode (optimized for sustained reading)

### Text Selection

- Reader content uses `SelectableText` (or `SelectableText.rich`)
- Long-press to select, handles to adjust
- Copy option in selection toolbar
- Future: highlight and annotate

---

## Offline Reading

### Pre-caching

When user views a book detail page:
1. Cache book metadata in Drift
2. Pre-fetch and cache first 3 chapters
3. Background-fetch remaining chapters if on Wi-Fi

### Offline Reader

1. Reader checks local cache first (always)
2. If cached → display immediately
3. If not cached + offline → show offline error with "chapter not available offline"
4. If not cached + online → fetch, display, cache

### Storage Estimate

| Content | Avg Size | Cached |
|---------|----------|--------|
| Book metadata | ~2 KB | Always |
| Chapter content | ~50 KB | Eagerly (first 3), lazily (rest) |
| Book cover image | ~200 KB | Via `cached_network_image` |
| Full book (~20 chapters) | ~1 MB | When user reads through |
