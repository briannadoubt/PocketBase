//
//  PocketBase+Admin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

extension PocketBase {
    /// Access the admin API for superuser operations.
    ///
    /// Provides a fluent interface to administrative endpoints including
    /// logs, collections, records, settings, backups, and health checks.
    ///
    /// ```swift
    /// // Access logs
    /// let logs = try await pocketbase.admin.logs.list()
    ///
    /// // Access collections
    /// let collections = try await pocketbase.admin.collections.list()
    ///
    /// // Access records with admin privileges
    /// let users = try await pocketbase.admin.records("_superusers").list()
    ///
    /// // Access settings
    /// let settings = try await pocketbase.admin.settings.get()
    ///
    /// // Access backups
    /// let backups = try await pocketbase.admin.backups.list()
    ///
    /// // Check server health
    /// let health = try await pocketbase.admin.health.check()
    /// ```
    public var admin: AdminAPI {
        AdminAPI(pocketbase: self)
    }
}
