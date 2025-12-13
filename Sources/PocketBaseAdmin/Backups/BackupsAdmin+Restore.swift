//
//  BackupsAdmin+Restore.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension BackupsAdmin {
    /// Restores the database from a backup.
    ///
    /// **Warning:** This will replace the current database with the backup.
    /// The server will restart after restoration.
    ///
    /// - Parameter name: The backup file name to restore.
    public func restore(name: String) async throws {
        _ = try await execute(method: "POST", path: "\(Self.basePath)/\(name)/restore")
    }
}
