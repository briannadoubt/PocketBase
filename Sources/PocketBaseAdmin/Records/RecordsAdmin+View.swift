//
//  RecordsAdmin+View.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension RecordsAdmin {
    /// Fetches a single record by ID.
    ///
    /// - Parameters:
    ///   - id: The record ID.
    ///   - expand: Comma-separated list of relations to expand.
    /// - Returns: The record.
    public func view(id: String, expand: String? = nil) async throws -> RecordModel {
        var query: [URLQueryItem] = []
        if let expand {
            query.append(URLQueryItem(name: "expand", value: expand))
        }
        return try await get(path: "\(Self.basePath(collection))/\(id)", query: query)
    }
}
