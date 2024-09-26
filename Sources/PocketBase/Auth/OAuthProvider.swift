//
//  OAuthProvider.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct OAuthProvider: Codable, Sendable, Identifiable, Equatable {
    public var id: String { name }
    public var name: String
    public var state: String
    public var codeVerifier: String
    public var codeChallenge: String
    public var codeChallengeMethod: String
    public var authUrl: URL
}
