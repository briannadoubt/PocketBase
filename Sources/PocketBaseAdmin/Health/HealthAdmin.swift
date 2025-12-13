//
//  HealthAdmin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin interface for PocketBase health checks.
///
/// Provides access to server health status including
/// version information and system metrics.
///
/// ```swift
/// let health = try await pocketbase.admin.health.check()
/// print("PocketBase version: \(health.data.version)")
/// ```
public actor HealthAdmin: AdminNetworking {
    public let pocketbase: PocketBase

    static let basePath = "/api/health"

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }
}
