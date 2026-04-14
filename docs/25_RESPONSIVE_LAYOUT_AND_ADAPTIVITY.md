# 25 - Responsive Layout & Adaptivity

## Design Goals

1. **Single codebase, multiple forms** - the same widget tree adapts from a 5" phone to a 13" iPad and 8" foldable
2. **Postural awareness** - respond to foldable device states (half-opened, tabletop, book)
3. **Content prioritization** - use extra space to show more context, not just scale up UI elements
4. **Ergonomic input** - adjust touch targets and navigation for thumb-reach on large screens
5. **Platform-native multitasking** - support iPad Split View, Slide Over, and window resizing gracefully

---

## Breakpoints

We use a standard 3-tier breakpoint system based on logical pixels (dp).

| Tier | Range (Width) | Target Devices | Layout Strategy |
|------|---------------|----------------|-----------------|
| **Compact** | < 600dp | All phones (Portrait) | Single column, Bottom nav |
| **Medium** | 600 - 840dp | Small tablets, Foldables (Unfolded), Large phones (Landscape) | List-Detail (collapsed), Side rail |
| **Expanded** | > 840dp | iPads, Tablets, Desktop | List-Detail (fixed), Side navigation |

### Foldable Specifics

Foldables often transition between **Compact** (folded) and **Medium** (unfolded) tiers. Adaptive code must handle these transitions without losing state or scroll position.

---

## Adaptive Design Patterns

### 1. List-Detail (Master-Detail)
The most common pattern for tablets and foldables.

- **Compact**: List screen pushes to Detail screen.
- **Medium/Expanded**: List and Detail are shown side-by-side.
- **Rule**: If the screen width is > 600dp, use a `Row` to display both panels. Ensure the Detail panel handles "no selection" states gracefully.

### 2. Side Navigation (Rail vs. Drawer)
- **Compact**: `NavigationBar` (bottom) or `Drawer`.
- **Medium**: `NavigationRail` (slim side bar).
- **Expanded**: Permanent `NavigationDrawer` or wide `NavigationRail`.

### 3. Modal to Side Panel
- **Compact**: Full-screen modal or Bottom Sheet.
- **Expanded**: Side panel (anchored right) or centered Dialog.

---

## Foldable Support

Use `MediaQuery.displayFeatures` to detect physical hardware features like hinges or folds.

### Display Features

| Feature | Description | Handling |
|---------|-------------|----------|
| **Hinge** | Physical gap between screens | Avoid placing text or buttons directly under the hinge. Split content into two panes. |
| **Fold** | Seamless crease in a flexible display | Can be used as a logical separator. |

### Device Postures

Detection via `displayFeatures` and aspect ratio:

- **Tabletop Posture**: Device is half-opened horizontally (like a laptop).
  - *Strategy*: Top half for content (video, image), bottom half for controls (keyboard, playback).
- **Book Posture**: Device is half-opened vertically.
  - *Strategy*: Left and right panes for reading or comparison.

### Implementation Snippet (Fold-Aware)

```dart
final displayFeatures = MediaQuery.of(context).displayFeatures;
final hinge = displayFeatures.firstWhereOrNull(
  (f) => f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold,
);

if (hinge != null && hinge.state == DisplayFeatureState.halfOpened) {
  // Handle posture-specific layout (Tabletop or Book)
}
```

---

## iPad & Tablet Optimization

### Multitasking (Split View & Slide Over)
iPads allow users to resize the app window. Do not assume the app always has the full screen width.

- **Rule**: Always use `LayoutBuilder` or `MediaQuery.size` at the page level.
- **Behavior**: If a user drags your app into a 33% Split View, it should automatically switch from **Expanded** to **Compact** layout.

### Hover & Pointer Support
iPadOS supports trackpads and mice.

- **Implementation**: Wrap interactive elements in `MouseRegion` or use `InkWell.onHover`.
- **Cursor**: Use `SystemMouseCursors.click` for buttons.
- **Highlight**: The theme's `highlightColor` should respond to hover states.

### High-Density Layouts
Large screens have more "whitespace debt." 

- **Grids**: Increase `crossAxisCount` as width increases (e.g., 2 columns on Mobile, 4 on Tablet, 6 on Desktop).
- **Max Width**: For readable text (like a blog post), wrap content in a `ConstrainedBox` with a `maxWidth` of ~800dp, centered on the screen.

---

## Implementation Strategy

### The `AdaptiveLayout` Widget
(Reference: `lib/shared/widgets/adaptive_layout.dart`)

Use this widget to branch your UI high in the tree:

```dart
AdaptiveLayout(
  mobile: MobileDashboard(),
  tablet: TabletDashboard(), // 600 - 840dp
  desktop: DesktopDashboard(), // > 840dp
)
```

### Avoid "Magic Numbers"
Do not hardcode pixel checks like `if (width > 500)`. Use semantic getters from a central breakpoint class or extension.

```dart
extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600 && MediaQuery.sizeOf(this).width < 840;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 840;
}
```

---

## Testing & Validation

### Simulators / Emulators
- **iPad**: Test on 12.9" (Expanded) and 11" (Medium) models. Test Split View (1/3, 1/2, 2/3).
- **Android Foldable**: Use the "7.6 Fold-in with outer display" emulator. Test transition from folded to unfolded.

### Checklist
- [ ] No "stretched" buttons or full-width text lines on large screens
- [ ] Keyboard appears without overlapping primary action buttons
- [ ] Content is not cut off by the hinge on dual-screen devices
- [ ] App state (text in fields, scroll position) is preserved during resize/unfold
- [ ] Navigation is reachable with one hand on larger devices (e.g., avoid top-left menus on iPads)
