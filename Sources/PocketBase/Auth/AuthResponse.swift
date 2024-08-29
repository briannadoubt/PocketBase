//
//  AuthResponse.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public struct AuthResponse<T: AuthRecord>: Codable, Sendable, Hashable {
    var token: String
    var record: T
    var meta: MetaOAuth2Response?
}
