# 05 — Dynamic Theming System

## Goals

1. Zero inline themes — no widget constructs `TextStyle`/`Color`/`ThemeData`.
2. Multiple user-selectable primary palettes.
3. Full dark mode per palette.
4. User-adjustable font scale (0.8–1.4).
5. Centralized typography.
6. Hot-swappable (no restart).
7. Platform-native feel: Material ripples on Android, Cupertino dim on iOS. Adaptive widgets chosen at build time, not runtime branching.
8. Minimal platform code — prefer Flutter's automatic adaptations and `.adaptive` constructors over custom forks.

## Architecture

```
ThemeBloc(state: ThemeState { palette, themeMode, fontScale })
    ↓
AppTheme.build(palette, brightness, fontScale, platform)
    ↓
ThemeData  ⇒  MaterialApp
```

## Color palettes

### `AppColorPalette` (value object)

Semantic colors:

| Property | Purpose |
|---|---|
| `name` | display name |
| `primary`, `primaryVariant` | brand + darker variant |
| `secondary` | accent |
| `surface`, `background` | card vs page bg |
| `error` | error states |
| `onPrimary`/`onSecondary`/`onSurface`/`onBackground`/`onError` | foregrounds |

Add domain-specific tokens only when a role can't be expressed as a Material role. **Name by role, never by call site.**

### Predefined palettes (`app_colors.dart`)

| ID | Name | Primary | Character |
|---|---|---|---|
| `blue` | Ocean Blue | `#1565C0` | Calm/pro |
| `violet` | Royal Violet | `#7B1FA2` | Creative/premium |
| `red` | Crimson Red | `#C62828` | Bold/energetic |
| `orange` | Sunset Orange | `#E65100` | Warm/inviting |
| `pink` | Rose Pink | `#AD1457` | Soft/modern |

Each has light + dark. Dark is not "same colors on dark bg": reduced saturation, adjusted contrast, surface overlays.

**Dark mode adjustments:** primary — reduce sat, bump lightness; surface — near-black (`#121212`) + palette-tinted overlay at low opacity; WCAG AA (4.5:1) for all text; Material 3 elevation overlays.

## Typography (`app_text_styles.dart`)

Material 3 type scale (maps 1:1 onto `TextTheme`):

| Style | Size | Weight | Usage |
|---|---|---|---|
| `displayLarge` | 32 | Bold | Hero |
| `displayMedium` | 28 | Bold | Section |
| `titleLarge` | 22 | SemiBold | Page titles |
| `titleMedium` | 18 | SemiBold | Card titles |
| `titleSmall` | 16 | Medium | Subtitles |
| `bodyLarge` | 16 | Regular | Emphasized body |
| `bodyMedium` | 14 | Regular | Body |
| `bodySmall` | 12 | Regular | Captions |
| `labelLarge` | 14 | Medium | Buttons |
| `labelMedium` | 12 | Medium | Chips/tabs |
| `labelSmall` | 10 | Medium | Overlines |

**Font: Montserrat** — every style sets `fontFamily: 'Montserrat'`. Bundle weights 400/500/600/700 in `assets/fonts/`; register in `pubspec.yaml`. **No `google_fonts`** / no runtime fetch. Monospace family may be declared centrally for code blocks.

**Font scaling** — multiplier on all styles:

| Scale | Label | Factor |
|---|---|---|
| XS | Small | 0.8 |
| S | Compact | 0.9 |
| M | Default | 1.0 |
| L | Large | 1.15 |
| XL | Extra Large | 1.3 |
| XXL | Maximum | 1.4 |

`AppTextStyles.scaled(double factor)` returns a new `TextTheme` with all sizes multiplied.

## ThemeBloc

**Events:**
| Event | Payload |
|---|---|
| `ThemePaletteChanged` | `AppColorPalette` |
| `ThemeModeChanged` | `ThemeMode` |
| `FontScaleChanged` | `double` |
| `ThemeRestored` | — (loads saved on startup) |

**State:** `palette`, `themeMode` (default `system`), `fontScale` (default `1.0`), derived `lightTheme`, `darkTheme`.

**Persistence** — on every change: `theme_palette_id` (String), `theme_mode` (String), `font_scale` (double). `ThemeRestored` reads + applies on app start.

## `AppTheme.build` factory

```dart
static ThemeData build({
  required AppColorPalette palette,
  required Brightness brightness,
  required double fontScale,
  required TargetPlatform platform,
})
```

**API notes:**
- Use normalized `*ThemeData` suffix classes (`AppBarThemeData`, `CardThemeData`, `DialogThemeData`, `TabBarThemeData`, `InputDecorationThemeData`). **Not** the widget-name form — that refers to the `Theme` wrapper widgets.
- Use `WidgetStateProperty` (not deprecated `MaterialStateProperty`).
- Use `Color.withValues(alpha: 0.12)` (not `.withOpacity(0.12)`, deprecated in 3.27+). Docs below use `.withOpacity` for readability — real code uses `.withValues`.

**The one rule:** every visual property for every component lives in this factory. Feature code never sets `color:`, `padding:`, `shape:`, `textStyle:`, `elevation:`, `borderRadius:`, or inline styling. If it looks wrong, **fix the theme**, not the call site.

- No custom wrapper widgets (`AppButton`, `AppTextField`, `AppCard`, …). Use framework widgets directly.
- Platform differences (ripple, transitions, cupertino variants) baked into `ThemeData` via `platform` — widgets never branch on `Platform.isIOS`.
- For per-instance platform swaps, use `.adaptive` constructors: `Switch.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`, `RefreshIndicator.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `AlertDialog.adaptive`, `Icons.adaptive.*`, `showAdaptiveDialog`.
- Before writing custom platform forks, check Flutter's automatic adaptations first.

## Global theme table

### Foundations

| Sub-theme | Value |
|---|---|
| `colorScheme` | `ColorScheme.fromSeed(seedColor: palette.primary, brightness)` then override with palette tokens (`primary`/`secondary`/`surface`/`error` + `on*`) |
| `textTheme` | `AppTextStyles.scaled(fontScale)` bound to `onSurface` |
| `primaryTextTheme` | same, color = `onPrimary` |
| `iconTheme` | `onSurface`, size 24 |
| `primaryIconTheme` | `onPrimary`, size 24 |
| `scaffoldBackgroundColor` | `background` |
| `canvasColor` | `surface` |
| `dividerColor` | `onSurface.withOpacity(0.12)` — the **one** separator color everywhere |
| `shadowColor` | `Colors.black.withOpacity(0.08)` |
| `disabledColor` | `onSurface.withOpacity(0.38)` |
| `hintColor` | `onSurface.withOpacity(0.60)` |
| `visualDensity` | `adaptivePlatformDensity` |
| `materialTapTargetSize` | `padded` |

### Tap feedback (the iOS-no-ripple rule)

| Sub-theme | iOS / macOS | Android |
|---|---|---|
| `splashFactory` | `NoSplash.splashFactory` | `InkSparkle.splashFactory` |
| `splashColor` | `Colors.transparent` | `primary.withOpacity(0.12)` |
| `highlightColor` | `onSurface.withOpacity(0.08)` (instant Cupertino dim) | `primary.withOpacity(0.10)` |
| `pageTransitionsTheme` | `CupertinoPageTransitionsBuilder` (keeps edge-swipe back) | `ZoomPageTransitionsBuilder` |

Result: Material ripples on Android; iOS `InkWell`/`ListTile`/buttons/chips show instant opacity dim like `CupertinoButton`. 100% via theme — feature code uses `InkWell`/buttons normally.

### Top navigation

| Sub-theme | Value |
|---|---|
| `appBarTheme` | bg=`surface`, fg=`onSurface`, `elevation:0`, `scrolledUnderElevation:3`, `centerTitle: platform==iOS`, `titleTextStyle: titleLarge`, `systemOverlayStyle` from brightness |
| `tabBarTheme` | `labelColor: primary`, unselected `onSurface.withOpacity(0.6)`, `indicatorColor: primary`, `indicatorSize: label`, `dividerColor: transparent`, iOS `overlayColor: transparent` |
| `segmentedButtonTheme` | selected bg=`primary`, `StadiumBorder`, text=`onPrimary` (Material 3 segmented filter) |
| `bottomNavigationBarTheme` | legacy 3-item. selected=`primary`, unselected `onSurface.withOpacity(0.6)`, bg=`surface`, `elevation:0`, `showUnselectedLabels:true` |
| `navigationBarTheme` (M3) | `indicatorColor: primary.withOpacity(0.15)`, `labelTextStyle: labelMedium`, palette `iconTheme`, `height:72`, `elevation:0` |
| `navigationRailTheme` | tablets — palette selected, 72px width |
| `drawerTheme` | bg=`surface`, `elevation:1`, shape: top/bottom-right radius 16 |

Use native `AppBar`/`TabBar`/`NavigationBar`/`SegmentedButton` directly. For iOS "pill segmented filter", `SegmentedButton` with `StadiumBorder` + selected-primary renders identically to `CupertinoSlidingSegmentedControl` — keep the single Material widget.

### Buttons

| Sub-theme | Value |
|---|---|
| `filledButtonTheme` | Primary CTA. bg=`primary`, fg=`onPrimary`, `labelLarge`, `minimumSize: (64,48)`, `StadiumBorder`, padding `(24,0)` |
| `elevatedButtonTheme` | same + `elevation:0` (flat), legacy call sites |
| `outlinedButtonTheme` | fg=`primary`, border=`primary`, `StadiumBorder`, `(64,48)` |
| `textButtonTheme` | fg=`primary`, `labelLarge`, `(48,40)` |
| `iconButtonTheme` | fg=`onSurface`, padding 12, icon 24, `CircleBorder` |
| `floatingActionButtonTheme` | bg=`primary`, fg=`onPrimary`, radius 16, elevation 3 Android / 0 iOS |
| `menuButtonTheme`/`dropdownMenuTheme` | palette-tinted hover, surface bg, 8px corners |

One shape language: stadium for CTAs, circle for icon buttons, 16px rect for FAB. No per-screen overrides.

### Input & selection (Android `Switch`/`CheckBox`/`RadioButton`/`Spinner`/`SeekBar`; iOS `UISwitch`/`UIPickerView`/`UISlider`)

Use defaults with `.adaptive` where Flutter ships a Cupertino variant. Styling global, no wrappers.

| Widget | Sub-theme | Notes |
|---|---|---|
| `TextField`/`TextFormField` | `inputDecorationTheme` | `filled:true`, `fillColor:surface`, `OutlineInputBorder(12)`, focus border `primary`, error border `error`, padding `(16,14)`, `labelStyle: bodyMedium`, hint `bodyMedium.copyWith(color:hint)`. Cursor `primary`. Selection handle platform-default (Flutter handles automatically). |
| `Switch`/`.adaptive` | `switchTheme` | `thumb`/`trackColor` WidgetStateProperty → `primary`/`primary.withOpacity(0.5)`. iOS `CupertinoSwitch` picks palette via `activeColor`. |
| `Checkbox`/`.adaptive` | `checkboxTheme` | `fill: primary selected`, check=`onPrimary`, `RRect(4)`, side `onSurface.withOpacity(0.6)`. iOS renders filled-circle via `.adaptive`. |
| `Radio`/`.adaptive` | `radioTheme` | `fill: primary selected / onSurface unselected` |
| `Slider`/`.adaptive` (SeekBar) | `sliderTheme` | active `primary`, inactive `primary.withOpacity(0.24)`, thumb `primary`, overlay `primary.withOpacity(0.12)`, `trackHeight:4`, `valueIndicatorColor: primary`, `valueIndicatorTextStyle: labelMedium`. iOS `.adaptive` → `CupertinoSlider` inheriting active color. |
| `DropdownButton`/`DropdownMenu` (Spinner) | `dropdownMenuTheme` | surface bg, 8px, focus `primary`. Native iOS wheel: `showCupertinoModalPopup` + `CupertinoPicker` **only** when a wheel is semantically required — else keep Material dropdown on both. |
| `DatePicker` | `datePickerTheme` | header `primary`, surface bg, 16px. Use `showDatePicker` both platforms. Wheel style → `CupertinoDatePicker` via modal popup on iOS only. |
| `TimePicker` | `timePickerTheme` | same philosophy |
| `PopupMenuButton` | `popupMenuTheme` | surface, 8px, elevation 2, `bodyMedium` |

### Adaptive form & input patterns (behavioral — call site, not `ThemeData`)

Documented here because they're platform-native expectations that must be applied wherever a form appears.

| Pattern | API | Rule |
|---|---|---|
| **Autofill** | `AutofillGroup` + `autofillHints` | Always wrap credential forms. Email `[AutofillHints.email]`; password `[AutofillHints.password]`. Triggers Keychain (iOS) / Autofill (Android). Call `TextInput.finishAutofillContext()` after successful login. |
| **Keyboard type** | `keyboardType` | Email: `emailAddress` (`@` key). Password: `visiblePassword` (disables suggestions). |
| **Keyboard action** | `textInputAction` | Non-last: `next`. Last/single: `done`. Chain fields via `FocusNode` + `onSubmitted`. |
| **Keyboard avoidance** | `Scaffold(resizeToAvoidBottomInset: true)` + `SingleChildScrollView` | Keeps fields visible. No fixed-height containers in auth forms. |
| **Haptic** | `HapticFeedback` (services) | Primary CTA tap → `lightImpact()` before dispatch. Error/shake → `heavyImpact()`. No-op on Android (OS drives vibration via ripple); provides iOS tactile. **Never** on secondary/text buttons. |
| **Loading in button** | `CircularProgressIndicator.adaptive()` | Fix button dims with `SizedBox` so layout doesn't shift when label → spinner. |
| **Error dialogs** | `showAdaptiveDialog`/`AlertDialog.adaptive` | Auth errors rendered as dialogs → `CupertinoAlertDialog` on iOS (stacked buttons), Material on Android. |
| **Capitalization** | `textCapitalization` | Email `none`; name `words`; message `sentences`. |
| **Keyboard dismissal on gesture** | `KeyboardDismisser` (`lib/shared/widgets/keyboard_dismisser.dart`) | Wrap `Scaffold` (or `MaterialApp` for global). Forms gestures: `[onTap, onPanUpdateDownDirection, onPanUpdateUpDirection]`. Do NOT combine `onPanUpdate*` with `onScaleUpdate`; do NOT combine horizontal + vertical drag simultaneously. Nav dismissal is handled by Flutter. See `15_REUSABLE_COMPONENTS.md`. |

### Lists, grids, content

| Sub-theme | Value |
|---|---|
| `listTileTheme` | `tileColor:transparent`, `selectedTileColor: primary.withOpacity(0.08)`, `selectedColor: primary`, icon `onSurface.withOpacity(0.7)`, text `onSurface`, padding `(16,8)`, `minVerticalPadding:12`, title `bodyLarge`, subtitle `bodyMedium` |
| `cardTheme` | `color:surface`, elevation 1 Android / 0 iOS (iOS grouped-list look), `RRect(12)`, `margin:zero` (padding belongs to layout) |
| `expansionTileTheme` | expanded iconColor `primary`, flat bg |
| `dividerTheme` | `color:dividerColor`, thickness 0.5 iOS / 1.0 Android, `space:0`, indent 16 for list separators |
| `chipTheme` | bg `surface`, selected `primary.withOpacity(0.12)`, `labelMedium`, `StadiumBorder`, padding `(12,6)` |

`GridView` has no theme (cells inherit `textTheme`/`iconTheme`). `Image`/`CachedNetworkImage` have no theme either; wrap in `ClipRRect(12)` via `AppDimensions` — layout, not color.

### Feedback (Android Toast/Snackbar/AlertDialog/ProgressBar; iOS `UIAlertController`/`UIActivityIndicatorView`)

| Sub-theme | Value |
|---|---|
| `snackBarTheme` | `behavior: floating` (never `fixed` — bad on iOS notch), bg `inverseSurface`, text `bodyMedium.copyWith(color:onInverseSurface)`, `RRect(12)`, elevation 3, `actionTextColor: primary` |
| `dialogTheme` | bg `surface`, elevation 24 Android / 0 iOS, `RRect(28)`, title `titleMedium`, content `bodyMedium`. Use `AlertDialog.adaptive`/`showAdaptiveDialog` → `CupertinoAlertDialog` on iOS |
| `bottomSheetTheme` | bg `surface`, modal bg `surface`, `elevation:0`, top-left/right radius 20, `showDragHandle:true`, handle `onSurface.withOpacity(0.3)` |
| `tooltipTheme` | decoration: `inverseSurface` + `RRect(8)`, text `bodySmall.copyWith(color:onInverseSurface)`, padding `(12,8)`, `waitDuration: 500ms` |
| `progressIndicatorTheme` | `color: primary`, linear/circular track `primary.withOpacity(0.16)`, `strokeWidth:3` |
| `bannerTheme` (`MaterialBanner`) | bg `surface`, `bodyMedium`, `dividerColor` |

**Feedback call patterns (no wrappers):**
- **Toast/Snackbar** — `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))`. Android has no Flutter Toast — `SnackBar` is the idiomatic replacement on both platforms.
- **Alert dialog** — `showAdaptiveDialog(context: ..., builder: (_) => AlertDialog.adaptive(...))`. Styled by `dialogTheme` Android / auto Cupertino iOS.
- **Action sheet** — `showModalBottomSheet` on both (themed `bottomSheetTheme` + drag handle matches iOS). Only fall back to `showCupertinoModalPopup` if the iOS stacked-button look is required.
- **Inline loading** — `CircularProgressIndicator.adaptive()` — `CupertinoActivityIndicator` iOS, Material Android.
- **Pull to refresh** — `RefreshIndicator.adaptive(child, onRefresh)` — Cupertino overscroll iOS, Material Android.
- **Linear progress** — `LinearProgressIndicator()` via `progressIndicatorTheme`. Used sparingly (determinate only). No iOS equivalent but acceptable.

### Icons

Use `Icons.*`. Where semantics differ per platform, use `Icons.adaptive.*`:

| Glyph | Adaptive |
|---|---|
| Back | `Icons.adaptive.arrow_back` (chevron iOS) |
| More | `Icons.adaptive.more` (horizontal iOS) |
| Share | `Icons.adaptive.share` (iOS share glyph) |

Do not import `cupertino_icons` in feature code (Flutter pulls transitively).

## The golden rule

Feature code looks like:
```dart
FilledButton(onPressed: ..., child: Text('Save'))
TextField(decoration: InputDecoration(labelText: 'Email'))
Switch.adaptive(value: x, onChanged: ...)
ListTile(title: Text('...'), subtitle: Text('...'))
SnackBar(content: Text('...'))
```

**Never:**
```dart
FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.blue, ...))
Container(decoration: BoxDecoration(color: Color(0xFF1565C0), ...))
```

If the theme is missing a property, **add it to `AppTheme.build`** — never override at call site.

> **⚠️ Maintenance rule — read before adding any new UI component**
>
> When a new widget type is introduced (new Material component / new Flutter version sub-theme / third-party widget with theme extension) you MUST:
>
> 1. Add its sub-theme entry to `AppTheme.build` under the right section (Foundations / Tap feedback / Top navigation / Buttons / Input & selection / Lists / Feedback / Icons).
> 2. Document the sub-theme in the matching table here so the global table stays exhaustive.
> 3. If platform-specific (ripple, adaptive, Cupertino variant) — note it in the row.
> 4. If it needs a new semantic token not expressible as `ColorScheme` roles — add it to `AppColorPalette` and update every predefined palette.
>
> A widget used in feature code without a corresponding theme entry is a bug. Code review MUST reject PRs that inline-style instead of extending the theme.

## Theme access (`build_context_extensions.dart`)

Only 3 theme extensions:

| Extension | Returns | Replaces |
|---|---|---|
| `context.colorScheme` | `ColorScheme` | `Theme.of(context).colorScheme` |
| `context.textTheme` | `TextTheme` | `Theme.of(context).textTheme` |
| `context.appColors` | `AppColorPalette` | `context.read<ThemeBloc>().state.palette` |

**Not created:** `context.theme` (`Theme.of(context)` is already short); `context.isDarkMode` (inline `Theme.of(context).brightness == Brightness.dark` when rarely needed).

### Usage rule

Widgets MUST use semantic theme tokens:
- Never hardcode `Colors.blue` → `context.colorScheme.primary`.
- Never inline `TextStyle(fontSize: 16)` → `context.textTheme.bodyLarge`.
- Never `Color(0xFF...)` → palette via `context.appColors`.
- Never pass `style:`/`decoration:`/`shape:` to override visuals — fix `AppTheme.build` instead.
- **No custom wrapper widgets** whose job is styling (`AppButton`, `AppTextField`, `AppCard`, …). Use framework widgets + global theme. Wrappers justified only for real behavioral composition (e.g. a form field bundling validation + label + error semantics).

## Dark mode toggle

Settings page (and any quick toggle). Flow:
1. Emit `ThemeModeChanged(ThemeMode.dark|light)`.
2. `ThemeBloc` updates state + persists.
3. `MaterialApp.router` rebuilds with new `themeMode`.
4. Flutter's built-in theme animation (~200ms) crossfades.
