# 05 - Dynamic Theming System

## Design Goals

1. **Zero inline themes** - no widget ever constructs `TextStyle`, `Color`, or `ThemeData` directly
2. **Multiple primary palettes** - user-selectable brand palettes
3. **Dark mode** - full dark theme support per palette
4. **Font scaling** - user-adjustable text size (e.g. 0.8x to 1.4x)
5. **Centralized typography** - one source of truth for all text styles
6. **Hot-swappable** - theme changes apply instantly without restart
7. **Platform-native feel** - Material ripples on Android, Cupertino highlights on iOS; adaptive widgets chosen at build time, not runtime branching inside every widget

---

## Architecture

```
ThemeBloc (state: ThemeState)
    ├── currentPalette: AppColorPalette
    ├── themeMode: ThemeMode (light/dark/system)
    └── fontScale: double (e.g. 0.8 - 1.4)
           │
           ▼
    AppTheme.build(palette, brightness, fontScale, platform)
           │
           ▼
    ThemeData (consumed by MaterialApp)
```

---

## Color Palettes

### AppColorPalette (Value Object)

Each palette defines these semantic colors:

| Property | Type | Purpose |
|----------|------|---------|
| `name` | `String` | Display name shown in settings |
| `primary` | `Color` | Primary brand color |
| `primaryVariant` | `Color` | Darker primary for contrast |
| `secondary` | `Color` | Accent/secondary actions |
| `surface` | `Color` | Card/dialog backgrounds |
| `background` | `Color` | Page background |
| `error` | `Color` | Error states |
| `onPrimary` | `Color` | Text/icon on primary |
| `onSecondary` | `Color` | Text/icon on secondary |
| `onSurface` | `Color` | Text/icon on surface |
| `onBackground` | `Color` | Text/icon on background |
| `onError` | `Color` | Text/icon on error |

Add domain-specific semantic tokens to the palette only when a feature needs colors that cannot be expressed as Material roles — keep them named by *role*, never by call site.

### Predefined Palettes

**File**: `lib/core/theme/app_colors.dart`

| Palette ID | Name | Primary | Character |
|-----------|------|---------|-----------|
| `blue` | Ocean Blue | `#1565C0` | Calm, professional |
| `violet` | Royal Violet | `#7B1FA2` | Creative, premium |
| `red` | Crimson Red | `#C62828` | Bold, energetic |
| `orange` | Sunset Orange | `#E65100` | Warm, inviting |
| `pink` | Rose Pink | `#AD1457` | Soft, modern |

Each palette has both **light** and **dark** variants — the dark variant is not just "same colors on dark background": it has reduced saturation, adjusted contrast, and surface overlays.

### Dark Mode Adjustments Per Palette

- Primary color: reduce saturation slightly, increase lightness slightly
- Surface: near-black base (e.g. `#121212`) with palette-tinted overlay at low opacity
- All text meets WCAG AA contrast ratio (4.5:1 minimum)
- Elevation overlays follow Material 3 dark-theme guidance

---

## Typography System

### AppTextStyles (Centralized)

**File**: `lib/core/theme/app_text_styles.dart`

All text styles are defined once and derive from a base configuration. Use Material 3 type scale names so they map 1:1 onto `TextTheme`:

| Style Name | Base Size | Weight | Usage |
|-----------|-----------|--------|-------|
| `displayLarge` | 32sp | Bold | Hero headings |
| `displayMedium` | 28sp | Bold | Section headings |
| `titleLarge` | 22sp | SemiBold | Page titles |
| `titleMedium` | 18sp | SemiBold | Card titles |
| `titleSmall` | 16sp | Medium | Subtitles |
| `bodyLarge` | 16sp | Regular | Emphasized body text |
| `bodyMedium` | 14sp | Regular | General body text |
| `bodySmall` | 12sp | Regular | Captions, metadata |
| `labelLarge` | 14sp | Medium | Buttons |
| `labelMedium` | 12sp | Medium | Chips, tabs |
| `labelSmall` | 10sp | Medium | Overlines |

### Font Family

Declare one or two font families centrally (e.g. a primary UI font and an optional monospace for code). Bundle fonts in `assets/fonts/` and register them in `pubspec.yaml`; do not pull fonts at runtime from a network font provider.

### Font Scaling

Font scale is a multiplier applied to ALL text styles:

| Scale | Label | Multiplier |
|-------|-------|------------|
| XS | Small | 0.8 |
| S | Compact | 0.9 |
| M | Default | 1.0 |
| L | Large | 1.15 |
| XL | Extra Large | 1.3 |
| XXL | Maximum | 1.4 |

**Implementation**: `AppTextStyles.scaled(double factor)` returns a new `TextTheme` with all sizes multiplied.

---

## ThemeBloc

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `ThemePaletteChanged` | `AppColorPalette palette` | User selected a new color palette |
| `ThemeModeChanged` | `ThemeMode mode` | User toggled light/dark/system |
| `FontScaleChanged` | `double scale` | User adjusted font size slider |
| `ThemeRestored` | none | Load saved theme from preferences on startup |

### State

| Property | Type | Default |
|----------|------|---------|
| `palette` | `AppColorPalette` | First predefined palette |
| `themeMode` | `ThemeMode` | `ThemeMode.system` |
| `fontScale` | `double` | `1.0` |
| `lightTheme` | `ThemeData` | (derived) |
| `darkTheme` | `ThemeData` | (derived) |

### Persistence

On every state change, ThemeBloc persists to local preferences:
- `theme_palette_id` → `String`
- `theme_mode` → `String` ("light", "dark", "system")
- `font_scale` → `double`

On `ThemeRestored` event (called at app start), these values are read and applied.

---

## AppTheme Factory

**File**: `lib/core/theme/app_theme.dart`

**Method**: `static ThemeData build({required AppColorPalette palette, required Brightness brightness, required double fontScale, required TargetPlatform platform})`

**The one rule**: every visual property for every component lives in this factory. Feature code never sets `color:`, `padding:`, `shape:`, `textStyle:`, `elevation:`, `borderRadius:`, or any inline styling on a widget. If a widget renders wrong, **fix the theme**, not the call site.

- No custom wrapper widgets (`AppButton`, `AppTextField`, `AppSegmentedControl`, etc.). Use the framework widgets directly; the global theme does the work.
- Platform differences (ripple, transitions, cupertino variants) are baked into `ThemeData` at build time via `platform` — widgets never branch on `Platform.isIOS`.
- For per-instance platform swaps the framework handles natively, use the `.adaptive` constructors (`Switch.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`, `RefreshIndicator.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `AlertDialog.adaptive`, `Icons.adaptive.*`, `showAdaptiveDialog`).

### Global theme table

Every `ThemeData` sub-theme is set. Feature widgets get styled by inheritance.

#### Foundations

| Sub-theme | Configuration |
|-----------|---------------|
| `colorScheme` | `ColorScheme.fromSeed(seedColor: palette.primary, brightness)` then overridden with explicit palette tokens for `primary`, `secondary`, `surface`, `error`, and their `on*` counterparts |
| `textTheme` | `AppTextStyles.scaled(fontScale)` bound to palette `onSurface` |
| `primaryTextTheme` | Same, with `onPrimary` color |
| `iconTheme` | `color: onSurface`, `size: 24` |
| `primaryIconTheme` | `color: onPrimary`, `size: 24` |
| `scaffoldBackgroundColor` | Palette `background` |
| `canvasColor` | Palette `surface` |
| `dividerColor` | Palette `onSurface.withOpacity(0.12)` — the **one** separator color used everywhere |
| `shadowColor` | `Colors.black.withOpacity(0.08)` |
| `disabledColor` | `onSurface.withOpacity(0.38)` |
| `hintColor` | `onSurface.withOpacity(0.60)` |
| `visualDensity` | `VisualDensity.adaptivePlatformDensity` |
| `materialTapTargetSize` | `MaterialTapTargetSize.padded` |

#### Tap feedback (the iOS-no-ripple rule)

| Sub-theme | iOS / macOS | Android |
|-----------|-------------|---------|
| `splashFactory` | `NoSplash.splashFactory` | `InkSparkle.splashFactory` |
| `splashColor` | `Colors.transparent` | `primary.withOpacity(0.12)` |
| `highlightColor` | `onSurface.withOpacity(0.08)` (instant Cupertino-style dim) | `primary.withOpacity(0.10)` |
| `pageTransitionsTheme` | `CupertinoPageTransitionsBuilder` (keeps edge-swipe back) | `ZoomPageTransitionsBuilder` |

Result: Material ripples expand on Android. On iOS every `InkWell`, `ListTile`, button, and chip shows only an instant opacity dim — no expanding circle, matching `CupertinoButton` press behavior. This is 100% configured in the theme; feature code uses `InkWell`/buttons normally.

#### Top navigation

| Sub-theme | Configuration |
|-----------|---------------|
| `appBarTheme` | `backgroundColor: surface`, `foregroundColor: onSurface`, `elevation: 0`, `scrolledUnderElevation: 3`, `centerTitle: (platform == iOS)`, `titleTextStyle: textTheme.titleLarge`, `systemOverlayStyle` derived from brightness |
| `tabBarTheme` | `labelColor: primary`, `unselectedLabelColor: onSurface.withOpacity(0.6)`, `indicatorColor: primary`, `indicatorSize: TabBarIndicatorSize.label`, `dividerColor: Colors.transparent`, `overlayColor: transparent on iOS` |
| `segmentedButtonTheme` | Palette `primary` selected background, `StadiumBorder`, `onPrimary` text — used for Material-3 segmented filters |
| `bottomNavigationBarTheme` | Legacy (3-item). `selectedItemColor: primary`, `unselectedItemColor: onSurface.withOpacity(0.6)`, `backgroundColor: surface`, `elevation: 0`, `showUnselectedLabels: true` |
| `navigationBarTheme` (Material 3) | `indicatorColor: primary.withOpacity(0.15)`, `labelTextStyle: textTheme.labelMedium`, `iconTheme` palette-driven, `height: 72`, `elevation: 0` |
| `navigationRailTheme` | For tablets — palette selected color, 72px width |
| `drawerTheme` | `backgroundColor: surface`, `elevation: 1`, `shape: RoundedRectangleBorder(topRight/bottomRight: 16)` |

Use native `AppBar`, `TabBar`, `NavigationBar`/`BottomNavigationBar`, `SegmentedButton` directly. For the iOS "pill-style segmented filter" look, `SegmentedButton` themed with `StadiumBorder` and selected-primary renders identically to `CupertinoSlidingSegmentedControl` — keep the one Material widget.

#### Buttons

| Sub-theme | Configuration |
|-----------|---------------|
| `filledButtonTheme` | Primary CTA. `backgroundColor: primary`, `foregroundColor: onPrimary`, `textStyle: labelLarge`, `minimumSize: Size(64, 48)`, `shape: StadiumBorder()`, `padding: symmetric(24, 0)` |
| `elevatedButtonTheme` | Same as Filled, plus `elevation: 0` (flat look), kept for legacy call sites |
| `outlinedButtonTheme` | `foregroundColor: primary`, `side: BorderSide(color: primary)`, `shape: StadiumBorder()`, `minimumSize: Size(64, 48)` |
| `textButtonTheme` | `foregroundColor: primary`, `textStyle: labelLarge`, `minimumSize: Size(48, 40)` |
| `iconButtonTheme` | `foregroundColor: onSurface`, `padding: EdgeInsets.all(12)`, `iconSize: 24`, `shape: CircleBorder()` |
| `floatingActionButtonTheme` | `backgroundColor: primary`, `foregroundColor: onPrimary`, `shape: RoundedRectangleBorder(16)`, `elevation: 3 on Android / 0 on iOS` |
| `menuButtonTheme` / `dropdownMenuTheme` | Palette-tinted hover, surface background, 8px corners |

One shape language: stadium (pill) for CTAs, circle for icon buttons, 16px rect for FAB. No per-screen overrides.

#### Input & selection components

These map directly to Android's `Switch`, `CheckBox`, `RadioButton`, `Spinner`, `SeekBar` and iOS's `UISwitch`, `UIPickerView`, `UISlider`. Use the Flutter defaults with `.adaptive` where the framework ships a Cupertino variant — styling is global, no custom widgets.

| Widget | Sub-theme | Notes |
|--------|-----------|-------|
| `TextField` / `TextFormField` | `inputDecorationTheme` | `filled: true`, `fillColor: surface`, `border: OutlineInputBorder(12)`, `focusedBorder` with `primary`, `errorBorder` with `error`, `contentPadding: symmetric(16, 14)`, `labelStyle: bodyMedium`, `hintStyle: bodyMedium.copyWith(color: hint)`. Cursor: `primary`. Selection handle: platform default (Flutter handles this automatically). |
| `Switch` / `Switch.adaptive` | `switchTheme` | `thumbColor`/`trackColor` MaterialStateProperty resolved to palette `primary`/`primary.withOpacity(0.5)`. `.adaptive` becomes `CupertinoSwitch` on iOS — still picks up palette via `activeColor` in the theme. |
| `Checkbox` / `Checkbox.adaptive` | `checkboxTheme` | `fillColor: primary when selected`, `checkColor: onPrimary`, `shape: RoundedRectangleBorder(4)`, `side: BorderSide(color: onSurface.withOpacity(0.6))`. iOS renders the filled-circle check via `.adaptive`. |
| `Radio` / `Radio.adaptive` | `radioTheme` | `fillColor: primary selected / onSurface unselected`. |
| `Slider` / `Slider.adaptive` (SeekBar) | `sliderTheme` | `activeTrackColor: primary`, `inactiveTrackColor: primary.withOpacity(0.24)`, `thumbColor: primary`, `overlayColor: primary.withOpacity(0.12)`, `trackHeight: 4`, `valueIndicatorColor: primary`, `valueIndicatorTextStyle: labelMedium`. On iOS `.adaptive` renders `CupertinoSlider`, which inherits the active color. |
| `DropdownButton` / `DropdownMenu` (Spinner) | `dropdownMenuTheme` | Surface background, 8px corners, palette `primary` focus. For a native iOS wheel picker, use `showCupertinoModalPopup` + `CupertinoPicker` (framework-provided) gated on platform at the call site **only** when a wheel is semantically required; otherwise keep the Material dropdown on both platforms. |
| `DatePicker` | `datePickerTheme` | Palette `primary` header, surface background, 16px corners. Use `showDatePicker` on both platforms. For wheel-style, call `showCupertinoModalPopup` + `CupertinoDatePicker` on iOS only. |
| `TimePicker` | `timePickerTheme` | Same philosophy as date picker. |
| `PopupMenuButton` | `popupMenuTheme` | Surface background, 8px corners, elevation 2, `textStyle: bodyMedium`. |

#### Lists, grids, and content

| Sub-theme | Configuration |
|-----------|---------------|
| `listTileTheme` | `tileColor: transparent`, `selectedTileColor: primary.withOpacity(0.08)`, `selectedColor: primary`, `iconColor: onSurface.withOpacity(0.7)`, `textColor: onSurface`, `contentPadding: symmetric(16, 8)`, `minVerticalPadding: 12`, `titleTextStyle: bodyLarge`, `subtitleTextStyle: bodyMedium` |
| `cardTheme` | `color: surface`, `elevation: 1 on Android / 0 on iOS` (iOS prefers grouped-list look), `shape: RoundedRectangleBorder(12)`, `margin: EdgeInsets.zero` (wrapping padding belongs in layout) |
| `expansionTileTheme` | Palette `primary` iconColor when expanded, flat background |
| `dividerTheme` | `color: dividerColor` (see foundations), `thickness: 0.5 on iOS / 1.0 on Android`, `space: 0`, `indent: 16` for list separators |
| `chipTheme` | `backgroundColor: surface`, `selectedColor: primary.withOpacity(0.12)`, `labelStyle: labelMedium`, `shape: StadiumBorder()`, `padding: symmetric(12, 6)` |

`GridView` has no dedicated theme — cells inherit `textTheme`/`iconTheme` from context, which is sufficient. `Image` and `CachedNetworkImage` have no theme entries either; wrap images in `ClipRRect(borderRadius: 12)` using `AppDimensions` where needed (this is layout, not color theming).

#### Feedback components

These map to Android's `Toast` / `Snackbar` / `AlertDialog` / `ProgressBar` and iOS's `UIAlertController` / `UIActivityIndicatorView`. Use the framework defaults; the theme handles styling.

| Sub-theme | Configuration |
|-----------|---------------|
| `snackBarTheme` | `behavior: SnackBarBehavior.floating` (never `fixed` — bad on iOS notch), `backgroundColor: inverseSurface`, `contentTextStyle: bodyMedium.copyWith(color: onInverseSurface)`, `shape: RoundedRectangleBorder(12)`, `elevation: 3`, `actionTextColor: primary` |
| `dialogTheme` | `backgroundColor: surface`, `elevation: 24 on Android / 0 on iOS`, `shape: RoundedRectangleBorder(28)`, `titleTextStyle: titleMedium`, `contentTextStyle: bodyMedium`. Use `AlertDialog.adaptive` / `showAdaptiveDialog` — on iOS this becomes `CupertinoAlertDialog` (stacked buttons, the iOS standard) |
| `bottomSheetTheme` | `backgroundColor: surface`, `modalBackgroundColor: surface`, `elevation: 0`, `shape: RoundedRectangleBorder(topLeft: 20, topRight: 20)`, `showDragHandle: true`, `dragHandleColor: onSurface.withOpacity(0.3)` |
| `tooltipTheme` | `decoration: BoxDecoration(color: inverseSurface, borderRadius: 8)`, `textStyle: bodySmall.copyWith(color: onInverseSurface)`, `padding: symmetric(12, 8)`, `waitDuration: 500ms` |
| `progressIndicatorTheme` | `color: primary`, `linearTrackColor: primary.withOpacity(0.16)`, `circularTrackColor: primary.withOpacity(0.16)`, `strokeWidth: 3` |
| `bannerTheme` (`MaterialBanner`) | `backgroundColor: surface`, `contentTextStyle: bodyMedium`, `dividerColor: dividerColor` |

Feedback call patterns (zero custom code, zero wrappers):

- **Toast/Snackbar** → `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('...')))`. The `snackBarTheme` styles it. Android has no native Toast in Flutter — `SnackBar` is the idiomatic replacement on both platforms.
- **Alert dialog** → `showAdaptiveDialog(context: ..., builder: (_) => AlertDialog.adaptive(title: ..., content: ..., actions: [...]))`. Styled by `dialogTheme` on Android and automatically cupertino on iOS.
- **Action sheet** → `showModalBottomSheet` on both platforms — the themed `bottomSheetTheme` with drag handle matches iOS expectations. Only fall back to `showCupertinoModalPopup` if you genuinely need the iOS stacked-button look.
- **Inline loading** → `CircularProgressIndicator.adaptive()`. On iOS it renders `CupertinoActivityIndicator` colored by `progressIndicatorTheme`. On Android a themed material spinner.
- **Pull to refresh** → `RefreshIndicator.adaptive(child: ..., onRefresh: ...)`. Cupertino overscroll spinner on iOS, Material drop-down circle on Android.
- **Linear progress** → `LinearProgressIndicator()` colored by `progressIndicatorTheme`. Used sparingly (determinate progress only) — it has no iOS equivalent but looks acceptable.

#### Icons

Use Material `Icons.*` throughout. Where the glyph semantically differs per platform, the framework provides `Icons.adaptive.*`:

| Glyph | `Icons.adaptive.*` |
|-------|--------------------|
| Back | `Icons.adaptive.arrow_back` (chevron on iOS) |
| More | `Icons.adaptive.more` (horizontal on iOS) |
| Share | `Icons.adaptive.share` (iOS share glyph) |

Do not depend on `cupertino_icons` directly — it's pulled in transitively by Flutter, but feature code should never import it.

### The golden rule

Every new widget in feature code looks like:

```
FilledButton(onPressed: ..., child: Text('Save'))
TextField(decoration: InputDecoration(labelText: 'Email'))
Switch.adaptive(value: x, onChanged: ...)
ListTile(title: Text('...'), subtitle: Text('...'))
SnackBar(content: Text('...'))
```

Never:

```
FilledButton(
  style: FilledButton.styleFrom(backgroundColor: Colors.blue, shape: ...),  // inline
  ...
)
Container(
  decoration: BoxDecoration(color: Color(0xFF1565C0), borderRadius: ...),  // raw color
  ...
)
```

If the theme is missing a property, add it to `AppTheme.build` — never override at the call site.

> **⚠️ Maintenance rule — read before adding any new UI component**
>
> Whenever a new widget type is introduced to the app (a new Material component, a newly upgraded Flutter version with a new sub-theme, or a third-party widget with its own theme extension), you MUST:
>
> 1. Add its corresponding sub-theme entry to `AppTheme.build` under the correct section (Foundations / Tap feedback / Top navigation / Buttons / Input & selection / Lists, grids, and content / Feedback / Icons).
> 2. Document the sub-theme in the matching table in this file (`docs/05_THEMING_SYSTEM.md`) so the global theme table stays exhaustive.
> 3. If the widget has platform-specific behavior (ripple, adaptive constructor, Cupertino variant), note it in the same row.
> 4. If the widget needs a new semantic color token that cannot be expressed with existing `ColorScheme` roles, add it to `AppColorPalette` and update all predefined palettes.
>
> A widget used in feature code without a corresponding theme entry is a bug. Code review MUST reject PRs that inline-style a widget instead of extending the theme.

---

## Theme Access Pattern

**File**: `lib/core/extensions/build_context_extensions.dart`

Only 3 theme extensions (each saves real keystrokes on high-frequency calls):

| Extension | Returns | Replaces |
|-----------|---------|----------|
| `context.colorScheme` | `ColorScheme` | `Theme.of(context).colorScheme` |
| `context.textTheme` | `TextTheme` | `Theme.of(context).textTheme` |
| `context.appColors` | `AppColorPalette` | `context.read<ThemeBloc>().state.palette` |

**Not created** (not worth wrapping):
- `context.theme` - `Theme.of(context)` is already short and clear
- `context.isDarkMode` - rarely used; inline `Theme.of(context).brightness == Brightness.dark` when needed

### Usage Rule

Widgets MUST use semantic theme tokens and MUST NOT inline style:
- Never hardcode `Colors.blue` → use `context.colorScheme.primary`
- Never inline `TextStyle(fontSize: 16)` → use `context.textTheme.bodyLarge`
- Never use `Color(0xFF...)` → use palette color via `context.appColors`
- Never pass `style:` / `decoration:` / `shape:` to a themed widget to override visual properties — if the default looks wrong, fix `AppTheme.build`, not the call site
- Never write a custom wrapper widget (`AppButton`, `AppTextField`, `AppCard`, etc.) whose job is styling — use the framework widget directly and let the global theme handle it. Wrappers are only justified for real behavioral composition (e.g. a form field that bundles validation + label + error semantics), not for look-and-feel

---

## Dark Mode Toggle

**Location**: Settings page (and any feature-specific controls that want a quick toggle)

**Behavior**:
1. Toggle emits `ThemeModeChanged(ThemeMode.dark)` or `ThemeModeChanged(ThemeMode.light)`
2. ThemeBloc updates state and persists
3. `MaterialApp.router` rebuilds with new `themeMode`
4. Transition is animated by Flutter's built-in theme animation (~200ms)
