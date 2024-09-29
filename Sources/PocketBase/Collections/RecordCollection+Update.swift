//
//  RecordCollection+Update.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/5/24.
//

import Foundation

public extension RecordCollection {
    /// Returns a single collection record by its ID.
    ///
    /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
    ///
    /// *You could find individual generated records API documentation in the "Admin UI > Collections > API Preview".*
    /// - Parameters:
    ///   - record: The record to be updated, with the updates pre-applied.
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    @discardableResult
    func update(
        _ record: T
    ) async throws -> T {
        try await patch(
            path: PocketBase.recordPath(collection, record.id),
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers,
            body: record
        )
    }
}
