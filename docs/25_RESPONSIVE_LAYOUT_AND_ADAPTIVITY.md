# 25 - Responsive Layout & Adaptivity

## Design Goals

1. **Single codebase, multiple forms** — the same widget tree adapts from a 5" phone to a 13" iPad and 8" foldable
2. **Postural awareness** — respond to foldable device states (half-opened, tabletop, book)
3. **Content prioritization** — use extra space to show more context, not just scale up UI elements
4. **Ergonomic input** — adjust touch targets and navigation for thumb-reach on large screens
5. **Platform-native multitasking** — support iPad Split View, Slide Over, and window resizing gracefully

---

## Technology Recommendations

### Primary Approach: `flutter_adaptive_scaffold` (Official Flutter Team)

**Package**: `flutter_adaptive_scaffold` (https://pub.dev/packages/flutter_adaptive_scaffold)  
**Why**: Official Flutter support, Material 3 compliance, first-class foldable awareness, auto-adaptive navigation.

**Key Capabilities**:
- Automatic navigation switching: `NavigationBar` → `NavigationRail` → `NavigationDrawer`
- Hinge/fold detection via `MediaQuery.displayFeatures`
- Material 3 breakpoint system built-in
- No custom layout wrappers needed

**Installation**:
```yaml
dependencies:
  flutter_adaptive_scaffold: ^0.2.0  # Check pub.dev for latest
```

### Complementary Packages

| Package | Purpose | When to Use |
|---------|---------|------------|
| `responsive_builder` | Simple breakpoint detection | Edge cases after flutter_adaptive_scaffold handles primary layout |
| `screen_util` | Pixel-perfect UI scaling | Design-heavy apps needing 1:1 device mapping |
| `flutter_screenutil` | Text/icon responsive sizing | Complex typography needs |

---

## Breakpoints

We use a standard 3-tier breakpoint system based on logical pixels (dp), aligned with Material 3.

| Tier | Range (Width) | Target Devices | Layout Strategy |
|------|---------------|----------------|-----------------|
| **Compact** | < 600dp | All phones (Portrait), Foldables (Folded) | Single column, Bottom nav, Full-screen modals |
| **Medium** | 600 - 840dp | Small tablets, Foldables (Unfolded), Large phones (Landscape) | List-Detail (collapsed), Navigation rail |
| **Expanded** | 840 - 1200dp | iPads, Tablets | List-Detail (fixed), Side navigation |
| **Large** | ≥ 1200dp | iPad Pro, Desktop | Multi-pane layouts, Drawer + Rail |

### Responsive Tokens in Code

All breakpoints and responsive padding are centralized in `AppDimensions`:

```dart
// Use these instead of magic numbers:
if (context.screenWidth < AppDimensions.breakpointCompact) {
  // Compact layout
}

// Better: use semantic helpers
if (context.isCompact) {
  // Compact layout
} else if (context.isMedium) {
  // Medium layout
}

// Get responsive padding automatically
final padding = context.responsiveContentPadding; // EdgeInsets that adapt to breakpoint
```

---

## Adaptive Design Patterns

### 1. Navigation Adaptation

Use **`flutter_adaptive_scaffold`** to handle navigation automatically:

```dart
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

AdaptiveLayout(
  body: (_) {
    return const SafeArea(child: Placeholder()); // Always shown
  },
  secondaryBody: (_) {
    return const SafeArea(child: Placeholder()); // Shown on medium+ screens
  },
  primaryNavigation: AdaptiveScaffold.standardNavigationBuilder,
)
```

**What happens**:
- **Compact** (< 600dp): `NavigationBar` at bottom, single body
- **Medium** (600-840dp): `NavigationRail` on left, body + optional secondaryBody
- **Expanded** (≥ 840dp): Permanent `NavigationDrawer`, full width for content

**Don't**:
- Create custom `AdaptiveLayoutBuilder`, `AdaptiveScaffold`, `TwoPaneLayout` wrappers
- Manually switch between NavigationBar/Rail/Drawer based on screen width
- Use LayoutBuilder just to detect breakpoints — use `context.isCompact` instead

### 2. List-Detail (Master-Detail)

Standard pattern for content browsing on tablets and foldables:

```dart
// Compact: detail replaces list on navigation
if (context.isCompact) {
  return ListView(...); // List of items
} 
// Medium+: show both side-by-side
else {
  return Row(
    children: [
      Expanded(flex: 1, child: ListView(...)),
      Expanded(flex: 1, child: DetailView(...)),
    ],
  );
}
```

**Rules**:
- List panel: Resizable or fixed width. On Medium+, allow width between 250-400dp.
- Detail panel: Must gracefully handle "no selection" (show empty state or placeholder).
- Preserve scroll position and selection when resizing or rotating.

### 3. Modal to Side Panel

Modals on small screens should become side panels on tablets:

```dart
if (context.isCompact) {
  showModalBottomSheet(...); // Full-screen modal or bottom sheet
} else {
  // Side panel on the right
  showDialog(
    builder: (_) => Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.4,
        child: Content(),
      ),
    ),
  );
}
```

---

## Foldable Device Support

### Understanding Display Features

Use `MediaQuery.displayFeaturesOf(context)` to detect physical hardware features:

```dart
final features = MediaQuery.displayFeaturesOf(context);
for (final feature in features) {
  if (feature.type == DisplayFeatureType.hinge) {
    print('Hinge at: ${feature.bounds}');
  }
  if (feature.type == DisplayFeatureType.fold) {
    print('Fold at: ${feature.bounds}');
  }
}
```

### Handling Foldable Postures

Foldables rotate between states; detect them with convenience getters:

```dart
// Check if device is in a half-opened posture (tabletop or book mode)
if (context.hasActiveFold) {
  // Device is folded and half-opened
  // Posture is either:
  // - Tabletop: horizontal fold, top half for content, bottom for controls
  // - Book: vertical fold, left pane for reading, right pane for controls
}

// Get the fold bounds to avoid placing UI directly on the crease
final foldRect = context.foldBounds; 
if (foldRect != null) {
  // Don't place buttons or text within 50dp of the fold
  return Padding(
    padding: context.hingeAwarePadding,
    child: Content(),
  );
}
```

### Foldable Implementation Checklist

- [ ] No critical buttons or text directly under the hinge/fold
- [ ] Content reflows around the fold (use `Row` or `Column` that respects fold location)
- [ ] Scroll position preserved when device rotates or folds/unfolds
- [ ] Test on actual devices (emulator fold simulation is limited)
- [ ] Use `flutter_adaptive_scaffold` — it handles fold awareness natively

---

## iPad & Tablet Optimization

### Multitasking: Split View & Slide Over

iPads allow users to resize your app window. Always build with `LayoutBuilder` or use `MediaQuery` at the page level:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // Automatically adapts when user drags to Split View (33%) or Slide Over
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else if (constraints.maxWidth < 840) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

**Behavior**: If a user drags your app to a 33% Split View (width ~400dp), it automatically switches from **Expanded** to **Compact** layout without needing to handle rotation events.

### Hover & Pointer Support

iPadOS supports trackpads and mice. Respond to hover states:

```dart
InkWell(
  onHover: (hovering) {
    // Update button visual state
    setState(() => _isHovered = hovering);
  },
  child: MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Button(),
  ),
)
```

**Best Practices**:
- Use `MouseRegion` for cursor changes
- Apply `highlightColor` from theme on hover
- Increase touch target to 48dp minimum (Material 3 spec)

### Content Max-Width (Readability)

For text-heavy content (blog posts, articles), constrain width on large screens:

```dart
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
  child: Center(
    child: SingleChildScrollView(
      child: Column(...),
    ),
  ),
)
```

This prevents lines of text from becoming unreadably long on 13" iPads.

### High-Density Layouts

Use available space efficiently on tablets:

```dart
// Adapt grid columns based on breakpoint
final crossAxisCount = context.isCompact ? 2 : context.isMedium ? 3 : 4;

GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
  ),
  itemBuilder: (_,i) => Card(),
)
```

---

## Implementation in Your Codebase

### Step 1: Add Responsive Tokens to Theme

Already included in `lib/core/theme/app_dimensions.dart`:
```dart
static const double breakpointCompact = 600;
static const double breakpointMedium = 840;
static const double breakpointExpanded = 1200;
static const double responsivePaddingH = 24; // adapts by breakpoint
```

### Step 2: Use BuildContext Extensions

Included in `lib/core/theme/theme_extensions.dart`:
```dart
context.isCompact     // bool: width < 600
context.isMedium      // bool: 600 ≤ width < 840
context.isExpanded    // bool: width ≥ 840
context.responsiveContentPadding  // EdgeInsets that adapt
context.hasActiveFold // bool: foldable in half-open state
context.foldBounds    // Rect: location of hinge/fold
```

### Step 3: Build Adaptive Pages

For your first page (e.g., HomePage), use `flutter_adaptive_scaffold`:

```dart
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      body: (_) => const SafeArea(child: BillsListView()),
      secondaryBody: (_) => const SafeArea(child: BillDetailView()),
      primaryNavigation: AdaptiveScaffold.standardNavigationBuilder,
    );
  }
}
```

---

## Grid Layouts (Primary Pattern for Content Browsing)

Grids are the **preferred layout pattern** for browsing content (bills, items, cards) across all screen sizes. Complete widget implementations (`BillsGridView`, `BillCard`) → [15_REUSABLE_COMPONENTS.md § Responsive Grid Components](15_REUSABLE_COMPONENTS.md#responsive-grid-components).

### When to Use Grids

| Use Grid | Use List |
|----------|----------|
| Content browsing (bills, transactions, cards) | Navigation items, menus |
| Any screen showing a similar-item collection | Long-form text, feeds, chat |
| Responsive by default, no conditional layout code | Single-column variable-structure items |

### GridView.builder — Column Count from Breakpoints

```dart
final crossAxisCount = context.isCompact ? 2 :   // Phones
                       context.isMedium  ? 3 :   // Tablets
                       context.isExpanded ? 4 : 5; // iPad/Large

GridView.builder(
  padding: context.responsiveContentPadding,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: AppDimensions.s16,
    crossAxisSpacing: AppDimensions.s16,
    childAspectRatio: 1.0,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(item: items[index]),
);
```

### GridView.extent — Width-Based Auto-Columns

Prefer this when column count should derive from item width, not a fixed count:

```dart
GridView.extent(
  maxCrossAxisExtent: context.isCompact ? 150 : context.isMedium ? 200 : 250,
  mainAxisSpacing: AppDimensions.s16,
  crossAxisSpacing: AppDimensions.s16,
  children: items.map((item) => ItemCard(item: item)).toList(),
)
```

### Foldable-Aware Grids

Avoid placing content on the hinge in tabletop / book mode:

```dart
final gridHeight = context.hasActiveFold ? screenHeight / 2 : screenHeight;

SizedBox(
  height: gridHeight,
  child: GridView.builder(
    padding: context.hingeAwarePadding, // respects fold bounds
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: context.isCompact ? 2 : context.isMedium ? 3 : 4,
    ),
    ...
  ),
);
```

### iPad Multitasking

Grids adapt to Split View / Slide Over automatically — `context.isCompact/isMedium/isExpanded` recalculate as the window width changes. No extra code needed.

| Multitasking mode | Width | Columns |
|-------------------|-------|---------|
| Full screen | Expanded | 4+ |
| 50% Split View | Medium | 3 |
| 33% Slide Over | Compact | 2 |

### Content Max-Width on Large Screens

```dart
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: context.isExpanded ? AppDimensions.maxContentWidth : double.infinity,
  ),
  child: Center(child: GridView.builder(...)),
)
```

### Variable-Height Items (Optional)

For cards with significantly different heights, use `flutter_staggered_grid_view`:

```yaml
dependencies:
  flutter_staggered_grid_view: ^0.7.0
```

```dart
MasonryGridView.builder(
  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: context.isCompact ? 2 : context.isMedium ? 3 : 4,
  ),
  ...
)
```

Only adopt if items have meaningfully different heights. Native `GridView` is simpler and faster for uniform cards.

### Grid Performance

- Use `const` constructors on card widgets
- Keep `itemBuilder` build time < 16ms — avoid heavy work inside it
- Use `childAspectRatio` to avoid remeasuring card heights
- Never wrap `GridView` in `SingleChildScrollView` — it scrolls natively

---

## Testing & Validation

### Simulators & Emulators

| Device | How to Test | Key Scenarios |
|--------|------------|--------------|
| iPad 12.9" | Xcode simulator or Flutter device | Expanded (> 840dp), full-screen app, grid with 4+ columns |
| iPad 12.9" Split View | Xcode simulator with Split View | Compact (33% split, 2 columns), Medium (50% split, 3 columns) |
| Android Tablet (10") | Android emulator | Grid columns adapt: Medium/Expanded in landscape |
| Samsung Galaxy Fold | Emulator (limited) or device | Folded (Compact, 2 cols), Unfolded (Medium, 3 cols) |

### Testing Checklist

**Layout & Responsiveness:**
- [ ] Grid columns adjust correctly: 2 (compact), 3 (medium), 4+ (expanded)
- [ ] Grid adapts smoothly during iPad Split View resize (33% → 50% → full)
- [ ] Grid columns recompute on device rotation without layout bugs
- [ ] List-detail transitions smooth when folding/unfolding foldable device
- [ ] No stretched buttons or full-width text lines on large screens (max-width enforced)
- [ ] Multitasking works: app gracefully shrinks when user drags to Split View/Slide Over

**Grid-Specific:**
- [ ] Card content doesn't overflow (titles truncated, no word wrap in narrow cards)
- [ ] Grid scroll position preserved during rotate/resize
- [ ] Grid items have consistent aspect ratio (no layout shift during scroll)
- [ ] Card tap targets >= 48dp (Material 3 minimum)
- [ ] Foldable grids: no critical content placed on hinge/fold line
- [ ] Grid spacing respects `hingeAwarePadding` on foldables
- [ ] Grid padding scales per breakpoint (compactH, mediumH, expandedH from AppDimensions)

**iPad & Tablet:**
- [ ] Text remains readable on 13" iPad (use max-width constraints on grid container)
- [ ] Hover states working on iPad with trackpad/mouse (add `MouseRegion` to cards if needed)
- [ ] Grid layout optimal for landscape orientation on tablets

**General Responsiveness:**
- [ ] Keyboard appears without overlapping action buttons on all screen sizes
- [ ] Content not cut off by hinge on dual-screen devices
- [ ] App state (form inputs, scroll position) preserved during resize/orientation change
- [ ] Navigation accessible with one hand on large devices (buttons not in unreachable corners)

### Debugging Responsive Issues

```dart
// Temporarily display breakpoint info
Positioned(
  top: 0,
  right: 0,
  child: Container(
    color: Colors.black87,
    padding: EdgeInsets.all(8),
    child: Text(
      '${context.screenWidth.toInt()}x${context.screenHeight.toInt()}dp\n'
      '${context.isCompact ? 'Compact' : context.isMedium ? 'Medium' : 'Expanded'}',
      style: TextStyle(color: Colors.white, fontSize: 10),
    ),
  ),
)
```

---

## Performance Notes

- **Avoid expensive rebuilds on resize**: Use `LayoutBuilder` with `const` children where possible
- **Don't rebuild entire trees**: Use conditional widgets (`if (context.isCompact)`) instead of wrapping widgets
- **Foldable detection is cheap**: `MediaQuery.displayFeaturesOf()` is a lightweight call, safe in `build()`

---

## References

**Navigation & Adaptive Layout:**
- [flutter_adaptive_scaffold](https://pub.dev/packages/flutter_adaptive_scaffold) — Official Flutter team package
- [Flutter Responsive UI Guide](https://flutter.dev/docs/development/ui/adaptive-responsive)
- [MediaQuery.displayFeatures Docs](https://api.flutter.dev/flutter/widgets/MediaQuery/displayFeaturesOf.html) — Foldable API

**Grid & Layout:**
- [GridView Documentation](https://api.flutter.dev/flutter/widgets/GridView-class.html) — Native GridView.builder and GridView.extent
- [SliverGridDelegate Docs](https://api.flutter.dev/flutter/widgets/SliverGridDelegate-class.html) — Column count and aspect ratio
- [flutter_staggered_grid_view](https://pub.dev/packages/flutter_staggered_grid_view) — For variable-height items (optional)
- [Responsive Grid Example (GitHub)](https://github.com/rydmike/resp_stag_grid) — Breakpoint-based grid implementation

**Design & Standards:**
- [Material 3 Adaptive UI](https://m3.material.io/foundations/adaptive-design/overview) — Design specs
- [Flutter Large Screens Guide](https://docs.flutter.dev/ui/adaptive-responsive/large-screens) — iPad/tablet optimization
