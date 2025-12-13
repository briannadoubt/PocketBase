//
//  CollectionsAdmin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin interface for PocketBase collection schema management.
///
/// Provides full CRUD operations for collection schemas, including
/// creating, viewing, updating, and deleting collections.
///
/// ```swift
/// // List all collections
/// let response = try await pocketbase.admin.collections.list()
///
/// // View a specific collection
/// let posts = try await pocketbase.admin.collections.view(id: "posts")
///
/// // Create a new collection
/// try await pocketbase.admin.collections.create(newCollectionSchema)
///
/// // Delete a collection
/// try await pocketbase.admin.collections.delete(id: "posts")
/// ```
public actor CollectionsAdmin: AdminNetworking {
    public let pocketbase: PocketBase

    static let basePath = "/api/collections"

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }
}
