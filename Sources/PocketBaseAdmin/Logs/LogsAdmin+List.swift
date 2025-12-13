//
//  LogsAdmin+List.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension LogsAdmin {
    /// Fetches paginated request logs.
    ///
    /// - Parameters:
    ///   - page: The page number (1-indexed). Defaults to 1.
    ///   - perPage: Number of logs per page. Defaults to 30.
    ///   - filter: Optional filter expression (e.g., "level >= 4").
    /// - Returns: A paginated list of log entries.
    public func list(
        page: Int = 1,
        perPage: Int = 30,
        filter: String? = nil
    ) async throws -> LogsResponse {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "perPage", value: "\(perPage)")
        ]
        if let filter {
            query.append(URLQueryItem(name: "filter", value: filter))
        }
        return try await get(path: Self.basePath, query: query)
    }

    /// Fetches a single log entry by ID.
    ///
    /// - Parameter id: The log entry ID.
    /// - Returns: The log entry.
    public func view(id: String) async throws -> LogModel {
        try await get(path: "\(Self.basePath)/\(id)")
    }
}
