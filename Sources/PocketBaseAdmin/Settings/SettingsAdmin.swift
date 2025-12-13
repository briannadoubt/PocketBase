//
//  SettingsAdmin.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Admin interface for PocketBase global settings.
///
/// Provides access to application settings including metadata,
/// token durations, SMTP, S3, and backup configurations.
///
/// ```swift
/// // Get current settings
/// let settings = try await pocketbase.admin.settings.get()
///
/// // Update settings
/// var updated = settings
/// updated.meta?.appName = "My App"
/// try await pocketbase.admin.settings.update(updated)
/// ```
public actor SettingsAdmin: AdminNetworking {
    public let pocketbase: PocketBase

    static let basePath = "/api/settings"

    public init(pocketbase: PocketBase) {
        self.pocketbase = pocketbase
    }
}
