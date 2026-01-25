//
//  OAuthConfiguration.swift
//  PocketBase
//
//  OAuth configuration for SwiftUI environment
//

import SwiftUI

/// OAuth configuration for redirect scheme and session preferences
public struct OAuthConfiguration: Sendable {
    /// The URL scheme to intercept for OAuth callbacks (e.g., "myapp")
    /// Must match a URL scheme registered in your app's Info.plist
    public let redirectScheme: String

    /// Whether to use ephemeral browser sessions (default: true for security)
    public let preferEphemeralSession: Bool

    public init(
        redirectScheme: String,
        preferEphemeralSession: Bool = true
    ) {
        self.redirectScheme = redirectScheme
        self.preferEphemeralSession = preferEphemeralSession
    }
}

// MARK: - Environment Key

private struct OAuthConfigurationKey: EnvironmentKey {
    static let defaultValue: OAuthConfiguration? = nil
}

extension EnvironmentValues {
    public var oauthConfiguration: OAuthConfiguration? {
        get { self[OAuthConfigurationKey.self] }
        set { self[OAuthConfigurationKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Configure OAuth settings for this view hierarchy
    ///
    /// - Parameters:
    ///   - redirectScheme: The URL scheme for OAuth callbacks (must match Info.plist)
    ///   - preferEphemeralSession: Whether to use ephemeral browser sessions (default: true)
    /// - Returns: A view with OAuth configuration applied
    ///
    /// Example:
    /// ```swift
    /// ContentView()
    ///     .oauthConfiguration(redirectScheme: "myapp")
    /// ```
    public func oauthConfiguration(
        redirectScheme: String,
        preferEphemeralSession: Bool = true
    ) -> some View {
        environment(
            \.oauthConfiguration,
            OAuthConfiguration(
                redirectScheme: redirectScheme,
                preferEphemeralSession: preferEphemeralSession
            )
        )
    }
}
