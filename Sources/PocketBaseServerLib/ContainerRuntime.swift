//
//  ContainerRuntime.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/14/24.
//

#if os(macOS)

import Foundation

/// Manages the Apple Container runtime system
@available(macOS 26.0, *)
public struct ContainerRuntime: Sendable {

    public init() {}

    /// Path to the container CLI
    private var containerCLIPath: String? {
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

        return nil
    }

    /// Check if the container CLI is installed
    public var isInstalled: Bool {
        containerCLIPath != nil
    }

    /// Check if the container system is running
    public func isRunning() -> Bool {
        guard let cliPath = containerCLIPath else {
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["system", "status"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            // Exit code 0 means it's running
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Check for "running" in the output
                    return output.lowercased().contains("running") &&
                           !output.lowercased().contains("not running")
                }
            }
            return false
        } catch {
            return false
        }
    }

    /// Start the container system
    /// - Parameter verbose: Whether to print status messages
    /// - Throws: ContainerRuntimeError if starting fails
    public func start(verbose: Bool = false) throws {
        guard let cliPath = containerCLIPath else {
            throw ContainerRuntimeError.cliNotInstalled
        }

        if verbose {
            print("[ContainerRuntime] Starting container system...")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["system", "start"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw ContainerRuntimeError.startFailed(output)
        }

        if verbose {
            print("[ContainerRuntime] Container system started")
        }
    }

    /// Stop the container system
    /// - Parameter verbose: Whether to print status messages
    /// - Throws: ContainerRuntimeError if stopping fails
    public func stop(verbose: Bool = false) throws {
        guard let cliPath = containerCLIPath else {
            throw ContainerRuntimeError.cliNotInstalled
        }

        if verbose {
            print("[ContainerRuntime] Stopping container system...")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["system", "stop"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw ContainerRuntimeError.stopFailed(output)
        }

        if verbose {
            print("[ContainerRuntime] Container system stopped")
        }
    }

    /// Ensure the container system is running, starting it if necessary
    /// - Parameter verbose: Whether to print status messages
    /// - Throws: ContainerRuntimeError if the system cannot be started
    public func ensureRunning(verbose: Bool = false) throws {
        guard isInstalled else {
            throw ContainerRuntimeError.cliNotInstalled
        }

        if isRunning() {
            if verbose {
                print("[ContainerRuntime] Container system already running")
            }
            return
        }

        if verbose {
            print("[ContainerRuntime] Container system not running, starting...")
        }

        try start(verbose: verbose)

        // Verify it started
        // Give it a moment to start
        Thread.sleep(forTimeInterval: 1.0)

        if !isRunning() {
            throw ContainerRuntimeError.startFailed("System did not start properly")
        }
    }
}

/// Errors that can occur when managing the container runtime
@available(macOS 26.0, *)
public enum ContainerRuntimeError: Error, LocalizedError {
    case cliNotInstalled
    case startFailed(String)
    case stopFailed(String)

    public var errorDescription: String? {
        switch self {
        case .cliNotInstalled:
            return """
                Apple Container CLI not found. Please install it with:
                  brew tap apple/container
                  brew install apple/container/container
                """
        case .startFailed(let output):
            return "Failed to start container system: \(output)"
        case .stopFailed(let output):
            return "Failed to stop container system: \(output)"
        }
    }
}

#endif
