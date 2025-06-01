//
//  Oauth2Methods.swift
//  PocketBase
//
//  Created by Konstantin Gerry on 01/06/2025.
//


public struct Oauth2Methods: Codable, Sendable, Equatable {
    public var providers: [OAuthProvider]
    public var enabled: Bool
}
