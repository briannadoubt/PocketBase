//
//  RecordCollection+View.swift
//  PocketBase
//
//  Created by Brianna Zamora on 8/3/24.
//

import Foundation

public extension RecordCollection {
    /// Returns a single collection record by its ID.
    ///
    /// Depending on the collection's viewRule value, the access to this action may or may not have been restricted.
    ///
    /// *You could find individual generated records API documentation in the "Admin UI > Collections > API Preview".*
    /// - Parameters:
    ///   - id: ID of the record to view.
    /// - Returns: Returns a single collection record by its ID.
    @Sendable
    func view(
        id recordId: String
    ) async throws -> T {
        try await get(
            path: PocketBase.recordPath(collection, recordId, trailingSlash: false),
            query: {
                var query: [URLQueryItem] = []
                if !T.relations.isEmpty {
                    query.append(URLQueryItem(name: "expand", value: T.relations.keys.joined(separator: ",")))
                }
                return query
            }(),
            headers: headers
        )
    }
}
