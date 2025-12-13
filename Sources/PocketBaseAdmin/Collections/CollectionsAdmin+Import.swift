//
//  CollectionsAdmin+Import.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Imports collection schemas from a JSON array.
    ///
    /// This endpoint allows bulk importing of collection schemas,
    /// useful for syncing schemas between environments.
    ///
    /// - Parameters:
    ///   - collections: Array of collection schemas to import.
    ///   - deleteMissing: If true, deletes collections not in the import. Defaults to false.
    public func `import`(
        _ collections: [CollectionModel],
        deleteMissing: Bool = false
    ) async throws {
        let request = CollectionImportRequest(
            collections: collections,
            deleteMissing: deleteMissing
        )
        let body = try encoder.encode(request)
        _ = try await execute(method: "PUT", path: "\(Self.basePath)/import", body: body)
    }
}

/// Request body for importing collections.
struct CollectionImportRequest: Codable, Sendable {
    let collections: [CollectionModel]
    let deleteMissing: Bool
}
