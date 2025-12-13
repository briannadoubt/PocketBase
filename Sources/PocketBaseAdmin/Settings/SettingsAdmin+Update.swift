//
//  SettingsAdmin+Update.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension SettingsAdmin {
    /// Updates server settings.
    ///
    /// Only non-nil fields in the model will be updated.
    ///
    /// - Parameter settings: The settings to update.
    /// - Returns: The updated settings.
    @discardableResult
    public func update(_ settings: SettingsModel) async throws -> SettingsModel {
        let body = try encoder.encode(settings)
        return try await patch(path: Self.basePath, body: body)
    }
}
