//
//  BackupsAdmin+Create.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension BackupsAdmin {
    /// Creates a new backup.
    ///
    /// - Parameter name: Optional backup name. If not provided, a timestamp-based name is used.
    public func create(name: String? = nil) async throws {
        var body: Data? = nil
        if let name {
            let request = BackupCreateRequest(name: name)
            body = try encoder.encode(request)
        }
        _ = try await execute(method: "POST", path: Self.basePath, body: body)
    }
}

/// Request body for creating a backup.
struct BackupCreateRequest: Codable, Sendable {
    let name: String
}
