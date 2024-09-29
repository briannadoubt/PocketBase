//
//  RecordCollection+Delete.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection where T: BaseRecord {
    /// Deletes a single collection Record by its ID.
    ///
    /// Depending on the collection's `deleteRule` value, the access to this action may or may not have been restricted.
    ///
    /// *You could find individual generated records API documentation in the "Admin UI > Collections > API Preview".*
    /// - Parameters:
    ///   - record: The record to be deleted
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    func delete(_ record: T) async throws {
        try await delete(
            path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
            headers: headers
        )
    }
}

public extension RecordCollection where T: AuthRecord {
    /// Deletes a single collection Record by its ID.
    ///
    /// Depending on the collection's `deleteRule` value, the access to this action may or may not have been restricted.
    ///
    /// *You could find individual generated records API documentation in the "Admin UI > Collections > API Preview".*
    /// - Parameters:
    ///   - record: The record to be deleted
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    func delete(_ record: T) async throws {
        try await delete(
            path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
            headers: headers
        )
        pocketbase.authStore.clear()
    }
}
