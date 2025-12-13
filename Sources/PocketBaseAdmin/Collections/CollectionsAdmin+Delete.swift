//
//  CollectionsAdmin+Delete.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Deletes a collection by ID or name.
    ///
    /// - Parameter id: The collection ID or name.
    public func delete(id: String) async throws {
        try await delete(path: "\(Self.basePath)/\(id)")
    }
}
