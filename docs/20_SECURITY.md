# 20 — Security

## Secure token management

### Token storage
| Token | Storage | Encryption |
|---|---|---|
| Access token (JWT) | `flutter_secure_storage` | platform keychain/keystore |
| Refresh token | `flutter_secure_storage` | platform keychain/keystore |
| Token expiry | `flutter_secure_storage` | platform keychain/keystore |

**Never store tokens in:** SharedPreferences, Drift, plain files, or in-memory only.

### `TokenProvider` interface (`lib/core/security/token_provider.dart`)

| Method | Returns | Purpose |
|---|---|---|
| `getAccessToken()` | `Future<String?>` | read current access token |
| `getRefreshToken()` | `Future<String?>` | read refresh token |
| `saveTokens(access, refresh, expiry)` | `Future<void>` | store new tokens |
| `clearTokens()` | `Future<void>` | remove all (logout) |
| `hasValidToken()` | `Future<bool>` | exists and not expired |
| `isTokenExpired()` | `Future<bool>` | check expiry without network |

### Refresh flow

Handled by `AuthInterceptor` (`QueuedInterceptorsWrapper`). On 401 it calls a DI-provided refresh callback, saves the new pair via `TokenProvider`, and retries. If refresh itself fails, tokens are cleared and the error propagates so the UI can redirect to login.

### Lifecycle
1. **Login** — server returns `access_token`, `refresh_token`, `expires_in`.
2. **Storage** — both stored in `flutter_secure_storage`.
3. **Usage** — `AuthInterceptor` attaches access token to every request.
4. **Expiry** — proactive refresh when token is within 60s of expiry.
5. **401** — reactive refresh via `AuthInterceptor`.
6. **Logout** — `clearTokens()` removes all credentials.

## Platform security

### iOS
| Setting | Value | Purpose |
|---|---|---|
| Keychain accessibility | `kSecAttrAccessibleWhenUnlocked` | only when unlocked |
| App Transport Security | enabled | enforce HTTPS |
| Keychain sharing | disabled | no cross-app access |

### Android
| Setting | Value | Purpose |
|---|---|---|
| `EncryptedSharedPreferences` | AES-256 | hardware-backed |
| `android:allowBackup` | `false` | no secure-data backup |
| `android:usesCleartextTraffic` | `false` | enforce HTTPS |
| Network security config | disable cleartext + trust anchors | HTTPS enforcement / trust policy |

**HTTPS enforcement** (`android/app/src/main/res/xml/network_security_config.xml`) — target-state:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="false">
    <trust-anchors>
      <certificates src="system" />
    </trust-anchors>
  </base-config>
  <debug-overrides>
    <trust-anchors>
      <certificates src="user" />
    </trust-anchors>
  </debug-overrides>
</network-security-config>
```
Reference in `AndroidManifest.xml`:
```xml
<application
  android:networkSecurityConfig="@xml/network_security_config"
  android:usesCleartextTraffic="false"
  ...>
```

Disables cleartext + configures trust anchors. **Does NOT** implement cert/pubkey pinning by itself.

## Certificate pinning (optional)

For high-security requirements, pin via Dio.

| Option | When |
|---|---|
| Public key pinning | most flexible — survives cert rotation |
| Cert pinning | strictest — must update app on cert renewal |

**Recommendation:** public key pinning with a backup pin.

**Config:** custom `SecurityContext` on `HttpClient`, or Dio's `HttpClientAdapter` to validate server certs. Include 2 pins: current + backup/next.

**Pin update strategy:** include next cert's pin before rotation. App update required for pin change (use feature flag to disable pinning in emergency).

## API security headers

| Header | Value | Purpose |
|---|---|---|
| `Authorization` | `Bearer <token>` | auth |
| `X-App-Version` | `1.0.0+45` | client version tracking |
| `X-Platform` | `ios`/`android` | platform ID |
| `X-Request-ID` | UUID/request | tracing |

## Data at rest

| Data | Storage | Protection |
|---|---|---|
| Auth tokens | `flutter_secure_storage` | platform encryption |
| Preferences | SharedPreferences | none (non-sensitive) |
| Cached books | Drift | none (public content) |
| Reading progress | Drift | none (low sensitivity) |
| Bookmarks | Drift | none (low sensitivity) |

**Encrypt Drift DB?** If app stores private/premium content that must not be extractable:
- Use `sqlcipher_flutter_libs` instead of `sqlite3_flutter_libs`.
- Key derived from secure storage.
- Perf impact ~5–15% on DB ops.

**Default:** no DB encryption (content not DRM-protected). Enable if business requires.

## Input validation

| Input | Validation |
|---|---|
| Login form | email format, min password length (client-side) |
| Search query | sanitize special chars, max length |
| Deep link params | validate format before navigation |
| API responses | `JsonParser` validates types (→ `07_JSON_PARSING_CODABLE.md`) |

## Sensitive data policy

**Never log:** tokens (access, refresh), passwords, personal user info, full request bodies with sensitive fields.

**Masking:**
- Authorization header → `Bearer ***` in logs.
- Email → `m***@example.com` in analytics.
- User ID — full value OK (not PII alone).

**Debug builds:**
- `kDebugMode` controls verbose logging.
- Debug may show additional developer info.
- **Never** ship debug to production (enforced by CI `--release`).

## Dependency security

| Practice | Implementation |
|---|---|
| Audit deps | `flutter pub outdated` nightly CI |
| Pin major versions | caret syntax `^x.y.z` in pubspec |
| Review changelogs | before major bumps |
| Minimize deps | only packages that justify weight |
| No abandoned packages | check pub.dev scores + last publish |
