# 25 — Responsive Layout & Adaptivity

## Goals

1. **Single codebase, multiple forms** — same tree adapts from 5″ phone → 13″ iPad → 8″ foldable.
2. **Postural awareness** — respond to foldable states (half-opened, tabletop, book).
3. **Content prioritization** — use extra space for more context, not larger UI.
4. **Ergonomic input** — adjust touch targets + nav for thumb-reach on large screens.
5. **Platform multitasking** — support iPad Split View, Slide Over, window resize.

## Breakpoints

Standard 3-tier system (logical px / dp):

| Tier | Width | Target devices | Layout |
|---|---|---|---|
| **Compact** | < 600dp | phones (portrait) | single column, bottom nav |
| **Medium** | 600–840dp | small tablets, foldables unfolded, large phones landscape | list-detail (collapsed), side rail |
| **Expanded** | > 840dp | iPads, tablets, desktop | list-detail (fixed), side nav |

**Foldables** transition between Compact (folded) and Medium (unfolded). Adaptive code must handle transitions without losing state or scroll position.

## Adaptive patterns

### 1. List-Detail (master-detail)
Most common for tablets/foldables.
- **Compact** — list pushes to detail screen.
- **Medium/Expanded** — list + detail side-by-side.
- **Rule** — if width > 600dp, use `Row` for both panels. Handle "no selection" state gracefully.

### 2. Side navigation (Rail vs Drawer)
- **Compact** — `NavigationBar` (bottom) or `Drawer`.
- **Medium** — `NavigationRail` (slim).
- **Expanded** — permanent `NavigationDrawer` or wide `NavigationRail`.

### 3. Modal → side panel
- **Compact** — full-screen modal / bottom sheet.
- **Expanded** — side panel (right-anchored) or centered dialog.

## Foldable support

Use `MediaQuery.displayFeatures` to detect hardware features (hinges/folds).

### Display features
| Feature | Description | Handling |
|---|---|---|
| **Hinge** | physical gap between screens | don't place text/buttons under hinge; split into two panes |
| **Fold** | seamless crease in flexible display | use as logical separator |

### Postures
- **Tabletop** — half-opened horizontally (like laptop). Top = content (video/image), bottom = controls (keyboard/playback).
- **Book** — half-opened vertically. Left + right panes for reading/comparison.

### Detection
```dart
final displayFeatures = MediaQuery.of(context).displayFeatures;
final hinge = displayFeatures.firstWhereOrNull(
  (f) => f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold,
);
if (hinge != null && hinge.state == DisplayFeatureState.halfOpened) {
  // posture-specific layout (Tabletop or Book)
}
```

## iPad & tablet optimization

### Multitasking (Split View / Slide Over)
iPads resize windows. **Do not assume full width.**
- **Rule** — always use `LayoutBuilder` or `MediaQuery.size` at page level.
- **Behavior** — dragging into 33% Split View → auto-switch Expanded → Compact.

### Hover & pointer support
iPadOS supports trackpads/mice:
- Wrap interactive elements in `MouseRegion` or use `InkWell.onHover`.
- Cursor — `SystemMouseCursors.click` for buttons.
- Theme's `highlightColor` responds to hover.

### High-density layouts
Large screens have "whitespace debt."
- **Grids** — increase `crossAxisCount` as width grows (2 mobile, 4 tablet, 6 desktop).
- **Max width** — for readable text, wrap in `ConstrainedBox(maxWidth: ~800dp)`, centered.

## Implementation strategy

### `AdaptiveLayout` (`lib/shared/widgets/adaptive_layout.dart`)

Branch UI high in the tree:
```dart
AdaptiveLayout(
  mobile: MobileDashboard(),
  tablet: TabletDashboard(),   // 600 – 840dp
  desktop: DesktopDashboard(), // > 840dp
)
```

### No magic numbers

Don't hardcode `if (width > 500)`. Use semantic getters:
```dart
extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600
                    && MediaQuery.sizeOf(this).width < 840;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 840;
}
```

## Current implementation

### Existing adaptive screens
| Screen | Compact | Medium/Expanded |
|---|---|---|
| `LoginPage` | single-column: gradient top half, form card slides up | two-column: gradient + branding left, form card right |
| `RegisterPage` | single-column scrollable form | centered form with max-width (560dp) |
| `SplashPage` | centered logo | same |

### Adaptive layout widget
`lib/shared/widgets/adaptive_layout.dart` — top-level page branching:
```dart
AdaptiveLayout(
  compact: const _PhoneLayout(),
  expanded: const _TabletLayout(), // optional — falls back to compact
)
```

### Responsive extensions (`lib/core/extensions/responsive_extensions.dart`)

| Extension | Returns | Condition |
|---|---|---|
| `context.isCompact` | `bool` | width < 600dp |
| `context.isMedium` | `bool` | 600 ≤ width < 840dp |
| `context.isExpanded` | `bool` | width ≥ 840dp |
| `context.isLargeScreen` | `bool` | width ≥ 600dp |
| `context.hingeFeature` | `DisplayFeature?` | physical hinge/fold |
| `context.isHalfOpened` | `bool` | foldable half-opened posture |

### Rules for new screens

1. Wrap body with `AdaptiveLayout` when phone vs tablet differ meaningfully.
2. Forms (login/register/settings) on expanded screens: center with `ConstrainedBox(maxWidth: AppDimensions.contentMaxWidth)`.
3. Never let text lines exceed `AppDimensions.contentMaxWidth` (560dp).
4. Detect hinge with `context.hingeFeature` — avoid interactive elements or dividers directly over it.

## Testing & validation

**Simulators:**
- **iPad** — test on 12.9″ (Expanded) + 11″ (Medium). Test Split View (1/3, 1/2, 2/3).
- **Android foldable** — use "7.6 Fold-in with outer display" emulator. Test folded ↔ unfolded transition.

**Checklist:**
- [ ] No "stretched" buttons or full-width text lines on large screens.
- [ ] Keyboard appears without overlapping primary action buttons.
- [ ] Content not cut off by hinge on dual-screen devices.
- [ ] App state (text, scroll) preserved during resize/unfold.
- [ ] One-hand nav reachable on larger devices (avoid top-left menus on iPads).
