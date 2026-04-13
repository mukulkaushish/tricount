# 21 - Localization & Internationalization

## Overview

The app uses Flutter's built-in `gen-l10n` code generation for type-safe localized strings. No third-party i18n package is needed.

---

## Setup

### Dependencies

Already in `pubspec.yaml`:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any
```

### Enable Code Generation

**pubspec.yaml** (add under `flutter:` section):

```yaml
flutter:
  generate: true
```

### l10n Configuration

**File**: `l10n.yaml` (project root)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

---

## ARB Files

### Template (English)

**File**: `lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "appTitle": "<app_name>",
  "@appTitle": {
    "description": "The application title"
  },
  "loginTitle": "Sign In",
  "loginEmailLabel": "Email",
  "loginPasswordLabel": "Password",
  "loginButton": "Sign In",
  "registerButton": "Create Account",
  "forgotPassword": "Forgot Password?",
  "logoutButton": "Log Out",
  "errorGeneric": "Something went wrong. Please try again.",
  "errorNoConnection": "No internet connection.",
  "errorSessionExpired": "Session expired. Please sign in again.",
  "retry": "Try Again",
  "cancel": "Cancel",
  "save": "Save",
  "delete": "Delete",
  "confirmDeleteTitle": "Confirm Delete",
  "confirmDeleteMessage": "Are you sure you want to delete this?",
  "currencyAmount": "{amount}",
  "@currencyAmount": {
    "description": "Formatted currency amount",
    "placeholders": {
      "amount": {
        "type": "double",
        "format": "currency",
        "optionalParameters": {
          "symbol": "$",
          "decimalDigits": 2
        }
      }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Pluralized item count",
    "placeholders": {
      "count": {
        "type": "num"
      }
    }
  },
  "lastUpdated": "Last updated {date}",
  "@lastUpdated": {
    "description": "Shows when data was last updated",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMd"
      }
    }
  }
}
```

### Adding a New Language

1. Create `lib/l10n/app_<locale>.arb` (e.g., `app_fr.arb`)
2. Translate all keys from the template file
3. Add the `Locale` to `supportedLocales` in `app.dart`
4. Run `flutter gen-l10n` to regenerate
5. For iOS: add the language in Xcode under Runner > Info > Localizations

---

## App Integration

In `app.dart` (`MaterialApp.router`):

```dart
MaterialApp.router(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
  ],
  // ...
)
```

### Usage in Widgets

```dart
// Import:
import 'l10n/app_localizations.dart';

// Access:
Text(AppLocalizations.of(context)!.loginTitle)

// With parameters:
Text(AppLocalizations.of(context)!.itemCount(3))
Text(AppLocalizations.of(context)!.lastUpdated(DateTime.now()))
```

### Context Extension (optional convenience)

In `build_context_extensions.dart`, add:

```dart
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// Usage: context.l10n.loginTitle
```

Use your real app name in ARB values. If you keep docs generic elsewhere, replace `<app_name>` with the product name for the current repository.

---

## Rules

| Rule | Detail |
|------|--------|
| No hardcoded user-facing strings | Every visible string goes through `AppLocalizations` |
| Template file is the source of truth | `app_en.arb` defines all keys; other locales translate them |
| Use `@key` metadata | Every key should have a `description` for translators |
| Placeholders are typed | Use `type`, `format`, and `optionalParameters` for dates, numbers, currency |
| Plural forms use ICU syntax | `{count, plural, =0{...} =1{...} other{...}}` |
| No string concatenation for sentences | Use placeholders instead of `'Hello ' + name` |
| Error messages are localized | `AppException.userMessage` should return localization keys or pre-localized strings |

---

## Testing with Localization

Widget tests must include `AppLocalizations` delegates. Use the `pumpApp` test helper → [17_TESTING_STRATEGY.md](17_TESTING_STRATEGY.md#widget-test-helpers-with-localization)
