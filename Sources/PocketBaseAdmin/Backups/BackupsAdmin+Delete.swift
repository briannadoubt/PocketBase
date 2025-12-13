//
//  BackupsAdmin+Delete.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension BackupsAdmin {
    /// Deletes a backup by name.
    ///
    /// - Parameter name: The backup file name.
    public func delete(name: String) async throws {
        try await delete(path: "\(Self.basePath)/\(name)")
    }
}
