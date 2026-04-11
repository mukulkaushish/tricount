# 15 - Reusable Components

## Component Catalog

All reusable widgets live in `lib/shared/widgets/` and follow these rules:

1. **Stateless when possible** - use const constructors
2. **Theme-aware** - use `context.colorScheme` and `context.textTheme`, never hardcoded values
3. **Configurable** - expose meaningful props, not implementation details
4. **Accessible** - include semantics, adequate touch targets (48x48 minimum)

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

A base scaffold that includes the connectivity banner and standardized app bar.

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
- Does NOT include connectivity banner (that's at `MaterialApp` level)

---

## Connectivity Banner

(See 11_CONNECTIVITY_RESILIENCE.md for full specification)

---

## App Button

**File**: `lib/shared/widgets/app_button.dart`

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `label` | `String` | required | Button text |
| `onPressed` | `VoidCallback?` | `null` | Tap handler (null = disabled) |
| `variant` | `ButtonVariant` | `.primary` | primary, secondary, text |
| `isLoading` | `bool` | `false` | Shows spinner, disables tap |
| `icon` | `IconData?` | `null` | Leading icon |
| `isExpanded` | `bool` | `false` | Full width |

### Variants
- **Primary**: `ElevatedButton` with `colorScheme.primary` background
- **Secondary**: `OutlinedButton` with `colorScheme.primary` border
- **Text**: `TextButton` with `colorScheme.primary` text

### Loading State
When `isLoading` is true:
- Replace label with `SizedBox(16x16, CircularProgressIndicator(strokeWidth: 2))`
- Disable tap (ignore `onPressed`)
- Maintain button dimensions (no layout shift)

---

## App Text Field

**File**: `lib/shared/widgets/app_text_field.dart`

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `label` | `String` | required | Field label |
| `hint` | `String?` | `null` | Placeholder text |
| `controller` | `TextEditingController?` | `null` | External controller |
| `errorText` | `String?` | `null` | Error message below field |
| `obscureText` | `bool` | `false` | Password field |
| `keyboardType` | `TextInputType` | `.text` | Keyboard type |
| `onChanged` | `ValueChanged<String>?` | `null` | Change callback |
| `prefixIcon` | `IconData?` | `null` | Leading icon |

Uses `InputDecoration` from the global theme - no inline styling.

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

## Adaptive Layout

**File**: `lib/shared/widgets/adaptive_layout.dart`

Responsive wrapper that switches layout based on screen width.

| Prop | Type | Required | Purpose |
|------|------|----------|---------|
| `mobile` | `Widget` | Yes | Layout for < 600dp |
| `tablet` | `Widget?` | No | Layout for 600-1200dp |
| `desktop` | `Widget?` | No | Layout for > 1200dp |

Uses `LayoutBuilder` to determine breakpoints. Falls back to `mobile` if larger breakpoint widget is not provided.

### Breakpoints

| Name | Width Range | Typical Use |
|------|------------|-------------|
| Mobile | < 600dp | Single column, full-width cards |
| Tablet | 600-1200dp | Two-column, side panel |
| Desktop | > 1200dp | Three-column, expanded nav |

---

## Component Usage Rules

1. **Never duplicate** - if a widget exists in `shared/widgets/`, use it
2. **Feature-specific widgets** go in the feature's `presentation/widgets/` folder
3. **Promote to shared** when a widget is used in 2+ features
4. **No inline themes** - all components read from `context.colorScheme` / `context.textTheme`
5. **No magic numbers** - use `AppDimensions` for spacing, radius, elevation
