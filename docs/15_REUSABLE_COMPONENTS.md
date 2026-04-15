# 15 — Reusable Components

## Rules

All shared widgets live in `lib/shared/widgets/`:
1. **Stateless when possible** — use `const` constructors.
2. **Theme-aware** — `context.colorScheme`, `context.textTheme`; never hardcoded.
3. **Configurable** — expose meaningful props, not implementation details.
4. **Accessible** — semantics, ≥ 48×48 tap targets.
5. **No styling wrappers** — never create wrappers whose sole purpose is visual styling (see `05_THEMING_SYSTEM.md`). Use framework widgets directly — global theme handles styling. Shared widgets justified only when they add **behavioral composition** (loading states, cached image fallbacks, shimmer placeholders).

## App Loading Page (`app_loading_page.dart`)

Full-screen indicator for initial loads.

| Prop | Type | Default |
|---|---|---|
| `message` | `String?` | `null` |

```
Scaffold → Center → Column(center)
  ├── CircularProgressIndicator(color: colorScheme.primary)
  ├── SizedBox(height: 16)       // if message
  └── Text(message, bodyMedium)  // if message
```

## App Error Page
→ `14_ERROR_HANDLING.md`.

## App Scaffold (`app_scaffold.dart`)

Base scaffold standardizing chrome (AppBar, safe-area, slots).

| Prop | Type | Default |
|---|---|---|
| `title` | `String` | required |
| `body` | `Widget` | required |
| `showBackButton` | `bool` | `true` |
| `actions` | `List<Widget>?` | `null` |
| `floatingActionButton` | `Widget?` | `null` |
| `bottomNavigationBar` | `Widget?` | `null` |

**Behavior:** consistent `AppBar` from theme; safe area handled. **Does NOT** include `ConnectivityBanner` — that lives once at `MaterialApp` level.

## Connectivity Banner
→ `11_CONNECTIVITY_RESILIENCE.md`.

## Buttons, text fields, themed widgets

**Do not create** `AppButton`/`AppTextField`/etc. Use framework widgets directly:

| Need | Use | Why |
|---|---|---|
| Primary CTA | `FilledButton(onPressed, child: Text('Save'))` | `filledButtonTheme` |
| Secondary | `OutlinedButton(...)` | `outlinedButtonTheme` |
| Text action | `TextButton(...)` | `textButtonTheme` |
| Text input | `TextField(decoration: InputDecoration(labelText: 'Email'))` | `inputDecorationTheme` |
| Password | `TextField(obscureText: true, ...)` | framework handles toggle |

**Loading state on a button** — inline (~5 lines, not worth a wrapper). Use `CircularProgressIndicator.adaptive()`; lock size so layout doesn't shift:
```dart
FilledButton(
  onPressed: isLoading ? null : onSubmit,
  child: isLoading
    ? const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
      )
    : const Text('Save'),
)
```

## Auth Form (`lib/features/auth/presentation/widgets/auth_form.dart`)

Behavioral composition — bundles validation, focus chain, autofill, keyboard handling. Not a styling wrapper.

| Prop | Type | Purpose |
|---|---|---|
| `onLoginPressed` | `void Function(String email, String password)` | valid submit |
| `onForgotPasswordPressed` | `void Function(String email)` | "Forgot password?" tap |
| `isLoading` | `bool` | disables fields; swaps button to adaptive spinner |

**Adaptive behaviors built in:**
- `AutofillGroup` wraps both fields — iOS Keychain / Android Autofill.
- `TextInputAction.next` on email → focus password via `FocusNode`.
- `TextInputAction.done` on password → submit if valid, else inline error.
- `HapticFeedback.lightImpact()` before `onLoginPressed`.
- `HapticFeedback.heavyImpact()` + shake on validation failure.
- `keyboardType: TextInputType.emailAddress` on email.
- `keyboardType: TextInputType.visiblePassword` on password.
- `textCapitalization: TextCapitalization.none` on both.
- `TextInput.finishAutofillContext()` after successful login.

**Accessibility:**

| Requirement | Implementation |
|---|---|
| Email field | `Semantics(label: 'Email address', textField: true)` |
| Password field | `Semantics(label: 'Password', obscured: true, textField: true)` |
| Error live region | `Semantics(liveRegion: true)` on error text |
| Show/hide toggle | `Semantics(label: 'Show password'/'Hide password', button: true)` |
| Login button tap target | min `48×52dp` via `filledButtonTheme.minimumSize` |

## KeyboardDismisser (`lib/shared/widgets/keyboard_dismisser.dart`)

Vendored (no package dep). Dismisses keyboard on user gesture. Behavioral contract used across every form screen.

### Usage
```dart
// Per screen (recommended)
KeyboardDismisser(
  gestures: const [
    GestureType.onTap,
    GestureType.onPanUpdateDownDirection,
    GestureType.onPanUpdateUpDirection,
  ],
  child: Scaffold(...),
)

// Global (wraps MaterialApp)
KeyboardDismisser(
  gestures: const [GestureType.onTap, GestureType.onPanUpdateDownDirection],
  child: MaterialApp.router(...),
)
```

### Recommended gesture sets

| Screen | Gestures | Reason |
|---|---|---|
| **Login/Register** (scrollable form) | `onTap`, `onPanUpdateDownDirection`, `onPanUpdateUpDirection` | tap outside + scroll either way |
| **Chat/feed** (vertical scroll) | `onTap`, `onPanUpdateDownDirection` | only downward, avoid fighting upward scroll |
| **Horizontal pager** | `onTap` only | pan gestures conflict with horizontal page swipe |
| **Search** | `onTap`, `onPanUpdateDownDirection` | standard pull-down-to-dismiss |
| **Global / MaterialApp** | `onTap`, `onPanUpdateDownDirection` | conservative default |

### Interaction notes
- Gestures absorbed by child widgets (buttons, fields, list tiles) **do not** bubble up — tapping a button won't dismiss keyboard, only inert areas will.
- Do **not** combine `onPanUpdate*` with `onScaleUpdate` — `GestureDetector` underneath will throw an assertion.
- Do **not** combine `onHorizontalDrag*` with `onVerticalDrag*` simultaneously.
- On nav (push/pop), Flutter auto-dismisses keyboard — this widget is for in-screen cases only.

### Props

| Prop | Type | Default |
|---|---|---|
| `gestures` | `List<GestureType>` | `[GestureType.onTap]` |
| `behavior` | `HitTestBehavior?` | `null` |
| `dragStartBehavior` | `DragStartBehavior` | `.start` |
| `excludeFromSemantics` | `bool` | `false` |
| `child` | `Widget?` | `null` |

**Accessibility:** internal `GestureDetector` doesn't affect screen reader nav; `excludeFromSemantics` is `false` by default. Dismissal is a secondary affordance — no accessible label needed.

## App Image (`app_image.dart`)

Cached network image with loading + error placeholders.

| Prop | Type | Default |
|---|---|---|
| `url` | `String` | required |
| `width` | `double?` | `null` |
| `height` | `double?` | `null` |
| `borderRadius` | `double` | `8.0` |
| `fit` | `BoxFit` | `.cover` |

**States:**
- **Loading** — `ShimmerLoading` placeholder matching dimensions.
- **Error** — colored placeholder with `Icons.broken_image`.
- **Loaded** — cached image, 300 ms fade-in.

Backed by `cached_network_image`.

## Shimmer Loading (`shimmer_loading.dart`)

Skeleton placeholder for not-yet-loaded content.

| Prop | Type | Default |
|---|---|---|
| `width` | `double?` | `double.infinity` |
| `height` | `double` | `16.0` |
| `borderRadius` | `double` | `4.0` |

Custom impl with `AnimationController` + `ShaderMask` (~30 lines, no package). Base color from `colorScheme.surfaceContainerHighest`.

**Predefined skeletons:**
| Name | Description |
|---|---|
| `ShimmerBookCard` | image + 3 text lines |
| `ShimmerBookGrid` | grid of 6 cards |
| `ShimmerReaderPage` | 15 text lines of varying widths |

## Adaptive Layout (`adaptive_layout.dart`)

Responsive wrapper that switches on screen width. Full strategies → `25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md`.

| Prop | Type | Required |
|---|---|---|
| `mobile` | `Widget` | ✓ |
| `tablet` | `Widget?` | — |
| `desktop` | `Widget?` | — |

Uses `LayoutBuilder`; falls back to `mobile` if larger breakpoint widget missing.

**Breakpoints:**
| Name | Range | Use |
|---|---|---|
| Compact (Mobile) | < 600dp | single column, full-width cards |
| Medium (Tablet) | 600–840dp | two-column, side panel, foldables |
| Expanded (Desktop/iPad) | > 840dp | three-column, expanded nav, large iPads |

## Usage rules

1. **Never duplicate** — if it exists in `shared/widgets/`, use it.
2. **Feature-specific widgets** live in the feature's `presentation/widgets/`.
3. **Promote to shared** when used in 2+ features.
4. No inline themes — all components read `context.colorScheme`/`textTheme`.
5. No magic numbers — use `AppDimensions`.

## Accessibility per component

Every shared widget meets (full → `22_ACCESSIBILITY.md`):

| Requirement | Standard | Applies to |
|---|---|---|
| Min tap target 48×48 | Material | all interactive |
| Contrast 4.5:1 | WCAG AA | text on backgrounds |
| Semantics label | VoiceOver/TalkBack | custom interactive / decorative images |
| Font scale tolerance | system settings | all text containers — no fixed heights |
| Live region | screen readers | connectivity banner, error messages |

### Per-widget checklist

| Widget | Tap target | Semantics | Font-scale safe |
|---|---|---|---|
| App Loading Page | — | `Semantics(label: 'Loading')` | ✓ |
| App Error Page | Retry ≥ 48px | error msg readable | ✓ |
| App Scaffold | back ≥ 48px (AppBar default) | automatic | ✓ |
| Connectivity Banner | — (not dismissible) | `Semantics(liveRegion: true)` | ✓ |
| App Image | — (decorative unless tappable) | `ExcludeSemantics` decorative / `Semantics(label:)` meaningful | ✓ |
| Shimmer Loading | — | `ExcludeSemantics` (placeholder) | ✓ |
| Adaptive Layout | — (container) | none needed | ✓ |
