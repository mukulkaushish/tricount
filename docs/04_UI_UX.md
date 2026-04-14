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

## 2. Navigation (go_router)

We use `go_router` for all navigation, including deep links and guards.

### Pattern
- **Typed Routes**: Use `go_router_builder` for type-safe navigation.
- **Auth Guard**: A global `redirect` in `app_router.dart` checks for tokens and redirects to `/login` if needed.
- **Shell Routes**: Used for persistent bottom navigation (Tabs).
- **Injection**: BLoCs are injected per-route in the `builder` callback to ensure they are disposed of correctly.

---

## 3. Responsive Layout (Grids over Lists)

The app must adapt from a 5" phone to a 13" iPad and 8" foldable using a single codebase.

### Priority: Grids
**Grid layouts are the primary pattern** for content browsing.
- **Compact (<600dp)**: 2 columns.
- **Medium (600-840dp)**: 3 columns + Navigation Rail.
- **Expanded (>840dp)**: 4+ columns + Navigation Drawer.

### Technology
Use `flutter_adaptive_scaffold` for automatic navigation switching and hinge/fold awareness.

---

## 4. Reusable Components (Shared Widgets)

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

## 5. Accessibility & Localization

- **Tap Targets**: Minimum 48x48dp for all interactive elements.
- **Contrast**: 4.5:1 minimum for all text (WCAG AA).
- **Semantics**: Use `Semantics()` for custom widgets; standard widgets handle this automatically.
- **L10n**: Use `gen-l10n` for type-safe strings. No hardcoded text in widgets.

---

## 6. Animations & Transitions

- **Page Transitions**: Zoom on Android, Slide on iOS (standard platform feel).
- **Micro-interactions**: Subtle scale-down on taps, 300ms fades for images.
- **Performance**: Always use `const` and `ListView.builder` to maintain 60fps.
