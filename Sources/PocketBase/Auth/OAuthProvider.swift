//
//  OAuthProvider.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct OAuthProvider: Codable, Sendable, Identifiable, Equatable, CustomStringConvertible {
    public var id: String { name }
    public var name: String
    public var state: String
    public var codeVerifier: String
    public var codeChallenge: String
    public var codeChallengeMethod: String
    public var authUrl: URL

    /// Custom description to avoid Swift Testing crashes when displaying URLs
    public var description: String {
        "OAuthProvider(name: \(name), authUrl: \(authUrl.absoluteString))"
    }
}
