//
//  User.swift
//  PocketBase
//
//  Created by Bri on 9/18/22.
//

import Foundation

public struct User<Profile: Codable>: BaseModel {
    public var id: UUID?
    public var created: Date
    public var updated: Date
    public var email: String
    public var verified: Bool
    public var lastResetSentAt: Date
    public var lastVerificationSentAt: Date
    public var profile: Profile?
}

public struct UserProfile: Model {
    public var id: UUID?
    public var collectionId: String
    public var collectionName: String
    public var expand: String
    public var created: Date
    public var updated: Date
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
