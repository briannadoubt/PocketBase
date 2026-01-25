//
//  RecordCollection+AuthWithOAuth2.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection where T: AuthRecord {
    /// Authenticate with OAuth2 code exchange (with optional createData for signup)
    ///
    /// - Parameters:
    ///   - provider: The OAuth provider name (e.g., "google", "github")
    ///   - code: The authorization code from the OAuth provider
    ///   - codeVerifier: The PKCE code verifier
    ///   - redirectUrl: The redirect URL used in the OAuth flow
    ///   - createData: Optional data for creating a new user record during signup
    /// - Returns: The auth response containing a token and a record
    @Sendable
    @discardableResult
    func authWithOAuth2<CreateData: EncodableWithConfiguration & Sendable>(
        provider: String,
        code: String,
        codeVerifier: String,
        redirectUrl: URL,
        createData: CreateData
    ) async throws -> AuthResponse<T> where CreateData.EncodingConfiguration == PocketBase.EncodingConfiguration {
        let response: AuthResponse<T> = try await post(
            path: PocketBase.collectionPath(collection) + "auth-with-oauth2",
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers,
            body: AuthWithOAuth2Body(
                provider: provider,
                code: code,
                codeVerifier: codeVerifier,
                redirectUrl: redirectUrl,
                createData: createData
            )
        )
        try pocketbase.authStore.set(response)
        return response
    }

    /// Authenticate with OAuth2 code exchange (login only, no createData)
    ///
    /// - Parameters:
    ///   - provider: The OAuth provider name (e.g., "google", "github")
    ///   - code: The authorization code from the OAuth provider
    ///   - codeVerifier: The PKCE code verifier
    ///   - redirectUrl: The redirect URL used in the OAuth flow
    /// - Returns: The auth response containing a token and a record
    @Sendable
    @discardableResult
    func authWithOAuth2(
        provider: String,
        code: String,
        codeVerifier: String,
        redirectUrl: URL
    ) async throws -> AuthResponse<T> {
        let response: AuthResponse<T> = try await post(
            path: PocketBase.collectionPath(collection) + "auth-with-oauth2",
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers,
            body: AuthWithOAuth2BodyNoCreateData(
                provider: provider,
                code: code,
                codeVerifier: codeVerifier,
                redirectUrl: redirectUrl
            )
        )
        try pocketbase.authStore.set(response)
        return response
    }
}

struct AuthWithOAuth2Body<CreateData: EncodableWithConfiguration & Sendable>: EncodableWithConfiguration, Sendable where CreateData.EncodingConfiguration == PocketBase.EncodingConfiguration {
    typealias EncodingConfiguration = PocketBase.EncodingConfiguration

    var provider: String
    var code: String
    var codeVerifier: String
    var redirectUrl: URL
    var createData: CreateData

    func encode(to encoder: any Encoder, configuration: PocketBase.EncodingConfiguration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(code, forKey: .code)
        try container.encode(codeVerifier, forKey: .codeVerifier)
        try container.encode(redirectUrl, forKey: .redirectUrl)

        // Encode createData - the configuration constraint ensures this works
        try container.encode(createData, forKey: .createData, configuration: configuration)
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case code
        case codeVerifier
        case redirectUrl
        case createData
    }
}

struct AuthWithOAuth2BodyNoCreateData: EncodableWithConfiguration, Sendable {
    typealias EncodingConfiguration = PocketBase.EncodingConfiguration

    var provider: String
    var code: String
    var codeVerifier: String
    var redirectUrl: URL

    func encode(to encoder: any Encoder, configuration: PocketBase.EncodingConfiguration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(code, forKey: .code)
        try container.encode(codeVerifier, forKey: .codeVerifier)
        try container.encode(redirectUrl, forKey: .redirectUrl)
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case code
        case codeVerifier
        case redirectUrl
    }
}
