//
//  BackupsAdmin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin interface for PocketBase backup management.
///
/// Provides operations for listing, creating, downloading,
/// uploading, restoring, and deleting database backups.
///
/// ```swift
/// // List all backups
/// let backups = try await pocketbase.admin.backups.list()
///
/// // Create a new backup
/// try await pocketbase.admin.backups.create(name: "my-backup.zip")
///
/// // Download a backup
/// let url = try await pocketbase.admin.backups.downloadURL(name: "my-backup.zip")
/// ```
public actor BackupsAdmin: AdminNetworking {
    public let pocketbase: PocketBase

    static let basePath = "/api/backups"

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }
}
