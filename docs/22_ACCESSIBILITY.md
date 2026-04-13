# 22 - Accessibility

## Design Targets

| Criterion | Target | Standard |
|-----------|--------|----------|
| Color contrast (normal text) | 4.5:1 minimum | WCAG AA |
| Color contrast (large text 18pt+) | 3.0:1 minimum | WCAG AA |
| Tap target size | 48x48 logical pixels minimum | Material guidelines |
| Font scaling | Layouts must not clip at max OS font size | System accessibility settings |
| Screen reader traversal | Logical, ordered, no dead ends | VoiceOver / TalkBack |

---

## Semantics

### When to Add Explicit Semantics

| Scenario | Widget | Action |
|----------|--------|--------|
| Custom interactive widget | `GestureDetector`, `InkWell` on non-button | Wrap in `Semantics(button: true, label: '...')` |
| Decorative image | `Image`, `Icon` with no meaning | Wrap in `ExcludeSemantics` |
| Meaningful image | Book cover, user avatar | Add `Semantics(label: 'Cover of $title')` |
| Composite widget | Icon + text acting as one unit | Wrap in `MergeSemantics` |
| Live region | Connectivity banner, toast | Add `Semantics(liveRegion: true)` |
| Custom role | Non-standard interactive element | Use `Semantics(role: SemanticsRole.listItem)` |

### What Flutter Handles Automatically

Standard Material widgets (`FilledButton`, `TextField`, `Switch`, `Checkbox`, `Slider`, `ListTile`, `AppBar`) already expose correct semantics. Do not add redundant `Semantics` wrappers to these.

---

## Color Contrast

### Validation

Before finalizing any palette in `AppColorPalette`, validate contrast ratios:

| Combination | Minimum Ratio |
|-------------|---------------|
| `onPrimary` on `primary` | 4.5:1 |
| `onSurface` on `surface` | 4.5:1 |
| `onBackground` on `background` | 4.5:1 |
| `onError` on `error` | 4.5:1 |
| `primary` on `surface` (icons, links) | 3.0:1 |
| Disabled text on `surface` | Not required, but aim for 2.5:1 |

**Dark mode**: Reduced saturation palettes must still meet these ratios. Test each palette variant independently.

### Tools

- Chrome DevTools Accessibility panel
- macOS Accessibility Inspector
- Flutter DevTools > Semantics debugger

---

## Font Scaling

### Layout Rules

- Never use fixed-height containers for text. Use `constraints` or let content size itself.
- Test layouts at font scale 1.0x AND 2.0x (max iOS setting).
- `AppDimensions` spacing values should accommodate text growth.
- If text overflows at large scale, use `maxLines` + `overflow: TextOverflow.ellipsis` with a `Tooltip` for the full text.

### Testing

```dart
// In widget tests, simulate large text:
await tester.pumpWidget(
  MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
    child: MaterialApp(home: WidgetUnderTest()),
  ),
);
```

---

## Tap Targets

Every interactive element must have at minimum 48x48 logical pixels of tappable area:

| Widget | Default Compliant? | Notes |
|--------|--------------------|-------|
| `FilledButton` | Yes | `minimumSize: Size(64, 48)` in theme |
| `IconButton` | Yes | `padding: 12` + 24px icon = 48px |
| `ListTile` | Yes | Default min height 56px |
| `Checkbox` / `Radio` | Yes | Material 48px hit area |
| `Switch` | Yes | Material 48px hit area |
| Custom `GestureDetector` | **No** | Must add `SizedBox(width: 48, height: 48)` or equivalent padding |
| Small text links | **No** | Wrap in `InkWell` with sufficient padding |

---

## Screen Reader

### Testing Checklist

| Test | How | Pass Criteria |
|------|-----|---------------|
| VoiceOver (iOS) | Settings > Accessibility > VoiceOver | Every interactive element is announced with role and label |
| TalkBack (Android) | Settings > Accessibility > TalkBack | Same as above |
| Focus order | Swipe through elements | Logical reading order, no trapped focus |
| Connectivity banner | Toggle airplane mode | "No internet connection" announced as live region |
| Error states | Trigger API error | Error message announced |
| Loading states | Trigger data load | "Loading" announced, then content |
| Dialogs | Open dialog | Focus moves to dialog, escape/back dismisses |

### Navigation Hints

- `AppBar` back button: Flutter provides automatic "Back" semantics
- Tab bar: Flutter provides automatic "Tab N of M" semantics
- Bottom sheet drag handle: Add `Semantics(label: 'Drag handle, double-tap to dismiss')`

---

## Platform-Specific Notes

### iOS

- VoiceOver uses swipe gestures — ensure no gesture conflicts with reader controls
- `CupertinoAlertDialog` (via `showAdaptiveDialog`) has built-in accessibility

### Android

- TalkBack uses explore-by-touch — ensure all elements have adequate spacing
- `MaterialBanner` has built-in semantics

### Web (Future)

- Flutter web renders on canvas — semantics DOM is a separate overlay
- Enable semantics at startup if web accessibility is required:
  ```dart
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  ```

---

## Checklist for Every New Screen

Before marking a screen as complete:

- [ ] All interactive elements have 48x48 minimum tap targets
- [ ] No text clips or overflows at 2.0x font scale
- [ ] Color contrast meets 4.5:1 for body text, 3.0:1 for large text
- [ ] Custom widgets have appropriate `Semantics` annotations
- [ ] Decorative elements excluded from semantics tree
- [ ] Screen reader traversal is logical and complete
- [ ] Error and loading states are announced
- [ ] Dialogs and bottom sheets trap and restore focus correctly
