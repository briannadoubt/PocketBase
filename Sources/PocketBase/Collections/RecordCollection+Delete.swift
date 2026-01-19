//
//  RecordCollection+Delete.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

// MARK: - Internal

extension RecordCollection where T: Record {
    /// Internal helper that performs the delete API call.
    @Sendable
    func deleteRecord(_ record: T) async throws {
        try await delete(
            path: PocketBase.recordPath(collection, record.id, trailingSlash: false),
            headers: headers
        )
    }
}

// MARK: - Public API

public extension RecordCollection where T: BaseRecord {
    /// Deletes a single collection Record by its ID.
    ///
    /// - note: Depending on the collection's `deleteRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The record to be deleted
    @Sendable
    func delete(_ record: T) async throws {
        try await deleteRecord(record)
    }
}

public extension RecordCollection where T: AuthRecord {
    /// Deletes a single collection Record by its ID.
    ///
    /// - note: Depending on the collection's `deleteRule` value, the access to this action may or may not have been restricted.
    /// - Parameters:
    ///   - record: The record to be deleted
    @Sendable
    func delete(_ record: T) async throws {
        try await deleteRecord(record)
        pocketbase.authStore.clear()
    }
}
