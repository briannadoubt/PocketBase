//
//  RunServerPlugin.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/14/24.
//

import PackagePlugin
import Foundation

@main
struct RunServerPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        print("🚀 PocketBase Server Runner")
        print("===========================")
        print("")

        // Parse arguments
        var serverArgs: [String] = []
        var skipBuild = false

        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            if arg == "--skip-build" {
                skipBuild = true
            } else if arg == "--help" || arg == "-h" {
                printHelp()
                return
            } else {
                // Pass remaining args to the server
                serverArgs.append(contentsOf: arguments[i...])
                break
            }
            i += 1
        }

        let packageDirectory = context.package.directoryURL

        // Step 1: Build the server (unless skipped)
        if !skipBuild {
            print("📦 Building PocketBaseServer...")
            let buildResult = try runProcess(
                "/usr/bin/swift",
                arguments: ["build", "--package-path", packageDirectory.path, "--target", "PocketBaseServer"],
                verbose: true
            )
            if buildResult.exitCode != 0 {
                print("❌ Build failed")
                throw RunServerError.buildFailed
            }
            print("✅ Build succeeded")
            print("")
        }

        // Step 2: Find the built binary
        let binaryPath = packageDirectory
            .appendingPathComponent(".build/debug/PocketBaseServer")

        guard FileManager.default.fileExists(atPath: binaryPath.path) else {
            print("❌ Binary not found at \(binaryPath.path)")
            throw RunServerError.binaryNotFound
        }

        // Step 3: Sign with entitlements
        print("🔏 Signing binary with entitlements...")
        let entitlementsPath = packageDirectory
            .appendingPathComponent("Sources/PocketBaseServer/PocketBaseServer.entitlements")

        guard FileManager.default.fileExists(atPath: entitlementsPath.path) else {
            print("❌ Entitlements file not found at \(entitlementsPath.path)")
            throw RunServerError.entitlementsNotFound
        }

        let signResult = try runProcess(
            "/usr/bin/codesign",
            arguments: [
                "--entitlements", entitlementsPath.path,
                "--force",
                "-s", "-",
                binaryPath.path
            ],
            verbose: false
        )

        if signResult.exitCode != 0 {
            print("❌ Code signing failed: \(signResult.output)")
            throw RunServerError.signingFailed
        }
        print("✅ Binary signed")
        print("")

        // Step 4: Ensure container runtime is running
        print("🐳 Checking container runtime...")
        let containerPath = findContainerCLI()

        if let containerPath = containerPath {
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

        // Run the server interactively
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = serverArgs
        process.currentDirectoryURL = packageDirectory

        // Connect to terminal for interactive use
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

    private func printHelp() {
        print("""
        Usage: swift package run-server [options] [-- server-options]

        Options:
          --skip-build    Skip building (use existing binary)
          --help, -h      Show this help

        Server Options (passed to PocketBaseServer):
          -p, --port      Port to expose PocketBase on (default: 8090)
          -d, --dataPath  Path to data directory (default: ./pb_data)
          --cpus          Number of CPUs to allocate (default: 2)
          --memory        Memory in MB to allocate (default: 512)
          --verbose       Enable verbose output

        Examples:
          swift package run-server
          swift package run-server -- --port 8080 --verbose
          swift package run-server --skip-build -- -p 9090
        """)
    }

    private func findContainerCLI() -> String? {
        let paths = [
            "/opt/homebrew/bin/container",
            "/usr/local/bin/container",
            "/usr/bin/container"
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }

    private func runProcess(_ executable: String, arguments: [String], verbose: Bool) throws -> (exitCode: Int32, output: String) {
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
}

enum RunServerError: Error, CustomStringConvertible {
    case buildFailed
    case binaryNotFound
    case entitlementsNotFound
    case signingFailed
    case containerRuntimeFailed

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
        }
    }
}
