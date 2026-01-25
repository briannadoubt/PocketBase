# OAuth2 Authentication Setup Guide

This guide covers setting up OAuth2 authentication with PKCE in your PocketBase Swift app.

## Table of Contents

- [Overview](#overview)
- [PocketBase Configuration](#pocketbase-configuration)
- [iOS/macOS App Configuration](#iosmacos-app-configuration)
- [SwiftUI Integration](#swiftui-integration)
- [Manual Integration](#manual-integration)
- [Supported Providers](#supported-providers)
- [Platform Support](#platform-support)
- [Troubleshooting](#troubleshooting)

## Overview

The PocketBase Swift client provides full OAuth2 authentication with PKCE (Proof Key for Code Exchange) support. The implementation handles:

- ✅ Authorization code flow with PKCE
- ✅ Browser-based authentication via `ASWebAuthenticationSession`
- ✅ Automatic token exchange
- ✅ Custom user data on signup
- ✅ Type-safe provider names
- ✅ Ephemeral browser sessions (secure, no cookie persistence)

## PocketBase Configuration

### 1. Enable OAuth Provider

In your PocketBase admin dashboard:

1. Navigate to **Settings** → **Auth providers**
2. Enable your desired provider (e.g., Google, GitHub, Discord)
3. Configure OAuth credentials (Client ID, Client Secret)
4. Add redirect URL: `https://your-pocketbase-url/api/oauth2-redirect`

### 2. Configure Collection

Ensure your auth collection has OAuth enabled:

1. Go to **Collections** → Select your users collection
2. Enable **OAuth2** in the auth options
3. Configure which fields to auto-populate from OAuth profile

## iOS/macOS App Configuration

### 1. Register URL Scheme

Add a custom URL scheme to your app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp.oauth</string>
    </dict>
</array>
```

**Important:** Use a unique scheme name (not `http` or `https`). This will be used as `myapp://callback` for OAuth callbacks.

### 2. Handle OAuth Callbacks (iOS 14+)

Your app automatically handles OAuth callbacks when using `ASWebAuthenticationSession`. No additional code needed.

## SwiftUI Integration

### Basic Setup

```swift
import SwiftUI
import PocketBase
import PocketBaseUI

@main
struct MyApp: App {
    let pocketbase = PocketBase(url: "https://your-pocketbase-url.com")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.pocketbase, pocketbase)
                .oauthConfiguration(redirectScheme: "myapp")
        }
    }
}
```

### Login with OAuth

Using the built-in `LoginButton`:

```swift
import SwiftUI
import PocketBase
import PocketBaseUI

struct LoginView: View {
    @Environment(\.pocketbase) var pocketbase
    @State private var authState: AuthState = .signedOut

    var body: some View {
        VStack {
            // OAuth login buttons
            LoginButton(
                collection: pocketbase.collection("users"),
                authState: $authState,
                strategy: .oauth(provider) // provider from listAuthMethods()
            )

            // Or use type-safe provider names
            LoginButton(
                collection: pocketbase.collection("users"),
                authState: $authState,
                strategy: .oauth(googleProvider)
            )
        }
    }
}
```

### Sign Up with OAuth

Using the built-in `SignUpButton` with custom user data:

```swift
SignUpButton(
    { username, email in
        User(
            username: username,
            email: email,
            name: "Default Name",
            avatar: nil
        )
    },
    collection: pocketbase.collection("users"),
    authState: $authState,
    provider: oauthProvider
)
```

### Getting Available OAuth Providers

```swift
struct LoginView: View {
    @Environment(\.pocketbase) var pocketbase
    @State private var providers: [OAuthProvider] = []

    var body: some View {
        VStack {
            ForEach(providers) { provider in
                LoginButton(
                    collection: pocketbase.collection("users"),
                    authState: $authState,
                    strategy: .oauth(provider)
                )
            }
        }
        .task {
            do {
                let methods = try await pocketbase
                    .collection("users")
                    .listAuthMethods()
                providers = methods.oauth2.providers
            } catch {
                print("Failed to fetch auth methods: \(error)")
            }
        }
    }
}
```

## Manual Integration

For custom UI or advanced flows:

### 1. Login Flow

```swift
import PocketBase

let pocketbase = PocketBase(url: "https://your-pocketbase-url.com")
let users = pocketbase.collection("users")

do {
    // Login with OAuth (automatically handles browser flow)
    let response = try await users.loginWithOAuth(
        provider: .google,           // Type-safe provider name
        redirectScheme: "myapp",     // Must match Info.plist
        preferEphemeralSession: true // No cookie persistence (default)
    )

    print("Logged in as: \(response.record.email)")
    print("Token: \(response.token)")
} catch PocketBaseError.oauthCancelled {
    // User cancelled the OAuth flow
    print("Login cancelled")
} catch {
    print("Login failed: \(error)")
}
```

### 2. Signup Flow with Custom Data

```swift
struct User: Record, AuthRecord {
    var id: String
    var email: String
    var username: String
    var verified: Bool
    var emailVisibility: Bool
    var created: Date
    var updated: Date

    // Custom fields
    var name: String
    var avatar: URL?
}

do {
    let customUser = User(
        id: "",
        email: "",
        username: "",
        verified: false,
        emailVisibility: false,
        created: Date(),
        updated: Date(),
        name: "My Custom Name",
        avatar: nil
    )

    let response = try await users.loginWithOAuth(
        provider: .github,
        redirectScheme: "myapp",
        createData: customUser
    )

    print("Signed up as: \(response.record.name)")
} catch {
    print("Signup failed: \(error)")
}
```

### 3. Low-Level API (Advanced)

For complete control over the OAuth flow:

```swift
// 1. Get OAuth provider configuration
let authMethods = try await users.listAuthMethods()
guard let provider = authMethods.oauth2.providers.first(where: { $0.name == "google" }) else {
    throw NSError(domain: "OAuth", code: -1)
}

// 2. Open authorization URL in browser (manual implementation)
// The provider.authUrl contains the full OAuth authorization URL with PKCE params

// 3. Extract code from callback URL
// Your app receives: myapp://callback?code=abc123

// 4. Exchange code for token
let response = try await users.authWithOAuth2(
    provider: "google",
    code: authorizationCode,
    codeVerifier: provider.codeVerifier,
    redirectUrl: URL(string: "myapp://callback")!
)
```

## Supported Providers

The library includes type-safe constants for common OAuth providers:

```swift
// Well-known providers
OAuthProviderName.google
OAuthProviderName.github
OAuthProviderName.gitlab
OAuthProviderName.discord
OAuthProviderName.twitter
OAuthProviderName.facebook
OAuthProviderName.microsoft
OAuthProviderName.apple
OAuthProviderName.spotify
OAuthProviderName.kakao
OAuthProviderName.twitch
OAuthProviderName.strava
OAuthProviderName.gitee
OAuthProviderName.livechat
OAuthProviderName.gitea
OAuthProviderName.oidc
OAuthProviderName.oidc2
OAuthProviderName.oidc3

// Custom providers
OAuthProviderName.custom("okta")
OAuthProviderName.custom("keycloak")

// String literal support
let provider: OAuthProviderName = "github"
```

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| iOS 12+ | ✅ Full | Uses `ASWebAuthenticationSession` |
| macOS 10.15+ | ✅ Full | Uses `ASWebAuthenticationSession` |
| tvOS | ❌ Limited | No browser-based OAuth support |
| watchOS | ❌ Limited | No browser-based OAuth support |
| visionOS | ✅ Full | Uses `ASWebAuthenticationSession` |

For tvOS/watchOS, consider alternative auth methods like:
- Password authentication
- Magic link authentication
- Token-based authentication from companion iOS app

## Troubleshooting

### OAuth Flow Doesn't Start

**Problem:** Nothing happens when tapping the OAuth login button.

**Solutions:**
1. Verify `.oauthConfiguration(redirectScheme:)` is set in SwiftUI hierarchy
2. Check that the redirect scheme matches your Info.plist
3. Ensure you're on iOS/macOS (not tvOS/watchOS)

### "Invalid Redirect URI" Error

**Problem:** OAuth provider shows "redirect URI mismatch" error.

**Solutions:**
1. Verify PocketBase redirect URL is configured in OAuth provider settings
2. PocketBase redirect URL should be: `https://your-pocketbase-url/api/oauth2-redirect`
3. Check that OAuth provider is properly configured in PocketBase admin

### App Doesn't Receive Callback

**Problem:** Browser completes OAuth but app doesn't open.

**Solutions:**
1. Verify URL scheme is registered in Info.plist
2. Use the exact scheme name when calling `loginWithOAuth(redirectScheme:)`
3. Test URL scheme manually: `xcrun simctl openurl booted myapp://test`

### "OAuth provider not found" Error

**Problem:** Error says provider isn't enabled.

**Solutions:**
1. Verify OAuth provider is enabled in PocketBase admin
2. Check provider name matches exactly (case-sensitive)
3. Use `listAuthMethods()` to see available providers

### Silent Failures

**Problem:** OAuth flow completes but no error or success.

**Solutions:**
1. Check for `PocketBaseError.oauthCancelled` - this is thrown when user cancels
2. Verify auth token is being stored: check `pocketbase.authStore.isValid`
3. Enable logging to see detailed errors

### Token Not Persisted

**Problem:** User is logged out after app restart.

**Solutions:**
1. Verify Keychain access is configured (automatic in most cases)
2. Check that `authStore.set()` is being called (automatic in `loginWithOAuth`)
3. Ensure app has proper keychain entitlements

### Custom createData Ignored

**Problem:** Custom fields not set during OAuth signup.

**Solutions:**
1. Verify custom fields exist in your PocketBase collection schema
2. Check field permissions allow creation by unsigned users
3. Use the `loginWithOAuth(createData:)` overload, not the basic version

## Advanced Topics

### Ephemeral vs Persistent Sessions

By default, OAuth uses ephemeral browser sessions (no cookies saved):

```swift
// Default: ephemeral (more secure)
try await users.loginWithOAuth(
    provider: .google,
    redirectScheme: "myapp"
)

// Persistent session (remembers previous login)
try await users.loginWithOAuth(
    provider: .google,
    redirectScheme: "myapp",
    preferEphemeralSession: false
)
```

**Recommendation:** Use ephemeral sessions (default) for better security.

### Linking OAuth to Existing Account

After a user is already logged in with password auth:

```swift
// Not yet implemented - coming in Phase 6
```

### Unlinking OAuth Provider

```swift
try await users.unlinkExternalAuthProvider(
    id: currentUser.id,
    provider: .google
)
```

### Listing Linked Providers

```swift
let linkedProviders = try await users.listLinkedAuthProviders(
    id: currentUser.id
)

for provider in linkedProviders {
    print("Linked: \(provider.provider)")
}
```

## Security Best Practices

1. **Use Ephemeral Sessions:** Default `preferEphemeralSession: true` prevents cookie persistence
2. **HTTPS Only:** Always use HTTPS for PocketBase URLs in production
3. **Unique URL Schemes:** Use a unique redirect scheme, not a common one
4. **Validate Tokens:** PocketBase automatically validates tokens on each request
5. **Token Refresh:** Use `authRefresh()` to refresh tokens before they expire
6. **Keychain Storage:** Tokens are automatically stored in Keychain (encrypted)

## Example Apps

See the test apps in the repository:
- `Tests/PocketBaseIntegrationTests/` - Integration test examples
- `Tests/PocketBaseTests/Auth/` - Unit test examples

## Next Steps

- [Authentication Overview](./Authentication.md)
- [Custom Auth Collections](./CustomCollections.md)
- [Realtime Subscriptions](./Realtime.md)
