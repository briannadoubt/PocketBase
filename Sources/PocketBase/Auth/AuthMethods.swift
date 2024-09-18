//
//  AuthMethods.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

public struct AuthMethods: Decodable, Sendable {
    public var usernamePassword: Bool
    public var emailPassword: Bool
    public var authProviders: [OAuthProvider]
}