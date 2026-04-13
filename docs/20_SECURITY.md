# 20 - Security

## Secure Token Management

### Token Storage

| Token | Storage | Encryption |
|-------|---------|------------|
| Access Token (JWT) | `flutter_secure_storage` | Platform keychain/keystore |
| Refresh Token | `flutter_secure_storage` | Platform keychain/keystore |
| Token Expiry | `flutter_secure_storage` | Platform keychain/keystore |

**Never store tokens in**: SharedPreferences, Drift database, plain files, or in-memory only.

### TokenProvider Interface

**File**: `lib/core/security/token_provider.dart`

| Method | Returns | Purpose |
|--------|---------|---------|
| `getAccessToken()` | `Future<String?>` | Read current access token |
| `getRefreshToken()` | `Future<String?>` | Read current refresh token |
| `saveTokens(access, refresh, expiry)` | `Future<void>` | Store new tokens |
| `clearTokens()` | `Future<void>` | Remove all tokens (logout) |
| `hasValidToken()` | `Future<bool>` | Check if token exists and not expired |
| `isTokenExpired()` | `Future<bool>` | Check expiry without network call |

### Token Refresh Flow

Handled by `AuthInterceptor` (extends `QueuedInterceptorsWrapper`) → [06_NETWORKING_LAYER.md](06_NETWORKING_LAYER.md#authinterceptor-extends-queuedinterceptorswrapper)

### Token Lifecycle

1. **Login**: Server returns `access_token`, `refresh_token`, `expires_in`
2. **Storage**: Both tokens stored in `flutter_secure_storage`
3. **Usage**: `AuthInterceptor` attaches access token to every request
4. **Expiry**: Proactive refresh when token is within 60s of expiry
5. **401**: Reactive refresh via `AuthInterceptor`
6. **Logout**: `clearTokens()` removes all credentials

---

## Platform Security Configuration

### iOS

| Setting | Value | Purpose |
|---------|-------|---------|
| Keychain accessibility | `kSecAttrAccessibleWhenUnlocked` | Token available only when device unlocked |
| App Transport Security | Enabled | Enforce HTTPS |
| Keychain sharing | Disabled | No cross-app access |

### Android

| Setting | Value | Purpose |
|---------|-------|---------|
| EncryptedSharedPreferences | AES-256 | Hardware-backed encryption |
| `android:allowBackup` | `false` | Prevent backup of secure data |
| `android:usesCleartextTraffic` | `false` | Enforce HTTPS |
| Network security config | Disable cleartext + configure trust anchors | HTTPS enforcement / trust policy |

#### HTTPS Enforcement (network_security_config.xml)

**File**: `android/app/src/main/res/xml/network_security_config.xml`

This XML example disables cleartext traffic and configures trust anchors via
`base-config` and `debug-overrides`. It enforces HTTPS and does **not**
implement certificate or public-key pinning by itself.

The current repository does not yet include this file or the corresponding
`AndroidManifest.xml` wiring below, so treat this as a target-state Android
configuration example.

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="false">
    <trust-anchors>
      <certificates src="system" />
    </trust-anchors>
  </base-config>
  <!-- Debug-only exception for local development -->
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

---

## Certificate Pinning (Optional)

For high-security requirements, configure Dio with certificate pinning:

### Implementation Approach

| Option | When |
|--------|------|
| Public key pinning | Most flexible - survives certificate rotation |
| Certificate pinning | Strictest - must update app on cert renewal |

**Recommendation**: Public key pinning with a backup pin.

### Configuration

In `DioHttpClient` / Dio setup:
- Provide custom `SecurityContext` to `HttpClient`
- Or use Dio's `HttpClientAdapter` to validate server certificates
- Include 2 pins: current certificate + backup/next certificate

### Pin Update Strategy

- Include next certificate's pin before rotation
- App update required for pin change (use feature flag to disable pinning if emergency)

---

## API Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| `Authorization` | `Bearer <token>` | Authentication |
| `X-App-Version` | `1.0.0+45` | Track client versions |
| `X-Platform` | `ios` or `android` | Platform identification |
| `X-Request-ID` | UUID per request | Request tracing |

---

## Data at Rest

| Data | Storage | Protection |
|------|---------|-----------|
| Auth tokens | flutter_secure_storage | Platform encryption |
| User preferences | SharedPreferences | Not encrypted (non-sensitive) |
| Cached books | Drift (SQLite) | Not encrypted (public content) |
| Reading progress | Drift (SQLite) | Not encrypted (low sensitivity) |
| Bookmarks | Drift (SQLite) | Not encrypted (low sensitivity) |

### When to Encrypt Drift DB

If the app stores private/premium content that must not be extractable:
- Use `sqlcipher_flutter_libs` instead of `sqlite3_flutter_libs`
- Encryption key derived from secure storage
- Performance impact: ~5-15% on DB operations

**Default**: No DB encryption (content is not DRM-protected). Enable if business requirements change.

---

## Input Validation

| Input Point | Validation |
|-------------|-----------|
| Login form | Email format, password minimum length (client-side) |
| Search query | Sanitize special characters, max length |
| Deep link params | Validate format before navigation |
| API responses | `JsonParser` validates types (see 07_JSON_PARSING_CODABLE.md) |

---

## Sensitive Data Policy

### Never Log

- Tokens (access, refresh)
- Passwords
- Personal user information
- Full request bodies with sensitive fields

### Masking

- Authorization header: `Bearer ***` in logs
- Email: `m***@example.com` in analytics
- User ID: full value OK (not PII by itself)

### Debug Builds

- `kDebugMode` flag controls verbose logging
- Debug builds may show additional developer info
- **Never** ship debug builds to production (enforced by CI `--release` flag)

---

## Dependency Security

| Practice | Implementation |
|----------|---------------|
| Audit dependencies | `flutter pub outdated` in nightly CI |
| Pin major versions | Caret syntax (`^x.y.z`) in pubspec |
| Review changelogs | Before major version bumps |
| Minimize dependencies | Only add packages that justify their weight |
| No abandoned packages | Check pub.dev scores and last publish date |
