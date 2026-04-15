# 21 — Localization & Internationalization

Uses Flutter's built-in `gen-l10n`. No third-party i18n package.

## Setup

**Dependencies (`pubspec.yaml`):**
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any
```

**Enable codegen** (under `flutter:`):
```yaml
flutter:
  generate: true
```

**`l10n.yaml` (project root):**
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

## ARB files

### Template — `lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "appTitle": "<app_name>",
  "@appTitle": {"description": "The application title"},
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
        "optionalParameters": {"symbol": "$", "decimalDigits": 2}
      }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Pluralized item count",
    "placeholders": {"count": {"type": "num"}}
  },
  "lastUpdated": "Last updated {date}",
  "@lastUpdated": {
    "description": "Shows when data was last updated",
    "placeholders": {"date": {"type": "DateTime", "format": "yMd"}}
  }
}
```

### Adding a new language
1. Create `lib/l10n/app_<locale>.arb` (e.g. `app_fr.arb`).
2. Translate all keys from the template.
3. Add the `Locale` to `supportedLocales` in `app.dart`.
4. Run `flutter gen-l10n` to regenerate.
5. **iOS** — add language in Xcode (Runner > Info > Localizations) **only when** the locale is actually being shipped.

## App integration

```dart
MaterialApp.router(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
  // ...
)
```

### Usage in widgets

```dart
import 'l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.loginTitle)
Text(AppLocalizations.of(context)!.itemCount(3))
Text(AppLocalizations.of(context)!.lastUpdated(DateTime.now()))
```

### Context extension (optional)

In `build_context_extensions.dart`:
```dart
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
// Usage: context.l10n.loginTitle
```

Replace `<app_name>` with the real product name in ARB values.

## Rules

| Rule | Detail |
|---|---|
| No hardcoded user-facing strings | every visible string via `AppLocalizations` |
| Template is the source of truth | `app_en.arb` defines all keys; other locales translate |
| Use `@key` metadata | every key has `description` for translators |
| Placeholders are typed | use `type`, `format`, `optionalParameters` for dates/numbers/currency |
| Plurals use ICU | `{count, plural, =0{...} =1{...} other{...}}` |
| No string concatenation for sentences | use placeholders, not `'Hello ' + name` |
| Error messages localized | `AppException.userMessage` returns localization keys / pre-localized strings |

## Testing

Widget tests must include `AppLocalizations` delegates — use `pumpApp` helper → `17_TESTING_STRATEGY.md`.
