//
//  PocketBaseContainer.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/11/24.
//

#if os(macOS)

import Containerization
import ContainerizationOCI
import ContainerizationOS
import Foundation

/// A Writer that prints container output to the console
/// Used to capture PocketBase's stdout/stderr including the installer URL
@available(macOS 26.0, *)
final class ConsoleWriter: Writer, @unchecked Sendable {
    private let prefix: String
    private let urlHandler: ((String) -> Void)?

    init(prefix: String = "", urlHandler: ((String) -> Void)? = nil) {
        self.prefix = prefix
        self.urlHandler = urlHandler
    }

    func write(_ data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else { return }

        // Print with prefix
        for line in string.components(separatedBy: "\n") where !line.isEmpty {
            print("\(prefix)\(line)")

            // Check for installer URL (PocketBase 0.23+)
            if line.contains("/#/pbinstal/") || line.contains("/_/#/pbinstal/") {
                urlHandler?(line)
            }
        }
    }

    func close() throws {}
}

/// Configuration for the PocketBase container
@available(macOS 26.0, *)
public struct PocketBaseContainerConfiguration: Sendable {
    /// The port to expose PocketBase on (default: 8090)
    public var port: Int

    /// The path to the data directory on the host (default: ./pb_data)
    public var dataPath: String

    /// Number of CPUs to allocate to the container
    public var cpus: Int

    /// Memory in bytes to allocate to the container
    public var memoryInBytes: UInt64

    /// Size of the root filesystem in bytes
    public var rootfsSizeInBytes: UInt64

    /// Enable verbose logging
    public var verbose: Bool

    public init(
        port: Int = 8090,
        dataPath: String = "./pb_data",
        cpus: Int = 2,
        memoryInBytes: UInt64 = 512 * 1024 * 1024, // 512 MiB
        rootfsSizeInBytes: UInt64 = 2 * 1024 * 1024 * 1024, // 2 GiB
        verbose: Bool = false
    ) {
        self.port = port
        self.dataPath = dataPath
        self.cpus = cpus
        self.memoryInBytes = memoryInBytes
        self.rootfsSizeInBytes = rootfsSizeInBytes
        self.verbose = verbose
    }
}

/// Manages a PocketBase container using Apple's Containerization framework
@available(macOS 26.0, *)
public actor PocketBaseContainer {
    /// The container image reference
    public static let imageReference = "docker.io/adrianmusante/pocketbase:latest"

    /// The init filesystem image reference
    public static let initfsReference = "ghcr.io/apple/containerization/vminit:0.13.0"

    /// Container ID
    public static let containerId = "pocketbase-server"

    private var manager: ContainerManager?
    private var container: LinuxContainer?
    private let configuration: PocketBaseContainerConfiguration
    private var portForwarder: PortForwarder?

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

    /// Get the kernel path - checks ./vmlinux first, then falls back to the system kernel location
    private func getKernelPath() throws -> URL {
        // First try ./vmlinux in current directory (like ctr-example)
        let localKernel = URL(fileURLWithPath: "./vmlinux")
        if FileManager.default.fileExists(atPath: localKernel.path) {
            return localKernel
        }

        // Fall back to the system kernel location
        let systemKernel = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.container/kernels/default.kernel-arm64")
        if FileManager.default.fileExists(atPath: systemKernel.path) {
            return systemKernel
        }

        throw PocketBaseContainerError.kernelNotFound
    }

    /// Clean up stale container from previous runs
    private func cleanupStaleContainer() throws {
        let containerPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.containerization/containers")
            .appendingPathComponent(Self.containerId)

        if configuration.verbose {
            print("[PocketBaseContainer] Checking for stale container at: \(containerPath.path)")
        }

        if FileManager.default.fileExists(atPath: containerPath.path) {
            if configuration.verbose {
                print("[PocketBaseContainer] Cleaning up stale container...")
            }
            try FileManager.default.removeItem(at: containerPath)
            if configuration.verbose {
                print("[PocketBaseContainer] Stale container removed successfully")
            }
        } else if configuration.verbose {
            print("[PocketBaseContainer] No stale container found")
        }
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
            // Clean up any stale container from previous runs
            try cleanupStaleContainer()

            let kernelPath = try getKernelPath()

            if configuration.verbose {
                print("[PocketBaseContainer] Using kernel at: \(kernelPath.path)")
                print("[PocketBaseContainer] Creating container manager...")
            }

            // Create data directory if it doesn't exist
            let dataURL = URL(fileURLWithPath: configuration.dataPath).absoluteURL
            try FileManager.default.createDirectory(at: dataURL, withIntermediateDirectories: true)

            // Create the container manager with vmnet networking (like ctr-example)
            var manager = try await ContainerManager(
                kernel: Kernel(path: kernelPath, platform: .linuxArm),
                initfsReference: Self.initfsReference,
                network: try ContainerManager.VmnetNetwork()
            )

            if configuration.verbose {
                print("[PocketBaseContainer] Creating container from \(Self.imageReference)...")
            }

            // Create the container
            let container = try await manager.create(
                Self.containerId,
                reference: Self.imageReference,
                rootfsSizeInBytes: configuration.rootfsSizeInBytes
            ) { @Sendable [configuration] config in
                config.cpus = configuration.cpus
                config.memoryInBytes = configuration.memoryInBytes

                // Set environment variables
                config.process.environmentVariables = [
                    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/pocketbase",
                    "HOME=/tmp"
                ]

                // Run pocketbase directly
                config.process.arguments = [
                    "pocketbase",
                    "serve",
                    "--http=0.0.0.0:\(configuration.port)",
                    "--dir=/tmp/pb_data"
                ]
                config.process.workingDirectory = "/pocketbase"

                // Capture stdout/stderr to see installer URL (PocketBase 0.23+)
                let outputWriter = ConsoleWriter(prefix: "[PocketBase] ")
                config.process.stdout = outputWriter
                config.process.stderr = outputWriter
            }

            self.manager = manager
            self.container = container

            if configuration.verbose {
                print("[PocketBaseContainer] Starting container...")
            }

            // Start the container
            try await container.create()
            try await container.start()

            state = .running

            // Get the container's IP address and start port forwarding
            if let interface = container.interfaces.first {
                let ip = String(interface.address.split(separator: "/").first ?? Substring(interface.address))
                self.containerIP = ip

                if configuration.verbose {
                    print("[PocketBaseContainer] Container started successfully")
                    print("[PocketBaseContainer] Container IP: \(ip)")
                }

                // Start port forwarder to make container accessible on localhost
                let forwarder = PortForwarder(
                    localPort: UInt16(configuration.port),
                    remoteHost: ip,
                    remotePort: UInt16(configuration.port),
                    verbose: configuration.verbose
                )
                self.portForwarder = forwarder
                try await forwarder.start()

                if configuration.verbose {
                    print("[PocketBaseContainer] PocketBase available at http://localhost:\(configuration.port)")
                }
            } else if configuration.verbose {
                print("[PocketBaseContainer] Container started successfully")
                print("[PocketBaseContainer] Warning: No network interface found, port forwarding not available")
            }

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

            // Stop the port forwarder first
            await portForwarder?.stop()
            portForwarder = nil

            if let container = container {
                try await container.stop()
            }

            if var manager = manager {
                try manager.delete(Self.containerId)
            }

            container = nil
            manager = nil
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
        guard let container = container else {
            throw PocketBaseContainerError.notRunning
        }
        let status = try await container.wait()
        return status.exitCode
    }
}

/// Errors that can occur when managing the PocketBase container
@available(macOS 26.0, *)
public enum PocketBaseContainerError: Error, LocalizedError {
    case notRunning
    case kernelNotFound
    case containerCreationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notRunning:
            return "Container is not running"
        case .kernelNotFound:
            return "Linux kernel not found. Please ensure the Apple container tool is installed and run `container system start` first."
        case .containerCreationFailed(let reason):
            return "Failed to create container: \(reason)"
        }
    }
}

#endif
