//
//  HealthModel.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

/// Health check response from PocketBase.
public struct HealthStatus: Codable, Sendable, Hashable {
    /// HTTP status code (should be 200 for healthy).
    public let code: Int

    /// Health status message.
    public let message: String

    /// Detailed health data.
    public let data: HealthData

    public init(
        code: Int,
        message: String,
        data: HealthData
    ) {
        self.code = code
        self.message = message
        self.data = data
    }
}

/// Detailed health information.
public struct HealthData: Codable, Sendable, Hashable {
    /// Whether the server can handle new requests.
    public let canBackup: Bool

    /// PocketBase version string.
    public let version: String?

    public init(
        canBackup: Bool,
        version: String? = nil
    ) {
        self.canBackup = canBackup
        self.version = version
    }
}
