//
//  AdminRecord.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Represents an admin account in PocketBase.
/// Admins have full access to all admin APIs and can manage the entire PocketBase instance.
public struct AdminRecord: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let created: Date
    public let updated: Date
    public var email: String
    public var avatar: Int

    public init(
        id: String = "",
        created: Date = Date(),
        updated: Date = Date(),
        email: String,
        avatar: Int = 0
    ) {
        self.id = id
        self.created = created
        self.updated = updated
        self.email = email
        self.avatar = avatar
    }
}

/// Response type for admin authentication.
public struct AdminAuthResponse: Codable, Sendable, Hashable {
    public let token: String
    public let admin: AdminRecord
}
