//
//  ObservableSettings.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import PocketBase

/// Observable wrapper for admin settings management.
///
/// Provides an observable settings object that can be used in SwiftUI views.
/// Uses the fluent SettingsAdmin API internally.
///
/// ```swift
/// @State private var settings = Admin.Settings()
///
/// // Load settings
/// try await settings.load(pocketbase: pocketbase)
///
/// // Access settings
/// if let appName = settings.meta?.appName {
///     Text(appName)
/// }
///
/// // Update settings
/// settings.meta?.appName = "My App"
/// try await settings.update(pocketbase: pocketbase)
/// ```
extension Admin {
    @Observable
    @MainActor
    public final class Settings: Sendable {
        // MARK: - Meta

        public var meta: Meta?

        // MARK: - Admin Token Options

        public var adminAuthToken: TokenDuration?
        public var adminPasswordResetToken: TokenDuration?
        public var adminFileToken: TokenDuration?

        // MARK: - Record Token Options

        public var recordAuthToken: TokenDuration?
        public var recordPasswordResetToken: TokenDuration?
        public var recordEmailChangeToken: TokenDuration?
        public var recordVerificationToken: TokenDuration?
        public var recordFileToken: TokenDuration?

        // MARK: - Logs

        public var logs: LogsSettings?

        // MARK: - SMTP

        public var smtp: SMTPSettings?

        // MARK: - S3

        public var s3: S3Settings?

        // MARK: - Backups

        public var backups: BackupsSettings?

        public init() {}

        /// Loads settings from the PocketBase server.
        public func load(pocketbase: PocketBase) async throws {
            let response = try await pocketbase.admin.settings.get()
            await MainActor.run {
                self.meta = response.meta
                self.adminAuthToken = response.adminAuthToken.map { TokenDuration($0) }
                self.adminPasswordResetToken = response.adminPasswordResetToken.map { TokenDuration($0) }
                self.adminFileToken = response.adminFileToken.map { TokenDuration($0) }
                self.recordAuthToken = response.recordAuthToken.map { TokenDuration($0) }
                self.recordPasswordResetToken = response.recordPasswordResetToken.map { TokenDuration($0) }
                self.recordEmailChangeToken = response.recordEmailChangeToken.map { TokenDuration($0) }
                self.recordVerificationToken = response.recordVerificationToken.map { TokenDuration($0) }
                self.recordFileToken = response.recordFileToken.map { TokenDuration($0) }
                self.logs = response.logs
                self.smtp = response.smtp
                self.s3 = response.s3
                self.backups = response.backups
            }
        }

        /// Updates settings on the PocketBase server.
        public func update(pocketbase: PocketBase) async throws {
            let request = SettingsModel(
                meta: meta,
                adminAuthToken: adminAuthToken?.duration,
                adminPasswordResetToken: adminPasswordResetToken?.duration,
                adminFileToken: adminFileToken?.duration,
                recordAuthToken: recordAuthToken?.duration,
                recordPasswordResetToken: recordPasswordResetToken?.duration,
                recordEmailChangeToken: recordEmailChangeToken?.duration,
                recordVerificationToken: recordVerificationToken?.duration,
                recordFileToken: recordFileToken?.duration,
                logs: logs,
                smtp: smtp,
                s3: s3,
                backups: backups
            )
            _ = try await pocketbase.admin.settings.update(request)
        }
    }
}

// Keep the old Admin type for backwards compatibility with the Settings nested class
public enum Admin {}
