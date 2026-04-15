# 22 — Accessibility

## Design targets

| Criterion | Target | Standard |
|---|---|---|
| Color contrast (normal text) | 4.5:1 min | WCAG AA |
| Color contrast (large text 18pt+) | 3.0:1 min | WCAG AA |
| Tap target | 48×48 logical px min | Material |
| Font scaling | no clipping at max OS font size | system a11y settings |
| Screen reader traversal | logical, ordered, no dead ends | VoiceOver / TalkBack |

## Semantics

### When to add explicit semantics
| Scenario | Widget | Action |
|---|---|---|
| Custom interactive | `GestureDetector`/`InkWell` on non-button | `Semantics(button: true, label: '...')` |
| Decorative image | `Image`/`Icon` with no meaning | `ExcludeSemantics` |
| Meaningful image | book cover, avatar | `Semantics(label: 'Cover of $title')` |
| Composite unit | icon + text acting as one | `MergeSemantics` |
| Live region | connectivity banner, toast | `Semantics(liveRegion: true)` |
| Custom role | non-standard interactive | `Semantics(role: SemanticsRole.listItem)` |

**Flutter handles automatically:** `FilledButton`, `TextField`, `Switch`, `Checkbox`, `Slider`, `ListTile`, `AppBar` already expose correct semantics. **Do not add redundant `Semantics` wrappers.**

## Color contrast

Validate in `AppColorPalette`:

| Combination | Min ratio |
|---|---|
| `onPrimary` on `primary` | 4.5:1 |
| `onSurface` on `surface` | 4.5:1 |
| `onBackground` on `background` | 4.5:1 |
| `onError` on `error` | 4.5:1 |
| `primary` on `surface` (icons/links) | 3.0:1 |
| Disabled text on `surface` | aim 2.5:1 (not required) |

**Dark mode:** reduced-saturation palettes must still meet these. Test each palette variant independently.

**Tools:** Chrome DevTools a11y panel, macOS Accessibility Inspector, Flutter DevTools Semantics debugger.

## Font scaling

**Layout rules:**
- Never use fixed-height containers for text. Use constraints or let content size itself.
- Test at 1.0× AND 2.0× (max iOS setting).
- `AppDimensions` spacing must accommodate text growth.
- If text overflows at large scale, use `maxLines` + `overflow: TextOverflow.ellipsis` + `Tooltip` for full text.

**Testing:**
```dart
await tester.pumpWidget(
  MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
    child: MaterialApp(home: WidgetUnderTest()),
  ),
);
```

## Tap targets

| Widget | Default compliant? | Notes |
|---|---|---|
| `FilledButton` | ✓ | `minimumSize: Size(64, 48)` in theme |
| `IconButton` | ✓ | padding 12 + icon 24 = 48px |
| `ListTile` | ✓ | default min height 56px |
| `Checkbox`/`Radio` | ✓ | Material 48px hit area |
| `Switch` | ✓ | Material 48px hit area |
| Custom `GestureDetector` | ✗ | must add `SizedBox(48×48)` or padding |
| Small text links | ✗ | wrap in `InkWell` with padding |

## Screen reader

| Test | How | Pass |
|---|---|---|
| VoiceOver (iOS) | Settings > Accessibility > VoiceOver | every interactive element announced with role + label |
| TalkBack (Android) | Settings > Accessibility > TalkBack | same |
| Focus order | swipe through | logical order, no trapped focus |
| Connectivity banner | toggle airplane mode | "No internet connection" announced as live region |
| Error states | trigger API error | error message announced |
| Loading states | trigger load | "Loading" announced, then content |
| Dialogs | open | focus moves to dialog, escape/back dismisses |

**Navigation hints:**
- `AppBar` back button — automatic "Back" semantics.
- Tab bar — automatic "Tab N of M" semantics.
- Bottom sheet drag handle — add `Semantics(label: 'Drag handle, double-tap to dismiss')`.

## Platform notes

**iOS** — VoiceOver uses swipe gestures; avoid conflicts with reader controls. `CupertinoAlertDialog` (via `showAdaptiveDialog`) has built-in a11y.

**Android** — TalkBack uses explore-by-touch; ensure adequate spacing. `MaterialBanner` has built-in semantics.

**Web (future)** — Flutter web renders on canvas; semantics DOM is a separate overlay. Enable at startup:
```dart
if (kIsWeb) {
  SemanticsBinding.instance.ensureSemantics();
}
```

## Checklist for every new screen

- [ ] All interactive elements ≥ 48×48 tap targets.
- [ ] No text clips/overflows at 2.0× font scale.
- [ ] Color contrast meets 4.5:1 body / 3.0:1 large.
- [ ] Custom widgets have appropriate `Semantics`.
- [ ] Decorative elements excluded from semantics tree.
- [ ] Screen reader traversal logical and complete.
- [ ] Error + loading states announced.
- [ ] Dialogs + bottom sheets trap and restore focus.
