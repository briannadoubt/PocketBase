//
//  RecordsAdmin+Delete.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension RecordsAdmin {
    /// Deletes a record by ID.
    ///
    /// - Parameter id: The record ID.
    public func delete(id: String) async throws {
        try await delete(path: "\(Self.basePath(collection))/\(id)")
    }
}
