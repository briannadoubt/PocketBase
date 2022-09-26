//
//  User.swift
//  PocketBase
//
//  Created by Bri on 9/18/22.
//

import Foundation

public struct User<Profile: Codable>: BaseModel {
    public var id: String?
    public var created: String?
    public var updated: String?
    public var email: String
    public var verified: Bool
    public var lastResetSentAt: String?
    public var lastVerificationSentAt: String?
    public var profile: Profile?
}

// MARK: User Sort Keys
public extension SortKey {
    var email: SortKey {
        .custom(key: "email")
    }
    var verified: SortKey {
        .custom(key: "verified")
    }
}
