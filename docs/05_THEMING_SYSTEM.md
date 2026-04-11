# 05 - Dynamic Theming System

## Design Goals

1. **Zero inline themes** - no widget ever constructs `TextStyle`, `Color`, or `ThemeData` directly
2. **Multiple primary palettes** - blue, violet, red, orange, pink (user-selectable)
3. **Night mode** - full dark theme support per palette
4. **Font scaling** - user-adjustable text size (0.8x to 1.4x)
5. **Centralized typography** - one source of truth for all text styles
6. **Hot-swappable** - theme changes apply instantly without restart

---

## Architecture

```
ThemeBloc (state: ThemeState)
    ├── currentPalette: AppColorPalette
    ├── themeMode: ThemeMode (light/dark/system)
    └── fontScale: double (0.8 - 1.4)
           │
           ▼
    AppTheme.build(palette, mode, fontScale)
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
| `name` | `String` | Display name ("Ocean Blue") |
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
| `readerBackground` | `Color` | Reader-specific background |
| `readerText` | `Color` | Reader-specific text color |
| `readerAccent` | `Color` | Highlights, links in reader |

### Predefined Palettes

**File**: `lib/core/theme/app_colors.dart`

| Palette ID | Name | Primary | Character |
|-----------|------|---------|-----------|
| `blue` | Ocean Blue | `#1565C0` | Calm, professional |
| `violet` | Royal Violet | `#7B1FA2` | Creative, premium |
| `red` | Crimson Red | `#C62828` | Bold, energetic |
| `orange` | Sunset Orange | `#E65100` | Warm, inviting |
| `pink` | Rose Pink | `#AD1457` | Soft, modern |

Each palette has both **light** and **dark** variants. The dark variant is NOT just "same colors on dark background" - it has reduced saturation, adjusted contrast ratios, and reader-specific tweaks.

### Dark Mode Adjustments Per Palette

- Primary color: reduce saturation by 15%, increase lightness by 10%
- Surface: `#121212` base with palette-tinted overlay at 5% opacity
- Reader background: `#1A1A1A` (pure dark, no palette tint - reduces eye strain)
- Reader text: `#E0E0E0` (not pure white - reduces glare)
- All text meets WCAG AA contrast ratio (4.5:1 minimum)

---

## Typography System

### AppTextStyles (Centralized)

**File**: `lib/core/theme/app_text_styles.dart`

All text styles are defined once and derive from a base configuration:

| Style Name | Base Size | Weight | Usage |
|-----------|-----------|--------|-------|
| `displayLarge` | 32sp | Bold | Hero headings |
| `displayMedium` | 28sp | Bold | Section headings |
| `titleLarge` | 22sp | SemiBold | Page titles |
| `titleMedium` | 18sp | SemiBold | Card titles |
| `titleSmall` | 16sp | Medium | Subtitles |
| `bodyLarge` | 16sp | Regular | Default reader text |
| `bodyMedium` | 14sp | Regular | General body text |
| `bodySmall` | 12sp | Regular | Captions, metadata |
| `labelLarge` | 14sp | Medium | Buttons |
| `labelMedium` | 12sp | Medium | Chips, tabs |
| `labelSmall` | 10sp | Medium | Overlines |

### Font Family

- **Primary**: Google Fonts `Merriweather` (serif - optimized for reading)
- **Secondary**: Google Fonts `Inter` (sans-serif - UI elements)
- **Monospace**: Google Fonts `JetBrains Mono` (code snippets if any)

The reader uses the serif font; the app chrome uses sans-serif.

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
| `palette` | `AppColorPalette` | `AppColors.blue` |
| `themeMode` | `ThemeMode` | `ThemeMode.system` |
| `fontScale` | `double` | `1.0` |
| `lightTheme` | `ThemeData` | (derived) |
| `darkTheme` | `ThemeData` | (derived) |

### Persistence

On every state change, ThemeBloc persists to `SharedPreferences`:
- `theme_palette_id` → `String`
- `theme_mode` → `String` ("light", "dark", "system")
- `font_scale` → `double`

On `ThemeRestored` event (called at app start), these values are read and applied.

---

## AppTheme Factory

**File**: `lib/core/theme/app_theme.dart`

**Method**: `static ThemeData build({required AppColorPalette palette, required Brightness brightness, required double fontScale})`

This factory produces a complete `ThemeData` from a palette:

### What it configures:
- `colorScheme` - from palette colors
- `textTheme` - from `AppTextStyles.scaled(fontScale)` with palette text colors
- `appBarTheme` - palette primary, no elevation, consistent text
- `cardTheme` - palette surface, standard elevation, rounded corners
- `elevatedButtonTheme` - palette primary, rounded, minimum size
- `outlinedButtonTheme` - palette primary outline, transparent fill
- `inputDecorationTheme` - palette-aware borders, labels, focus colors
- `bottomNavigationBarTheme` - palette primary selected, surface background
- `dividerTheme` - subtle palette-tinted divider
- `scaffoldBackgroundColor` - palette background
- `pageTransitionsTheme` - platform-adaptive transitions
- `splashFactory` - `InkSparkle` on Android, `NoSplash` on iOS

---

## Extension Access Pattern

**File**: `lib/core/theme/theme_extensions.dart`

Widgets access theme values through extensions on `BuildContext`:

| Extension | Returns | Shortcut For |
|-----------|---------|-------------|
| `context.theme` | `ThemeData` | `Theme.of(context)` |
| `context.colorScheme` | `ColorScheme` | `Theme.of(context).colorScheme` |
| `context.textTheme` | `TextTheme` | `Theme.of(context).textTheme` |
| `context.appColors` | `AppColorPalette` | Current palette from ThemeBloc |
| `context.isDarkMode` | `bool` | `Theme.of(context).brightness == Brightness.dark` |

### Usage Rule

Widgets MUST use these extensions instead of:
- Hardcoded `Colors.blue` → use `context.colorScheme.primary`
- Inline `TextStyle(fontSize: 16)` → use `context.textTheme.bodyLarge`
- `Color(0xFF...)` → use semantic color from palette

---

## Night Mode Toggle

**Location**: Reader controls bar and Settings page

**Behavior**:
1. Toggle emits `ThemeModeChanged(ThemeMode.dark)` or `ThemeModeChanged(ThemeMode.light)`
2. ThemeBloc updates state and persists
3. `MaterialApp.router` rebuilds with new `themeMode`
4. Transition is animated by Flutter's built-in theme animation (~200ms)

**Reader-specific**: The reader page may additionally adjust:
- Reader background color (darker than app dark mode)
- Text color (warmer white for less blue light)
- UI chrome opacity (dimmed controls in dark mode)
