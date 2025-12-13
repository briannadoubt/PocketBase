//
//  HealthAdmin+Check.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension HealthAdmin {
    /// Performs a health check on the PocketBase server.
    ///
    /// - Returns: The health status including version and system info.
    public func check() async throws -> HealthStatus {
        try await get(path: Self.basePath)
    }
}
