# 16 - Animations & Transitions

## Performance Budget

| Metric | Target | How |
|--------|--------|-----|
| Frame rate | 60 fps constant | Profile with DevTools, fix jank |
| Page transition | < 350ms | Platform-appropriate transitions |
| Micro-interaction | < 200ms | Subtle, non-blocking |
| Image fade-in | 300ms | `FadeInImage` or cached_network_image |
| Skeleton → content | Instant swap | No animation on data arrival |

---

## Page Transitions

### Default Per-Platform

| Platform | Transition | Duration | Curve |
|----------|-----------|----------|-------|
| Android | Zoom (`ZoomPageTransitionsBuilder`) | 300ms | Material default |
| iOS | Cupertino slide (`CupertinoPageTransitionsBuilder`) | 350ms | iOS default |

Configured in `AppTheme.build()` via `pageTransitionsTheme`.

### Route-Specific Overrides

| Route | Transition | Duration | Reason |
|-------|-----------|----------|--------|
| Reader page | Fade | 250ms | Immersive content entry |
| Modal bottom sheet | Slide up | 300ms | Platform convention |
| Settings sub-pages | Fade through | 200ms | Lightweight navigation |
| Tab switch | None (instant) | 0ms | Tabs should feel instant |

---

## Micro-Interactions

### Bookmark Button
- **Tap**: Scale down to 0.9x (50ms) → scale up to 1.0x (100ms)
- **State change**: Icon morphs from outlined to filled with `AnimatedSwitcher` (200ms)
- **Color**: Transitions from `onSurface` to `primary` via `ColorTween`

### Pull-to-Refresh
- Uses Flutter's built-in `RefreshIndicator`
- Color: `colorScheme.primary`
- Displacement: 40.0

### Theme Switch
- Theme change: Flutter's built-in `AnimatedTheme` handles this (200ms)
- Night mode toggle: smooth brightness transition via `MaterialApp`'s theme animation

### Font Size Change
- Text reflows instantly (no animation - animation would cause jank on large text blocks)
- Slider shows live preview

### Loading States
- Shimmer animation: continuous, 1.5s cycle
- `CircularProgressIndicator`: platform default
- Button loading: cross-fade label → spinner (150ms)

---

## List Animations

### Book Grid/List
- Initial load: staggered fade-in, 50ms delay per item, max 8 items animated
- Pagination: new items slide in from bottom (200ms)
- Removal: `AnimatedList` slide-out (200ms)

### Implementation
- Use `AnimatedList` or `SliverAnimatedList` for dynamic lists
- For static lists with initial animation: custom `StaggeredAnimation` widget
- Stagger limit: only animate first 8 visible items (avoid jank on large lists)

---

## Performance Rules

1. **Use `const` widgets** wherever possible to avoid rebuild
2. **RepaintBoundary** around expensive widgets (book covers, reader content)
3. **No heavy computation in build()** - pre-compute in BLoC/ViewModel
4. **Avoid `Opacity` widget** for fading - use `FadeTransition` or `AnimatedOpacity`
5. **Avoid `ClipRRect` on large surfaces** - use `Container` with `decoration` instead when possible
6. **Image sizing**: always specify `width`/`height` or `cacheWidth`/`cacheHeight` to avoid decoding full-resolution images
7. **ListView.builder** for all scrollable lists (lazy construction)
8. **Keep widget tree shallow** - extract widgets into named components when depth > 5 levels

---

## Navigation Transition Config

Set in `AppTheme.build()`:

```
pageTransitionsTheme: PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
)
```

For route-specific overrides, use auto_route's `@RoutePage(transitionsBuilder: ...)` annotation.
