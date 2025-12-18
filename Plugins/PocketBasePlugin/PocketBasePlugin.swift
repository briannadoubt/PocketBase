//
//  PocketBasePlugin.swift
//  PocketBase
//
//  Unified SwiftPM command plugin for PocketBase development.
//  Consolidates build, run, container, and database management commands.
//

import Foundation
import PackagePlugin

@main
struct PocketBasePlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            printUsage()
            return
        }

        let subcommandArgs = Array(arguments.dropFirst())

        switch subcommand {
        case "build":
            try await buildCommand(context: context, arguments: subcommandArgs)
        case "run":
            try await runCommand(context: context, arguments: subcommandArgs)
        case "container":
            try await containerCommand(context: context, arguments: subcommandArgs)
        case "db":
            try dbCommand(context: context, arguments: subcommandArgs)
        case "--help", "-h", "help":
            printUsage()
        default:
            print("Unknown subcommand: \(subcommand)")
            print("")
            printUsage()
        }
    }

    private func printUsage() {
        print("""
        PocketBase Development Tools
        ============================

        Usage: swift package pocketbase <command> [options]

        Commands:
          build       Build and sign PocketBaseServer
          run         Build, sign, and run PocketBaseServer
          container   Manage the Apple Container system
          db          Database management utilities

        Run 'swift package pocketbase <command> --help' for more information.

        Examples:
          swift package pocketbase build --release
          swift package pocketbase run -- --port 8080
          swift package pocketbase container start
          swift package pocketbase db backup my-backup
        """)
    }
}

// MARK: - Shared Utilities

extension PocketBasePlugin {
    /// Find the container CLI binary
    func findContainerCLI() -> String? {
        let paths = [
            "/opt/homebrew/bin/container",
            "/usr/local/bin/container",
            "/usr/bin/container"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Try which command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["container"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Ignore errors
        }

        return nil
    }

    /// Find the entitlements file for PocketBaseServer
    func findEntitlementsPath(context: PluginContext) -> URL? {
        let possiblePaths = [
            // Direct path (when run from PocketBase package itself)
            context.package.directoryURL.appendingPathComponent(
                "Sources/PocketBaseServer/PocketBaseServer.entitlements"
            ),
            // Checkouts path (when PocketBase is a remote dependency)
            context.package.directoryURL.appendingPathComponent(
                ".build/checkouts/PocketBase/Sources/PocketBaseServer/PocketBaseServer.entitlements"
            ),
            // Local package path (when PocketBase is referenced as ../PocketBase)
            context.package.directoryURL.appendingPathComponent(
                "../PocketBase/Sources/PocketBaseServer/PocketBaseServer.entitlements"
            ),
        ]

        return possiblePaths.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Get the binary path for PocketBaseServer
    func binaryPath(context: PluginContext, release: Bool) -> URL {
        let configuration = release ? "release" : "debug"
        return context.package.directoryURL
            .appendingPathComponent(".build")
            .appendingPathComponent(configuration)
            .appendingPathComponent("PocketBaseServer")
    }

    /// Build PocketBaseServer
    func buildServer(context: PluginContext, release: Bool, verbose: Bool) throws -> Bool {
        let configuration = release ? "release" : "debug"
        print("📦 Building PocketBaseServer (\(configuration))...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["build", "--package-path", context.package.directoryURL.path, "--product", "PocketBaseServer", "-c", configuration]

        if verbose {
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
        } else {
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
        }

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("✅ Build succeeded")
            return true
        } else {
            print("❌ Build failed with exit code \(process.terminationStatus)")
            return false
        }
    }

    /// Sign the binary with entitlements
    func signBinary(binaryPath: URL, entitlementsPath: URL) throws -> Bool {
        print("🔏 Signing binary with entitlements...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = [
            "--force",
            "--sign", "-",
            "--entitlements", entitlementsPath.path,
            binaryPath.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("✅ Binary signed")
            return true
        } else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            print("❌ Code signing failed: \(output)")
            return false
        }
    }

    /// Run a process and capture output
    func runProcess(_ executable: String, arguments: [String], verbose: Bool) throws -> (exitCode: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = verbose ? FileHandle.standardOutput : pipe
        process.standardError = verbose ? FileHandle.standardError : pipe

        try process.run()
        process.waitUntilExit()

        var output = ""
        if !verbose {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8) ?? ""
        }

        return (process.terminationStatus, output)
    }

    /// Calculate directory size
    func directorySize(url: URL) -> UInt64? {
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

// MARK: - Build Command

extension PocketBasePlugin {
    func buildCommand(context: PluginContext, arguments: [String]) async throws {
        var release = false
        var run = false
        var verbose = false
        var serverArgs: [String] = []

        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--release":
                release = true
            case "--run":
                run = true
            case "--verbose", "-v":
                verbose = true
            case "--help", "-h":
                printBuildHelp()
                return
            case "--":
                serverArgs = Array(arguments[(i + 1)...])
                i = arguments.count
            default:
                serverArgs.append(arguments[i])
            }
            i += 1
        }

        // Build
        guard try buildServer(context: context, release: release, verbose: verbose) else {
            throw PocketBasePluginError.buildFailed
        }

        // Find entitlements
        guard let entitlementsPath = findEntitlementsPath(context: context) else {
            print("❌ Could not find PocketBaseServer.entitlements")
            throw PocketBasePluginError.entitlementsNotFound
        }

        // Sign
        let binary = binaryPath(context: context, release: release)
        guard try signBinary(binaryPath: binary, entitlementsPath: entitlementsPath) else {
            throw PocketBasePluginError.signingFailed
        }

        print("")
        print("✅ Build complete: \(binary.path)")

        // Run if requested
        if run {
            print("")
            print("🚀 Starting PocketBaseServer...")

            let runProcess = Process()
            runProcess.executableURL = binary
            runProcess.arguments = serverArgs
            runProcess.currentDirectoryURL = context.package.directoryURL
            runProcess.standardOutput = FileHandle.standardOutput
            runProcess.standardError = FileHandle.standardError

            try runProcess.run()
            runProcess.waitUntilExit()
        }
    }

    private func printBuildHelp() {
        print("""
        Usage: swift package pocketbase build [options] [-- server-args]

        Options:
          --release     Build in release mode (default: debug)
          --run         Run the server after building
          --verbose     Show verbose build output
          --help, -h    Show this help

        Examples:
          swift package pocketbase build
          swift package pocketbase build --release
          swift package pocketbase build --run -- --port 8080
        """)
    }
}

// MARK: - Run Command

extension PocketBasePlugin {
    func runCommand(context: PluginContext, arguments: [String]) async throws {
        print("🚀 PocketBase Server Runner")
        print("===========================")
        print("")

        var skipBuild = false
        var release = false
        var verbose = false
        var serverArgs: [String] = []

        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--skip-build":
                skipBuild = true
            case "--release":
                release = true
            case "--verbose", "-v":
                verbose = true
            case "--help", "-h":
                printRunHelp()
                return
            case "--":
                serverArgs = Array(arguments[(i + 1)...])
                i = arguments.count
            default:
                serverArgs.append(arguments[i])
            }
            i += 1
        }

        // Step 1: Build (unless skipped)
        if !skipBuild {
            guard try buildServer(context: context, release: release, verbose: verbose) else {
                throw PocketBasePluginError.buildFailed
            }
            print("")
        }

        // Step 2: Verify binary exists
        let binary = binaryPath(context: context, release: release)
        guard FileManager.default.fileExists(atPath: binary.path) else {
            print("❌ Binary not found at \(binary.path)")
            throw PocketBasePluginError.binaryNotFound
        }

        // Step 3: Sign with entitlements
        guard let entitlementsPath = findEntitlementsPath(context: context) else {
            print("❌ Could not find PocketBaseServer.entitlements")
            throw PocketBasePluginError.entitlementsNotFound
        }

        guard try signBinary(binaryPath: binary, entitlementsPath: entitlementsPath) else {
            throw PocketBasePluginError.signingFailed
        }
        print("")

        // Step 4: Ensure container runtime is running
        print("🐳 Checking container runtime...")
        if let containerPath = findContainerCLI() {
            let statusResult = try runProcess(containerPath, arguments: ["system", "status"], verbose: false)

            if statusResult.output.lowercased().contains("not running") || statusResult.exitCode != 0 {
                print("   Container system not running, starting...")
                let startResult = try runProcess(containerPath, arguments: ["system", "start"], verbose: false)
                if startResult.exitCode != 0 {
                    print("⚠️  Failed to start container system: \(startResult.output)")
                    print("   You may need to start it manually: container system start")
                } else {
                    print("✅ Container system started")
                }
            } else {
                print("✅ Container system running")
            }
        } else {
            print("⚠️  Container CLI not found. Install with: brew install apple/container/container")
        }
        print("")

        // Step 5: Launch the server
        print("🚀 Launching PocketBaseServer...")
        print("   Press Ctrl+C to stop")
        print("")
        print("─────────────────────────────────────────")
        print("")

        let process = Process()
        process.executableURL = binary
        process.arguments = serverArgs
        process.currentDirectoryURL = context.package.directoryURL
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        // Handle Ctrl+C
        signal(SIGINT, SIG_IGN)
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSource.setEventHandler {
            print("\n\n🛑 Stopping server...")
            process.terminate()
        }
        sigintSource.resume()

        try process.run()
        process.waitUntilExit()

        print("")
        print("─────────────────────────────────────────")
        print("Server exited with code: \(process.terminationStatus)")
    }

    private func printRunHelp() {
        print("""
        Usage: swift package pocketbase run [options] [-- server-options]

        Options:
          --skip-build    Skip building (use existing binary)
          --release       Build/use release binary (default: debug)
          --verbose       Enable verbose output
          --help, -h      Show this help

        Server Options (passed to PocketBaseServer):
          -p, --port      Port to expose PocketBase on (default: 8090)
          -d, --dataPath  Path to data directory (default: ./pb_data)
          --cpus          Number of CPUs to allocate (default: 2)
          --memory        Memory in MB to allocate (default: 512)
          --verbose       Enable verbose output

        Examples:
          swift package pocketbase run
          swift package pocketbase run -- --port 8080 --verbose
          swift package pocketbase run --skip-build -- -p 9090
        """)
    }
}

// MARK: - Container Command

extension PocketBasePlugin {
    func containerCommand(context: PluginContext, arguments: [String]) async throws {
        print("🐳 PocketBase Container Setup")
        print("==============================")
        print("")

        #if !os(macOS)
        print("❌ Container support is only available on macOS")
        throw PocketBasePluginError.unsupportedPlatform
        #endif

        var action: ContainerAction = .status

        for arg in arguments {
            switch arg {
            case "start":
                action = .start
            case "stop":
                action = .stop
            case "status":
                action = .status
            case "install":
                action = .install
            case "--help", "-h":
                printContainerHelp()
                return
            default:
                print("Unknown argument: \(arg)")
                printContainerHelp()
                return
            }
        }

        // Check if container CLI is available
        let containerPath = findContainerCLI()

        if containerPath == nil {
            print("⚠️  Apple Container CLI not found")
            print("")
            print("To install, run:")
            print("  brew install apple/container/container")
            print("")

            if action == .install {
                try await installContainerCLI()
            } else {
                print("Run with 'install' argument to install automatically:")
                print("  swift package pocketbase container install")
            }
            return
        }

        print("✅ Container CLI found at: \(containerPath!)")
        print("")

        switch action {
        case .status:
            try await checkContainerStatus(containerPath: containerPath!)
        case .start:
            try await startContainer(containerPath: containerPath!)
        case .stop:
            try await stopContainer(containerPath: containerPath!)
        case .install:
            print("Container CLI is already installed.")
        }
    }

    private enum ContainerAction {
        case status, start, stop, install
    }

    private func printContainerHelp() {
        print("""
        Usage: swift package pocketbase container [command]

        Commands:
          status    Check container system status (default)
          start     Start the container system
          stop      Stop the container system
          install   Install the Apple Container CLI via Homebrew

        Options:
          --help, -h    Show this help message

        The container system must be running before you can use PocketBaseServer.
        """)
    }

    private func checkContainerStatus(containerPath: String) async throws {
        print("📊 Container System Status")
        print("--------------------------")

        let result = try runProcess(containerPath, arguments: ["system", "status"], verbose: false)
        print(result.output)

        if result.exitCode != 0 {
            print("")
            print("💡 Tip: Run 'swift package pocketbase container start' to start the container system")
        }
    }

    private func startContainer(containerPath: String) async throws {
        print("🚀 Starting container system...")
        print("")

        let result = try runProcess(containerPath, arguments: ["system", "start"], verbose: false)
        if !result.output.isEmpty {
            print(result.output)
        }

        if result.exitCode == 0 {
            print("✅ Container system started successfully!")
            print("")
            print("You can now run PocketBaseServer:")
            print("  swift package pocketbase run")
        } else {
            print("❌ Failed to start container system (exit code: \(result.exitCode))")
            print("")
            print("You may need to grant permissions in System Settings > Privacy & Security")
        }
    }

    private func stopContainer(containerPath: String) async throws {
        print("🛑 Stopping container system...")
        print("")

        let result = try runProcess(containerPath, arguments: ["system", "stop"], verbose: false)
        if !result.output.isEmpty {
            print(result.output)
        }

        if result.exitCode == 0 {
            print("✅ Container system stopped")
        } else {
            print("❌ Failed to stop container system (exit code: \(result.exitCode))")
        }
    }

    private func installContainerCLI() async throws {
        print("📦 Installing Apple Container CLI...")
        print("")

        let brewPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
            ? "/opt/homebrew/bin/brew"
            : "/usr/local/bin/brew"

        guard FileManager.default.fileExists(atPath: brewPath) else {
            print("❌ Homebrew not found. Please install Homebrew first:")
            print("   /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
            throw PocketBasePluginError.homebrewNotFound
        }

        // Add tap
        print("Adding apple/container tap...")
        _ = try runProcess(brewPath, arguments: ["tap", "apple/container"], verbose: true)

        // Install container
        print("Installing container...")
        let result = try runProcess(brewPath, arguments: ["install", "apple/container/container"], verbose: true)

        if result.exitCode == 0 {
            print("")
            print("✅ Apple Container CLI installed successfully!")
            print("")
            print("Next steps:")
            print("  1. Run: swift package pocketbase container start")
            print("  2. Run: swift package pocketbase run")
        } else {
            print("❌ Installation failed")
            throw PocketBasePluginError.installationFailed
        }
    }
}

// MARK: - Database Command

extension PocketBasePlugin {
    func dbCommand(context: PluginContext, arguments: [String]) throws {
        guard !arguments.isEmpty else {
            printDbHelp()
            return
        }

        let command = arguments[0]

        if command == "--help" || command == "-h" {
            printDbHelp()
            return
        }

        let remainingArgs = Array(arguments.dropFirst())
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
            printDbHelp()
        }
    }

    private func printDbHelp() {
        print("""
        Usage: swift package pocketbase db <command> [options]

        Commands:
          clear              Clear all data (removes pb_data contents)
          backup [name]      Create a backup of pb_data
          restore <name>     Restore from a backup
          info               Show database info
          path               Print the pb_data path

        Options:
          --data-path <path>  Custom path to pb_data directory (default: ./pb_data)
          --help, -h          Show this help

        Examples:
          swift package pocketbase db clear
          swift package pocketbase db backup my-backup
          swift package pocketbase db restore my-backup
          swift package pocketbase db info
        """)
    }

    private func findDataPath(context: PluginContext, args: [String]) -> String {
        if let index = args.firstIndex(of: "--data-path"), index + 1 < args.count {
            return args[index + 1]
        }
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

        try FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)

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
            print("Available backups:")
            if FileManager.default.fileExists(atPath: backupsDir.path) {
                let backups = try FileManager.default.contentsOfDirectory(atPath: backupsDir.path)
                for backup in backups {
                    print("  - \(backup)")
                }
            } else {
                print("  No backups found")
            }
            print("\nUsage: swift package pocketbase db restore <backup-name>")
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

        if FileManager.default.fileExists(atPath: dataPath) {
            try FileManager.default.removeItem(at: url)
        }

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

        if let size = directorySize(url: url) {
            print("Size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
        }

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
}

// MARK: - Errors

enum PocketBasePluginError: Error, CustomStringConvertible {
    case buildFailed
    case binaryNotFound
    case entitlementsNotFound
    case signingFailed
    case containerRuntimeFailed
    case unsupportedPlatform
    case homebrewNotFound
    case installationFailed

    var description: String {
        switch self {
        case .buildFailed:
            return "Failed to build PocketBaseServer"
        case .binaryNotFound:
            return "PocketBaseServer binary not found"
        case .entitlementsNotFound:
            return "Entitlements file not found"
        case .signingFailed:
            return "Failed to sign binary with entitlements"
        case .containerRuntimeFailed:
            return "Failed to start container runtime"
        case .unsupportedPlatform:
            return "Container support is only available on macOS"
        case .homebrewNotFound:
            return "Homebrew is required to install the Apple Container CLI"
        case .installationFailed:
            return "Failed to install the Apple Container CLI"
        }
    }
}
