//
//  OAuthProviderName.swift
//  PocketBase
//
//  Type-safe OAuth provider names with support for custom providers
//

import Foundation

/// Type-safe representation of OAuth provider names
///
/// Provides compile-time safety for well-known OAuth providers while
/// maintaining flexibility for custom providers.
///
/// Example usage:
/// ```swift
/// // Use well-known providers
/// collection.loginWithOAuth(provider: .google, redirectScheme: "myapp")
///
/// // Use custom providers
/// collection.loginWithOAuth(provider: .custom("okta"), redirectScheme: "myapp")
///
/// // String literal support
/// let provider: OAuthProviderName = "github"
/// ```
public struct OAuthProviderName: RawRepresentable, Sendable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    // MARK: - Well-known OAuth Providers

    /// Google OAuth provider
    public static let google = OAuthProviderName(rawValue: "google")

    /// GitHub OAuth provider
    public static let github = OAuthProviderName(rawValue: "github")

    /// GitLab OAuth provider
    public static let gitlab = OAuthProviderName(rawValue: "gitlab")

    /// Discord OAuth provider
    public static let discord = OAuthProviderName(rawValue: "discord")

    /// Twitter OAuth provider
    public static let twitter = OAuthProviderName(rawValue: "twitter")

    /// Facebook OAuth provider
    public static let facebook = OAuthProviderName(rawValue: "facebook")

    /// Microsoft OAuth provider
    public static let microsoft = OAuthProviderName(rawValue: "microsoft")

    /// Apple OAuth provider
    public static let apple = OAuthProviderName(rawValue: "apple")

    /// Spotify OAuth provider
    public static let spotify = OAuthProviderName(rawValue: "spotify")

    /// Kakao OAuth provider
    public static let kakao = OAuthProviderName(rawValue: "kakao")

    /// Twitch OAuth provider
    public static let twitch = OAuthProviderName(rawValue: "twitch")

    /// Strava OAuth provider
    public static let strava = OAuthProviderName(rawValue: "strava")

    /// Gitee OAuth provider
    public static let gitee = OAuthProviderName(rawValue: "gitee")

    /// LiveChat OAuth provider
    public static let livechat = OAuthProviderName(rawValue: "livechat")

    /// Gitea OAuth provider
    public static let gitea = OAuthProviderName(rawValue: "gitea")

    /// OIDC OAuth provider
    public static let oidc = OAuthProviderName(rawValue: "oidc")

    /// OIDC2 OAuth provider
    public static let oidc2 = OAuthProviderName(rawValue: "oidc2")

    /// OIDC3 OAuth provider
    public static let oidc3 = OAuthProviderName(rawValue: "oidc3")

    // MARK: - Custom Provider

    /// Create a custom OAuth provider
    ///
    /// Use this for OAuth providers not included in the well-known list
    ///
    /// - Parameter name: The provider name as configured in PocketBase
    /// - Returns: A custom OAuth provider name
    public static func custom(_ name: String) -> OAuthProviderName {
        OAuthProviderName(rawValue: name)
    }
}
