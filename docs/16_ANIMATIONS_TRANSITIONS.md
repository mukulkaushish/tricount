# 16 — Animations & Transitions

## Performance budget

| Metric | Target | How |
|---|---|---|
| Frame rate | constant 60 fps | DevTools profiling, fix jank |
| Page transition | < 350 ms | platform-appropriate |
| Micro-interaction | < 200 ms | subtle, non-blocking |
| Image fade-in | 300 ms | `FadeInImage` / `cached_network_image` |
| Skeleton → content | instant swap | no animation on data arrival |

## Page transitions

### Defaults per platform
| Platform | Transition | Duration | Curve |
|---|---|---|---|
| Android | `ZoomPageTransitionsBuilder` | 300 ms | Material default |
| iOS | `CupertinoPageTransitionsBuilder` | 350 ms | iOS default |

Configured in `AppTheme.build()` via `pageTransitionsTheme`.

### Route-specific overrides
Use auto_route's `CustomRoute` with `TransitionsBuilders` → `09_NAVIGATION_DEEP_LINKING.md#built-in-transitionsbuilders-library`.

| Route | Builder | Duration | Reason |
|---|---|---|---|
| Reader | `fadeIn` | 250 ms | immersive entry |
| Modal bottom sheet | `slideBottom` | 300 ms | platform convention |
| Settings sub-pages | `fadeIn` | 200 ms | lightweight |
| Tab switch | `noTransition` | 0 ms | feel instant |

## Micro-interactions

**Bookmark button**
- Tap: scale 0.9× (50 ms) → 1.0× (100 ms).
- State: icon outlined ↔ filled via `AnimatedSwitcher` (200 ms).
- Color: `onSurface` → `primary` via `ColorTween`.

**Pull-to-refresh** — Flutter's built-in `RefreshIndicator`. Color: `colorScheme.primary`. Displacement: 40.0.

**Theme switch** — Flutter's built-in `AnimatedTheme` (200 ms). Night mode: smooth brightness transition via `MaterialApp` theme animation.

**Font size change** — text reflows instantly (animation would cause jank on large blocks). Slider shows live preview.

**Loading states**
- Shimmer: continuous, 1.5 s cycle.
- `CircularProgressIndicator`: platform default.
- Button loading: cross-fade label → spinner (150 ms).

## List animations

**Book grid/list**
- Initial load: staggered fade-in, 50 ms delay per item, max 8 items animated.
- Pagination: new items slide in from bottom (200 ms).
- Removal: `AnimatedList` slide-out (200 ms).

**Impl:** `AnimatedList`/`SliverAnimatedList` for dynamic lists. For static lists with initial animation, custom `StaggeredAnimation`. **Stagger limit:** only animate first 8 visible (avoid jank on large lists).

## Performance rules

1. **`const` widgets** wherever possible — avoid rebuild.
2. **`RepaintBoundary`** around expensive widgets (book covers, reader content).
3. **No heavy computation in `build()`** — pre-compute in BLoC.
4. **Avoid `Opacity` for fading** — use `FadeTransition`/`AnimatedOpacity`.
5. **Avoid `ClipRRect` on large surfaces** — use `Container` with `decoration` when possible.
6. **Image sizing** — always specify `width`/`height` or `cacheWidth`/`cacheHeight` to avoid decoding full-res.
7. **`ListView.builder`** for all scrollable lists (lazy).
8. **Shallow tree** — extract widgets when depth > 5 levels.

## Nav transition config

```dart
pageTransitionsTheme: PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
)
```
For route-specific overrides, use `@RoutePage(transitionsBuilder: ...)` or `CustomRoute`.
