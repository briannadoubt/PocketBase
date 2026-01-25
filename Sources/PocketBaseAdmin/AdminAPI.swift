//
//  AdminAPI.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Fluent API entry point for PocketBase admin operations.
///
/// Access admin functionality through `pocketbase.admin`:
/// ```swift
/// let logs = try await pocketbase.admin.logs.list()
/// let collections = try await pocketbase.admin.collections.list()
/// let records = try await pocketbase.admin.records("_superusers").list()
/// let settings = try await pocketbase.admin.settings.get()
/// ```
public struct AdminAPI: Sendable {
    public let pocketbase: PocketBase

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }

    // MARK: - Admin Subsystems

    /// Access logs management.
    public var logs: LogsAdmin {
        LogsAdmin(pocketbase: pocketbase)
    }

    /// Access collection schema management.
    public var collections: CollectionsAdmin {
        CollectionsAdmin(pocketbase: pocketbase)
    }

    /// Access global settings management.
    public var settings: SettingsAdmin {
        SettingsAdmin(pocketbase: pocketbase)
    }

    /// Access backup management.
    public var backups: BackupsAdmin {
        BackupsAdmin(pocketbase: pocketbase)
    }

    /// Access health check.
    public var health: HealthAdmin {
        HealthAdmin(pocketbase: pocketbase)
    }

    /// Access records in a specific collection with admin privileges.
    /// - Parameter collection: The collection name or ID.
    /// - Returns: A records admin interface for the specified collection.
    public func records(_ collection: String) -> RecordsAdmin {
        RecordsAdmin(collection: collection, pocketbase: pocketbase)
    }
}
