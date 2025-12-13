//
//  SettingsAdmin+Get.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension SettingsAdmin {
    /// Fetches current server settings.
    ///
    /// - Returns: The current settings configuration.
    public func get() async throws -> SettingsModel {
        try await get(path: Self.basePath)
    }
}
