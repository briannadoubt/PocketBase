//
//  MetaOAuth2Response.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct MetaOAuth2Response: Codable, Sendable, Hashable {
    // "id": "abc123",
    var id: String
    // "name": "John Doe",
    var name: String
    // "username": "john.doe",
    var username: String
    // "email": "test@example.com",
    var email: String
    // "isNew": false,
    var isNew: Bool
    // "avatarUrl": "https://example.com/avatar.png",
    var avatarUrl: URL
    // "rawUser": {...},
    var rawUser: Data
    // "accessToken": "...",
    var accessToken: String
    // "refreshToken": "...",
    var refreshToken: String
    // "expiry": "..."
    var expiry: Date
}
