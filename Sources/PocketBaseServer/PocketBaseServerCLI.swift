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

@main
struct PocketBaseServerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pocketbase-server",
        abstract: "Run a PocketBase server using Apple's Containerization framework",
        discussion: """
            Runs the PocketBase Docker image (ghcr.io/muchobien/pocketbase:latest) using
            Apple's native container virtualization. No Docker Desktop required!
            
            The server will be available at http://localhost:<port> (default: 8090).
            
            First run will download the Linux kernel (~30MB) which may take a few minutes.
            """,
        version: "1.0.0"
    )
    
    @Option(name: [.short, .long], help: "Port to expose PocketBase on")
    var port: Int = 8090
    
    @Option(name: [.short, .long], help: "Path to the data directory")
    var dataPath: String = "./pb_data"
    
    @Option(name: .long, help: "Number of CPUs to allocate")
    var cpus: Int = 2
    
    @Option(name: .long, help: "Memory in megabytes to allocate")
    var memory: Int = 512
    
    @Option(name: .long, help: "Root filesystem size in megabytes")
    var fsSize: Int = 2048
    
    @Flag(name: [.short, .long], help: "Enable verbose output")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "Clear the data directory before starting")
    var clear: Bool = false
    
    func run() async throws {
        // Handle Ctrl+C gracefully
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN)
        
        let configuration = PocketBaseContainerConfiguration(
            port: port,
            dataPath: dataPath,
            cpus: cpus,
            memoryInBytes: UInt64(memory) * 1024 * 1024,
            rootfsSizeInBytes: UInt64(fsSize) * 1024 * 1024,
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
        print("  Port: \(port)")
        print("  Data: \(dataPath)")
        print("  CPUs: \(cpus)")
        print("  Memory: \(memory)MB")
        print("")
        
        do {
            try await container.start()
            
            print("")
            print("✅ PocketBase is running!")
            print("   Admin UI: http://localhost:\(port)/_/")
            print("   API: http://localhost:\(port)/api/")
            print("")
            print("Press Ctrl+C to stop the server")
            
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
