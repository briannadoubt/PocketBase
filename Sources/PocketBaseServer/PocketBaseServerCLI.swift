//
//  main.swift
//  PocketBaseServer
//
//  Created by Brianna Zamora on 12/11/24.
//

#if os(macOS)

import ArgumentParser
import Foundation
import PocketBaseServerLib

@available(macOS 26.0, *)
@main
struct PocketBaseServerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pocketbase-server",
        abstract: "Run a PocketBase server using Apple's Containerization framework",
        discussion: """
            Runs the PocketBase Docker image (ghcr.io/muchobien/pocketbase:latest) using
            Apple's native container virtualization. No Docker Desktop required!

            The server will be available at http://<host>:<port> (default: 0.0.0.0:8090).

            First run will download the Linux kernel (~30MB) which may take a few minutes.

            Host options:
              0.0.0.0   - Listen on all interfaces (allows network access from phones, etc.)
              localhost - Listen only on localhost (local machine only)
              <ip>      - Listen on a specific IP address
            """,
        version: "1.0.0"
    )

    @Option(name: [.customShort("H"), .long], help: "Host/interface to bind to (default: 0.0.0.0 for all interfaces)")
    var host: String = "0.0.0.0"

    @Option(name: [.short, .long], help: "Port to expose PocketBase on (default: 8090)")
    var port: Int = 8090

    @Option(name: [.short, .long], help: "Path to the data directory")
    var dataPath: String = "./pb_data"

    @Option(name: .long, help: "Number of CPUs to allocate")
    var cpus: Int = 2

    @Option(name: .long, help: "Memory in megabytes to allocate")
    var memory: Int = 512

    @Flag(name: [.short, .long], help: "Enable verbose output")
    var verbose: Bool = false

    @Flag(name: .long, help: "Clear the data directory before starting")
    var clear: Bool = false

    /// Get the local network IP address
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            // Check for IPv4
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // Look for en0 (WiFi) or en1 (Ethernet)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    ) == 0 {
                        address = hostname.withUnsafeBufferPointer { buffer in
                            String(cString: buffer.baseAddress!)
                        }
                        break
                    }
                }
            }
        }

        return address
    }
    
    func run() async throws {
        // Handle Ctrl+C gracefully
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN)

        let configuration = PocketBaseContainerConfiguration(
            host: host,
            port: port,
            dataPath: dataPath,
            cpus: cpus,
            memoryInBytes: UInt64(memory) * 1024 * 1024,
            verbose: verbose
        )

        // Clear data directory if requested
        if clear {
            let dataURL = URL(fileURLWithPath: dataPath)
            if FileManager.default.fileExists(atPath: dataURL.path) {
                if verbose {
                    print("Clearing data directory: \(dataPath)")
                }
                try? FileManager.default.removeItem(at: dataURL)
            }
        }

        let container = PocketBaseContainer(configuration: configuration)

        signalSource.setEventHandler {
            print("\nShutting down...")
            Task {
                try? await container.stop()
                Foundation.exit(0)
            }
        }
        signalSource.resume()

        print("Starting PocketBase server...")
        print("  Host: \(host)")
        print("  Port: \(port)")
        print("  Data: \(dataPath)")
        print("  CPUs: \(cpus)")
        print("  Memory: \(memory)MB")
        print("")

        do {
            try await container.start()

            print("")
            print("✅ PocketBase is running!")
            print("")

            // Show accessible URLs based on host configuration
            if host == "0.0.0.0" {
                // Listening on all interfaces
                print("   Local:   http://localhost:\(port)/_/")
                if let networkIP = getLocalIPAddress() {
                    print("   Network: http://\(networkIP):\(port)/_/")
                }
            } else if host == "localhost" || host == "127.0.0.1" {
                // Localhost only
                print("   Admin UI: http://localhost:\(port)/_/")
            } else {
                // Specific IP
                print("   Admin UI: http://\(host):\(port)/_/")
            }

            print("")
            print("Press Ctrl+C to stop the server")
            print("")

            // Wait for the container to exit
            let exitCode = try await container.wait()

            print("Container exited with code: \(exitCode)")

        } catch {
            print("❌ Error: \(error.localizedDescription)")
            throw error
        }
    }
}

#else

@main
struct PocketBaseServerCLI {
    static func main() {
        fatalError("PocketBaseServer is only available on macOS")
    }
}

#endif
