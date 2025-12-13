//
//  LogsAdmin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin interface for PocketBase request logs.
///
/// Provides read-only access to server request logs for monitoring
/// and debugging purposes.
///
/// ```swift
/// // List logs with pagination
/// let response = try await pocketbase.admin.logs.list()
/// for log in response.items {
///     print("\(log.level.displayName): \(log.message)")
/// }
///
/// // Get log statistics for charting
/// let stats = try await pocketbase.admin.logs.stats()
/// ```
public actor LogsAdmin: AdminNetworking {
    public let pocketbase: PocketBase

    static let basePath = "/api/logs"
    static let statsPath = "/api/logs/stats"

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }
}
