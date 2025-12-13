//
//  Superuser.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Represents a PocketBase superuser (admin) from the _superusers collection.
@AuthCollection("_superusers")
public struct Superuser {
    public init(
        id: String = "",
        username: String = "",
        email: String = "",
        verified: Bool = false,
        emailVisibility: Bool = false
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.verified = verified
        self.emailVisibility = emailVisibility
        self.created = Date()
        self.updated = Date()
        self.collectionName = Self.collection
    }
}
