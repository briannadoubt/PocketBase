//
//  CollectionsAdmin+View.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Fetches a single collection schema by ID or name.
    ///
    /// - Parameter id: The collection ID or name.
    /// - Returns: The collection schema.
    public func view(id: String) async throws -> CollectionModel {
        try await get(path: "\(Self.basePath)/\(id)")
    }
}
