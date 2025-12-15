//
//  PocketBaseDatabasePlugin.swift
//  PocketBase
//
//  A SwiftPM command plugin for managing the PocketBase database.
//

import Foundation
import PackagePlugin

@main
struct PocketBaseDatabasePlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            printUsage()
            return
        }

        let command = arguments[0]
        let remainingArgs = Array(arguments.dropFirst())

        // Find the pb_data directory
        let dataPath = findDataPath(context: context, args: remainingArgs)

        switch command {
        case "clear":
            try clearDatabase(dataPath: dataPath)
        case "backup":
            try backupDatabase(dataPath: dataPath, args: remainingArgs)
        case "restore":
            try restoreDatabase(dataPath: dataPath, args: remainingArgs)
        case "info":
            showDatabaseInfo(dataPath: dataPath)
        case "path":
            print(dataPath)
        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }

    private func printUsage() {
        print("""
        PocketBase Database Management

        Usage: swift package pocketbase-db <command> [options]

        Commands:
          clear              Clear all data (removes pb_data contents)
          backup [name]      Create a backup of pb_data
          restore <name>     Restore from a backup
          info               Show database info
          path               Print the pb_data path

        Options:
          --data-path <path>  Custom path to pb_data directory (default: ./pb_data)

        Examples:
          swift package pocketbase-db clear
          swift package pocketbase-db backup my-backup
          swift package pocketbase-db restore my-backup
          swift package pocketbase-db info
        """)
    }

    private func findDataPath(context: PluginContext, args: [String]) -> String {
        // Check for --data-path argument
        if let index = args.firstIndex(of: "--data-path"), index + 1 < args.count {
            return args[index + 1]
        }

        // Default to pb_data in the package directory
        return context.package.directoryURL.appendingPathComponent("pb_data").path
    }

    private func clearDatabase(dataPath: String) throws {
        let url = URL(fileURLWithPath: dataPath)

        guard FileManager.default.fileExists(atPath: dataPath) else {
            print("No database found at: \(dataPath)")
            return
        }

        print("⚠️  This will permanently delete all data in: \(dataPath)")
        print("Press Enter to continue or Ctrl+C to cancel...")

        _ = readLine()

        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for item in contents {
            try FileManager.default.removeItem(at: item)
        }

        print("✅ Database cleared")
    }

    private func backupDatabase(dataPath: String, args: [String]) throws {
        let url = URL(fileURLWithPath: dataPath)

        guard FileManager.default.fileExists(atPath: dataPath) else {
            print("No database found at: \(dataPath)")
            return
        }

        let backupName = args.first(where: { !$0.hasPrefix("--") }) ?? "backup-\(ISO8601DateFormatter().string(from: Date()))"
        let backupsDir = url.deletingLastPathComponent().appendingPathComponent("pb_backups")
        let backupPath = backupsDir.appendingPathComponent(backupName)

        // Create backups directory
        try FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)

        // Copy pb_data to backup location
        if FileManager.default.fileExists(atPath: backupPath.path) {
            try FileManager.default.removeItem(at: backupPath)
        }
        try FileManager.default.copyItem(at: url, to: backupPath)

        print("✅ Backup created: \(backupPath.path)")
    }

    private func restoreDatabase(dataPath: String, args: [String]) throws {
        let url = URL(fileURLWithPath: dataPath)
        let backupsDir = url.deletingLastPathComponent().appendingPathComponent("pb_backups")

        guard let backupName = args.first(where: { !$0.hasPrefix("--") }) else {
            // List available backups
            print("Available backups:")
            if FileManager.default.fileExists(atPath: backupsDir.path) {
                let backups = try FileManager.default.contentsOfDirectory(atPath: backupsDir.path)
                for backup in backups {
                    print("  - \(backup)")
                }
            } else {
                print("  No backups found")
            }
            print("\nUsage: swift package pocketbase-db restore <backup-name>")
            return
        }

        let backupPath = backupsDir.appendingPathComponent(backupName)

        guard FileManager.default.fileExists(atPath: backupPath.path) else {
            print("Backup not found: \(backupPath.path)")
            return
        }

        print("⚠️  This will replace the current database with: \(backupName)")
        print("Press Enter to continue or Ctrl+C to cancel...")

        _ = readLine()

        // Remove current data
        if FileManager.default.fileExists(atPath: dataPath) {
            try FileManager.default.removeItem(at: url)
        }

        // Restore from backup
        try FileManager.default.copyItem(at: backupPath, to: url)

        print("✅ Database restored from: \(backupName)")
    }

    private func showDatabaseInfo(dataPath: String) {
        let url = URL(fileURLWithPath: dataPath)

        print("PocketBase Database Info")
        print("========================")
        print("Path: \(dataPath)")

        guard FileManager.default.fileExists(atPath: dataPath) else {
            print("Status: Not initialized")
            return
        }

        print("Status: Initialized")

        // Show directory size
        if let size = directorySize(url: url) {
            print("Size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
        }

        // List contents
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: dataPath) {
            print("Contents:")
            for item in contents.sorted() {
                let itemPath = url.appendingPathComponent(item)
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: itemPath.path, isDirectory: &isDir)
                let type = isDir.boolValue ? "📁" : "📄"
                print("  \(type) \(item)")
            }
        }
    }

    private func directorySize(url: URL) -> UInt64? {
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var totalSize: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  let isDirectory = resourceValues.isDirectory,
                  !isDirectory,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += UInt64(fileSize)
        }
        return totalSize
    }
}
