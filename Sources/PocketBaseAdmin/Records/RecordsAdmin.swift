//
//  RecordsAdmin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin interface for accessing records in any collection.
///
/// Provides full CRUD operations and realtime event streaming
/// with admin privileges, allowing access to any collection.
///
/// ```swift
/// // List records from a collection
/// let users = try await pocketbase.admin.records("_superusers").list()
///
/// // Subscribe to record events
/// for await event in try await pocketbase.admin.records("posts").events() {
///     switch event.action {
///     case .create: print("Created: \(event.record.id)")
///     case .update: print("Updated: \(event.record.id)")
///     case .delete: print("Deleted: \(event.record.id)")
///     }
/// }
/// ```
public actor RecordsAdmin: AdminNetworking {
    public let collection: String
    public let pocketbase: PocketBase

    static func basePath(_ collection: String) -> String {
        "/api/collections/\(collection)/records"
    }

    public init(collection: String, pocketbase: PocketBase) {
        self.collection = collection
        self.pocketbase = pocketbase
    }
}
