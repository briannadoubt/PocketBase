//
//  CollectionsAdmin+List.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Fetches all collection schemas.
    ///
    /// - Parameters:
    ///   - page: The page number (1-indexed). Defaults to 1.
    ///   - perPage: Number of collections per page. Defaults to 100.
    /// - Returns: A paginated list of collection schemas.
    public func list(
        page: Int = 1,
        perPage: Int = 100
    ) async throws -> CollectionsResponse {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "perPage", value: "\(perPage)")
        ]
        return try await get(path: Self.basePath, query: query)
    }
}
