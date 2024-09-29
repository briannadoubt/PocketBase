//
//  PocketBase+AuthWithPassword.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection where T: AuthRecord {
    /// The easiest way to authenticate your app users is with their username/email and password.
    ///
    /// You can customize the supported authentication options from your Auth collection configuration (including disabling all auth options).
    /// - Parameters:
    ///   - identity: The username or email that the user types in
    ///   - password: The password for the new user

    /// - Returns: The auth response containing a token and a record
    @Sendable
    @discardableResult
    func authWithPassword(
        _ identity: String,
        password: String
    ) async throws -> AuthResponse<T> {
        let response: AuthResponse<T> = try await post(
            path: PocketBase.collectionPath(collection) + "auth-with-password",
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers,
            body: AuthWithPasswordBody(identity: identity, password: password)
        )
        try pocketbase.authStore.set(response)
        return response
    }
}

struct AuthWithPasswordBody: EncodableWithConfiguration, Decodable, Equatable {
    func encode(to encoder: any Encoder, configuration: PocketBase.EncodingConfiguration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identity, forKey: .identity)
        try container.encode(password, forKey: .password)
    }
    
    enum CodingKeys: String, CodingKey {
        case identity
        case password
    }
    
    typealias EncodingConfiguration = PocketBase.EncodingConfiguration
    
    var identity: String
    var password: String
}
