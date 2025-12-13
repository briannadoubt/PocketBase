//
//  RecordsAdmin+List.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension RecordsAdmin {
    /// Fetches paginated records from the collection.
    ///
    /// - Parameters:
    ///   - page: The page number (1-indexed). Defaults to 1.
    ///   - perPage: Number of records per page. Defaults to 30.
    ///   - sort: Sort expression (e.g., "-created" for descending by created).
    ///   - filter: Filter expression (e.g., "verified = true").
    ///   - expand: Comma-separated list of relations to expand.
    /// - Returns: A paginated list of records.
    public func list(
        page: Int = 1,
        perPage: Int = 30,
        sort: String? = nil,
        filter: String? = nil,
        expand: String? = nil
    ) async throws -> RecordsResponse {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "perPage", value: "\(perPage)")
        ]
        if let sort {
            query.append(URLQueryItem(name: "sort", value: sort))
        }
        if let filter {
            query.append(URLQueryItem(name: "filter", value: filter))
        }
        if let expand {
            query.append(URLQueryItem(name: "expand", value: expand))
        }
        return try await get(path: Self.basePath(collection), query: query)
    }
}
