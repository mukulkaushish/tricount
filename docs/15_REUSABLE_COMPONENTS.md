# 15 - Reusable Components

## Component Catalog

All reusable widgets live in `lib/shared/widgets/` and follow these rules:

1. **Stateless when possible** - use const constructors
2. **Theme-aware** - use `context.colorScheme` and `context.textTheme`, never hardcoded values
3. **Configurable** - expose meaningful props, not implementation details
4. **Accessible** - include semantics, adequate touch targets (48x48 minimum)
5. **No styling wrappers** - do not create wrapper widgets whose sole purpose is visual styling (see 05_THEMING_SYSTEM.md). Use framework widgets (`FilledButton`, `TextField`, `Switch.adaptive`, etc.) directly — the global theme handles styling. Shared widgets are justified only when they add **behavioral composition** (e.g., loading states, cached image fallbacks, shimmer placeholders)

---

## App Loading Page

**File**: `lib/shared/widgets/app_loading_page.dart`

Full-screen loading indicator shown during initial data loads.

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `message` | `String?` | `null` | Optional loading message |

### Layout
```
Scaffold
└── Center
    └── Column(mainAxisAlignment: center)
        ├── CircularProgressIndicator(color: colorScheme.primary)
        ├── SizedBox(height: 16)  [if message != null]
        └── Text(message, style: bodyMedium)  [if message != null]
```

---

## App Error Page

(See 14_ERROR_HANDLING.md for full specification)

---

## App Scaffold

**File**: `lib/shared/widgets/app_scaffold.dart`

A base scaffold that standardizes common page chrome such as the app bar,
safe-area handling, and page-level slots.

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `title` | `String` | required | AppBar title |
| `body` | `Widget` | required | Page content |
| `showBackButton` | `bool` | `true` | Show/hide back nav |
| `actions` | `List<Widget>?` | `null` | AppBar actions |
| `floatingActionButton` | `Widget?` | `null` | FAB |
| `bottomNavigationBar` | `Widget?` | `null` | Bottom nav |

### Behavior
- Applies consistent `AppBar` styling from theme
- Handles safe area insets
- Does NOT include the connectivity banner; that lives once at the
  `MaterialApp` level via `ConnectivityBanner`

---

## Connectivity Banner

(See 11_CONNECTIVITY_RESILIENCE.md for full specification)

---

## Buttons, Text Fields, and Other Themed Widgets

**Do not create** `AppButton`, `AppTextField`, or similar styling wrappers. Use framework widgets directly:

| Need | Use | Why |
|------|-----|-----|
| Primary CTA | `FilledButton(onPressed: ..., child: Text('Save'))` | Styled by `filledButtonTheme` |
| Secondary action | `OutlinedButton(onPressed: ..., child: Text('Cancel'))` | Styled by `outlinedButtonTheme` |
| Text action | `TextButton(onPressed: ..., child: Text('Skip'))` | Styled by `textButtonTheme` |
| Text input | `TextField(decoration: InputDecoration(labelText: 'Email'))` | Styled by `inputDecorationTheme` |
| Password input | `TextField(obscureText: true, decoration: ...)` | Framework handles toggle |

For loading state on a button, handle inline — it's ~5 lines, not worth a wrapper. Use `CircularProgressIndicator.adaptive()` so iOS renders `CupertinoActivityIndicator` and Android renders the Material spinner. Lock the button size so layout does not shift:

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

---

## Auth Form

**File**: `lib/features/auth/presentation/widgets/auth_form.dart`

Behavioral composition widget for the login credential form. Justified as a shared widget because it bundles validation logic, focus chain management, autofill context, and keyboard handling — not just visual styling.

| Prop | Type | Purpose |
|------|------|---------|
| `onLoginPressed` | `void Function(String email, String password)` | Called on valid submit |
| `onForgotPasswordPressed` | `void Function(String email)` | Called when "Forgot Password?" is tapped |
| `isLoading` | `bool` | Disables fields and swaps button label to adaptive spinner |

### Adaptive behaviors built into this widget

- **`AutofillGroup`** wraps both fields — triggers iOS Keychain / Android Autofill
- **`TextInputAction.next`** on email → moves focus to password field via `FocusNode`
- **`TextInputAction.done`** on password → submits if valid, else shows inline error
- **`HapticFeedback.lightImpact()`** fired before `onLoginPressed` is called
- **`HapticFeedback.heavyImpact()`** + shake animation on validation failure
- **`keyboardType: TextInputType.emailAddress`** on email field
- **`keyboardType: TextInputType.visiblePassword`** on password field
- **`textCapitalization: TextCapitalization.none`** on both fields
- Calls `TextInput.finishAutofillContext()` after successful login signal

### Accessibility

| Requirement | Implementation |
|---|---|
| Email field semantics | `Semantics(label: 'Email address', textField: true)` |
| Password field semantics | `Semantics(label: 'Password', obscured: true, textField: true)` |
| Error message live region | `Semantics(liveRegion: true)` on error text below field |
| Show/hide password toggle | `Semantics(label: 'Show password' / 'Hide password', button: true)` |
| Login button tap target | Min `48×52dp` — enforced by `filledButtonTheme.minimumSize` |

---

## KeyboardDismisser

**File**: `lib/shared/widgets/keyboard_dismisser.dart`

A behavioral wrapper that dismisses the software keyboard when the user performs a gesture. Vendored directly into the project (no external package dependency).

Justified as a shared widget because it provides a reusable behavioral contract used across every form screen — not visual styling.

### Usage

Wrap a `Scaffold` (or the entire `MaterialApp` for global coverage):

```dart
// Per-screen (recommended for most cases)
KeyboardDismisser(
  gestures: const [
    GestureType.onTap,
    GestureType.onPanUpdateDownDirection,
    GestureType.onPanUpdateUpDirection,
  ],
  child: Scaffold(...),
)

// Global — wrapping MaterialApp dismisses keyboard on every screen
KeyboardDismisser(
  gestures: const [
    GestureType.onTap,
    GestureType.onPanUpdateDownDirection,
  ],
  child: MaterialApp.router(...),
)
```

### Recommended gesture sets by screen type

| Screen type | Recommended gestures | Reason |
|---|---|---|
| **Login / Register** (scrollable form) | `onTap`, `onPanUpdateDownDirection`, `onPanUpdateUpDirection` | Dismiss on tap outside + scroll in either direction |
| **Chat / feed** (vertical scroll dominant) | `onTap`, `onPanUpdateDownDirection` | Only dismiss on downward swipe to avoid fighting upward scrolling |
| **Horizontal pager** | `onTap` only | Pan gestures conflict with horizontal page swipe |
| **Search** | `onTap`, `onPanUpdateDownDirection` | Standard search-dismiss pattern (pull down to dismiss) |
| **Global / MaterialApp level** | `onTap`, `onPanUpdateDownDirection` | Conservative default — covers most cases without gesture conflicts |

### Important interaction notes

- Gestures **absorbed by child widgets** (buttons, text fields, list tiles) do **not** bubble up — tapping a button will not dismiss the keyboard, only taps on inert areas will.
- Do **not** combine `onPanUpdate*` gestures with `onScaleUpdate` — the `GestureDetector` underneath will throw an assertion.
- Do **not** combine `onHorizontalDrag*` with `onVerticalDrag*` simultaneously.
- On **navigation** (route push/pop), Flutter automatically dismisses the keyboard — `KeyboardDismisser` is not needed for that case.

### Props

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `gestures` | `List<GestureType>` | `[GestureType.onTap]` | Which gestures trigger dismissal |
| `behavior` | `HitTestBehavior?` | `null` | Hit test behavior of internal `GestureDetector` |
| `dragStartBehavior` | `DragStartBehavior` | `.start` | When a drag formally begins |
| `excludeFromSemantics` | `bool` | `false` | Exclude gesture detector from semantics tree |
| `child` | `Widget?` | `null` | Wrapped widget |

### Accessibility

The `GestureDetector` inside does not affect screen reader navigation — `excludeFromSemantics` is `false` by default so the widget tree remains accessible. The unfocus action itself does not require an accessible label since the keyboard dismissal is a secondary affordance, not a primary action.

---

## App Image

**File**: `lib/shared/widgets/app_image.dart`

Cached network image with loading and error placeholders.

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `url` | `String` | required | Image URL |
| `width` | `double?` | `null` | Fixed width |
| `height` | `double?` | `null` | Fixed height |
| `borderRadius` | `double` | `8.0` | Corner radius |
| `fit` | `BoxFit` | `.cover` | Image fit |

### States
- **Loading**: `ShimmerLoading` placeholder matching dimensions
- **Error**: Colored placeholder with `Icons.broken_image`
- **Loaded**: Cached image with fade-in animation (300ms)

Backed by `cached_network_image` package.

---

## Shimmer Loading

**File**: `lib/shared/widgets/shimmer_loading.dart`

Skeleton placeholder for content that hasn't loaded yet.

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `width` | `double?` | `double.infinity` | Width |
| `height` | `double` | `16.0` | Height |
| `borderRadius` | `double` | `4.0` | Corner radius |

Custom implementation using `AnimationController` + `ShaderMask` (~30 lines, no package). Base color derived from `colorScheme.surfaceContainerHighest`.

### Predefined Skeletons

| Skeleton | Description |
|----------|-------------|
| `ShimmerBookCard` | Book card placeholder (image + 3 text lines) |
| `ShimmerBookGrid` | Grid of 6 `ShimmerBookCard` items |
| `ShimmerReaderPage` | 15 text line placeholders of varying widths |

---

## Responsive Grid Components

Grid layouts are the **primary pattern for content browsing** across all screen sizes. Rather than creating custom layout wrappers, use native `GridView` with breakpoint-aware column counts. See **[25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md § Grid Layouts](25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md#grid-layouts-primary-pattern-for-content-browsing)** for complete grid implementation guidance including foldables and iPad multitasking.

### Grid Component Pattern

Create a reusable grid widget per feature. Example: `BillsGridView` for the bills list.

**File**: `lib/features/bills/presentation/widgets/bills_grid_view.dart`

```dart
import 'package:tricount/core/theme/theme_extensions.dart';
import 'package:tricount/core/theme/app_dimensions.dart';

class BillsGridView extends StatelessWidget {
  final List<Bill> bills;
  final void Function(Bill)? onTapBill;

  const BillsGridView({
    required this.bills,
    this.onTapBill,
  });

  @override
  Widget build(BuildContext context) {
    // Compute column count from existing breakpoints
    final crossAxisCount = context.isCompact ? 2 :      // Phones: 2
                           context.isMedium ? 3 :       // Tablets: 3
                           context.isExpanded ? 4 : 5;  // iPad/Large: 4-5

    return GridView.builder(
      padding: context.responsiveContentPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.s16,
        crossAxisSpacing: AppDimensions.s16,
        childAspectRatio: 1.0,
      ),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return BillCard(
          bill: bill,
          onTap: () => onTapBill?.call(bill),
        );
      },
    );
  }
}
```

### Grid Card Components

Cards used in grids should be **theme-aware** and **configurable**:

| Property | Default | Notes |
|----------|---------|-------|
| `bill` (or entity) | required | The data model |
| `onTap` | optional | Callback when card is tapped |
| `showBadge` | `true` | Display status badge (settled, pending) |

**File**: `lib/features/bills/presentation/widgets/bill_card.dart`

```dart
class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onTap;
  final bool showBadge;

  const BillCard({
    required this.bill,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bill.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall,
              ),
              SizedBox(height: AppDimensions.s8),
              Text(
                '\$${bill.amount.toStringAsFixed(2)}',
                style: context.textTheme.headlineSmall
                    ?.copyWith(color: context.colorScheme.primary),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bill.paidBy,
                    style: context.textTheme.labelSmall,
                  ),
                  if (showBadge)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.s8,
                        vertical: AppDimensions.s4,
                      ),
                      decoration: BoxDecoration(
                        color: bill.isSettled
                            ? context.colorScheme.tertiary
                            : context.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppDimensions.r4),
                      ),
                      child: Text(
                        bill.isSettled ? 'Settled' : 'Pending',
                        style: context.textTheme.labelSmall
                            ?.copyWith(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Accessibility for Grid Cards

- **Tap target >= 48dp** — Entire card is tappable (GestureDetector)
- **Semantics** — Frame as `Semantics(button: true, child: GestureDetector(...))`
- **Text contrast** — Use `context.colorScheme` (already contrast-checked)
- **Overflow** — Always use `maxLines` + `TextOverflow.ellipsis` to prevent layout shift

### When NOT to Create Custom Layout Wrappers

Do not create `AdaptiveLayoutBuilder`, `TwoPaneLayout`, or custom responsive wrappers. Instead:
- Use native `LayoutBuilder` + `MediaQuery` directly in page/widget code
- Read breakpoint helpers from `context.isCompact`, `context.isMedium` (defined in `theme_extensions.dart`)
- Use `GridView.builder` with computed `crossAxisCount` based on breakpoints
- Let `flutter_adaptive_scaffold` handle navigation switching (see [25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md](25_RESPONSIVE_LAYOUT_AND_ADAPTIVITY.md))

No custom wrappers = simpler code, fewer bugs, easier testing.

---

## Component Usage Rules

1. **Never duplicate** - if a widget exists in `shared/widgets/`, use it
2. **Feature-specific widgets** go in the feature's `presentation/widgets/` folder
3. **Promote to shared** when a widget is used in 2+ features
4. **No inline themes** - all components read from `context.colorScheme` / `context.textTheme`
5. **No magic numbers** - use `AppDimensions` for spacing, radius, elevation

---

## Accessibility Requirements Per Component

Every shared widget must meet these criteria (see 22_ACCESSIBILITY.md for full guidelines):

| Requirement | Standard | Applies To |
|-------------|----------|------------|
| Minimum tap target 48x48 | Material guidelines | All interactive widgets |
| Color contrast 4.5:1 | WCAG AA | All text on backgrounds |
| Semantics label | VoiceOver / TalkBack | Custom interactive widgets, decorative images |
| Font scale tolerance | System settings | All text containers — no fixed heights |
| Live region | Screen readers | Connectivity banner, error messages |

### Per-Widget Checklist

| Widget | Tap Target | Semantics | Font Scale Safe |
|--------|-----------|-----------|-----------------|
| App Loading Page | N/A | `Semantics(label: 'Loading')` on indicator | Yes (flexible layout) |
| App Error Page | Retry button >=48px | Error message readable by screen reader | Yes |
| App Scaffold | Back button >=48px (AppBar default) | Automatic via AppBar | Yes |
| Connectivity Banner | N/A (not dismissible) | `Semantics(liveRegion: true)` | Yes |
| App Image | N/A (decorative unless tappable) | `ExcludeSemantics` for decorative, `Semantics(label:)` for meaningful | Yes |
| Shimmer Loading | N/A | `ExcludeSemantics` (placeholder) | Yes |
| Adaptive Layout | N/A (container) | None needed | Yes |
