//
//  BackupModel.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

/// Represents a backup file from PocketBase.
public struct BackupModel: Codable, Identifiable, Sendable, Hashable {
    /// The backup file name (serves as the ID).
    public let key: String

    /// The backup file size in bytes.
    public let size: Int

    /// The modification time of the backup.
    public let modified: Date

    public var id: String { key }

    public init(
        key: String,
        size: Int,
        modified: Date
    ) {
        self.key = key
        self.size = size
        self.modified = modified
    }
}

// MARK: - Size Formatting

public extension BackupModel {
    /// Human-readable file size.
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
