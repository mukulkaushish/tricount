# 04 - UI & UX: Theming, Navigation & Components

This document defines the visual language, navigation patterns, and user experience standards for the app.

---

## 1. Dynamic Theming (The "Zero Inline" Rule)

Every visual property must live in `AppTheme.build`. **No widget may inline style** colors, text, or shapes.

### Key Tokens
- **Palettes**: Multiple brand palettes (Blue, Violet, etc.) each with Light/Dark variants.
- **Typography**: Centralized in `AppTextStyles` using Material 3 naming (e.g., `bodyLarge`).
- **Dimensions**: `AppDimensions` defines all spacing, radius, and elevation.

### Platform Adaptation
- **Android**: Material ripples (`InkSparkle`).
- **iOS**: Instant opacity dim (no ripples) to match Cupertino feel.
- **Adaptive Widgets**: Use `.adaptive()` constructors (e.g., `Switch.adaptive`) to get platform-native looks automatically.

---

## 2. Navigation (auto_route)

We use `auto_route` for all navigation, including deep links and guards.

### Pattern
- **Typed Routes**: Generate routes using `@RoutePage()` and `auto_route_generator`.
- **Auth Guard**: Implement `AutoRouteGuard` to protect private routes.
- **Scoping**: Use `AutoRouteWrapper` on pages to wrap them with `BlocProvider`. This ensures BLoCs are correctly scoped and disposed.
- **Observers**: Use `AutoRouterObserver` for global navigation tracking.
- **Persistence**: Supports deep linking and universal links natively.

### Example Guard
```dart
class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (isAuthenticated) {
      resolver.next(true);
    } else {
      router.push(const LoginRoute());
    }
  }
}
```

---

## 3. Responsive Layout

### Single Design System — No Separate UIs Needed
The same design system and widget tree adapts to all form factors (phone, foldable, iPad) via breakpoints. There is **no separate tablet UI**. Use `LayoutBuilder` + `constraints.maxWidth` to drive column counts and spacing.

### Breakpoints (`AppDimensions`)
| Breakpoint | Width | Layout pattern |
|---|---|---|
| **Compact** | `< 600dp` | Single column, `ListView.builder`, natural card heights |
| **Medium** | `600–840dp` | 2-column `Wrap`, `NavigationRail` |
| **Expanded** | `> 840dp` | 3-column `Wrap`, `NavigationDrawer` |

### Pattern: Wrap Grid (no fixed `mainAxisExtent`)
For medium/expanded screens use `Wrap` + `SizedBox(width: cardWidth)` so cards size to their content. **Never set `mainAxisExtent` in a `SliverGridDelegate`** — it causes `RenderFlex` overflow when card content is taller than the fixed height.

```dart
LayoutBuilder(builder: (context, constraints) {
  final width = constraints.maxWidth;

  if (width < AppDimensions.breakpointCompact) {
    return ListView.builder(...); // phone: natural heights
  }

  final columns = width >= AppDimensions.breakpointMedium ? 3 : 2;
  final hPadding = width >= AppDimensions.breakpointMedium
      ? AppDimensions.paddingExpandedH
      : AppDimensions.paddingMediumH;
  final cardWidth =
      (width - hPadding * 2 - AppDimensions.s16 * (columns - 1)) / columns;

  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: AppDimensions.s16),
    child: Wrap(
      spacing: AppDimensions.s16,
      runSpacing: AppDimensions.s16,
      children: [for (final card in cards) SizedBox(width: cardWidth, child: card)],
    ),
  );
})
```

### Foldables
Use `context.hasActiveFold` and `context.hingeAwarePadding` (from `theme_extensions.dart`) to avoid placing content on the crease.

---

## 4. Icons

- Always use `Icons.*_rounded` variants (e.g. `Icons.logout_rounded`, `Icons.add_rounded`).
- Size icons using `AppDimensions` constants — `iconSm` (18dp), `iconMd` (24dp), `iconLg` (32dp).
- Never hardcode icon sizes inline (no `Icon(Icons.x, size: 24)`).
- `const Icon(Icons.x_rounded)` uses the theme's default icon size automatically; only set `size:` when deviating from that default.

---

## 5. Reusable Components (Shared Widgets)

Shared widgets (`lib/shared/widgets/`) are justified only for **behavioral composition**, not just styling.

| Component | Purpose |
|-----------|---------|
| **AppImage** | Cached network image + Shimmer placeholder. |
| **AppScaffold** | Standardizes AppBar and Safe Area. |
| **AuthForm** | Bundles validation, focus chains, and autofill. |
| **ConnectivityBanner** | Global slide-in for offline states. |
| **KeyboardDismisser** | Dismisses keyboard on scroll/tap. |

**Rule**: Do not create `AppButton` or `AppTextField`. Use framework widgets directly — the theme styles them.

---

## 6. Accessibility & Localization

- **Tap Targets**: Minimum 48x48dp for all interactive elements.
- **Contrast**: 4.5:1 minimum for all text (WCAG AA).
- **Semantics**: Use `Semantics()` for custom widgets; standard widgets handle this automatically.
- **L10n**: Use `gen-l10n` for type-safe strings. No hardcoded text in widgets.

---

## 7. Animations & Transitions

- **Page Transitions**: Zoom on Android, Slide on iOS (standard platform feel).
- **Micro-interactions**: Subtle scale-down on taps, 300ms fades for images.
- **Performance**: Always use `const` and `ListView.builder` to maintain 60fps.
