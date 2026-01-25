//
//  RecordCollection+OAuthFlow.swift
//  PocketBase
//
//  High-level OAuth flow orchestration
//

import Foundation

public extension RecordCollection where T: AuthRecord {
    /// Complete OAuth login flow (authorization + token exchange)
    ///
    /// This method orchestrates the full OAuth flow:
    /// 1. Fetches OAuth provider configuration from PocketBase
    /// 2. Launches browser-based authorization flow
    /// 3. Exchanges authorization code for auth token
    ///
    /// - Parameters:
    ///   - provider: The OAuth provider name (e.g., "google", "github")
    ///   - redirectScheme: The URL scheme to intercept (must match Info.plist)
    ///   - preferEphemeralSession: Whether to use ephemeral browser session (default: true)
    /// - Returns: The auth response containing a token and user record
    @MainActor
    @Sendable
    @discardableResult
    func loginWithOAuth(
        provider: OAuthProviderName,
        redirectScheme: String,
        preferEphemeralSession: Bool = true
    ) async throws -> AuthResponse<T> {
        #if canImport(AuthenticationServices) && (os(iOS) || os(macOS))
        // Get OAuth provider configuration
        let authMethods = try await listAuthMethods()
        guard let oauthProvider = authMethods.oauth2.providers.first(where: { $0.name == provider.rawValue }) else {
            throw PocketBaseError.oauthFailed(
                NSError(domain: "OAuthFlow", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "OAuth provider '\(provider.rawValue)' not found or not enabled"
                ])
            )
        }

        // Launch OAuth authorization flow
        let flowHandler = OAuthFlowHandler()
        let code = try await flowHandler.authenticate(
            authUrl: oauthProvider.authUrl,
            redirectScheme: redirectScheme,
            preferEphemeralSession: preferEphemeralSession
        )

        // Build redirect URL (PocketBase needs the full callback URL)
        let redirectUrl = URL(string: "\(redirectScheme)://callback")!

        // Exchange code for token
        return try await authWithOAuth2(
            provider: provider.rawValue,
            code: code,
            codeVerifier: oauthProvider.codeVerifier,
            redirectUrl: redirectUrl
        )
        #else
        throw PocketBaseError.notImplemented
        #endif
    }

    /// Complete OAuth signup flow with custom user data
    ///
    /// Same as `loginWithOAuth` but allows passing createData for new user signup
    ///
    /// - Parameters:
    ///   - provider: The OAuth provider name (e.g., "google", "github")
    ///   - redirectScheme: The URL scheme to intercept (must match Info.plist)
    ///   - createData: Custom data for new user record
    ///   - preferEphemeralSession: Whether to use ephemeral browser session (default: true)
    /// - Returns: The auth response containing a token and user record
    @MainActor
    @Sendable
    @discardableResult
    func loginWithOAuth<CreateData: EncodableWithConfiguration & Sendable>(
        provider: OAuthProviderName,
        redirectScheme: String,
        createData: CreateData,
        preferEphemeralSession: Bool = true
    ) async throws -> AuthResponse<T> where CreateData.EncodingConfiguration == PocketBase.EncodingConfiguration {
        #if canImport(AuthenticationServices) && (os(iOS) || os(macOS))
        // Get OAuth provider configuration
        let authMethods = try await listAuthMethods()
        guard let oauthProvider = authMethods.oauth2.providers.first(where: { $0.name == provider.rawValue }) else {
            throw PocketBaseError.oauthFailed(
                NSError(domain: "OAuthFlow", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "OAuth provider '\(provider.rawValue)' not found or not enabled"
                ])
            )
        }

        // Launch OAuth authorization flow
        let flowHandler = OAuthFlowHandler()
        let code = try await flowHandler.authenticate(
            authUrl: oauthProvider.authUrl,
            redirectScheme: redirectScheme,
            preferEphemeralSession: preferEphemeralSession
        )

        // Build redirect URL (PocketBase needs the full callback URL)
        let redirectUrl = URL(string: "\(redirectScheme)://callback")!

        // Exchange code for token with createData
        return try await authWithOAuth2(
            provider: provider.rawValue,
            code: code,
            codeVerifier: oauthProvider.codeVerifier,
            redirectUrl: redirectUrl,
            createData: createData
        )
        #else
        throw PocketBaseError.notImplemented
        #endif
    }
}
