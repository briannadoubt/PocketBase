//
//  LogsAdmin+Stats.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension LogsAdmin {
    /// Fetches aggregated log statistics for charting.
    ///
    /// Returns statistics grouped by date, useful for visualizing
    /// request volume over time.
    ///
    /// - Parameter filter: Optional filter expression to narrow down stats.
    /// - Returns: An array of log statistics grouped by date.
    public func stats(filter: String? = nil) async throws -> [LogStat] {
        var query: [URLQueryItem] = []
        if let filter {
            query.append(URLQueryItem(name: "filter", value: filter))
        }
        return try await get(path: Self.statsPath, query: query)
    }
}
