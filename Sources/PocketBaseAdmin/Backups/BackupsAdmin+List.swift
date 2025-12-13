//
//  BackupsAdmin+List.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension BackupsAdmin {
    /// Fetches all available backups.
    ///
    /// - Returns: An array of backup records.
    public func list() async throws -> [BackupModel] {
        try await get(path: Self.basePath)
    }
}
