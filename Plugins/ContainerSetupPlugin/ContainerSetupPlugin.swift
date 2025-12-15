//
//  ContainerSetupPlugin.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/14/24.
//

import PackagePlugin
import Foundation

@main
struct ContainerSetupPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        print("🐳 PocketBase Container Setup")
        print("==============================")
        print("")

        // Check if we're on macOS
        #if !os(macOS)
        print("❌ Container support is only available on macOS")
        throw ContainerSetupError.unsupportedPlatform
        #endif

        // Parse arguments
        var shouldStart = false
        var shouldStop = false
        var shouldStatus = false
        var shouldInstall = false

        if arguments.isEmpty {
            shouldStatus = true
        }

        for arg in arguments {
            switch arg {
            case "start":
                shouldStart = true
            case "stop":
                shouldStop = true
            case "status":
                shouldStatus = true
            case "install":
                shouldInstall = true
            case "--help", "-h":
                printHelp()
                return
            default:
                print("Unknown argument: \(arg)")
                printHelp()
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

            if shouldInstall {
                try await installContainerCLI()
            } else {
                print("Run with 'install' argument to install automatically:")
                print("  swift package container-setup install")
            }
            return
        }

        print("✅ Container CLI found at: \(containerPath!)")
        print("")

        // Handle commands
        if shouldStatus || (!shouldStart && !shouldStop && !shouldInstall) {
            try await checkStatus(containerPath: containerPath!)
        }

        if shouldStart {
            try await startContainer(containerPath: containerPath!)
        }

        if shouldStop {
            try await stopContainer(containerPath: containerPath!)
        }
    }

    private func printHelp() {
        print("""
        Usage: swift package container-setup [command]

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

    private func findContainerCLI() -> String? {
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

    private func checkStatus(containerPath: String) async throws {
        print("📊 Container System Status")
        print("--------------------------")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: containerPath)
        process.arguments = ["system", "status"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print(output)
        }

        if process.terminationStatus != 0 {
            print("")
            print("💡 Tip: Run 'swift package container-setup start' to start the container system")
        }
    }

    private func startContainer(containerPath: String) async throws {
        print("🚀 Starting container system...")
        print("")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: containerPath)
        process.arguments = ["system", "start"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }

        if process.terminationStatus == 0 {
            print("✅ Container system started successfully!")
            print("")
            print("You can now run PocketBaseServer:")
            print("  swift run PocketBaseServer")
        } else {
            print("❌ Failed to start container system (exit code: \(process.terminationStatus))")
            print("")
            print("You may need to grant permissions in System Settings > Privacy & Security")
        }
    }

    private func stopContainer(containerPath: String) async throws {
        print("🛑 Stopping container system...")
        print("")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: containerPath)
        process.arguments = ["system", "stop"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }

        if process.terminationStatus == 0 {
            print("✅ Container system stopped")
        } else {
            print("❌ Failed to stop container system (exit code: \(process.terminationStatus))")
        }
    }

    private func installContainerCLI() async throws {
        print("📦 Installing Apple Container CLI...")
        print("")

        // Check if Homebrew is installed
        let brewPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
            ? "/opt/homebrew/bin/brew"
            : "/usr/local/bin/brew"

        guard FileManager.default.fileExists(atPath: brewPath) else {
            print("❌ Homebrew not found. Please install Homebrew first:")
            print("   /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
            throw ContainerSetupError.homebrewNotFound
        }

        // Add tap
        print("Adding apple/container tap...")
        let tapProcess = Process()
        tapProcess.executableURL = URL(fileURLWithPath: brewPath)
        tapProcess.arguments = ["tap", "apple/container"]
        try tapProcess.run()
        tapProcess.waitUntilExit()

        // Install container
        print("Installing container...")
        let installProcess = Process()
        installProcess.executableURL = URL(fileURLWithPath: brewPath)
        installProcess.arguments = ["install", "apple/container/container"]

        let pipe = Pipe()
        installProcess.standardOutput = pipe
        installProcess.standardError = pipe

        try installProcess.run()
        installProcess.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            print(output)
        }

        if installProcess.terminationStatus == 0 {
            print("")
            print("✅ Apple Container CLI installed successfully!")
            print("")
            print("Next steps:")
            print("  1. Run: swift package container-setup start")
            print("  2. Run: swift run PocketBaseServer")
        } else {
            print("❌ Installation failed")
            throw ContainerSetupError.installationFailed
        }
    }
}

enum ContainerSetupError: Error, CustomStringConvertible {
    case unsupportedPlatform
    case homebrewNotFound
    case installationFailed
    case containerNotRunning

    var description: String {
        switch self {
        case .unsupportedPlatform:
            return "Container support is only available on macOS"
        case .homebrewNotFound:
            return "Homebrew is required to install the Apple Container CLI"
        case .installationFailed:
            return "Failed to install the Apple Container CLI"
        case .containerNotRunning:
            return "Container system is not running"
        }
    }
}
