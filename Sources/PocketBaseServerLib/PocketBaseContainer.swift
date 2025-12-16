//
//  PocketBaseContainer.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/11/24.
//

#if os(macOS)

import Foundation

/// Configuration for the PocketBase container
@available(macOS 26.0, *)
public struct PocketBaseContainerConfiguration: Sendable {
    /// The host/interface to bind to (default: 0.0.0.0 for all interfaces)
    /// Use "localhost" or "127.0.0.1" to only allow local connections
    /// Use "0.0.0.0" to allow connections from any interface (including network)
    public var host: String

    /// The port to expose PocketBase on (default: 8090)
    public var port: Int

    /// The path to the data directory on the host (default: ./pb_data)
    public var dataPath: String

    /// Number of CPUs to allocate to the container
    public var cpus: Int

    /// Memory in bytes to allocate to the container
    public var memoryInBytes: UInt64

    /// Enable verbose logging
    public var verbose: Bool

    public init(
        host: String = "0.0.0.0",
        port: Int = 8090,
        dataPath: String = "./pb_data",
        cpus: Int = 2,
        memoryInBytes: UInt64 = 512 * 1024 * 1024, // 512 MiB
        verbose: Bool = false
    ) {
        self.host = host
        self.port = port
        self.dataPath = dataPath
        self.cpus = cpus
        self.memoryInBytes = memoryInBytes
        self.verbose = verbose
    }
}

/// Manages a PocketBase container using Apple's container CLI
@available(macOS 26.0, *)
public actor PocketBaseContainer {
    /// The container image reference
    public static let imageReference = "ghcr.io/muchobien/pocketbase:latest"

    /// Container name
    public static let containerName = "pocketbase-server"

    private let configuration: PocketBaseContainerConfiguration
    private var portForwarder: PortForwarder?
    private var logStreamProcess: Process?

    /// Current state of the container
    public private(set) var state: ContainerState = .stopped

    /// The container's IP address (available after start)
    public private(set) var containerIP: String?

    /// Possible states of the container
    public enum ContainerState: Sendable {
        case stopped
        case starting
        case running
        case stopping
        case error(String)
    }

    public init(configuration: PocketBaseContainerConfiguration = .init()) {
        self.configuration = configuration
    }

    /// Find the container CLI path
    private func findContainerCLI() -> String? {
        let paths = [
            "/opt/homebrew/bin/container",
            "/usr/local/bin/container",
            "/usr/bin/container"
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }

    /// Run a container CLI command and return the output
    private func runContainerCommand(_ arguments: [String], silent: Bool = false) throws -> String {
        guard let cliPath = findContainerCLI() else {
            throw PocketBaseContainerError.containerCLINotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = silent ? FileHandle.nullDevice : pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Start streaming container logs to stdout
    private func startLogStreaming() throws {
        guard let cliPath = findContainerCLI() else {
            throw PocketBaseContainerError.containerCLINotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["logs", "--follow", Self.containerName]

        // Stream stdout directly to our stdout
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        try process.run()
        logStreamProcess = process

        if configuration.verbose {
            print("[PocketBaseContainer] Log streaming started")
        }
    }

    /// Stop log streaming
    private func stopLogStreaming() {
        logStreamProcess?.terminate()
        logStreamProcess = nil
    }

    /// Stop and remove any existing container with the same name
    private func cleanupExistingContainer() {
        if configuration.verbose {
            print("[PocketBaseContainer] Cleaning up any existing container...")
        }

        // Try to stop and remove existing container (ignore errors)
        _ = try? runContainerCommand(["stop", Self.containerName], silent: true)
        _ = try? runContainerCommand(["rm", Self.containerName], silent: true)
    }

    /// Get the IP address of a running container
    private func getContainerIP() throws -> String? {
        let output = try runContainerCommand(["ls"])

        // Parse the output to find our container's IP
        // Format: ID  IMAGE  OS  ARCH  STATE  ADDR  CPUS  MEMORY
        for line in output.components(separatedBy: "\n") {
            if line.contains(Self.containerName) {
                let parts = line.split(separator: " ").map(String.init)
                // Find the IP address (looks like 192.168.x.x)
                for part in parts {
                    if part.contains("192.168.") || part.contains("10.") || part.contains("172.") {
                        return part
                    }
                }
            }
        }
        return nil
    }

    /// Start the PocketBase container
    public func start() async throws {
        guard case .stopped = state else {
            if configuration.verbose {
                print("[PocketBaseContainer] Container already running or in transition")
            }
            return
        }

        state = .starting

        do {
            // Ensure the container runtime is running
            let runtime = ContainerRuntime()
            try runtime.ensureRunning(verbose: configuration.verbose)

            guard findContainerCLI() != nil else {
                throw PocketBaseContainerError.containerCLINotFound
            }

            // Clean up any existing container
            cleanupExistingContainer()

            if configuration.verbose {
                print("[PocketBaseContainer] Starting container from \(Self.imageReference)...")
            }

            // Run the container in detached mode
            let memoryMB = configuration.memoryInBytes / (1024 * 1024)

            // Resolve and create the data directory for persistence
            let dataURL: URL
            let expandedPath = NSString(string: configuration.dataPath).expandingTildeInPath
            if expandedPath.hasPrefix("/") {
                dataURL = URL(fileURLWithPath: expandedPath)
            } else {
                dataURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent(expandedPath)
            }

            // Create data directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: dataURL.path) {
                try FileManager.default.createDirectory(at: dataURL, withIntermediateDirectories: true)
                if configuration.verbose {
                    print("[PocketBaseContainer] Created data directory: \(dataURL.path)")
                }
            }

            let output = try runContainerCommand([
                "run",
                "-d",
                "--name", Self.containerName,
                "-c", String(configuration.cpus),
                "-m", "\(memoryMB)M",
                "-v", "\(dataURL.path):/pb_data",
                Self.imageReference
            ])

            if configuration.verbose {
                print("[PocketBaseContainer] Container started: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }

            // Wait a moment for the container to get an IP
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Get the container IP
            guard let ip = try getContainerIP() else {
                throw PocketBaseContainerError.containerCreationFailed("Could not get container IP address")
            }

            self.containerIP = ip

            if configuration.verbose {
                print("[PocketBaseContainer] Container IP: \(ip)")
                print("[PocketBaseContainer] Setting up port forwarding...")
            }

            // Start port forwarder
            let forwarder = PortForwarder(
                localHost: configuration.host,
                localPort: UInt16(configuration.port),
                remoteHost: ip,
                remotePort: UInt16(configuration.port),
                verbose: configuration.verbose
            )
            self.portForwarder = forwarder
            try await forwarder.start()

            state = .running

            if configuration.verbose {
                print("[PocketBaseContainer] Port forwarding active")
                print("[PocketBaseContainer] PocketBase available at http://localhost:\(configuration.port)")
                print("[PocketBaseContainer] Admin UI: http://localhost:\(configuration.port)/_/")
            }

            // Start streaming container logs to stdout
            try startLogStreaming()

        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    /// Stop the PocketBase container
    public func stop() async throws {
        guard case .running = state else {
            if configuration.verbose {
                print("[PocketBaseContainer] Container not running")
            }
            return
        }

        state = .stopping

        do {
            if configuration.verbose {
                print("[PocketBaseContainer] Stopping container...")
            }

            // Stop log streaming
            stopLogStreaming()

            // Stop port forwarder
            await portForwarder?.stop()
            portForwarder = nil

            // Stop and remove the container
            _ = try runContainerCommand(["stop", Self.containerName], silent: true)
            _ = try runContainerCommand(["rm", Self.containerName], silent: true)

            containerIP = nil
            state = .stopped

            if configuration.verbose {
                print("[PocketBaseContainer] Container stopped")
            }

        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    /// Wait for the container to exit
    public func wait() async throws -> Int32 {
        guard case .running = state else {
            throw PocketBaseContainerError.notRunning
        }

        // Poll container status until it's no longer running
        while true {
            let output = try runContainerCommand(["ls"], silent: true)
            if !output.contains(Self.containerName) || !output.lowercased().contains("running") {
                break
            }
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        return 0
    }
}

/// Errors that can occur when managing the PocketBase container
@available(macOS 26.0, *)
public enum PocketBaseContainerError: Error, LocalizedError {
    case notRunning
    case containerCLINotFound
    case containerCreationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notRunning:
            return "Container is not running"
        case .containerCLINotFound:
            return """
                Apple Container CLI not found. Please install it with:
                  brew tap apple/container
                  brew install apple/container/container
                """
        case .containerCreationFailed(let reason):
            return "Failed to create container: \(reason)"
        }
    }
}

#endif
